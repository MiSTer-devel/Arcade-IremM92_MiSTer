`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module nec_decode(
    input clk,
    input ce_1,
    input ce_2,

    output reg [15:0] pc,

    input [15:0] new_pc,
    input        set_pc,

    input        retire_op,

    input [3:0] ipq_len,
    input [7:0] ipq[8],

    output logic valid,

    output logic block_prefetch,

    output nec_decode_t decoded
);

function bit [7:0] ipq_byte(bit [2:0] ofs);
    return ipq[pc[2:0] + ofs[2:0]];
endfunction

decode_state_e state;

nec_decode_t d; // in flight
assign decoded = d;

function bit [2:0] calc_imm_size(width_e width, operand_e s0, operand_e s1);
    case(s0)
    OPERAND_IMM: return { 1'd0, width } + 3'd1;
    OPERAND_IMM8: return 3'd1;
    OPERAND_IMM_EXT: return 3'd1;
    default: begin end
    endcase

    case(s1)
    OPERAND_IMM: return { 1'd0, width } + 3'd1;
    OPERAND_IMM8: return 3'd1;
    OPERAND_IMM_EXT: return 3'd1;
    default: begin end
    endcase

    return 3'd0;
endfunction

function bit [2:0] calc_disp_size(bit [2:0] mem, bit [1:0] mod);
    case(mod)
    2'b00: begin
        if (mem == 3'b110) return 3'd2;
        return 3'd0;
    end
    2'b01: return 3'd1;
    2'b10: return 3'd2;
    2'b11: return 3'd0;
    endcase
endfunction

function sreg_index_e calc_seg(bit [2:0] mem, bit [1:0] mod);
    sreg_index_e seg;
    case(mem)
    3'b010: seg = SS;
    3'b011: seg = SS;
    3'b110: seg = mod == 0 ? DS0 : SS;
    default: seg = DS0;
    endcase

    return seg;
endfunction

/* verilator lint_off CASEX */
/* verilator lint_off CASEOVERLAP */
`include "opcodes.svh"
/* verilator lint_on CASEOVERLAP */
/* verilator lint_on CASEX */

reg [2:0] disp_read;
reg [2:0] imm_read;

task reset_decode();
    d.segment_override <= 0;
    d.segment <= DS0;
    d.buslock <= 0;
    d.rep <= REPEAT_NONE;
    d.io <= 0;
    d.mem_write <= 0;
    d.mem_read <= 0;
    d.mod <= 2'b11;
    d.dest <= OPERAND_NONE;
    d.source0 <= OPERAND_NONE;
    d.source1 <= OPERAND_NONE;
    d.opcode <= OP_INVALID;
    d.alu_operation <= ALU_OP_NONE;
    d.push <= 16'd0;
    d.pop <= 16'd0;

    d.disp_size <= 3'd0;
    d.opclass <= MISC;

    decode_valid <= 0;
    disp_read <= 3'd0;
    imm_read <= 3'd0;
    state <= INITIAL;
endtask


//wire [2:0] disp_size = calc_disp_size(d.rm, d.mod);
wire [2:0] imm_size = calc_imm_size(d.width, d.source0, d.source1);

reg decode_valid;

`ifdef ONE_CYCLE_DECODE_DELAY
wire decode_ready = state == TERMINAL && d.disp_size == disp_read && imm_size == imm_read && decode_valid;
`else
wire decode_ready = state == TERMINAL && d.disp_size == disp_read && imm_size == imm_read;
`endif

assign valid = decode_ready & ~set_pc;

`ifdef BRANCH_BLOCK_PREFETCH
assign block_prefetch = state == TERMINAL && d.opclass == BRANCH && ipq_len > 3;
`else
assign block_prefetch = 0;
`endif 

always_ff @(posedge clk) begin
    bit [3:0] avail;
    bit [7:0] q;

    avail = ipq_len;

    q = ipq_byte(0);

    if (ce_1 | ce_2) begin
        if (set_pc) begin
            pc <= new_pc;
            reset_decode();
            d.pc <= new_pc;
        end else if (ce_1) begin
            case(state)
                TERMINAL: begin
                    if (disp_read < d.disp_size || imm_read < imm_size) begin
`ifndef OPERAND_DECODE_DELAY
                        decode_valid <= 1;
`endif
`ifdef FULL_OPERAND_FETCH
                        if (avail >= (d.disp_size + imm_size)) begin
                            d.disp[7:0] <= ipq_byte(0);
                            d.disp[15:8] <= ipq_byte(1);
                            d.imm[7:0] <= ipq_byte(d.disp_size);
                            d.imm[15:8] <= ipq_byte(d.disp_size + 1);
                            d.imm[23:16] <= ipq_byte(d.disp_size + 2);
                            d.imm[31:24] <= ipq_byte(d.disp_size + 3);
                            pc <= pc + {13'd0, d.disp_size} + {13'd0, imm_size};
                            d.end_pc <= pc + {13'd0, d.disp_size} + {13'd0, imm_size};
                            disp_read <= d.disp_size;
                            imm_read <= imm_size;
                        end
`else
                        if (disp_read < d.disp_size) begin
                            if (avail > 0) begin
                                d.disp[(disp_read*8) +: 8] <= q;
                                pc <= pc + 16'd1;
                                d.end_pc <= pc + 16'd1;
                                disp_read <= disp_read + 3'd1;
                            end
                        end else if (imm_read < imm_size) begin
                            if (avail > 0) begin
                                d.imm[(imm_read*8) +: 8] <= q;
                                pc <= pc + 16'd1;
                                d.end_pc <= pc + 16'd1;
                                imm_read <= imm_read + 3'd1;
                            end
                        end
`endif
                    end else begin
                        decode_valid <= 1;
                        if (retire_op) begin
                            reset_decode();
                            d.pc <= pc;
                            if (avail > 0) begin
                                process_decode(q);
                                pc <= pc + 16'd1;
                                d.end_pc <= pc + 16'd1;
                            end
                        end
                    end
                end

                DELAY_3: state <= DELAY_2;
                DELAY_2: state <= DELAY_1;
                DELAY_1: state <= TERMINAL;

                default: begin
                    if (avail > 0) begin
                        process_decode(q);
                        pc <= pc + 16'd1;
                        d.end_pc <= pc + 16'd1;
                    end
                end

            endcase
        end
    end
end

endmodule