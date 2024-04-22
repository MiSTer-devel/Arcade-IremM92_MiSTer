//============================================================================
//  Irem M92 for MiSTer FPGA - ROM loading
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

import m92_pkg::*;

module rom_loader
(
    input sys_clk,
    input ram_clk,

    input ioctl_wr,
    input [7:0] ioctl_data,

    output ioctl_wait,

    output [24:0] sdr_addr,
    output [15:0] sdr_data,
    output [1:0] sdr_be,
    output sdr_req,
    input sdr_rdy,

    output [19:0] bram_addr,
    output [7:0] bram_data,
    output reg [4:0] bram_cs,
    output bram_wr,

    output board_cfg_t board_cfg
);


reg [24:0] base_addr;
reg reorder_64;
reg [24:0] offset;
reg [23:0] size;

enum {
    BOARD_CFG,
    REGION_IDX,
    SIZE_0,
    SIZE_1,
    SIZE_2,
    SDR_DATA,
    BRAM_DATA
} stage = BOARD_CFG;

reg [3:0] region = 0;

reg write_rq = 0;
reg write_ack = 0;

always @(posedge sys_clk) begin
    if (write_ack == write_rq) begin
        ioctl_wait <= 0;
        sdr_req <= 0;
    end

    bram_wr <= 0;
    
    if (ioctl_wr) begin
        case (stage)
        BOARD_CFG: begin 
            if (ioctl_data == 8'hff) board_cfg <= board_cfg_t'(9'b100000000);
            else board_cfg <= board_cfg_t'({1'b0, ioctl_data});
            stage <= REGION_IDX;
        end
        REGION_IDX: begin
            if (ioctl_data == 8'hff) region <= region + 4'd1;
            else region <= ioctl_data[3:0];
            stage <= SIZE_0;
        end
        SIZE_0: begin size[23:16] <= ioctl_data; stage <= SIZE_1; end
        SIZE_1: begin size[15:8] <= ioctl_data; stage <= SIZE_2; end
        SIZE_2: begin
            size[7:0] <= ioctl_data;
            base_addr <= LOAD_REGIONS[region].base_addr;
            reorder_64 <= LOAD_REGIONS[region].reorder_64;
            bram_cs <= LOAD_REGIONS[region].bram_cs;
            offset <= 25'd0;

            if ({size[23:8], ioctl_data} == 24'd0)
                stage <= REGION_IDX;
            else if (LOAD_REGIONS[region].bram_cs != 0)
                stage <= BRAM_DATA;
            else
                stage <= SDR_DATA;
        end
        SDR_DATA: begin
            if (reorder_64)
                sdr_addr <= base_addr[24:0] + {offset[24:7], offset[5:2], offset[6], offset[1:0]};
            else
                sdr_addr <= base_addr[24:0] + offset[24:0];
            sdr_data = {ioctl_data, ioctl_data};
            sdr_be <= { offset[0], ~offset[0] };
            offset <= offset + 25'd1;
            sdr_req <= 1;
            ioctl_wait <= 1;
            write_rq <= ~write_rq; 

            if (offset == ( size - 1)) stage <= REGION_IDX;
        end
        BRAM_DATA: begin
            bram_addr <= offset[19:0];
            bram_data <= ioctl_data;
            bram_wr <= 1;
            offset <= offset + 25'd1;

            if (offset == ( size - 1)) stage <= REGION_IDX;
        end
        endcase
    end
end

always @(posedge ram_clk) begin
    if (sdr_rdy) begin
        write_ack <= write_rq;
    end
end

endmodule

module ddr_download_adaptor(
    input clk,

    // HPS ioctl interface
    input ioctl_download,
    input [24:0] ioctl_addr,
    input [7:0] ioctl_index,
    input ioctl_wr,
    input [7:0] ioctl_data,
    output ioctl_wait,

    output busy,
    
    input data_wait,
    output data_strobe,
    output [7:0] data,

	input         DDRAM_BUSY,
	input  [63:0] DDRAM_DOUT,
    input         DDRAM_DOUT_READY,
	output  [7:0] DDRAM_BURSTCNT,
	output [28:0] DDRAM_ADDR,
	output  [7:0] DDRAM_BE,
	output        DDRAM_WE,
	output        DDRAM_RD
);

localparam [7:0] ROM_INDEX = 8'd0;
localparam [31:0] DDR_BASE_ADDR = 32'h3000_0000;

assign DDRAM_WE = 0;
assign DDRAM_BE = 8'hff;
assign DDRAM_BURSTCNT = 8'd1;

enum {
    IDLE,
    DDR_READ,
    DDR_WAIT,
    OUTPUT_DATA
} state = IDLE;

reg prev_download = 0;
reg wr_detected = 0;

reg active = 0;
reg [24:0] length;
reg [24:0] offset;

reg [63:0] buffer;

reg [7:0] ddr_byte;
reg ddr_strobe;

wire valid_index = ROM_INDEX == ioctl_index;

// pass-through ioctl signals if DDR is not active
always_comb begin
    if (state == IDLE) begin
        ioctl_wait = data_wait;
        data_strobe = valid_index & ioctl_download & ioctl_wr;
        data = ioctl_data;
        busy = valid_index & ioctl_download;
    end else begin
        ioctl_wait = 0;
        data_strobe = ddr_strobe;
        data = ddr_byte;
        busy = offset != length;
    end
end


always_ff @(posedge clk) begin
    prev_download <= ioctl_download;
    DDRAM_RD <= 0;
    ddr_strobe <= 0;

    if (valid_index && ioctl_download && ioctl_wr) wr_detected <= 1;
    
    case(state)
        IDLE: if (valid_index && prev_download && ~ioctl_download) begin
            if (~wr_detected) begin
                length <= ioctl_addr;
                offset <= 0;
                state <= DDR_READ;
            end
        end

        DDR_READ: if (~DDRAM_BUSY) begin
            bit [31:0] addr;
            addr = DDR_BASE_ADDR + offset;
            DDRAM_ADDR <= addr[31:3];
            DDRAM_RD <= 1;
            state <= DDR_WAIT;
        end

        DDR_WAIT: if (DDRAM_DOUT_READY) begin
            buffer <= DDRAM_DOUT;
            state <= OUTPUT_DATA;
        end

        OUTPUT_DATA: if (~data_wait & !ddr_strobe) begin
            if (offset == length) begin
                state <= IDLE;
            end else begin
                offset <= offset + 32'd1;
                if (&offset[2:0]) state <= DDR_READ;
                ddr_strobe <= 1;
                ddr_byte <= buffer[(offset[2:0] * 8) +: 8];
            end
        end
    endcase
end


endmodule