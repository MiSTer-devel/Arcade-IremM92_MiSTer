//============================================================================
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

module GA21(
    input clk,
    input clk_ram,

    input ce,

    input reset,

    input [15:0] din,
    output [15:0] dout,

    input [11:0] addr,

    input reg_cs,
    input buf_cs,
    input wr,

    output busy,

    output [15:0] obj_dout,
    input [15:0] obj_din,
    output [11:0] obj_addr,
    output obj_we,

    output buffer_we,
    output [11:0] buffer_addr,
    output [15:0] buffer_dout,
    input [15:0] buffer_din,

    input [9:0] count,

    output [12:0] pal_addr,
    output [15:0] pal_dout,
    input [15:0] pal_din,
    output pal_we,
    output pal_cs,

    input [63:0] sdr_data,
    output reg [24:0] sdr_addr,
    output reg sdr_req,
    input sdr_rdy
);

reg [7:0] reg_direct_access;
reg [7:0] reg_obj_ptr;
reg [15:0] reg_copy_mode;

wire [2:0] pal_addr_high = reg_copy_mode[10:8];
wire layer_ordered_copy = reg_copy_mode[0];
wire full_copy          = reg_copy_mode[7] & ~reg_copy_mode[0];

reg obj_addr_high = 0;

enum {
    IDLE,
    IDLE_DELAY,
    INIT_COPY_PAL,
    COPY_PAL,
    INIT_CLEAR_OBJ,
    CLEAR_OBJ,
    INIT_COPY_OBJ,
    READ_BASE0,
    READ_BASE1,
    READ_BASE2,
    READ_BASE3,
    WAIT_SDR,
    WRITE_INST0,
    WRITE_INST1,
    WRITE_INST2,
    WRITE_INST3
} copy_state = IDLE;


reg [11:0] copy_counter;
reg [15:0] copy_dout;
reg [11:0] copy_obj_addr;
reg [11:0] copy_pal_addr;
reg [8:0] copy_obj_idx;
reg [11:0] buffer_src_addr;
reg [11:0] next_buffer_src_addr;
reg [2:0] copy_layer;
reg copy_this_obj;

reg copy_obj_we, copy_pal_we;

wire direct_access_pal = reg_direct_access[1];
wire direct_access_obj = reg_direct_access[0];

reg sdr_rdy2;

reg [63:0] base_obj;
reg [63:0] inst_obj;

wire [8:0] base_y = base_obj[8:0];
wire [9:0] base_x = base_obj[57:48];
wire [6:0] base_color = base_obj[38:32];
wire base_prio = base_obj[39];
wire base_flipx = base_obj[40];
wire base_flipy = base_obj[41];

wire [8:0] inst_y = inst_obj[24:16];
wire [1:0] inst_height = inst_obj[26:25];
wire [15:0] inst_code = inst_obj[47:32];
wire inst_flipx = inst_obj[8];
wire inst_flipy = inst_obj[9];
wire inst_end = inst_obj[15];
wire [9:0] inst_x = inst_obj[57:48];

always_ff @(posedge clk_ram) begin
    if (sdr_req) sdr_rdy2 <= 0;
    if (sdr_rdy) sdr_rdy2 <= 1;
end

