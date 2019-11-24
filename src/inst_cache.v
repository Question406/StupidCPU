`include "defines.v"

// 128 * 32 bit direct-mapping inst cache

`define InstCacheBus 127:0

module inst_cache(
    input wire rst,

    input wire cache_query,
    input wire [`InstAddrBus] query_addr,
    
    input wire cache_enable,
    input wire [`InstAddrBus] inst_addr,
    input wire [`InstBus] inst_cache_i,

    output reg inst_hit_o,
    output reg [`InstBus] inst_cache_o
);

    // inst_cache
    reg [`InstBus] inst_cache[`InstCacheBus];
    reg [11:0] inst_tag[`InstCacheBus];
    reg inst_valid[`InstCacheBus];


    // temp caching info for an inst
    wire [11:0] inst_caching_tag;
    wire [6:0] inst_caching_column;

    assign inst_caching_column = inst_addr[6:0];
    assign inst_caching_tag = inst_addr[(12 + 7 - 1):7];

    // query info
    wire [11:0] query_inst_caching_tag;
    wire [6:0] query_inst_caching_column;
    wire query_inst_valid;

    assign query_inst_caching_column = query_addr[6:0];
    assign query_inst_caching_tag = inst_addr[(12 + 7 - 1):7];
    assign query_inst_valid = inst_valid[inst_caching_column];
    
    integer i;

    always @(*) begin
        if (rst == 1) begin
            inst_cache_o <= `ZeroWord;
            for (i = 0; i < 128; i = i + 1) begin
                inst_cache[i] = `ZeroWord;
                inst_tag[i] = 0;
                inst_valid[i] = 0;
            end
        end else begin
            if (cache_enable) begin
                inst_cache[inst_caching_column] <= inst_cache_i;
                inst_tag[inst_caching_column] <= inst_caching_tag;
                inst_valid[inst_caching_column] <= 1;
            end
        end
    end

    always @(cache_query) begin
        if (cache_query == 1) begin
            if (query_inst_valid && inst_tag[query_inst_caching_column] == query_inst_caching_tag) begin
                inst_hit_o <= 1;
                inst_cache_o <= inst_cache[query_inst_caching_column];
            end
        end else begin
            inst_hit_o <= 0;
            inst_cache_o <= `ZeroWord;
        end
    end

endmodule