//`include "defines.v"

//// 128 * 32 bit direct-mapping inst cache

//`define InstCacheBus 127:0//127:0

//module inst_cache(
//    input wire clk,
//    input wire rst,

//    input wire cache_query,
//    input wire [`InstAddrBus] query_addr,
    
//    input wire cache_enable,
//    input wire [`InstAddrBus] inst_addr,
//    input wire [`InstBus] inst_cache_i,

//    output reg inst_hit_o,
//    output reg [`InstBus] inst_cache_o
//);

//    // inst_cache
//    (* ram_style = "registers" *) reg [`InstBus] inst_cache[`InstCacheBus];
//    (* ram_style = "registers" *) reg [8:0] inst_tag[`InstCacheBus];
//    (* ram_style = "registers" *) reg inst_valid[`InstCacheBus];


//    // temp caching info for an inst
//    wire [8:0] inst_caching_tag;
//    wire [6:0] inst_caching_column;

//    assign inst_caching_column = inst_addr[8:2];
//    assign inst_caching_tag = inst_addr[17 : 9];

//    // query info
//    wire [8:0] query_inst_caching_tag;
//    wire [6:0] query_inst_caching_column;
//    wire query_inst_valid;

//    assign query_inst_caching_column = query_addr[8:2];
//    assign query_inst_caching_tag = query_addr[17 : 9];
//    assign query_inst_valid = inst_valid[query_inst_caching_column];
    
////    integer i;
////    initial begin
////        for (i = 0; i < 128; i = i + 1) begin
////                inst_cache[i] = `ZeroWord;
////                inst_tag[i] = 0;
////                inst_valid[i] = 0;
////            end
////    end

//    always @(posedge clk) begin
//        if (rst == 0) begin
//            if (cache_enable) begin
//                inst_cache[inst_caching_column] <= inst_cache_i;
//                inst_tag[inst_caching_column] <= inst_caching_tag;
//                inst_valid[inst_caching_column] <= 1;
////                if (`DEBUG) begin
////                    $display("cache changing, set: ", inst_caching_column, " to: ", inst_cache_i);
////                    $display("cache tag set to : ", inst_caching_tag);
////                end
//            end
//        end
//    end

//    always @(*) begin
//        if (cache_query == 1) begin
//            if (query_inst_valid && inst_tag[query_inst_caching_column] == query_inst_caching_tag) begin
//                inst_hit_o <= 1;
//               //inst_hit_o <= 0;
//                inst_cache_o <= inst_cache[query_inst_caching_column];
////                if (`DEBUG) begin
////                    $display("cache hit: ", query_addr, " at ", query_inst_caching_column, " : ", inst_cache[query_inst_caching_column]);
////                end
//            end else begin
//                inst_hit_o <= 0;
//                inst_cache_o <= `ZeroWord;
//            end
//        end else begin
//            inst_hit_o <= 0;
//            inst_cache_o <= `ZeroWord;
//        end
//    end

//endmodule

`include "defines.v"

// 128 * 32 bit direct-mapping inst cache

`define InstCacheBus 255:0//127:0

module inst_cache(
    input wire clk,
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
    (* ram_style = "registers" *) reg [`InstBus] inst_cache[`InstCacheBus];
    (* ram_style = "registers" *) reg [7:0] inst_tag[`InstCacheBus];
    (* ram_style = "registers" *) reg inst_valid[`InstCacheBus];


    // temp caching info for an inst
    wire [7:0] inst_caching_tag;
    wire [7:0] inst_caching_column;

    assign inst_caching_column = inst_addr[9:2];
    assign inst_caching_tag = inst_addr[17 : 10];

    // query info
    wire [7:0] query_inst_caching_tag;
    wire [7:0] query_inst_caching_column;
    wire query_inst_valid;

    assign query_inst_caching_column = query_addr[9:2];
    assign query_inst_caching_tag = query_addr[17 : 10];
    assign query_inst_valid = inst_valid[query_inst_caching_column];
    
//    integer i;
//    initial begin
//        for (i = 0; i < 128; i = i + 1) begin
//                inst_cache[i] = `ZeroWord;
//                inst_tag[i] = 0;
//                inst_valid[i] = 0;
//            end
//    end

    always @(posedge clk) begin
        if (rst == 0) begin
            if (cache_enable) begin
                inst_cache[inst_caching_column] <= inst_cache_i;
                inst_tag[inst_caching_column] <= inst_caching_tag;
                inst_valid[inst_caching_column] <= 1;
//                if (`DEBUG) begin
//                    $display("cache changing, set: ", inst_caching_column, " to: ", inst_cache_i);
//                    $display("cache tag set to : ", inst_caching_tag);
//                end
            end
        end
    end

    always @(clk) begin
        if (cache_query == 1) begin
            if (query_inst_valid && inst_tag[query_inst_caching_column] == query_inst_caching_tag) begin
                inst_hit_o <= 1;
               //inst_hit_o <= 0;
                inst_cache_o <= inst_cache[query_inst_caching_column];
//                if (`DEBUG) begin
//                    $display("cache hit: ", query_addr, " at ", query_inst_caching_column, " : ", inst_cache[query_inst_caching_column]);
//                end
            end else begin
                inst_hit_o <= 0;
                inst_cache_o <= `ZeroWord;
            end
        end else begin
            inst_hit_o <= 0;
            inst_cache_o <= `ZeroWord;
        end
    end

endmodule
//    end

//endmodule