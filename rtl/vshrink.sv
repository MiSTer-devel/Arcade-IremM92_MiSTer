
module vshrink_linebuffer(
    input clk,

    input wr,

    input [8:0] hcnt,
    input [23:0] color_in,
    output [23:0] color_out
);

(* ramstyle = "no_rw_check" *) reg [23:0] buffer[384];

assign color_out = buffer[hcnt];

always_ff @(posedge clk) begin
    if (wr) begin
        buffer[hcnt] <= color_in;
    end 
end

endmodule

module vshrink(
    input clk,
    input ce_pix,

    input enable,
    input debug,

    input hs_in,
    input vs_in,
    input hb_in,
    input vb_in,
    input [7:0] r_in,
    input [7:0] g_in,
    input [7:0] b_in,

    output hs_out,
    output vs_out,
    output hb_out,
    output vb_out,
    output [7:0] r_out,
    output [7:0] g_out,
    output [7:0] b_out
);

reg [8:0] hcnt, vcnt;
reg prev_hb, prev_vb;

reg [8:0] src_a, src_b;
reg [7:0] r_a, g_a, b_a;
reg [7:0] r_b, g_b, b_b;
reg hs_out1, hb_out1, vs_out1, vb_out1;

reg [2:0] adv[240] = '{
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2,
    1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 1,
    2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2,

    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,

    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,

    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,

    1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 2, 1,
    1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1, 1, 1, 2, 1, 1,
    1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1, 1, 1, 2, 1
};

wire [23:0] color_out[16];

generate
	genvar i;
    for(i = 0; i < 16; i = i + 1 ) begin : generate_buffer
        vshrink_linebuffer linebuffer(
            .clk(clk),
            .wr(ce_pix && ~hb_in && ~vb_in && vcnt[3:0] == i),
            .hcnt(hcnt),
            .color_in({r_in, g_in, b_in}),
            .color_out(color_out[i])
        );
    end
endgenerate


always_ff @(posedge clk) begin
    if (ce_pix) begin
        bit [8:0] t9;

        hs_out1 <= hs_in;
        vs_out1 <= vs_in;
        hb_out1 <= hb_in;
        vb_out1 <= vb_in;

        prev_hb <= hb_in;
        prev_vb <= vb_in;

        r_a <= r_in;
        g_a <= g_in;
        b_a <= b_in;

        r_b <= r_in;
        g_b <= g_in;
        b_b <= b_in;

        if (enable) begin
            if (hb_in & ~prev_hb) begin
                hcnt <= 9'd0;
                vcnt <= vcnt + 9'd1;
                src_a <= src_a + adv[vcnt];
                src_b <= src_a + adv[vcnt];
                if (adv[vcnt] == 3'd2) src_b <= src_a + 3'd1;
            end
            
            if (vb_in) begin
                vcnt <= 9'd0;
                src_a <= 9'd511;
				src_b <= 9'd511;
            end

            if (~hb_in & ~vb_in) begin
                hcnt <= hcnt + 9'd1;

                if (src_a > 9'd239) begin
                    { r_a, g_a, b_a } <= 24'd0;
                end else if (vcnt != src_a) begin
                    { r_a, g_a, b_a } <= color_out[src_a[3:0]];
                end

                if (src_b > 9'd239) begin
                    { r_b, g_b, b_b } <= 24'd0;
                end else if (vcnt != src_b) begin
                    { r_b, g_b, b_b } <= color_out[src_b[3:0]];
                end

                if (debug) begin
                    bit [3:0] diff;

                    diff = vcnt - src_a;

                    { r_a, g_a, b_a } <= { diff, diff, diff, diff, diff, diff };
                    { r_b, g_b, b_b } <= { diff, diff, diff, diff, diff, diff };
                end

            end
        end

        t9 = { 1'd0, r_a } + { 1'd0, r_b };
        r_out <= t9[8:1];
        t9 = { 1'd0, g_a } + { 1'd0, g_b };
        g_out <= t9[8:1];
        t9 = { 1'd0, b_a } + { 1'd0, b_b };
        b_out <= t9[8:1];

        hs_out <= hs_out1;
        vs_out <= vs_out1;
        hb_out <= hb_out1;
        vb_out <= vb_out1;
    end
end


endmodule