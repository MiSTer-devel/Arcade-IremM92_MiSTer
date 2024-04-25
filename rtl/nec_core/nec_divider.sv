// Based on:
// Project F Library - Division: Unsigned Integer with Remainder
// (C)2023 Will Green, Open source hardware released under the MIT License
// Learn more at https://projectf.io/verilog-lib/

// Adapted to specific needs of NEC Vxx CPUs
// 32 bit and 16 bit modes
// Clock enable
// overflow detection
// signed support
`default_nettype none

module divu_int #(parameter WIDTH=5) ( // width of numbers in bits
    input wire logic clk,              // clock
    input wire logic ce,               // clock
    input wire logic reset,            // reset
    input wire logic start,            // start calculation
    output     logic done,             // calculation is complete (high for one tick)
    output     logic overflow,         // result overflowed
    output     logic dbz,              // divide by zero
    input wire logic [WIDTH-1:0] a,    // dividend (numerator)
    input wire logic [WIDTH-1:0] b,    // divisor (denominator)
    output     logic [WIDTH-1:0] quot, // result: quotient
    output     logic [WIDTH-1:0] rem   // result: remainder
);

logic busy;
logic [WIDTH-1:0] b1;             // copy of divisor
logic [WIDTH-1:0] quo, quo_next;  // intermediate quotient
logic [WIDTH:0] acc, acc_next;    // accumulator (1 bit wider)
int i;      // iteration counter

// division algorithm iteration
always_comb begin
    if (acc >= {1'b0, b1}) begin
        acc_next = acc - b1;
        {acc_next, quo_next} = {acc_next[WIDTH-1:0], quo, 1'b1};
    end else begin
        {acc_next, quo_next} = {acc, quo} << 1;
    end
end

// calculation control
always_ff @(posedge clk) begin
    if (ce) begin
        if (start) begin
            done <= 0;
            overflow <= 0;
            i <= 0;
            if (b == 0) begin  // catch divide by zero
                busy <= 0;
                done <= 1;
                dbz <= 1;
            end else begin
                busy <= 1;
                dbz <= 0;
                b1 <= b;
                {acc, quo} <= {{WIDTH{1'b0}}, a, 1'b0};  // initialize calculation
            end
        end else if (busy) begin
            if (i == WIDTH-1) begin  // we're done
                busy <= 0;
                done <= 1;
                overflow <= |quo_next[WIDTH-1:WIDTH/2];
                quot <= quo_next;
                rem <= acc_next[WIDTH:1];  // undo final shift
            end else begin  // next iteration
                i <= i + 1;
                acc <= acc_next;
                quo <= quo_next;
            end
        end
        if (reset) begin
            busy <= 0;
            done <= 0;
            overflow <= 0;
            dbz <= 0;
            quot <= 0;
            rem <= 0;
        end
    end
end
endmodule


module nec_divider(
    input wire logic clk,           // clock
    input wire logic ce,            // clock enable
    input wire logic reset,         // reset
    input wire logic start,         // start calculation
    input wire logic wide,          // 32 / 16
    output     logic done,          // calculation is complete (high for one tick)
    output     logic overflow,      // result overflowed
    output     logic dbz,           // divide by zero
    input wire logic [32:0] a,      // dividend (numerator), signed
    input wire logic [32:0] b,      // divisor (denominator), signed
    output     logic [15:0] quot,   // result value: quotient
    output     logic [15:0] rem     // result: remainder
);

wire done_16, done_32;
wire overflow_16, overflow_32;
wire dbz_16, dbz_32;
wire [15:0] quot_16, rem_16;
wire [31:0] quot_32, rem_32;

wire [31:0] a_abs = a[32] ? -a[31:0] : a[31:0];
wire [31:0] b_abs = b[32] ? -b[31:0] : b[31:0];

always_comb begin
    if (wide) begin
        done = done_32;
        overflow = overflow_32;
        dbz = dbz_32;
        quot = a[32] ^ b[32] ? -quot_32[15:0] : quot_32[15:0];
        rem = a[32] ? -rem_32[15:0] : rem_32[15:0]; 
    end else begin
        done = done_16;
        overflow = overflow_16;
        dbz = dbz_16;
        quot = a[32] ^ b[32] ? -quot_16[15:0] : quot_16[15:0];
        rem = a[32] ? -rem_16[15:0] : rem_16[15:0]; 
    end
end

divu_int #(.WIDTH(16)) div_16(
    .clk, .ce, .reset, .start,
    .done(done_16), .overflow(overflow_16), .dbz(dbz_16),
    .a(a_abs[15:0]), .b(b_abs[15:0]),
    .quot(quot_16), .rem(rem_16)
);

divu_int #(.WIDTH(32)) div_32(
    .clk, .ce, .reset, .start,
    .done(done_32), .overflow(overflow_32), .dbz(dbz_32),
    .a(a_abs[31:0]), .b(b_abs[31:0]),
    .quot(quot_32), .rem(rem_32)
);

endmodule

/*
MIT License

Copyright (c) 2023 Will Green, Project F

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/