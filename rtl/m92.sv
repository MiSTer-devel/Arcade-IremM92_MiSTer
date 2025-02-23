//============================================================================
//  Irem M92 for MiSTer FPGA - Main module
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

module m92 (
    input clk_sys,
    input clk_ram,

    input reset_n,
    output reg ce_pix,

    input board_cfg_t board_cfg,

    input z80_reset_n,

    output [7:0] R,
    output [7:0] G,
    output [7:0] B,

    output HSync,
    output VSync,
    output HBlank,
    output VBlank,

    output [15:0] AUDIO_L,
    output [15:0] AUDIO_R,

    input [3:0] coin,
    input [3:0] start_buttons,

    input [9:0] p1_input,
    input [9:0] p2_input,
    input [9:0] p3_input,
    input [9:0] p4_input,

    input [23:0] dip_sw,

    input pause_rq,
    output cpu_paused,

    input cpu_turbo,

    input [1:0] sample_attn,

    output [24:0] sdr_sprite_addr,
    input [63:0] sdr_sprite_dout,
    output sdr_sprite_req,
    input sdr_sprite_rdy,
    output sdr_sprite_refresh,

    output [24:0] sdr_bg_addr,
    input [31:0] sdr_bg_dout,
    output sdr_bg_req,
    input sdr_bg_rdy,

    output reg [24:0] sdr_cpu_addr,
    input [63:0] sdr_cpu_dout,
    output reg sdr_cpu_req,
    input sdr_cpu_rdy,

    output [24:0] sdr_audio_addr,
    input [63:0] sdr_audio_dout,
    output sdr_audio_req,
    input sdr_audio_rdy,

    input clk_bram,
    input bram_wr,
    input [7:0] bram_data,
    input [19:0] bram_addr,
    input [4:0] bram_cs,

    input ioctl_download,
    input [15:0] ioctl_index,
    input ioctl_wr,
    input [26:0] ioctl_addr,
    input [7:0] ioctl_dout,

    input ioctl_upload,
    output [7:0] ioctl_upload_index,
    output [7:0] ioctl_din,
    input ioctl_rd,
    output ioctl_upload_req,

    input [19:0]     hs_address,
    input [7:0]      hs_din,
    output [7:0]      hs_dout,
    input hs_write,
    input hs_read,

    input [2:0] dbg_en_layers,
    input dbg_solid_sprites,
    input en_sprites,
    input en_audio_filters,

    input sprite_freeze
);

assign ioctl_upload_index = 8'd1;

wire [15:0] rgb_color;
assign R = { rgb_color[4:0], rgb_color[4:2] };
assign G = { rgb_color[9:5], rgb_color[9:7] };
assign B = { rgb_color[14:10], rgb_color[14:12] };

reg paused = 0;
assign cpu_paused = paused;

always @(posedge clk_sys) begin
    if (pause_rq & ~paused) begin
        if (vpulse) begin
            paused <= 1;
        end
    end else if (~pause_rq & paused) begin
        paused <= ~vpulse;
    end
end