always_ff @(posedge clk) begin
    bit [8:0] obj_y;
    bit [1:0] obj_height;
    bit [1:0] obj_log2_cols;
    bit [2:0] obj_layer;
    bit [3:0] obj_cols;
    bit [8:0] next_obj_idx;

    sdr_req <= 0;
    if (reset) begin
        copy_state <= IDLE;
        reg_direct_access <= 0;
        reg_obj_ptr <= 0;
        reg_copy_mode <= 0;
        
        copy_obj_we <= 0;
        copy_pal_we <= 0;

    end else begin

        if (reg_cs & wr) begin
            if (din[11]) begin
                copy_state <= INIT_COPY_PAL;
            end
            //if (addr == 12'h0) reg_obj_ptr <= din[7:0];
            //if (addr == 12'h1) reg_direct_access <= din[7:0];
            //if (addr == 12'h2) reg_copy_mode <= din[15:0];
            //if (addr == 12'h4) begin
            //    copy_state <= INIT_COPY_PAL;
            //end
        end

        if (ce) begin
            copy_obj_we <= 0;
            copy_pal_we <= 0;

            case(copy_state)
            IDLE_DELAY: copy_state <= IDLE;
            IDLE: begin
            end
            INIT_COPY_PAL: begin
                buffer_src_addr <= 12'h800;
                copy_pal_addr <= ~12'd0;
                copy_state <= COPY_PAL;
            end
            COPY_PAL: begin
                if (buffer_src_addr == 12'h000) begin
                    copy_state <= INIT_CLEAR_OBJ;
                end else begin
                    buffer_src_addr <= buffer_src_addr + 12'd1;
                    copy_pal_addr <= copy_pal_addr + 11'd1;
                    copy_dout <= buffer_din;
                    copy_pal_we <= 1;
                end
            end
            INIT_CLEAR_OBJ: begin
                copy_dout <= 16'd0;
                copy_obj_addr <= 11'd0;
                copy_obj_we <= 1;
                copy_state <= CLEAR_OBJ;
            end
            CLEAR_OBJ: begin
                copy_obj_addr <= copy_obj_addr + 11'd1;
                copy_obj_we <= 1;
                if (&copy_obj_addr) begin
                    copy_state <= INIT_COPY_OBJ;
                end
            end
            INIT_COPY_OBJ: begin
                copy_state <= READ_BASE0;
                copy_this_obj <= 0;
                buffer_src_addr <= 12'd0;
                copy_layer <= 3'd0;
                copy_obj_idx <= 9'h0ec;
            end

            READ_BASE0: begin
                if (buffer_din[14:0] == 'd0) begin
                    copy_state <= READ_BASE0;
                    buffer_src_addr <= buffer_src_addr + 'd4;
                end else begin
                    copy_state <= READ_BASE1;
                    base_obj[15:0] <= buffer_din;
                    buffer_src_addr <= buffer_src_addr + 12'd1;
                end

                if (buffer_src_addr[11]) copy_state <= IDLE;
            end
            
            READ_BASE1: begin
                if (buffer_din[14:0] == 'd0) begin
                    copy_state <= READ_BASE0;
                    buffer_src_addr <= buffer_src_addr + 'd3;
                end else begin
                    sdr_req <= 1;
                    sdr_addr <= REGION_SPRITE_TABLE.base_addr[24:0] + { buffer_din[14:0], 3'b000 };
                    copy_state <= READ_BASE2;
                    base_obj[31:16] <= buffer_din;
                    buffer_src_addr <= buffer_src_addr + 12'd1;
                end
            end
            READ_BASE2: begin
                copy_state <= READ_BASE3;
                base_obj[47:32] <= buffer_din;
                buffer_src_addr <= buffer_src_addr + 12'd1;
            end
            READ_BASE3: begin
                base_obj[63:48] <= buffer_din;
                buffer_src_addr <= buffer_src_addr + 12'd1;

                copy_state <= WAIT_SDR;
            end

            WAIT_SDR: begin
                if (sdr_rdy2) begin
                    copy_state <= WRITE_INST0;
                    inst_obj <= sdr_data;
                end
            end

            WRITE_INST0: begin
                copy_dout[8:0] <= base_y + inst_y;
                copy_dout[10:9] <= inst_height;
                copy_dout[12:11] <= 2'd0; // width
                copy_dout[15:13] <= 3'd0; // layer
                copy_obj_addr <= {copy_obj_idx, 2'b00};
                copy_obj_we <= 1;
                copy_state <= WRITE_INST1;

                // start next read
                sdr_addr <= sdr_addr + 25'd8;
                sdr_req <= 1;
            end

            WRITE_INST1: begin
                copy_dout[15:0] <= inst_code;
                copy_obj_addr <= {copy_obj_idx, 2'b01};
                copy_obj_we <= 1;
                copy_state <= WRITE_INST2;
            end

            WRITE_INST2: begin
                copy_dout[6:0] <= base_color;
                copy_dout[7] <= base_prio;
                copy_dout[8] <= base_flipx ^ inst_flipx;
                copy_dout[9] <= base_flipy ^ inst_flipy;
                copy_obj_addr <= {copy_obj_idx, 2'b10};
                copy_obj_we <= 1;
                copy_state <= WRITE_INST3;
            end

            WRITE_INST3: begin
                copy_dout[9:0] <= base_x + inst_x;
                copy_obj_addr <= {copy_obj_idx, 2'b11};
                copy_obj_we <= 1;
                copy_obj_idx <= copy_obj_idx - 9'd1;

                if (copy_obj_idx == 9'h000) begin
                    copy_state <= IDLE_DELAY;
                end else if (inst_end) begin
                    copy_state <= READ_BASE0;
                end else begin
                    copy_state <= WAIT_SDR;
                end
            end
            endcase
        end
    end
end

assign dout = buf_cs ? (direct_access_obj ? obj_din : (direct_access_pal ? pal_din : buffer_din)) : 16'd0;
assign busy = copy_state != IDLE;

assign buffer_we = ~busy & buf_cs & wr;
assign buffer_addr = busy ? buffer_src_addr : addr;

assign buffer_dout = din;

assign obj_dout = direct_access_obj ? din : copy_dout;
assign obj_addr = direct_access_obj ? addr : (busy ? copy_obj_addr : {obj_addr_high, count});
assign obj_we = direct_access_obj ? (buf_cs & wr) : (busy ? copy_obj_we : 1'b0);

assign pal_dout = direct_access_pal ? din : copy_dout;
assign pal_addr = {1'b0, direct_access_pal ? addr[10:0] : (busy ? copy_pal_addr : 11'd0)};
assign pal_we = direct_access_pal ? (buf_cs & wr) : (busy ? copy_pal_we : 1'b0);
assign pal_cs = direct_access_pal ? buf_cs : 1'b0;

endmodule