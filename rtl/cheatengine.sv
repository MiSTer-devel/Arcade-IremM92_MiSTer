//============================================================================
//  Irem M92 for MiSTer FPGA - Cheat Engine
//
//  Copyright (C) 2023 Martin Donlon
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================


// Based on cheat code handling by Kitrinx
// Apr 21, 2019

// Code layout:
// {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

module cheatengine_32_16(
	input  clk,        // Best to not make it too high speed for timing reasons
	input  reset,      // This should only be triggered when a new rom is loaded or before new codes load, not warm reset
	input  enable,
	output available,
	input  [128:0] code,
	input  [ADDR_WIDTH - 1:0] addr_in,
	input  [15:0] data_in,
	output [15:0] data_out
);

typedef struct
{
    bit [1:0] method;
    bit [3:0] value_mask;
    bit [31:0] compare_mask;
    bit [31:0] value;
    bit [31:0] compare;
    bit [ADDR_WIDTH - 1:0] addr;
} code_t;

parameter ADDR_WIDTH   = 16; // Not more than 32
parameter MAX_CODES    = 32;

localparam INDEX_SIZE  = $clog2(MAX_CODES-1); // Number of bits for index, must accomodate MAX_CODES

code_t codes[MAX_CODES];

wire [ADDR_WIDTH-1: 0] code_addr    = code[64+:ADDR_WIDTH];
wire [31: 0] code_compare = code[32+:32];
wire [31: 0] code_data    = code[0+:32];
wire code_comp_f = code[96];
wire [2:0] code_width  = code[102:100];
wire [1:0] code_method = code[105:104];

reg [INDEX_SIZE:0] next_index;
assign available = |next_index;

reg code_change;
always_ff @(posedge clk) begin
	int x;
    reg [3:0] mask;
    reg [31:0] value;
    reg [31:0] compare;
	if (reset) begin
		next_index <= 0;
		code_change <= 0;
		for (x = 0; x < MAX_CODES; x = x + 1) codes[x].value_mask <= '0;
	end else begin
		code_change <= code[128];
		if (code[128] && ~code_change && next_index < MAX_CODES) begin // detect posedge
            case ({code_addr[1:0], code_width[2:0]})
                'b00_001: begin mask = 4'b0001; value = { 24'd0, code_data[7:0]         }; compare = { 24'd0, code_compare[7:0]         }; end
                'b01_001: begin mask = 4'b0010; value = { 16'd0, code_data[7:0],   8'd0 }; compare = { 16'd0, code_compare[7:0],   8'd0 }; end
                'b10_001: begin mask = 4'b0100; value = {  8'd0, code_data[7:0],  16'd0 }; compare = {  8'd0, code_compare[7:0],  16'd0 }; end
                'b11_001: begin mask = 4'b1000; value = {        code_data[7:0],  24'd0 }; compare = {        code_compare[7:0],  24'd0 }; end
                'b00_010: begin mask = 4'b0011; value = { 16'd0, code_data[15:0]        }; compare = { 16'd0, code_compare[15:0]        }; end
                'b10_010: begin mask = 4'b1100; value = {        code_data[15:0], 16'd0 }; compare = {        code_compare[15:0], 16'd0 }; end
                'b00_100: begin mask = 4'b1111; value = {        code_data[31:0]        }; compare = { 32'd0                            }; end
                default:  begin mask = 4'b0000; value =   32'd0;                           compare =   32'd0;                              end
            endcase

            codes[next_index].value_mask <= mask;
            codes[next_index].compare_mask <= code_comp_f ? { {8{mask[3]}}, {8{mask[2]}}, {8{mask[1]}}, {8{mask[0]}} }: 32'd0;
            codes[next_index].addr <= code_addr;
            codes[next_index].value <= value;
            codes[next_index].compare <= compare;
            codes[next_index].method <= code_method;
			next_index <= next_index + 1'b1;
		end
	end
end

always_comb begin
	int x;
    int p;

    reg [31:0] wdi;
    reg [31:0] wdo;

    wdi = addr_in[1] ? { data_in, 16'd0 } : { 16'd0, data_in };
	wdo = wdi;

	if (enable) begin
		for (x = 0; x < MAX_CODES; x = x + 1) begin
			if (codes[x].addr[ADDR_WIDTH-1:2] == addr_in[ADDR_WIDTH-1:2]) begin
                reg [31:0] compare;
                compare = (codes[x].compare ^ wdi) & codes[x].compare_mask;
                if ( ~|compare ) begin
                    for (p = 0; p < 4; p = p + 1) begin
                        if (codes[x].value_mask[p]) begin
                            case(codes[x].method)
                                1: wdo[8*p +: 8] = codes[x].value[8*p +: 8] | wdi[8*p +: 8];
                                2: wdo[8*p +: 8] = codes[x].value[8*p +: 8] & wdi[8*p +: 8];
                                default: wdo[8*p +: 8] = codes[x].value[8*p +: 8];
                            endcase
                        end
                    end
                end
			end
		end
	end

    data_out = addr_in[1] ? wdo[31:16] : wdo[15:0];
end

endmodule