wire ce_13m;
jtframe_frac_cen #(2) pixel_cen
(
    .clk(clk_sys),
    .cen_in(1),
    .n(10'd1),
    .m(10'd3),
    .cen({ce_pix, ce_13m})
);

wire ce_9m, ce_18m;
jtframe_frac_cen #(2) cpu_cen
(
    .clk(clk_sys),
    .cen_in(1),
    .n(10'd9),
    .m(10'd20),
    .cen({ce_9m, ce_18m})
);
wire clock = clk_sys;


wire dma_busy;

wire [15:0] cpu_mem_out;
wire [19:0] cpu_mem_addr;

wire [15:0] cpu_mem_in;

/* Global signals from schematics */
wire cpu_n_dstb, cpu_busst0, cpu_busst1, cpu_n_bcyst;
wire cpu_n_ube, cpu_r_w, cpu_m_io;

wire IOWR = ~cpu_m_io & ~cpu_r_w & ~cpu_busst1 & cpu_busst0 & ~cpu_n_dstb; // IO Write
wire IORD = ~cpu_m_io & cpu_r_w & ~cpu_busst1 & cpu_busst0; // IO Read
wire MWR = cpu_m_io & ~cpu_r_w & ~cpu_busst1 & cpu_busst0 & ~cpu_n_dstb; // Mem Write
wire MRD = cpu_m_io & cpu_r_w & ~cpu_busst1; // Mem Read

wire INTACK = ~cpu_m_io & cpu_r_w & ~cpu_busst1 & ~cpu_busst0 & ~cpu_n_dstb;

wire [19:0] cpu_word_addr = { cpu_mem_addr[19:1], 1'b0 };
wire [15:0] cpu_rom_data;
wire [15:0] cpu_ram_dout;
wire [19:0] cpu_rom_addr;

wire cpu_rom_memrq;
wire cpu_ram_memrq;
wire buffer_memrq;
wire sprite_control_memrq;
wire video_control_memrq;
wire pf_vram_memrq;
wire eeprom_memrq;
wire banked_memrq;
wire timer_memrq;

wire [7:0] snd_latch_dout;
wire snd_latch_rdy;

reg [15:0] cpu_cycle_timer;
reg [15:0] deferred_ce;
reg ce_toggle;
reg ce_1, ce_2;
wire ga23_busy;
wire cpu_rom_ready;

wire ce_1_cpu = ce_1 & cpu_rom_ready;
wire ce_2_cpu = ce_2 & cpu_rom_ready;

always @(posedge clk_sys) begin
    if (!reset_n) begin
        ce_1 <= 0;
        ce_2 <= 0;
        ce_toggle <= 0;
        deferred_ce <= 16'd0;
    end else begin
        ce_1 <= 0;
        ce_2 <= 0;

        if (ce_18m) begin
            if (~cpu_rom_ready) begin
                deferred_ce <= deferred_ce + 16'd1;
            end else if (|deferred_ce) begin
                deferred_ce <= deferred_ce - 16'd1;
            end
        end

        if (~paused & (ce_18m | cpu_turbo | (cpu_rom_ready & |deferred_ce))) begin
            ce_toggle <= ~ce_toggle;
            ce_1 <= ce_toggle;
            ce_2 <= ~ce_toggle;
        end
    end
end

always @(posedge clk_sys) begin
    if (ce_1_cpu) cpu_cycle_timer <= cpu_cycle_timer + 16'd1;
end

wire hs_access = hs_read | hs_write;
assign hs_dout = hs_address[0] ? cpu_ram_dout[15:8] : cpu_ram_dout[7:0];

singleport_ram #(.widthad(15), .width(8), .name("CPU0")) cpu_ram_0(
    .clock(clk_sys),
    .address(hs_access ? hs_address[15:1] : cpu_mem_addr[15:1]),
    .q(cpu_ram_dout[7:0]),
    .wren(hs_access ? (hs_write & ~hs_address[0]) : (cpu_ram_memrq & MWR & ~cpu_mem_addr[0])),
    .data(hs_access ? hs_din : cpu_mem_out[7:0])
);

singleport_ram #(.widthad(15), .width(8), .name("CPU1")) cpu_ram_1(
    .clock(clk_sys),
    .address(hs_access ? hs_address[15:1] : cpu_mem_addr[15:1]),
    .q(cpu_ram_dout[15:8]),
    .wren(hs_access ? (hs_write & hs_address[0]) : (cpu_ram_memrq & MWR & ~cpu_n_ube)),
    .data(hs_access ? hs_din : cpu_mem_out[15:8])
);

rom_cache rom_cache(
    .clk(clk_sys),
    .ce_1(ce_1),
    .ce_2(ce_2),
    .reset(~reset_n),

    .clk_ram(clk_ram),

    .sdr_addr(sdr_cpu_addr),
    .sdr_data(sdr_cpu_dout),
    .sdr_req(sdr_cpu_req),
    .sdr_rdy(sdr_cpu_rdy),

    .n_bcyst(cpu_n_bcyst),
    .read(MRD & cpu_rom_memrq),
    .rom_word_addr(cpu_rom_addr[19:1]),
    .rom_data(cpu_rom_data),
    .rom_ready(cpu_rom_ready)
);

wire rom0_ce, rom1_ce, ram_cs2;

reg [3:0] bank_select = 4'd0;


wire [7:0] switches_p1 = board_cfg.kick_harness ? { p1_input[4], p1_input[5], p1_input[6], 1'b0,             p1_input[3], p1_input[2], p1_input[1], p1_input[0] }
                                                : { p1_input[4], p1_input[5], 1'b0,        1'b0,             p1_input[3], p1_input[2], p1_input[1], p1_input[0] };
wire [7:0] switches_p2 = board_cfg.kick_harness ? { p2_input[4], p2_input[5], p2_input[6], 1'b0,             p2_input[3], p2_input[2], p2_input[1], p2_input[0] }
                                                : { p2_input[4], p2_input[5], 1'b0,        1'b0,             p2_input[3], p2_input[2], p2_input[1], p2_input[0] };
wire [7:0] switches_p3 = board_cfg.kick_harness ? { 1'b0,        1'b0,        1'b0,        1'b0,             1'b0,        1'b0,        1'b0,        1'b0        }
                                                : { p3_input[4], p3_input[5], coin[2],     start_buttons[2], p3_input[3], p3_input[2], p3_input[1], p3_input[0] };
wire [7:0] switches_p4 = board_cfg.kick_harness ? { p2_input[9], p2_input[8], p2_input[7], 1'b0,             p1_input[9], p1_input[8], p1_input[7], 1'b0        }
                                                : { p4_input[4], p4_input[5], coin[3],     start_buttons[3], p4_input[3], p4_input[2], p4_input[1], p4_input[0] };

wire [15:0] switches_p1_p2 = { ~switches_p2, ~switches_p1 };
wire [15:0] switches_p3_p4 = { ~switches_p4, ~switches_p3 };

wire [15:0] flags = { ~dip_sw[23:16], ~dma_busy, 1'b1, 1'b1 /*TEST*/, 1'b1 /*R*/, ~coin[1:0], ~start_buttons[1:0] };

reg [7:0] sys_flags = 0;
wire COIN0 = sys_flags[0];
wire COIN1 = sys_flags[1];
wire SOFT_NL = ~sys_flags[2];
wire CBLK = sys_flags[3];
wire BRQ = ~sys_flags[4];
wire BANK = sys_flags[5];
wire NL = SOFT_NL ^ ~dip_sw[8];

reg sound_reset = 0;


///////////////////////////////////////////////////
reg [128:0] gg_code;
wire        gg_available;
wire        code_download = ioctl_download && (ioctl_index == 8'd255);

// Code layout:
// {clock bit, code flags,     32'b address, 32'b compare, 32'b replace}
//  128        127:96          95:64         63:32         31:0
// Integer values are in BIG endian byte order, so it up to the loader
// or generator of the code to re-arrange them correctly.

always_ff @(posedge clk_sys) begin
	gg_code[128] <= 1'b0;

	if (code_download & ioctl_wr) begin
        gg_code[127:0] <= { gg_code[119:0], ioctl_dout }; // shift in next byte
		gg_code[128]   <= &ioctl_addr[3:0];      // Clock it in if it's 16th byte
	end
end

wire [15:0] genie_ram_dout, genie_rom_data;
cheatengine_32_16 #(.ADDR_WIDTH(20)) codes_rom
(
	.clk(clk_sys),
	.reset(code_download && ioctl_wr && !ioctl_addr),
	.enable(1),
	.code(gg_code),
	.available(),
	.addr_in(cpu_word_addr),
	.data_in(cpu_rom_data),
	.data_out(genie_rom_data)
);

cheatengine_32_16 #(.ADDR_WIDTH(20)) codes_ram
(
	.clk(clk_sys),
	.reset(code_download && ioctl_wr && !ioctl_addr),
	.enable(1),
	.code(gg_code),
	.available(),
	.addr_in(cpu_word_addr),
	.data_in(cpu_ram_dout),
	.data_out(genie_ram_dout)
);



// TODO BANK, CBLK, NL
always @(posedge clk_sys) begin
    if (~reset_n) begin
        sys_flags <= 8'd0;
        bank_select <= 4'd0;
        sound_reset <= 1'd0;
    end else begin
        if (IOWR && cpu_word_addr == 8'h02) sys_flags <= cpu_mem_out[7:0];
        if (IOWR && cpu_word_addr == 8'h20) bank_select <= cpu_mem_out[3:0];
        if (IOWR && cpu_word_addr == 8'hc0) sound_reset <= ~cpu_mem_out[0];
    end
end

reg [15:0] vid_ctrl;
always @(posedge clk_sys or negedge reset_n) begin
    if (~reset_n) begin
        vid_ctrl <= 0;
    end else if (video_control_memrq & MWR) begin
        vid_ctrl <= cpu_mem_out;
    end
end

wire [15:0] ga21_dout, ga23_dout;
wire [7:0] eeprom_dout;

// mux io and memory reads
always_comb begin
    bit [15:0] d16;
    bit [15:0] io16;

    if (INTACK) begin
        cpu_mem_in = { 8'd0, int_vector };
    end else if (MRD) begin
        if (buffer_memrq) cpu_mem_in = ga21_dout;
        else if (pf_vram_memrq) cpu_mem_in = ga23_dout;
        else if (eeprom_memrq) cpu_mem_in = { eeprom_dout, eeprom_dout };
        else if (timer_memrq) cpu_mem_in = cpu_cycle_timer;
        else if (cpu_rom_memrq) cpu_mem_in = genie_rom_data;
        else cpu_mem_in = genie_ram_dout;
    end else if (IORD) begin
        case ({cpu_word_addr[7:0]})
        8'h00: cpu_mem_in = switches_p1_p2;
        8'h02: cpu_mem_in = flags;
        8'h04: cpu_mem_in = ~dip_sw[15:0];
        8'h06: cpu_mem_in = switches_p3_p4;
        8'h08: cpu_mem_in = { snd_latch_dout, snd_latch_dout };
        default: cpu_mem_in = 16'hffff;
        endcase
    end else begin
        cpu_mem_in = 16'hffff;
    end
end

wire int_req;
wire [7:0] int_vector;

V33 v33(
    .clk(clk_sys),
    .ce_1(ce_1_cpu),
    .ce_2(ce_2_cpu),

    // Pins
    .reset(~reset_n),
    .hldrq(0),
    .n_ready(ga23_busy),
    .bs16(0),

    .hldak(),
    .n_buslock(),
    .n_ube(cpu_n_ube),
    .r_w(cpu_r_w),
    .m_io(cpu_m_io),
    .busst0(cpu_busst0),
    .busst1(cpu_busst1),
    .aex(),
    .n_bcyst(cpu_n_bcyst),
    .n_dstb(cpu_n_dstb),

    .intreq(int_req),
    .n_nmi(1),

    .n_cpbusy(1),
    .n_cperr(1),
    .cpreq(0),

    .addr(cpu_mem_addr),
    .dout(cpu_mem_out),
    .din(cpu_mem_in),

    .turbo(cpu_turbo)
);

address_translator address_translator(
    .A(cpu_mem_addr),
    .board_cfg(board_cfg),
    .cpu_rom_memrq(cpu_rom_memrq),
    .cpu_ram_memrq(cpu_ram_memrq),
    .rom_addr(cpu_rom_addr),

    .buffer_memrq,
    .sprite_control_memrq,
    .video_control_memrq,
    .pf_vram_memrq,
    .eeprom_memrq,
    .timer_memrq,

    .bank_select
);

wire vblank, hblank, vsync, hsync, vpulse, hpulse, hint;

m92_pic m92_pic(
    .clk(clk_sys),
    .ce(ce_1_cpu),
    .reset(~reset_n),

    .cs((IORD | IOWR) & ~cpu_mem_addr[7] & cpu_mem_addr[6] & ~cpu_mem_addr[0]), // 0x40-0x43
    .wr(IOWR),
    .rd(0),
    .a0(cpu_mem_addr[1]),

    .din(cpu_mem_out[7:0]),

    .int_req(int_req),
    .int_vector(int_vector),
    .int_ack(INTACK),

    .intp({4'd0, snd_latch_rdy, hint, ~dma_busy, vblank})
);


assign HSync = hsync;
assign HBlank = hblank;
assign VSync = vsync;
assign VBlank = vblank;

wire objram_we;
wire [15:0] objram_data, objram_q;
wire [63:0] objram_q64;
wire [10:0] objram_addr;

wire [11:0] ga22_color, ga23_color;
wire ga23_prio;

objram objram(
    .clk(clk_sys),

    .addr(objram_addr),
    .we(objram_we),

    .data(objram_data),

    .q(objram_q),
    .q64(objram_q64)
);

wire bufram_we;
wire [15:0] bufram_data;
wire [15:0] bufram_q00, bufram_q01, bufram_q10, bufram_q11;
wire [10:0] bufram_addr;

wire [1:0] bufram_cs =  ( ~bufram_addr[10] & ~dma_busy ) ? { 1'b0,        vid_ctrl[0] } :
                        (  bufram_addr[10] & ~dma_busy ) ? { vid_ctrl[2], vid_ctrl[1] } :
                        ( ~bufram_addr[10] &  dma_busy ) ? { 1'b0,        vid_ctrl[3] } :
                        (  bufram_addr[10] &  dma_busy ) ? { vid_ctrl[5], vid_ctrl[4] } : 2'b00;

wire [15:0] bufram_q;

wire [12:0] ga21_palram_addr;
wire ga21_palram_we, ga21_palram_cs;
wire [15:0] ga21_palram_dout;
wire [15:0] palram_q;
wire [10:0] ga22_count;



singleport_unreg_ram #(.widthad(13), .width(16), .name("BUFRAM")) bufram(
    .clock(clk_sys),
    .address({bufram_cs, bufram_addr}),
    .q(bufram_q),
    .wren(bufram_we),
    .data(bufram_data)
);

palram palram(
    .clk(clk_sys),

    .ce_pix(ce_pix),

    .vid_ctrl(vid_ctrl),
    .dma_busy(dma_busy),

    .cpu_addr(cpu_mem_addr[10:1]),

    .ga21_addr(ga21_palram_addr),
    .ga21_we(ga21_palram_we),
    .ga21_req(ga21_palram_cs),

    .obj_color(ga22_color[10:0]),
    .obj_prio(ga22_color[11]),
    .obj_active(|ga22_color[3:0]),

    .pf_color(ga23_color),
    .pf_prio(~ga23_prio),

    .din(ga21_palram_dout),
    .dout(palram_q),

    .rgb_out(rgb_color)
);

GA21 ga21(
    .clk(clk_sys),
    .ce(ce_9m),

    .reset(),

    .din(cpu_mem_out),
    .dout(ga21_dout),

    .addr(cpu_mem_addr[11:1]),

    .reg_cs(sprite_control_memrq),
    .buf_cs(buffer_memrq),
    .wr(MWR),

    .busy(dma_busy),

    .obj_dout(objram_data),
    .obj_din(objram_q),
    .obj_addr(objram_addr),
    .obj_we(objram_we),

    .buffer_dout(bufram_data),
    .buffer_din(bufram_q),
    .buffer_addr(bufram_addr),
    .buffer_we(bufram_we),

    .count(ga22_count),

    .pal_addr(ga21_palram_addr),
    .pal_dout(ga21_palram_dout),
    .pal_din(palram_q),
    .pal_we(ga21_palram_we),
    .pal_cs(ga21_palram_cs)
);

GA22 ga22(
    .clk(clk_sys),
    .clk_ram(clk_ram),

    .ce(ce_13m), // 13.33Mhz

    .ce_pix(ce_pix), // 6.66Mhz

    .reset(~reset_n),

    .color(ga22_color),

    .NL(NL),
    .hpulse(hpulse),
    .vpulse(vpulse),

    .count(ga22_count),

    .obj_in(objram_q64),

    .sdr_data(sdr_sprite_dout),
    .sdr_addr(sdr_sprite_addr),
    .sdr_req(sdr_sprite_req),
    .sdr_rdy(sdr_sprite_rdy),
    .sdr_refresh(sdr_sprite_refresh),

    .dbg_solid_sprites(dbg_solid_sprites)
);

wire [14:0] vram_addr;
wire [15:0] vram_data, vram_q;
wire vram_we;

singleport_unreg_ram #(.widthad(15), .width(16), .name("VRAM")) vram
(
    .clock(clk_sys),
    .address(vram_addr),
    .q(vram_q),
    .wren(vram_we),
    .data(vram_data)
);

GA23 ga23(
    .clk(clk_sys),
    .clk_ram(clk_ram),

    .ce(ce_pix),

    .reset(~reset_n),

    .paused(paused),

    .mem_cs(pf_vram_memrq),
    .mem_wr(MWR),
    .mem_rd(MRD),
    .io_wr(IOWR),

    .busy(ga23_busy),

    .addr(cpu_mem_addr),
    .cpu_din(cpu_mem_out),
    .cpu_dout(ga23_dout),

    .vram_addr(vram_addr),
    .vram_din(vram_q),
    .vram_dout(vram_data),
    .vram_we(vram_we),

    .NL(NL),
    .large_tileset(board_cfg.large_tileset),

    .sdr_data(sdr_bg_dout),
    .sdr_addr(sdr_bg_addr),
    .sdr_req(sdr_bg_req),
    .sdr_rdy(sdr_bg_rdy),

    .vblank(vblank),
    .hblank(hblank),
    .vsync(vsync),
    .hsync(hsync),
    .hpulse(hpulse),
    .vpulse(vpulse),

    .hint(hint),

    .color_out(ga23_color),
    .prio_out(ga23_prio),

    .dbg_en_layers(dbg_en_layers)
);


wire [15:0] sound_sample;
sound sound(
    .clk_sys(clk_sys),
    .reset(sound_reset | ~reset_n),

    .paused(paused),

    .sample_attn(sample_attn),

    .latch_wr(IOWR & cpu_word_addr[7:0] == 8'h00),
    .latch_rd(IORD & cpu_word_addr[7:0] == 8'h08),
    .latch_din(cpu_mem_out[7:0]),
    .latch_dout(snd_latch_dout),
    .latch_rdy(snd_latch_rdy),

    .rom_addr(bram_addr),
    .rom_data(bram_data),
    .rom_wr(bram_wr & bram_cs[1]),

    .secure_addr(bram_addr[7:0]),
    .secure_data(bram_data),
    .secure_wr(bram_wr & bram_cs[0]),

    .sample(sound_sample),

    .clk_ram(clk_ram),
    .sdr_addr(sdr_audio_addr),
    .sdr_data(sdr_audio_dout),
    .sdr_req(sdr_audio_req),
    .sdr_rdy(sdr_audio_rdy)
);

assign AUDIO_L = sound_sample;
assign AUDIO_R = sound_sample;

eeprom_28C64 eeprom(
    .clk(clk_sys),
    .reset(~reset_n),
    .ce(1),

    .rd(MRD & eeprom_memrq),
    .wr(MWR & eeprom_memrq),

    .addr(cpu_mem_addr[13:1]),
    .q(eeprom_dout),
    .data(cpu_mem_out[7:0]),

    .ready(),

    .modified(ioctl_upload_req),
    .ioctl_download(ioctl_download && (ioctl_index == 'd1)),
    .ioctl_wr(ioctl_wr),
    .ioctl_addr(ioctl_addr[12:0]),
    .ioctl_dout(ioctl_dout),

    .ioctl_upload(ioctl_upload && (ioctl_index == 'd1)),
    .ioctl_din(ioctl_din),
    .ioctl_rd(ioctl_rd)
);

endmodule
