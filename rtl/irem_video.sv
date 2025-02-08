module irem_video(
    input CLK_VIDEO,

    // Configuration inputs
    input             enable_vshrink,
    input       [4:0] hoffset,
    input       [4:0] voffset,
    input             forced_scandoubler,
    input       [2:0] scandoubler_fx,
    input       [1:0] ar,
    input       [1:0] scale,
    input             rotate,
    input             rotate_ccw,
    input             flip,
    output            video_rotated,

    // Core video signal
    input             core_ce_pix,
    input             core_hs,
    input             core_vs,
    input             core_hb,
    input             core_vb,
    input       [7:0] core_r,
    input       [7:0] core_g,
    input       [7:0] core_b,

    // Scaler info in/out
    input      [11:0] HDMI_WIDTH,
    input      [11:0] HDMI_HEIGHT,
    output     [12:0] VIDEO_ARX,
    output     [12:0] VIDEO_ARY,

    // Gamma
    inout      [21:0] gamma_bus,

    // Framebuffer signals for rotation
    output            FB_EN,
    output      [4:0] FB_FORMAT,
    output reg [11:0] FB_WIDTH,
    output reg [11:0] FB_HEIGHT,
    output     [31:0] FB_BASE,
    output     [13:0] FB_STRIDE,
    input             FB_VBL,
    input             FB_LL,

    // DDR for rotation
    input             DDRAM_BUSY,
    output      [7:0] DDRAM_BURSTCNT,
    output     [28:0] DDRAM_ADDR,
    output     [63:0] DDRAM_DIN,
    output      [7:0] DDRAM_BE,
    output            DDRAM_WE,
    output            DDRAM_RD,

    // Final output
    output            CE_PIXEL,
    output      [7:0] VGA_R,
    output      [7:0] VGA_G,
    output      [7:0] VGA_B,
    output            VGA_HS,
    output            VGA_VS,
    output            VGA_DE,
    output      [1:0] VGA_SL
);

wire [7:0] shrink_r, shrink_g, shrink_b;
wire shrink_hb, shrink_vb, shrink_hs, shrink_vs;
wire resync_hs, resync_vs;

vshrink vshrink(
    .clk(CLK_VIDEO),
    .ce_pix(core_ce_pix),

    .enable(enable_vshrink),
    .debug(0),

    .hs_in(core_hs),
    .vs_in(core_vs),
    .hb_in(core_hb),
    .vb_in(core_vb),
    .r_in(core_r),
    .g_in(core_g),
    .b_in(core_b),

    .hs_out(shrink_hs),
    .vs_out(shrink_vs),
    .hb_out(shrink_hb),
    .vb_out(shrink_vb),
    .r_out(shrink_r),
    .g_out(shrink_g),
    .b_out(shrink_b)
);

// H/V offset
jtframe_resync #(5) jtframe_resync
(
    .clk(CLK_VIDEO),
    .pxl_cen(core_ce_pix),
    .hs_in(shrink_hs),
    .vs_in(shrink_vs),
    .LVBL(~shrink_vb),
    .LHBL(~shrink_hb),
    .hoffset(-hoffset), // flip the sign
    .voffset(-voffset),
    .hs_out(resync_hs),
    .vs_out(resync_vs)
);

wire VGA_DE_MIXER;
wire [2:0] sl = scandoubler_fx ? scandoubler_fx - 1'd1 : 3'd0;
wire use_scandoubler = scandoubler_fx || forced_scandoubler;

assign VGA_SL  = sl[1:0];

video_mixer #(.LINE_LENGTH(324), .HALF_DEPTH(0), .GAMMA(1)) video_mixer
(
    .CLK_VIDEO(CLK_VIDEO),
    .ce_pix(core_ce_pix),
    .CE_PIXEL(CE_PIXEL),

    .scandoubler(use_scandoubler),
    .hq2x(scandoubler_fx == 1),
    .gamma_bus(gamma_bus),

    .HBlank(shrink_hb),
    .VBlank(shrink_vb),
    .HSync(resync_hs),
    .VSync(resync_vs),

    .R(shrink_r),
    .G(shrink_g),
    .B(shrink_b),

    .VGA_R(VGA_R),
    .VGA_G(VGA_G),
    .VGA_B(VGA_B),
    .VGA_VS(VGA_VS),
    .VGA_HS(VGA_HS),
    .VGA_DE(VGA_DE_MIXER)
);

video_freak video_freak(
    .CLK_VIDEO(CLK_VIDEO),
    .CE_PIXEL(CE_PIXEL),
    .VGA_VS(VGA_VS),
    .HDMI_WIDTH(HDMI_WIDTH),
    .HDMI_HEIGHT(HDMI_HEIGHT),
    .VGA_DE(VGA_DE),
    .VIDEO_ARX(VIDEO_ARX),
    .VIDEO_ARY(VIDEO_ARY),

    .VGA_DE_IN(VGA_DE_MIXER),
    .ARX((!ar) ? ( rotate ? 12'd3 : 12'd4 ) : (ar - 1'd1)),
    .ARY((!ar) ? ( rotate ? 12'd4 : 12'd3 ) : 12'd0),
    .CROP_SIZE(0),
    .CROP_OFF(0),
    .SCALE(scale)
);


screen_rotate screen_rotate(
    .CLK_VIDEO,
    .CE_PIXEL,

    .VGA_R, .VGA_G, .VGA_B,
    .VGA_HS, .VGA_VS, .VGA_DE,

    .rotate_ccw, // MJD_TODO
    .no_rotate(~rotate),
    .flip(flip),
    .video_rotated,

    .FB_EN,
    .FB_FORMAT, .FB_WIDTH, .FB_HEIGHT,
    .FB_BASE, .FB_STRIDE,
    .FB_VBL, .FB_LL,


    .DDRAM_CLK(), // it's clk_sys and clk_video
    .DDRAM_BUSY,
    .DDRAM_BURSTCNT,
    .DDRAM_ADDR,
    .DDRAM_DIN,
    .DDRAM_BE,
    .DDRAM_WE,
    .DDRAM_RD
);


endmodule
