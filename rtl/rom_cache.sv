import m92_pkg::*;

module rom_cache(
    input clk,
    input ce_1,
    input ce_2,
    input reset,

    input clk_ram,
    
    output reg [24:0]   sdr_addr,
    input [63:0]        sdr_data,
    output reg          sdr_req,
    input               sdr_rdy,

    input               n_bcyst,
    input               read,
    input [18:0]        rom_word_addr,
    output [15:0]       rom_data,
    output reg          rom_ready
);

localparam CACHE_WIDTH = 8;

wire [18-CACHE_WIDTH:0] tag = { version, rom_word_addr[18:CACHE_WIDTH+2] };
wire [CACHE_WIDTH-1:0] index = rom_word_addr[CACHE_WIDTH+1:2];

reg [1:0] version;
reg [63:0] cache_data[2**CACHE_WIDTH];
reg [18-CACHE_WIDTH:0] cache_tag[2**CACHE_WIDTH];

reg [63:0] cache_line;
reg [18-CACHE_WIDTH:0] cached_tag;

always_comb begin
    case(rom_word_addr[1:0])
    2'b00: rom_data = cache_line[15:0];
    2'b01: rom_data = cache_line[31:16];
    2'b10: rom_data = cache_line[47:32];
    2'b11: rom_data = cache_line[63:48];
    endcase
end

enum { IDLE, CACHE_CHECK, SDR_WAIT } state = IDLE;
reg read_req, read_ack;
reg prev_reset;
always_ff @(posedge clk) begin
    
    cache_line <= cache_data[index];
    cached_tag <= cache_tag[index];
    
    prev_reset <= reset;
    
    if (reset) begin
        rom_ready <= 1;
        state <= IDLE;
        if (~prev_reset) version <= version + 2'd1;
    end else if (ce_1 | ce_2) begin
        if (ce_1 & ~n_bcyst & read) begin
            state <= CACHE_CHECK;
        end else if (ce_2 && state == CACHE_CHECK) begin
            if (cached_tag == tag) begin
                state <= IDLE;
                rom_ready <= 1;
            end else begin
                sdr_addr <= { REGION_CPU_ROM.base_addr[24:20], rom_word_addr[18:2], 3'b000 };
                read_req <= ~read_req;
                rom_ready <= 0;
                state <= SDR_WAIT;
            end
        end else if (ce_2 && state == SDR_WAIT) begin
            if (read_req == read_ack) begin
                cache_tag[index] <= tag;
                rom_ready <= 1;
                state <= IDLE;
            end
        end
    end
end


reg read_req_prev;
always_ff @(posedge clk_ram) begin
    sdr_req <= 0;
    read_req_prev <= read_req;

    if (sdr_rdy) begin
        cache_data[index] <= sdr_data;
        read_ack <= read_req;
    end

    if (read_req != read_req_prev) begin
        sdr_req <= 1;
    end        
end



endmodule