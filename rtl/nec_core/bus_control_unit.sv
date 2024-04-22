`ifdef LINTING
`include "types.sv"
`endif

import types::*;

// V33 bus control with prefetch
// Not implemented:
//   buslock, hldrq, hldak
//   extended addressing (aex)
//   bus sizing
//   co-processor memory access
// TODO
//   Halting
//   Interrupt ack
module bus_control_unit(
    input               clk,
    input               ce_1,
    input               ce_2,


    // Pins
    input               reset,
    input               hldrq,
    input               n_ready,
    input               bs16,

    output  reg         hldak,
    output  reg         n_buslock,
    output  reg         n_ube,
    output              r_w,
    output              m_io,
    output              busst0,
    output              busst1,
    output              aex,
    output  reg         n_bcyst,
    output              n_dstb,

    output  reg [23:0]  addr,
    output      [15:0]  dout,
    input       [15:0]  din,


    // Execution Unit Communication
    input       [15:0]  reg_ps,
    input       [15:0]  reg_ss,
    input       [15:0]  reg_ds0,
    input       [15:0]  reg_ds1,

    // instruction queue
    // inputs only read on ce1
    input               pfp_set,
    input               block_prefetch,
    input       [15:0]  ipq_head,
    output  reg [7:0]   ipq[8],
    output      [3:0]   ipq_len,

    // Data pointer read/write
    input       [15:0]  dp_addr,
    input       [15:0]  dp_dout,
    output      [15:0]  dp_din,
    input sreg_index_e  dp_sreg,
    input               dp_write,
    input               dp_wide,
    input               dp_io,
    input               dp_req,
    input               dp_zero_seg,
    output              dp_ready,

    input               buslock_prefix,
    output  reg         implementation_fault,

    // Interrupt handling
    input               intreq,
    output  reg         intack,
    output  reg  [7:0]  intvec
);

function bit [23:0] physical_addr(sreg_index_e sreg, bit [15:0] ea);
    bit [19:0] addr;
    case(sreg)
    DS0: addr = {reg_ds0, 4'd0} + {4'd0, ea};
    DS1: addr = {reg_ds1, 4'd0} + {4'd0, ea};
    SS: addr = {reg_ss, 4'd0} + {4'd0, ea};
    PS: addr = {reg_ps, 4'd0} + {4'd0, ea};
    endcase
    return { 4'd0, addr };
endfunction

bcu_t_state_e t_state;
bcu_cycle_type_e cycle_type;

// Set external bus status signals based on cycle_type
always_comb begin
    case(cycle_type)
    INT_ACK1,
    INT_ACK2:  begin m_io = 0; r_w = 1; busst1 = 0; busst0 = 0; end
    IO_READ:   begin m_io = 0; r_w = 1; busst1 = 0; busst0 = 1; end
    IO_WRITE:  begin m_io = 0; r_w = 0; busst1 = 0; busst0 = 1; end
    HALT_ACK:  begin m_io = 0; r_w = 0; busst1 = 1; busst0 = 1; end
    IPQ_FETCH: begin m_io = 1; r_w = 1; busst1 = 0; busst0 = 0; end
    MEM_READ:  begin m_io = 1; r_w = 1; busst1 = 0; busst0 = 1; end
    MEM_WRITE: begin m_io = 1; r_w = 0; busst1 = 0; busst0 = 1; end
    endcase
end

reg dp_busy;
reg dp_final_cycle;
reg dp_req2;
reg [15:0] dp_din_buf;
reg [15:0] reg_pfp;
reg discard_ipq_fetch = 0;
assign ipq_len = pfp_set ? 4'd0 : reg_pfp[3:0] - ipq_head[3:0];

wire dp_bus_ready = (dp_final_cycle && ce_1 && t_state == T_2 && ~n_ready);
assign dp_ready = ~dp_req & ~dp_req2 & (dp_bus_ready | ~dp_busy);
int intack_idles;

reg [3:0] prefetch_delay;

always_comb begin
    if (~dp_addr[0]) dp_din = din;
    else if (dp_addr[0] & dp_wide) dp_din = { din[7:0], dp_din_buf[15:8] };
    else dp_din = { din[7:0], din[15:8] };
end

always_ff @(posedge clk) begin
    if (reset) begin
        t_state <= T_IDLE;

        hldak <= 0;
        n_ube <= 0;
        n_dstb <= 1;
        n_bcyst <= 1;

        cycle_type <= IPQ_FETCH;
        intack <= 0;

        implementation_fault <= 0;

        reg_pfp <= ipq_head;
        discard_ipq_fetch <= 0;

        dp_req2 <= 0;
        dp_busy <= 0;
        dp_din_buf <= 16'hffff;

        prefetch_delay <= 4'd0;

    end else if (ce_1 | ce_2) begin
        bit [15:0] cur_pfp;
        cur_pfp = reg_pfp;
        if (pfp_set) begin
            reg_pfp <= ipq_head;
            cur_pfp = ipq_head;
            discard_ipq_fetch <= 1;
        end

        if (dp_req) dp_req2 <= 1;

        if (~intreq) intack <= 0;

        if (ce_1 && t_state == T_1) begin
            n_dstb <= 0;
            dout <= dp_addr[0] ? { dp_dout[7:0], dp_dout[15:8] } : dp_dout;
        end else if (ce_2 && t_state == T_IDLE) begin
            bit do_prefetch;

            n_dstb <= 1; // clear data strobe
            n_buslock <= ~buslock_prefix;
            intack_idles <= intack_idles + 1;
            
            do_prefetch = 0;

            if (block_prefetch) begin
                do_prefetch = 0;
                prefetch_delay <= 4'd2;
            end else if (ipq_len < 7) begin
                prefetch_delay <= 4'd1;
                if (prefetch_delay > 4'd0) do_prefetch = 1;
                do_prefetch = 1;
            end else begin
                prefetch_delay <= 4'd0;
            end

            if (cycle_type == INT_ACK1) begin
                if (intack_idles == 6) begin
                    t_state <= T_1;
                    n_bcyst <= 0;
                    cycle_type <= INT_ACK2;
                    intack_idles <= 0;
                end else begin
                    n_buslock <= 0;
                end
            end else if (cycle_type == INT_ACK2) begin
                if (intack_idles == 5) begin
                    cycle_type <= IPQ_FETCH;
                    intack <= 1;
                end
            end else if (dp_busy) begin // Second byte of an unaligned access
                t_state <= T_1;
                n_bcyst <= 0;
                addr <= addr + 24'd1; // TODO: should only the lower 16-bits be impacted?
                n_ube <= 1;
                dp_final_cycle <= 1;
            end else if (intreq & ~intack) begin
                n_buslock <= 0;
                cycle_type <= INT_ACK1;
                n_bcyst <= 0;
                t_state <= T_1;
                intack_idles <= 0;
                n_ube <= 1;
            end else if (dp_req | dp_req2) begin
                dp_req2 <= 0;
                t_state <= T_1;
                n_bcyst <= 0;
                if (dp_io) begin
                    addr <= {8'd0, dp_addr};
                    cycle_type <= dp_write ? IO_WRITE : IO_READ;
                end else begin
                    if (dp_zero_seg) begin
                        addr <= { 8'd0, dp_addr };
                    end else begin
                        addr <= physical_addr(dp_sreg, dp_addr);
                    end
                    cycle_type <= dp_write ? MEM_WRITE : MEM_READ;
                end

                n_ube <= (~dp_wide & ~dp_addr[0]);
                dp_final_cycle <= ~dp_wide | ~dp_addr[0];
                dp_busy <= 1;
            end else if (do_prefetch) begin
                t_state <= T_1;
                n_bcyst <= 0;
                cycle_type <= IPQ_FETCH;
                addr <= physical_addr(PS, cur_pfp);
                n_ube <= 0; // always
                discard_ipq_fetch <= 0;
                //prefetch_delay <= 4'd0;
            end
        end else if (ce_2 && t_state == T_1) begin
            n_bcyst <= 1;
            t_state <= T_2;
        end else if (ce_1 && t_state == T_2) begin
            if (~n_ready) begin
                dp_final_cycle <= 1;
                case(cycle_type)
                    IPQ_FETCH: begin
                        if (~pfp_set & ~discard_ipq_fetch) begin
                            if (reg_pfp[0]) begin
                                ipq[reg_pfp[2:0]] <= din[15:8];
                                reg_pfp <= reg_pfp + 16'd1;
                            end else begin
                                ipq[reg_pfp[2:0]] <= din[7:0];
                                ipq[reg_pfp[2:0] + 1] <= din[15:8];
                                reg_pfp <= reg_pfp + 16'd2;
                            end
                        end
                    end
                    MEM_READ, IO_READ: begin
                        dp_din_buf <= din;
                        dp_busy <= ~dp_final_cycle;
                    end
                    MEM_WRITE, IO_WRITE: begin
                        dp_busy <= ~dp_final_cycle;
                        n_dstb <= 1;
                    end
                    INT_ACK1,
                    INT_ACK2: begin
                        intvec <= din[7:0];
                    end
                    default: begin end
                endcase

                t_state <= T_IDLE;
            end
        end
    end
end

endmodule