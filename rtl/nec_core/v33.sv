`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module V33(
    input               clk,
    input               ce_1,
    input               ce_2,


    // Pins
    input               reset,
    input               hldrq,
    input               n_ready,
    input               bs16,

    output              hldak,
    output              n_buslock,
    output              n_ube,
    output              r_w,
    output              m_io,
    output              busst0,
    output              busst1,
    output              aex,
    output              n_bcyst,
    output              n_dstb,

    input               intreq,
    input               n_nmi,

    input               n_cpbusy,
    input               n_cperr,
    input               cpreq,

    output      [23:0]  addr,
    output      [15:0]  dout,
    input       [15:0]  din,

    // Non-hardware
    input               turbo
);

// Register file
// Segment registers
reg [15:0] reg_ds0 /*verilator public*/;
reg [15:0] reg_ds1 /*verilator public*/;
reg [15:0] reg_ss  /*verilator public*/;
reg [15:0] reg_ps  /*verilator public*/;

// General purpose
reg [15:0] reg_aw  /*verilator public*/;
reg [15:0] reg_bw  /*verilator public*/;
reg [15:0] reg_cw  /*verilator public*/;
reg [15:0] reg_dw  /*verilator public*/;
reg [15:0] reg_sp  /*verilator public*/;
reg [15:0] reg_bp  /*verilator public*/;
reg [15:0] reg_ix  /*verilator public*/;
reg [15:0] reg_iy  /*verilator public*/;

wire [15:0] cur_pc  /*verilator public*/;

reg [15:0] TA;
reg [15:0] TB;

reg halt /*verilator public*/; // TODO, do something with this

flags_t flags;
wire [15:0] reg_psw /*verilator public*/ = {
    flags.MD,
    3'b111,
    flags.V,
    flags.DIR,
    flags.IE,
    flags.BRK,
    flags.S,
    flags.Z,
    1'b0,
    flags.AC,
    1'b0,
    flags.P,
    1'b1,
    flags.CY
};

// Data Pointer operations
reg [15:0] dp_addr;
reg [15:0] dp_dout;
wire [15:0] dp_din;
sreg_index_e dp_sreg;
reg dp_zero_seg;
reg dp_write;
reg dp_wide;
reg dp_io;
reg dp_req;
wire dp_ready;

// Instruction prefetch
reg [15:0] next_pc /*verilator public*/;
reg set_pc /*verilator public*/;

wire [7:0] ipq[8];
wire [3:0] ipq_len;

nec_decode_t decoded /*verilator public*/;
opcode_e cur_opcode;

function bit [15:0] calc_ea(nec_decode_t dec);
    bit [15:0] addr;

    if (dec.dest == OPERAND_IO_DIRECT || dec.source0 == OPERAND_IO_DIRECT) begin
        addr = { 8'd0, dec.disp[7:0] };
    end else if (dec.dest == OPERAND_IO_INDIRECT || dec.source0 == OPERAND_IO_INDIRECT) begin
        addr = reg_dw;
    end else begin
        case(dec.rm)
        3'b000: addr = reg_bw + reg_ix;
        3'b001: addr = reg_bw + reg_iy;
        3'b010: addr = reg_bp + reg_ix;
        3'b011: addr = reg_bp + reg_iy;
        3'b100: addr = reg_ix;
        3'b101: addr = reg_iy;
        3'b110: addr = dec.mod == 0 ? dec.disp : reg_bp;
        3'b111: addr = reg_bw;
        endcase

        if (dec.mod == 2'b01) addr = addr + { {8{dec.disp[7]}}, dec.disp[7:0] };
        else if (dec.mod == 2'b10) addr = addr + dec.disp;
    end

    return addr;
endfunction

function bit [7:0] get_reg8(reg8_index_e r);
    case(r)
    AL: return reg_aw[7:0];
    AH: return reg_aw[15:8];
    BL: return reg_bw[7:0];
    BH: return reg_bw[15:8];
    CL: return reg_cw[7:0];
    CH: return reg_cw[15:8];
    DL: return reg_dw[7:0];
    DH: return reg_dw[15:8];
    endcase
endfunction

function bit [15:0] get_reg16(reg16_index_e r);
    case(r)
    AW: return reg_aw;
    BW: return reg_bw;
    CW: return reg_cw;
    DW: return reg_dw;
    SP: return reg_sp;
    BP: return reg_bp;
    IX: return reg_ix;
    IY: return reg_iy;
    endcase
endfunction

task set_reg8(input reg8_index_e r, input bit[7:0] val);
    case(r)
    AL: reg_aw[7:0]  <= val;
    AH: reg_aw[15:8] <= val;
    BL: reg_bw[7:0]  <= val;
    BH: reg_bw[15:8] <= val;
    CL: reg_cw[7:0]  <= val;
    CH: reg_cw[15:8] <= val;
    DL: reg_dw[7:0]  <= val;
    DH: reg_dw[15:8] <= val;
    endcase
endtask

task set_reg16(input reg16_index_e r, input bit[15:0] val);
    case(r)
    AW: reg_aw <= val;
    BW: reg_bw <= val;
    CW: reg_cw <= val;
    DW: reg_dw <= val;
    SP: reg_sp <= val;
    BP: reg_bp <= val;
    IX: reg_ix <= val;
    IY: reg_iy <= val;
    endcase
endtask

task set_sreg(input sreg_index_e r, input bit[15:0] val);
    case(r)
    DS0: reg_ds0 <= val;
    DS1: reg_ds1 <= val;
    SS: reg_ss <= val;
    PS: begin
        reg_ps <= val;
        set_pc <= 1;
    end
    endcase
endtask

task write_memory(input bit [15:0] addr, input sreg_index_e seg, input width_e width, input [15:0] data, input bit io);
    dp_addr <= addr;
    dp_dout <= data;
    dp_write <= 1;
    dp_io <= io;
    dp_zero_seg <= 0;
    dp_sreg <= seg;
    dp_wide <= width == BYTE ? 0 : 1;
    dp_req <= 1;
endtask

task read_memory(input bit [15:0] addr, input sreg_index_e seg, input width_e width, input bit io);
    dp_addr <= addr;
    dp_write <= 0;
    dp_io <= io;
    dp_sreg <= seg;
    dp_zero_seg <= 0;
    dp_wide <= width == BYTE ? 0 : 1;
    dp_req <= 1;
endtask

function bit [15:0] get_operand(nec_decode_t dec, operand_e operand);
    if (dec.width == BYTE) begin
        case(operand)
        OPERAND_ACC: return { 8'd0, reg_aw[7:0] };
        OPERAND_IMM: return { 8'd0, dec.imm[7:0] };
        OPERAND_IMM8: return { 8'd0, dec.imm[7:0] };
        OPERAND_IMM_EXT: return { {8{dec.imm[7]}}, dec.imm[7:0] };
        OPERAND_MODRM: begin
            if (dec.mod == 2'b11)
                return { 8'd0, get_reg8(reg8_index_e'(dec.rm)) };
            else
                return { 8'd0, dp_din[7:0] };
        end
        OPERAND_IO_DIRECT,
        OPERAND_IO_INDIRECT: return { 8'd0, dp_din[7:0] };
        OPERAND_REG_0: return { 8'd0, get_reg8(reg8_index_e'(dec.reg0)) };
        OPERAND_REG_1: return { 8'd0, get_reg8(reg8_index_e'(dec.reg1)) };
        OPERAND_CL: return { 8'd0, reg_cw[7:0] };
        default: return 16'hffff;
        endcase
    end else begin
        case(operand)
        OPERAND_ACC: return reg_aw;
        OPERAND_IMM: return dec.imm[15:0];
        OPERAND_IMM8: return { 8'd0, dec.imm[7:0] };
        OPERAND_IMM_EXT: return { {8{dec.imm[7]}}, dec.imm[7:0] };
        OPERAND_MODRM: begin
            if (dec.mod == 2'b11)
                return get_reg16(reg16_index_e'(dec.rm));
            else
                return dp_din;
        end
        OPERAND_IO_DIRECT,
        OPERAND_IO_INDIRECT: return { dp_din[15:0] };
        OPERAND_SREG: begin
            case(dec.sreg)
            DS0: return reg_ds0;
            DS1: return reg_ds1;
            SS: return reg_ss;
            PS: return reg_ps;
            endcase
        end
        OPERAND_REG_0: return get_reg16(reg16_index_e'(dec.reg0));
        OPERAND_REG_1: return get_reg16(reg16_index_e'(dec.reg1));
        OPERAND_CL: return { 8'd0, reg_cw[7:0] };
        default: return 16'hffff;
        endcase
    end
    return 16'hfefe;
endfunction

task load_operands(input nec_decode_t dec);
    op_result <= get_operand(dec, dec.source0);
    TA <= get_operand(dec, dec.source0);
    TB <= get_operand(dec, dec.source1);

    alu_operation <= ALU_OP_NONE;
    alu_wide <= dec.width == WORD;
    use_alu_result <= 1;

    case(dec.opcode)
        OP_ALU: begin
            alu_operation <= dec.alu_operation;
        end

        default: begin
            use_alu_result <= 0;
        end
    endcase
endtask


task shifter(shift_operation_e op, bit wide, bit single);
    bit calc_flags;
    bit [15:0] res;
    bit V;

    calc_flags = 0;

    V = flags.V;

    case(op)
        SHIFT_OP_ROL: begin
            if (wide) begin
                res = {TA[14:0], TA[15]};
                flags.CY <= TA[15];
                V = TA[15] ^ TA[14];
            end else begin
                res[7:0] = {TA[6:0], TA[7]};
                flags.CY <= TA[7];
                V = TA[7] ^ TA[6];
            end
        end

        SHIFT_OP_ROLC: begin
            if (wide) begin
                res = {TA[14:0], flags.CY};
                flags.CY <= TA[15];
                V = TA[15] ^ TA[14];
            end else begin
                res[7:0] = {TA[6:0], flags.CY};
                flags.CY <= TA[7];
                V = TA[7] ^ TA[6];
            end
        end

        SHIFT_OP_ROR: begin
            flags.CY <= TA[0];
            if (wide) begin
                res = {TA[0], TA[15:1]};
                V = TA[15] ^ TA[0];
            end else begin
                res[7:0] = {TA[0], TA[7:1]};
                V = TA[7] ^ TA[0];
            end
        end

        SHIFT_OP_RORC: begin
            flags.CY <= TA[0];
            if (wide) begin
                res = {flags.CY, TA[15:1]};
                V = TA[15] ^ flags.CY;
            end else begin
                res[7:0] = {flags.CY, TA[7:1]};
                V = TA[7] ^ flags.CY;
            end
        end

        SHIFT_OP_SHL: begin
            if (wide) begin
                flags.CY <= TA[15];
                V = TA[15] ^ TA[14];
                res = { TA[14:0], 1'b0 };
            end else begin
                flags.CY <= TA[7];
                V = TA[7] ^ TA[6];
                res[7:0] = { TA[6:0], 1'b0 };
            end
            calc_flags = 1;
        end

        SHIFT_OP_SHR: begin
            if (wide) begin
                flags.CY <= TA[0];
                V = TA[15];
                res = { 1'b0, TA[15:1] };
            end else begin
                flags.CY <= TA[0];
                V = TA[7];
                res[7:0] = { 1'b0, TA[7:1] };
            end
            calc_flags = 1;
        end

        SHIFT_OP_SHRA: begin
            if (wide) begin
                flags.CY <= TA[0];
                V = 0;
                res = { TA[15], TA[15:1] };
            end else begin
                flags.CY <= TA[0];
                V = 0;
                res[7:0] = { TA[7], TA[7:1] };
            end
            calc_flags = 1;
        end

        default: begin
        end
    endcase

    if (calc_flags) begin
        flags.P <= ~(res[0] ^ res[1] ^ res[2] ^ res[3] ^ res[4] ^ res[5] ^ res[6] ^ res[7]);
        flags.S <= wide ? res[15] : res[7];
        flags.Z <= wide ? res[15:0] == 16'd0 : res[7:0] == 8'd0;
    end

    if (single) flags.V <= V;

    op_result <= res;
    TA <= res;
endtask

task handle_branch(input nec_decode_t dec);
    case(dec.opcode)
        OP_B_COND: begin
            bit cond = 0;
            case(dec.cond)
            4'b0000: cond = flags.V; /* V */
            4'b0001: cond = ~flags.V; /* NV */
            4'b0010: cond = flags.CY; /* C/L */
            4'b0011: cond = ~flags.CY; /* NC/NL */
            4'b0100: cond = flags.Z; /* E/Z */
            4'b0101: cond = ~flags.Z; /* NE/NZ */
            4'b0110: cond = (flags.CY | flags.Z); /* NH */
            4'b0111: cond = ~(flags.CY | flags.Z); /* H */
            4'b1000: cond = flags.S; /* N */
            4'b1001: cond = ~flags.S; /* P */
            4'b1010: cond = flags.P; /* PE */
            4'b1011: cond = ~flags.P; /* PO */
            4'b1100: cond = (flags.S ^ flags.V) & ~flags.Z; /* LT */
            4'b1101: cond = ~(flags.S ^ flags.V) | flags.Z; /* GE */
            4'b1110: cond = (flags.S ^ flags.V) | flags.Z; /* LE */
            4'b1111: cond = ~((flags.S ^ flags.V) | flags.Z); /* GT */
            endcase

            if (cond) begin
                next_pc <= dec.end_pc + get_operand(dec, dec.source0);
                set_pc <= 1;
                state <= IDLE;
            end else begin
                state <= EXECUTE;
            end
        end

        OP_B_CW_COND: begin
            bit cond = 0;
            case(dec.cond)
            4'b0000: begin
                reg_cw <= reg_cw - 16'd1;
                cond = reg_cw != 16'd1 && ~flags.Z;
            end
            4'b0001: begin
                reg_cw <= reg_cw - 16'd1;
                cond = reg_cw != 16'd1 && flags.Z;
            end
            4'b0010: begin
                reg_cw <= reg_cw - 16'd1;
                cond = reg_cw != 16'd1;
            end
            4'b0011: cond = (reg_cw == 0);
            default: begin
            end
            endcase

            if (cond) begin
                next_pc <= dec.end_pc + TA;
                set_pc <= 1;
                state <= IDLE;
            end else begin
                state <= EXECUTE;
            end
        end

        OP_BR_REL: begin
            next_pc <= dec.end_pc + TA;
            set_pc <= 1;
            state <= IDLE;
        end

        OP_BR_ABS: begin
            if (dec.source0 == OPERAND_IMM && dec.width == DWORD) begin
                next_pc <= dec.imm[15:0];
                reg_ps <= dec.imm[31:16];
            end else if (dec.width == WORD) begin
                next_pc <= TA;
            end else if (dec.source0 == OPERAND_MODRM && dec.width == DWORD) begin
                next_pc <= TA;
                reg_ps <= TB;
            end
            set_pc <= 1;
            state <= IDLE;
        end

        OP_RET: begin
            set_pc <= 1;
            state <= IDLE;
        end

        OP_RET_POP_VALUE: begin
            reg_sp <= reg_sp + TA;
            set_pc <= 1;
            state <= IDLE;
        end

        default: begin
        end
    endcase
endtask



reg [7:0] interrupt_vector;
wire bcu_intreq;
wire bcu_intack;
wire [7:0] bcu_intvec;
wire block_prefetch;

bus_control_unit BCU(
    .clk, .ce_1, .ce_2,
    .reset, .hldrq, .n_ready, .bs16,
    .hldak, .n_buslock, .n_ube, .r_w,
    .m_io, .busst0, .busst1, .aex,
    .n_bcyst, .n_dstb,
    .addr, .dout, .din,

    .reg_ps, .reg_ss, .reg_ds0, .reg_ds1,

    .pfp_set(set_pc), .block_prefetch,
    .ipq, .ipq_head(set_pc ? next_pc : cur_pc), .ipq_len,

    .dp_addr, .dp_dout, .dp_din, .dp_sreg,
    .dp_write, .dp_wide, .dp_io, .dp_req,
    .dp_ready, .dp_zero_seg,

    .buslock_prefix(decoded.buslock),

    .intreq(bcu_intreq), .intack(bcu_intack), .intvec(bcu_intvec),

    .implementation_fault()
);

wire retire_op = state == IDLE && next_decode_valid && (dp_ready | n_buslock);
wire next_decode_valid;
nec_decode_t next_decode;

nec_decode nec_decode(
    .clk, .ce_1, .ce_2,
    .ipq_len,
    .ipq,
    .new_pc(next_pc), .set_pc,
    .pc(cur_pc),
    .valid(next_decode_valid),
    .decoded(next_decode),
    .retire_op,
    .block_prefetch
);

alu_operation_e alu_operation;
wire [15:0] alu_result;
flags_t alu_flags_result;
reg use_alu_result;
reg alu_wide;
wire [9:0] alu_delay;

alu ALU(
    .clk,

    .operation(alu_operation),
    .ta(TA),
    .tb(TB),
    .result(alu_result),
    .wide(alu_wide),

    .delay(alu_delay),

    .flags_in(flags),
    .flags(alu_flags_result)
);

reg div_start, div_wide, div_signed;
wire div_done, div_overflow, div_dbz;
reg [32:0] div_num, div_denom;
wire [15:0] div_quot, div_rem;

nec_divider divider(
    .clk, .ce(ce_1 | ce_2),
    .reset,
    .start(div_start),
    .done(div_done),
    .overflow(div_overflow),
    .dbz(div_dbz),
    .wide(div_wide),
    .a(div_num),
    .b(div_denom),
    .quot(div_quot),
    .rem(div_rem)
);

cpu_state_e state /* verilator public */;

assign bcu_intreq = state == INT_ACK_WAIT;

reg int_processing;
reg [15:0] calculated_ea;
reg [15:0] op_result;
reg [15:0] op_result_high;

reg [15:0] branch_new_pc;
reg [15:0] branch_new_ps;

reg [3:0] exec_stage;
reg [7:0] shift_count;

reg [15:0] push_list;
reg [15:0] pop_list;
reg [15:0] push_sp_save;
reg pop_store;

reg [4:0] prepare_nesting_level;
reg [15:0] prepare_sp_save;

reg [6:0] bcd_offset;
reg [4:0] bcd_acc_high, bcd_acc_low;
reg [7:0] bcd_acc, bcd_src;
reg [4:0] bcd_result_high, bcd_result_low;

reg stack_modified_pc, stack_modified_ps;

reg [9:0] cycles;
reg [9:0] op_delay;
reg [9:0] exec_delay;

always_ff @(posedge clk) begin
    bit [15:0] addr;
    bit [31:0] result32;
    bit [15:0] temp;
    bit [15:0] src;
    bit [7:0] temp8;
    bit [9:0] delay;

    delay = 0;

    if (reset) begin
        dp_req <= 0;
        reg_ps <= 16'hffff;
        reg_ss <= 16'd0;
        reg_ds0 <= 16'd0;
        reg_ds1 <= 16'd0;
        next_pc <= 16'd0;
        set_pc <= 1;
        
        reg_aw <= 16'd0;
        reg_bw <= 16'd0;
        reg_cw <= 16'd0;
        reg_dw <= 16'd0;
        reg_sp <= 16'd0;
        reg_bp <= 16'd0;
        reg_ix <= 16'd0;
        reg_iy <= 16'd0;

        flags.V <= 0;
        flags.S <= 0;
        flags.Z <= 0;
        flags.AC <= 0;
        flags.P <= 0;
        flags.CY <= 0;
        flags.MD <= 1;
        flags.DIR <= 0;
        flags.IE <= 0;
        flags.BRK <= 0;

        state <= IDLE;
        int_processing <= 0;
        use_alu_result <= 0;

        stack_modified_pc <= 0;
        stack_modified_ps <= 0;

        halt <= 0;
    end else if (ce_1 | ce_2) begin
        div_start <= 0;
        set_pc <= 0;
        dp_req <= 0;

        case(state)
            IDLE: if (ce_1) begin
                use_alu_result <= 0;
                stack_modified_pc <= 0;
                stack_modified_ps <= 0;

                exec_stage <= 4'd0;
                exec_delay <= 10'd0;
                shift_count <= 8'd0;

                if (n_buslock | dp_ready) begin
                    op_delay <= 10'd0;
                    cycles <= 10'd0;

                    if (intreq & flags.IE) begin
                        state <= INT_ACK_WAIT;
                    end else if (next_decode_valid) begin
                        decoded <= next_decode;
                        cur_opcode <= next_decode.opcode;
                        push_sp_save <= reg_sp;
                        push_list <= next_decode.push;
                        pop_list <= next_decode.pop;

                        next_pc <= cur_pc;

                        calculated_ea <= calc_ea(next_decode);

                        load_operands(next_decode);

                        if (next_decode.mem_read && next_decode.opcode != OP_LDEA)
                            state <= FETCH_OPERAND;
                        else if (next_decode.push != 16'd0)
                            state <= PUSH;
                        else if (next_decode.pop != 16'd0) begin
                            if (dp_ready) begin
                                read_memory(reg_sp, SS, WORD, 0);
                                reg_sp <= reg_sp + 16'd2;
                                state <= POP_WAIT;
                            end else begin
                                state <= POP;
                            end
                        end else if (next_decode.opclass == BRANCH)
                            state <= BRANCHING;
                        else
                            state <= EXECUTE;
                    end
                end
            end // IDLE

            FETCH_OPERAND: if (ce_1 & dp_ready) begin
                read_memory(calculated_ea, decoded.segment, decoded.width, decoded.io);
                state <= WAIT_OPERAND1;
            end

            WAIT_OPERAND1: if (ce_1 & dp_ready) begin
                load_operands(decoded);
                if (decoded.width == DWORD) begin
                    read_memory(calculated_ea + 16'd2, decoded.segment, WORD, 0);
                    state <= WAIT_OPERAND2;
                end else begin
                    if (push_list != 16'd0)
                        state <= PUSH;
                    else if (pop_list != 16'd0)
                        state <= POP;
                    else if (decoded.opclass == BRANCH)
                        state <= BRANCHING;
                    else if (decoded.opcode == OP_MOV)
                        state <= EXECUTE;
                    else
                        state <= EXECUTE_STALL;
                end
            end

            WAIT_OPERAND2: if (ce_1 & dp_ready) begin
                TB <= dp_din;

                if (push_list != 16'd0)
                    state <= PUSH;
                else if (pop_list != 16'd0)
                    state <= POP;
                else if (decoded.opclass == BRANCH)
                    state <= BRANCHING;
                else
                    state <= EXECUTE;
            end // WAIT_OPERAND2

            BRANCHING: if (ce_2) begin
                handle_branch(decoded);
            end

            INT_ACK_WAIT: if (ce_1) begin
                if (bcu_intack) begin
                    interrupt_vector <= bcu_intvec;
                    state <= INT_INITIATE;
                end
            end // INT_ACK_WAIT

            INT_INITIATE: if (ce_1) begin
                push_list <= STACK_PC | STACK_PS | STACK_PSW;
                state <= PUSH;
                int_processing <= 1;
            end

            INT_FETCH_VEC: if (dp_ready & ce_1) begin
                flags.IE <= 0;
                flags.BRK <= 0;
                dp_addr <= { 6'd0, interrupt_vector[7:0], 2'b00 };
                dp_write <= 0;
                dp_io <= 0;
                dp_zero_seg <= 1;
                dp_wide <= 1;
                dp_req <= 1;
                state <= INT_FETCH_WAIT1;
            end

            INT_FETCH_WAIT1: if (dp_ready & ce_1) begin
                next_pc <= dp_din;
                dp_addr <= { 6'd0, interrupt_vector[7:0], 2'b10 };
                dp_req <= 1;
                state <= INT_FETCH_WAIT2;
            end

            INT_FETCH_WAIT2: if (dp_ready & ce_1) begin
                reg_ps <= dp_din;
                set_pc <= 1;
                int_processing <= 0;
                state <= IDLE;
            end

            EXECUTE_STALL: if (ce_1) begin
                state <= EXECUTE;
            end

            EXECUTE: begin
                bit working;
                bit exception;
                bit check_interrupt;

                if (dp_ready & ce_1 & |exec_delay & ~turbo) begin
                    exec_delay <= exec_delay - 10'd1;
                end else if (dp_ready & ce_1) begin
                    working = 0;
                    exception = 0;
                    check_interrupt = 0;
                    
                    exec_stage <= exec_stage + 4'd1;

                    case(decoded.opcode)
                        OP_NOP: begin
                            delay = 1;
                        end

                        OP_POPR: begin
                            delay = 1;
                        end

                        OP_PUSH,
                        OP_PUSHR,
                        OP_POP: begin
                        end

                        OP_B_COND,
                        OP_B_CW_COND: begin
                            delay = 1;
                        end

                        OP_NOT1_CY:  flags.CY <= ~flags.CY;
                        OP_CLR1_CY:  flags.CY <= 0;
                        OP_SET1_CY:  flags.CY <= 1;
                        OP_DI:       flags.IE <= 0;
                        OP_EI:       flags.IE <= 1;
                        OP_CLR1_DIR: flags.DIR <= 0;
                        OP_SET1_DIR: flags.DIR <= 1;
                        OP_HALT:     halt <= 1;

                        OP_CVTWL: reg_dw <= reg_aw[15] ? 16'hffff : 16'h0000;
                        OP_CVTBW: reg_aw[15:8] <= reg_aw[7] ? 8'hff : 8'h00;

                        OP_CVTBD: begin
                            if (exec_stage == 0) begin
                                div_signed <= 0;
                                div_wide <= 0;
                                div_start <= 1;
                                div_num <= { 25'd0, reg_aw[7:0] };
                                div_denom <= 33'd10;
                                working = 1;
                                delay = 11;
                            end else begin
                                if (div_done) begin
                                    reg_aw[15:8] <= div_quot[7:0];
                                    reg_aw[7:0] <= div_rem[7:0];
                                    flags.Z <= ~(|{div_quot[7:0], div_rem[7:0]});
                                    flags.S <= div_rem[7];
                                    flags.P <= ~(^div_rem[7:0]);
                                end else begin
                                    working = 1;
                                    exec_stage <= exec_stage;
                                end
                            end
                        end

                        OP_CVTDB: begin
                            temp8 = reg_aw[7:0] + (reg_aw[15:8] * 8'd10);
                            flags.Z <= ~|temp8;
                            flags.S <= temp8[7];
                            flags.P <= ~(^temp8);
                            reg_aw <= { 8'd0, temp8 };
                            delay = 8;
                        end

                        OP_MOV: begin
                            op_result <= TA;
                        end

                        OP_MOV_SEG: begin
                            set_reg16(reg16_index_e'(decoded.reg0), TA);
                            set_sreg(sreg_index_e'(decoded.sreg), TB);
                            delay = 10'd2;
                        end

                        OP_MOV_PSW_AH: begin
                            flags.CY  <= reg_aw[8];
                            flags.P   <= reg_aw[10];
                            flags.AC  <= reg_aw[12];
                            flags.Z   <= reg_aw[14];
                            flags.S   <= reg_aw[15];
                        end

                        OP_MOV_AH_PSW: begin
                            reg_aw[15:8]  <= reg_psw[7:0];
                        end

                        OP_LDEA: begin
                            delay = 1;
                            op_result <= calculated_ea;
                        end

                        OP_XCH: begin
                            op_result <= TA;
                            delay = decoded.mem_read ? 3 : 1;
                            if (decoded.width == BYTE) begin
                                set_reg8(reg8_index_e'(decoded.reg0), TB[7:0]);
                            end else begin
                                set_reg16(reg16_index_e'(decoded.reg0), TB);
                            end
                        end

                        OP_ALU: begin
                        end

                        OP_STM: begin
                            bit do_work = 1;
                            if (decoded.rep != REPEAT_NONE) begin
                                if (reg_cw == 16'd0) begin
                                    do_work = 0;
                                end else begin
                                    reg_cw <= reg_cw - 16'd1;
                                    working = reg_cw == 16'd1 ? 0 : 1;
                                    check_interrupt = 1;
                                end
                                delay = 1;
                            end else begin
                                delay = 3;
                            end

                            if (do_work) begin
                                write_memory(reg_iy, DS1, decoded.width, reg_aw, 0);
                                if (flags.DIR)
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                else
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                            end


                        end

                        OP_LDM: begin
                            if (exec_stage == 0) begin
                                working = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        working = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end
                            end else if (exec_stage == 1) begin
                                read_memory(reg_ix, decoded.segment, decoded.width, 0);
                                working = 1;
                            end else begin
                                working = 1;
                                if (decoded.width == BYTE)
                                    reg_aw[7:0] <= dp_din[7:0];
                                else
                                    reg_aw <= dp_din;

                                if (flags.DIR) begin
                                    reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                                exec_stage <= 1;

                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        working = 0;
                                        delay = 3;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                    check_interrupt = 1;
                                end else begin
                                    delay = 2;
                                    working = 0;
                                end
                            end
                        end

                        OP_MOVBK: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, decoded.segment, decoded.width, 0);
                                    working = 1;
                                end
                            end else begin
                                write_memory(reg_iy, DS1, decoded.width, dp_din, 0);
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                                exec_stage <= 0;

                                if (decoded.rep != REPEAT_NONE) begin
                                    working = reg_cw != 16'd0;
                                    check_interrupt = 1;
                                    delay = 2;
                                end else begin
                                    delay = 3;
                                end
                            end
                        end
                        OP_CMPBK: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_ix, decoded.segment, decoded.width, 0);
                                    working = 1;
                                end
                            end else if (exec_stage == 1) begin
                                TA <= decoded.width == WORD ? dp_din : { 8'd0, dp_din[7:0] };
                                read_memory(reg_iy, DS1, decoded.width, 0);
                                working = 1;
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                            end else if (exec_stage == 2) begin
                                TB <= decoded.width == WORD ? dp_din : { 8'd0, dp_din[7:0] };
                                alu_operation <= ALU_OP_CMP;
                                alu_wide <= decoded.width == WORD ? 1 : 0;
                                working = 1;
                            end else if (exec_stage == 3) begin
                                working = 1;
                                flags <= alu_flags_result;
                                exec_stage <= 0;
                                if (decoded.rep != REPEAT_NONE) begin
                                    delay = 3;
                                    if (reg_cw == 16'd0) working = 0;
                                    else if (decoded.rep == REPEAT_NZ) working = ~alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_Z) working = alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_NC) working = ~alu_flags_result.CY;
                                    else if (decoded.rep == REPEAT_C) working = alu_flags_result.CY;
                                    check_interrupt = 1;
                                end else begin
                                    delay = 5;
                                    working = 0;
                                end
                            end
                        end

                        OP_CMPM: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    read_memory(reg_iy, DS1, decoded.width, 0);
                                    working = 1;
                                end
                            end else if (exec_stage == 1) begin
                                TA <= decoded.width == WORD ? reg_aw : { 8'd0, reg_aw[7:0] };
                                TB <= decoded.width == WORD ? dp_din : { 8'd0, dp_din[7:0] };;
                                alu_operation <= ALU_OP_CMP;
                                alu_wide <= decoded.width == WORD ? 1 : 0;
                                working = 1;
                                if (flags.DIR) begin
                                    reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end else begin
                                    reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                end
                            end else if (exec_stage == 2) begin
                                working = 1;
                                flags <= alu_flags_result;
                                exec_stage <= 0;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) working = 0;
                                    else if (decoded.rep == REPEAT_NZ) working = ~alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_Z) working = alu_flags_result.Z;
                                    else if (decoded.rep == REPEAT_NC) working = ~alu_flags_result.CY;
                                    else if (decoded.rep == REPEAT_C) working = alu_flags_result.CY;
                                    check_interrupt = 1;
                                end else begin
                                    working = 0;
                                end
                            end
                        end

                        OP_INM,
                        OP_OUTM: begin
                            if (exec_stage == 0) begin
                                bit do_work = 1;
                                if (decoded.rep != REPEAT_NONE) begin
                                    if (reg_cw == 16'd0) begin
                                        do_work = 0;
                                    end else begin
                                        reg_cw <= reg_cw - 16'd1;
                                    end
                                end

                                if (do_work) begin
                                    if (decoded.opcode == OP_INM)
                                        read_memory(reg_dw, decoded.segment, decoded.width, 1);
                                    else
                                        read_memory(reg_ix, decoded.segment, decoded.width, 0);
                                    working = 1;
                                end
                            end else begin
                                if (decoded.opcode == OP_INM) begin
                                    write_memory(reg_iy, DS1, decoded.width, dp_din, 0);
                                    if (flags.DIR) begin
                                        reg_iy <= reg_iy - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    end else begin
                                        reg_iy <= reg_iy + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    end
                                end else begin
                                    write_memory(reg_dw, DS1, decoded.width, dp_din, 1);
                                    if (flags.DIR) begin
                                        reg_ix <= reg_ix - ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    end else begin
                                        reg_ix <= reg_ix + ( decoded.width == BYTE ? 16'd1 : 16'd2 );
                                    end
                                end
                                exec_stage <= 0;

                                if (decoded.rep != REPEAT_NONE) begin
                                    working = reg_cw != 16'd0;
                                    check_interrupt = 1;
                                    delay = 7;
                                end else begin
                                    delay = 8;
                                end
                            end
                        end

                        OP_SHIFT: begin
                            if (shift_count != TB[7:0]) begin
                                shifter(decoded.shift, decoded.width == WORD, 0);
                                shift_count <= shift_count + 8'd1;
                                working = 1;
                            end else begin
                                delay = 2;
                            end
                        end

                        OP_SHIFT1: begin
                            shifter(decoded.shift, decoded.width == WORD, 1);
                        end


                        // TODO OUTM, INM
                        
                        OP_DIV,
                        OP_DIVU: begin
                            bit [15:0] operand;
                            operand = TA;

                            if (exec_stage == 0) begin
                                div_start <= 1;
                                if (decoded.opcode == OP_DIVU) begin
                                    if (decoded.width == BYTE) begin
                                        delay = 11;
                                        div_wide <= 0;
                                        div_num <= { 17'd0, reg_aw };
                                        div_denom <= { 25'd0, operand[7:0] };
                                    end else begin
                                        delay = 19;
                                        div_wide <= 1;
                                        div_num <= { 1'd0, reg_dw, reg_aw };
                                        div_denom <= { 17'd0, operand[15:0] };
                                    end
                                end else begin
                                    if (decoded.width == BYTE) begin
                                        delay = 15;
                                        div_wide <= 0;
                                        div_num <= { {17{reg_aw[15]}}, reg_aw };
                                        div_denom <= { {25{operand[7]}}, operand[7:0] };
                                    end else begin
                                        delay = 23;
                                        div_wide <= 1;
                                        div_num <= { reg_dw[15], reg_dw, reg_aw };
                                        div_denom <= { {17{operand[15]}}, operand[15:0] };
                                    end
                                end
                                working = 1;
                            end else begin
                                if (div_done) begin
                                    if (decoded.width == BYTE) begin
                                        if (div_dbz | div_overflow) begin
                                            interrupt_vector <= 8'd0;
                                            exception = 1;
                                        end else begin
                                            reg_aw <= { div_rem[7:0], div_quot[7:0] };
                                        end
                                    end else begin
                                        if (div_dbz | div_overflow) begin
                                            interrupt_vector <= 8'd0;
                                            exception = 1;
                                        end else begin
                                            reg_aw <= div_quot[15:0];
                                            reg_dw <= div_rem[15:0];
                                        end
                                    end
                                end else begin
                                    working = 1;
                                    exec_stage <= exec_stage;
                                end
                            end
                        end

                        OP_MULU: begin
                            flags.CY <= 0;
                            flags.V <= 0;
                            result32 = TA * TB;
                            if (decoded.width == WORD) begin
                                flags.CY <= |result32[31:16];
                                flags.V <= |result32[31:16];
                                delay = 12;
                            end else begin
                                flags.CY <= |result32[31:8];
                                flags.V <= |result32[31:8];
                                delay = 8;
                            end
                            op_result <= result32[15:0];
                            op_result_high <= result32[31:16];
                        end
                        
                        OP_MUL: begin 
                            flags.CY <= 0;
                            flags.V <= 0;

                            if (decoded.width == WORD) begin
                                result32 = $signed(TA) * $signed(TB);
                                if (16'd0 != result32[31:16]) begin
                                    flags.CY <= 1;
                                    flags.V <= 1;
                                end
                                delay = 12;
                            end else begin
                                result32[15:0] = $signed(TA[7:0]) * $signed(TB[7:0]);
                                if (8'd0 != result32[15:8]) begin
                                    flags.CY <= 1;
                                    flags.V <= 1;
                                end
                                delay = 8;
                            end
                            op_result <= result32[15:0];
                            op_result_high <= result32[31:16];
                        end                              

                        OP_PREPARE: begin
                            working = exec_stage != 3;
                            if (exec_stage == 0) begin
                                prepare_nesting_level <= decoded.imm[20:16];
                                reg_sp <= reg_sp - 16'd2;
                                prepare_sp_save <= reg_sp - 16'd2;
                                write_memory(reg_sp - 16'd2, SS, WORD, reg_bp, 0);
                                working = 1;
                                delay = 10'd6;
                                case(decoded.imm[20:16])
                                5'd0: exec_stage <= 3;
                                5'd1: exec_stage <= 2;
                                default: exec_stage <= 1;
                                endcase
                            end else if (exec_stage == 1) begin
                                reg_sp <= reg_sp - 16'd2;
                                reg_bp <= reg_bp - 16'd2;
                                write_memory(reg_sp - 16'd2, SS, WORD, reg_bp - 16'd2, 0);
                                prepare_nesting_level <= prepare_nesting_level - 5'd1;
                                if (prepare_nesting_level > 5'd2) begin
                                    exec_stage <= exec_stage;
                                    delay = 10'd7;
                                end
                            end else if (exec_stage == 2) begin
                                reg_sp <= reg_sp - 16'd2;
                                write_memory(reg_sp - 16'd2, SS, WORD, prepare_sp_save, 0);
                                delay = 10'd3;
                            end else if (exec_stage == 3) begin
                                reg_bp <= prepare_sp_save;
                                reg_sp <= reg_sp - decoded.imm[15:0];
                            end
                        end

                        OP_DISPOSE: begin
                            working = exec_stage == 0;
                            if (exec_stage == 0) begin
                                reg_sp <= reg_bp + 2;
                                read_memory(reg_bp, SS, WORD, 0);
                            end else begin
                                reg_bp <= dp_din;
                                delay = 10'd4;
                            end
                        end

                        OP_CHKIND: begin
                            temp = get_reg16(reg16_index_e'(decoded.reg0));
                            delay = 10'd9;
                            if (TA > temp || TB < temp) begin
                                interrupt_vector <= 8'd5;
                                exception = 1;
                            end
                        end

                        OP_TRANS: begin
                            working = exec_stage != 2;
                            if (exec_stage == 1) begin
                                read_memory(reg_bw + { 8'd0, reg_aw[7:0]}, decoded.segment, BYTE, 0);
                            end else if (exec_stage == 2) begin
                                reg_aw[7:0] <= dp_din[7:0];
                            end
                        end

                        OP_BRK3: begin
                            interrupt_vector <= 8'd3;
                            exception = 1;
                        end

                        OP_BRK: begin
                            interrupt_vector <= decoded.imm[7:0];
                            exception = 1;
                        end

                        OP_BRKV: begin
                            if (flags.V) begin
                                interrupt_vector <= 8'd4;
                                exception = 1;
                            end
                        end

                        OP_ADD4S, OP_SUB4S, OP_CMP4S: begin
                            working = 1;
                            if (exec_stage == 0) begin
                                bcd_offset <= 7'd0;
                                flags.Z <= 1;
                                flags.CY <= 0;
                            end else if (exec_stage == 1) begin
                                if (bcd_offset == reg_cw[7:1]) begin
                                    working = 0;
                                    delay = 0;
                                end else begin
                                    read_memory(reg_ix + {9'd0, bcd_offset}, decoded.segment, BYTE, 0);
                                end
                            end else if (exec_stage == 2) begin
                                bcd_src <= dp_din[7:0] + { 7'd0, flags.CY };
                                flags.CY <= 0;
                                read_memory(reg_iy + {9'd0, bcd_offset}, DS1, BYTE, 0);
                            end else if (exec_stage == 3) begin
                                if (decoded.opcode == OP_ADD4S) begin
                                    bcd_acc_low  <= { 1'b0, dp_din[3:0] } + { 1'b0, bcd_src[3:0] };
                                    bcd_acc_high <= { 1'b0, dp_din[7:4] } + { 1'b0, bcd_src[7:4] };
                                end else begin
                                    bcd_acc_low  <= { 1'b0, dp_din[3:0] } - { 1'b0, bcd_src[3:0] };
                                    bcd_acc_high <= { 1'b0, dp_din[7:4] } - { 1'b0, bcd_src[7:4] };
                                end
                            end else if (exec_stage == 4) begin
                                bcd_result_low = bcd_acc_low;
                                bcd_result_high = bcd_acc_high;
                                if (bcd_result_low > 5'd9) begin
                                    if (decoded.opcode == OP_ADD4S) begin
                                        bcd_result_low = bcd_acc_low + 5'd6;
                                        bcd_result_high = bcd_acc_high + 5'd1;
                                    end else begin
                                        bcd_result_low = bcd_acc_low + 5'd6;
                                        bcd_result_high = bcd_acc_high + 5'd1;
                                    end
                                end

                                if (bcd_result_high > 5'd9) begin
                                    if (decoded.opcode == OP_ADD4S) begin
                                        bcd_result_high = bcd_result_high + 5'd6;
                                    end else begin
                                        bcd_result_high = bcd_result_high - 5'd6;
                                    end
                                    flags.CY <= 1;
                                end
                                bcd_acc <= { bcd_result_high[3:0], bcd_result_low[3:0] };
                                delay = 13;
                            end else if (exec_stage == 5) begin
                                if (|bcd_acc) flags.Z <= 0;
                                if (decoded.opcode != OP_CMP4S) begin
                                    write_memory(reg_iy + { 9'd0, bcd_offset}, DS1, BYTE, { 8'd0, bcd_acc }, 0);
                                end else begin
                                    delay = 1;
                                end
                                bcd_offset <= bcd_offset + 7'd1;
                                exec_stage <= 1; // loop                                
                            end
                        end

                        OP_ROL4: begin
                            reg_aw[3:0] <= TA[7:4];
                            op_result <= { 8'd0, TA[3:0], reg_aw[3:0] };
                            delay = 10'd8;
                        end

                        OP_ROR4: begin
                            reg_aw[3:0] <= TA[3:0];
                            op_result <= { 8'd0, reg_aw[3:0], TA[7:4] };
                            delay = 10'd8;
                        end

                        default: begin // TODO exception
                        end

                    endcase

                    if (~working) begin
                        bit need_delay;
                        op_delay <= delay + alu_delay;
                        need_delay = delay > 0 || alu_delay > 0;

                        if (exception) begin
                            state <= INT_INITIATE;
                        end else begin
                            if (need_delay & ~turbo) begin
                                state <= STORE_DELAY;
                                cycles <= 10'd1;
                            end else begin
                                state <= STORE_REGISTER;
                            end
                        end
                    end else if (check_interrupt) begin
                        if (intreq & flags.IE) begin
                            state <= INT_ACK_WAIT;
                            next_pc <= decoded.pc;
                        end
                    end
                    exec_delay <= delay;
                end
            end // EXECUTE

            PUSH: if (ce_1) begin
                if (push_list == 16'd0) begin
                    if (int_processing) begin
                        state <= INT_FETCH_VEC;
                    end else if (decoded.opcode == OP_PUSH) begin
                        state <= IDLE;
                    end else if (decoded.opclass == BRANCH) begin
                        state <= BRANCHING;
                    end else begin
                        state <= EXECUTE;
                    end
                end else if (dp_ready) begin
                    reg_sp <= reg_sp - 16'd2;
                    state <= PUSH_WRITE;
                end
            end

            PUSH_WRITE: if (dp_ready & ce_1) begin
                bit [15:0] push_data;
                bit [15:0] list;
                int push_idx;

                push_idx = 0;
                list = push_list;
                for (int i = 15; i >= 0; i = i - 1) begin
                    if (list[i]) push_idx = i;
                end

                case(push_idx)
                0:  push_data = reg_aw;
                1:  push_data = reg_cw;
                2:  push_data = reg_dw;
                3:  push_data = reg_bw;
                4:  push_data = push_sp_save;
                5:  push_data = push_sp_save; // DISCARD
                6:  push_data = reg_bp;
                7:  push_data = reg_ix;
                8:  push_data = reg_iy;
                9:  push_data = reg_ds1;
                10: push_data = reg_psw;
                11: push_data = reg_ps;
                12: push_data = reg_ss;
                13: push_data = reg_ds0;
                14: push_data = next_pc;
                15: push_data = TA;
                endcase

                write_memory(reg_sp, SS, WORD, push_data, 0);

                list[push_idx] = 0;
                push_list <= list;

                state <= PUSH;
            end // PUSH

            POP_STORE: if (ce_1 & dp_ready) begin
                if (pop_store) begin
                    write_memory(calculated_ea, decoded.segment, WORD, TA, 0);
                end
                state <= POP_CHECK;
            end

            POP_CHECK: if (ce_1 & dp_ready) begin
                if (pop_list == 16'd0) begin
                    if (decoded.opcode == OP_POP) begin
                        state <= IDLE;
                    end else if (decoded.opclass == BRANCH) begin
                        state <= BRANCHING;
                    end else begin
                        state <= EXECUTE;
                    end
                end else begin
                    state <= POP;
                end            
            end

            POP: if (dp_ready & ce_1) begin
                read_memory(reg_sp, SS, WORD, 0);
                reg_sp <= reg_sp + 16'd2;

                state <= POP_WAIT;
            end // POP

            POP_WAIT: if (ce_1 & dp_ready) begin
                bit [15:0] list;
                int pop_idx = 0;

                pop_store <= 0;

                list = pop_list;
                for (int i = 0; i < 16; i = i + 1) begin
                    if (list[i]) pop_idx = i;
                end

                case(pop_idx)
                    0:  reg_aw <= dp_din;
                    1:  reg_cw <= dp_din;
                    2:  reg_dw <= dp_din;
                    3:  reg_bw <= dp_din;
                    4:  reg_sp <= dp_din;
                    5:  begin end // skip
                    6:  reg_bp <= dp_din;
                    7:  reg_ix <= dp_din;
                    8:  reg_iy <= dp_din;
                    9:  reg_ds1 <= dp_din;
                    10: begin
                        flags.CY  <= dp_din[0];
                        flags.P   <= dp_din[2];
                        flags.AC  <= dp_din[4];
                        flags.Z   <= dp_din[6];
                        flags.S   <= dp_din[7];
                        flags.BRK <= dp_din[8];
                        flags.IE  <= dp_din[9];
                        flags.DIR <= dp_din[10];
                        flags.V   <= dp_din[11];
                        // flags.MD  <= dp_din[15]; // TODO V33, no MD flag, V20/30 will need this
                    end
                    11: begin
                        reg_ps <= dp_din;
                        stack_modified_ps <= 1;
                    end
                    12: reg_ss <= dp_din;
                    13: reg_ds0 <= dp_din;
                    14: begin
                        next_pc <= dp_din;
                        stack_modified_pc <= 1;
                    end
                    15: begin
                        if (decoded.mod == 2'b11) begin
                            set_reg16(reg16_index_e'(decoded.rm), dp_din);
                        end else begin
                            TA <= dp_din;
                            pop_store <= 1;
                        end
                    end
                endcase

                list[pop_idx] = 0;
                pop_list <= list;
                state <= POP_STORE;
            end // POP_WAIT

            STORE_DELAY: if (ce_1) begin
                if (~&cycles) cycles <= cycles + 10'd1;
                if (cycles >= op_delay) begin
                    state <= STORE_REGISTER;
                end
            end

            STORE_MEMORY: begin
                if (ce_1 & dp_ready) begin
                    write_memory(calculated_ea, decoded.segment, decoded.width, op_result, decoded.io);
                    state <= IDLE;
                end
            end

            STORE_REGISTER: begin
                 if (ce_2) begin
                    if (use_alu_result) begin
                        result32 = { 16'd0, alu_result };
                        op_result <= alu_result; // for STORE_MEMORY
                        flags <= alu_flags_result;
                    end else begin
                        result32 = { op_result_high, op_result };
                    end

                    case(decoded.dest)
                        OPERAND_ACC: begin
                            if (decoded.width == BYTE)
                                reg_aw[7:0] <= result32[7:0];
                            else
                                reg_aw <= result32[15:0];
                        end
                        OPERAND_MODRM: begin
                            if (decoded.mod == 2'b11) begin
                                if (decoded.width == BYTE)
                                    set_reg8(reg8_index_e'(decoded.rm), result32[7:0]);
                                else
                                    set_reg16(reg16_index_e'(decoded.rm), result32[15:0]);
                            end
                        end
                        OPERAND_SREG: begin
                            set_sreg(sreg_index_e'(decoded.sreg), result32[15:0]);
                        end
                        OPERAND_REG_0: begin
                            if (decoded.width == BYTE)
                                set_reg8(reg8_index_e'(decoded.reg0), result32[7:0]);
                            else
                                set_reg16(reg16_index_e'(decoded.reg0), result32[15:0]);
                        end
                        OPERAND_REG_1: begin
                            if (decoded.width == BYTE)
                                set_reg8(reg8_index_e'(decoded.reg1), result32[7:0]);
                            else
                                set_reg16(reg16_index_e'(decoded.reg1), result32[15:0]);
                        end
                        OPERAND_PRODUCT: begin
                            if (decoded.width == WORD) reg_dw <= result32[31:16];
                            reg_aw <= result32[15:0];
                        end
                        default: begin end
                    endcase

                    if (decoded.mem_write) begin
                        state <= STORE_MEMORY;
                    end else begin
                        state <= IDLE;
                    end
                end
            end // STORE_REGISTER

            // for linting, should not be possible
            default: begin end
        endcase
    end
end
endmodule