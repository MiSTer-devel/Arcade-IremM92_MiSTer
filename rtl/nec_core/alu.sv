`ifdef LINTING
`include "types.sv"
`endif

import types::*;

module alu(
    input clk,

    input alu_operation_e operation,
    input [15:0] ta,
    input [15:0] tb,
    input wide,
    output [15:0] result,

    output [9:0] delay,

    input flags_t flags_in,
    output flags_t flags
);

always_comb begin
    bit calc_parity;
    bit calc_sign;
    bit calc_zero;
    flags_t fcalc;
    bit [15:0] res;
    bit [16:0] temp17;
    bit [16:0] temp17_2;
    bit [8:0] temp9;

    bit [15:0] bit_shift_mask;
    
    bit_shift_mask = 16'd1 << ( wide ? tb[3:0] : { 1'b0, tb[2:0] } );

    calc_parity = 0;
    calc_sign = 0;
    calc_zero = 0;
    res = 16'd0;
    temp17 = 17'd0;
    temp9 = 9'd0;
    temp17_2 = 17'd0;

    delay = 10'd0;

    flags = flags_in;

    case(operation)
    ALU_OP_ADD, ALU_OP_ADDC, ALU_OP_INC: begin
        if (operation == ALU_OP_INC)
            temp17 = 17'd1;
        else if (operation == ALU_OP_ADDC)
            temp17 = { 1'b0, tb } + { 16'd0, flags_in.CY };
        else
            temp17 = { 1'b0, tb };
        
        temp17_2 = { 1'b0, ta } + temp17;
        res = temp17_2[15:0];

        if (operation != ALU_OP_INC)
            flags.CY = wide ? temp17_2[16] : temp17_2[8];
        
        flags.AC = ( {1'b0, temp17[3:0]} + {1'b0, ta[3:0]} ) > 5'd15 ? 1 : 0;

        if (wide)
            flags.V = (ta[15] ^ res[15]) & (temp17[15] ^ res[15]);
        else
            flags.V = (ta[7] ^ res[7]) & (temp17[7] ^ res[7]);

        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SUB, ALU_OP_CMP, ALU_OP_DEC, ALU_OP_SUBC: begin
        if (operation == ALU_OP_DEC)
            temp17 = 17'd1;
        else if (operation == ALU_OP_SUBC)
            temp17 = {1'b0, tb} + { 16'd0, flags_in.CY };
        else
            temp17 = {1'b0, tb};

        temp17_2 = ta - temp17;
        res = temp17_2[15:0];

        if (operation != ALU_OP_DEC)
            flags.CY = wide ? temp17_2[16] : temp17_2[8];

        flags.AC = temp17_2[3:0] > ta[3:0] ? 1 : 0;

        if (wide)
            flags.V = (ta[15] ^ temp17[15]) & (ta[15] ^ res[15]);
        else
            flags.V = (ta[7] ^ temp17[7]) & (ta[7] ^ res[7]);
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_AND: begin
        res = ta & tb;
        flags.CY = 0;
        flags.V = 0;
        flags.AC = 0;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end
    
    ALU_OP_OR: begin
        res = ta | tb;
        flags.CY = 0;
        flags.V = 0;
        flags.AC = 0;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end
    
    ALU_OP_XOR: begin
        res = ta ^ tb;
        flags.CY = 0;
        flags.V = 0;
        flags.AC = 0;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_NOT: begin
        res = ~ta;
    end

    ALU_OP_NEG: begin
        res = (~ta) + 16'd1;
        flags.CY = ta != 16'd0 ? 1 : 0;
        
        // TODO - MAME doesn't update these flags, but documentation says it should
        //flags.AC = ta[3:0] > 4'd0 ? 1 : 0;   
        //flags.V = 0;
        //if (wide && ta == 16'h8000) flags.V = 1;
        //if (~wide && ta[7:0] == 8'h80) flags.V = 1;
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
    end

    ALU_OP_SET1: begin
        res = ta | bit_shift_mask;
        delay = 10'd3;
    end

    ALU_OP_CLR1: begin
        res = ta & ~bit_shift_mask;
        delay = 10'd3;
    end

    ALU_OP_TEST1: begin
        res = ta & bit_shift_mask;
        
        flags.CY = 0;
        flags.V = 0;

        delay = 10'd3;

        calc_zero = 1;
    end

    ALU_OP_NOT1: begin
        res = ta ^ bit_shift_mask;
        delay = 10'd3;
    end
    
    ALU_OP_ADJ4A: begin 
        temp9 = { 1'b0, ta[7:0] };
        flags.CY = 0;

        if (flags_in.AC || ta[3:0] > 4'h9) begin
            temp9 = temp9 + 9'd06;
            flags.AC = 1;
            flags.CY = flags_in.CY | temp9[8];
        end else begin
            flags.AC = 0;
        end

        if (flags_in.CY || ta[7:0] > 8'h99) begin
            temp9 = temp9 + 9'h60;
            flags.CY = 1;
        end else begin
            flags.CY = 0;
        end
        res = { 8'd0, temp9[7:0] };
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
        delay = 10'd3;
    end

    ALU_OP_ADJ4S: begin 
        temp9 = { 1'b0, ta[7:0] };
        flags.CY = 0;

        if (flags_in.AC || ta[3:0] > 4'h9) begin
            temp9 = temp9 - 9'd06;
            flags.AC = 1;
            flags.CY = flags_in.CY | temp9[8];
        end else begin
            flags.AC = 0;
        end

        if (flags_in.CY || ta[7:0] > 8'h99) begin
            temp9 = temp9 - 9'h60;
            flags.CY = 1;
        end else begin
            flags.CY = 0;
        end
        res = { 8'd0, temp9[7:0] };
        calc_parity = 1; calc_sign = 1; calc_zero = 1;
        delay = 10'd3;
    end

    ALU_OP_ADJBA: begin
        if (flags_in.AC || ta[3:0] > 4'h9) begin
                        res = ta + 16'h0106;
                        flags.AC = 1;
            flags.CY = 1;
        end else begin
            res = ta;
            flags.AC = 0;
            flags.CY = 0;
        end
        res[7:4] = 4'd0;
        delay = 10'd3;
    end 

    ALU_OP_ADJBS: begin
        if (flags_in.AC || ta[3:0] > 4'h9) begin
            res = ta - 16'h0006;
            res[15:7] = res[15:7] - 8'h1;
            flags.AC = 1;
            flags.CY = 1;
        end else begin
            res = ta;
            flags.AC = 0;
            flags.CY = 0;
        end
        res[7:4] = 4'd0;
        delay = 10'd3;
    end 

    default: begin end
    endcase

    if (calc_parity) flags.P = ~(res[0] ^ res[1] ^ res[2] ^ res[3] ^ res[4] ^ res[5] ^ res[6] ^ res[7]);
    if (calc_sign) flags.S = wide ? res[15] : res[7];
    if (calc_zero) flags.Z = wide ? res[15:0] == 16'd0 : res[7:0] == 8'd0;

    result = wide ? res[15:0] : { 8'd0, res[7:0] };
end

endmodule
