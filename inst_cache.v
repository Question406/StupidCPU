// ////256 DM cache

//`include "defines.v"

//// 128 * 32 bit direct-mapping inst cache

//`define InstCacheBus 255:0//127:0

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
////    (* ram_style = "registers" *) reg [`InstBus] inst_cache1[`InstCacheBus];
////    (* ram_style = "registers" *) reg [6:0] inst_tag1[`InstCacheBus];
////    (* ram_style = "registers" *) reg inst_valid1[`InstCacheBus];
    
//    (* ram_style = "registers" *) reg [`InstBus] inst_cache[`InstCacheBus];
//    (* ram_style = "registers" *) reg [7:0] inst_tag[`InstCacheBus];
//    (* ram_style = "registers" *) reg inst_valid[`InstCacheBus];
    
    
////    (* ram_style = "registers" *) reg [`InstBus] inst_cache2[`InstCacheBus];
////    (* ram_style = "registers" *) reg [6:0] inst_tag2[`InstCacheBus];
////    (* ram_style = "registers" *) reg inst_valid2[`InstCacheBus];


//    // temp caching info for an inst
//    wire [7:0] inst_caching_tag;
//    wire [7:0] inst_caching_column;

//    assign inst_caching_column = inst_addr[9:2];
//    assign inst_caching_tag = inst_addr[17 : 10];

//    // query info
//    wire [7:0] query_inst_caching_tag;
//    wire [7:0] query_inst_caching_column;
//    wire query_inst_valid;

//    assign query_inst_caching_column = query_addr[9:2];
//    assign query_inst_caching_tag = query_addr[17 : 10];
//    assign query_inst_valid = inst_valid[query_inst_caching_column];
    

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

//    always @(clk) begin
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

// 128 * 32 bit 2-way set associative inst cache

`define InstCacheBus 127:0

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
//    (* ram_style = "registers" *) reg [`InstBus] inst_cache1[`InstCacheBus];
//    (* ram_style = "registers" *) reg [6:0] inst_tag1[`InstCacheBus];
//    (* ram_style = "registers" *) reg inst_valid1[`InstCacheBus];
    
    (* ram_style = "registers" *) reg [`InstBus] inst_cache1[`InstCacheBus];
    (* ram_style = "registers" *) reg [6:0] inst_tag1[`InstCacheBus];
    (* ram_style = "registers" *) reg inst_valid1[`InstCacheBus];
    
    (* ram_style = "registers" *) reg [`InstBus] inst_cache2[`InstCacheBus];
    (* ram_style = "registers" *) reg [6:0] inst_tag2[`InstCacheBus];
    (* ram_style = "registers" *) reg inst_valid2[`InstCacheBus];
    
    // for FIFO 2-way associative
    (* ram_style = "registers" *) reg changing_pos[`InstCacheBus];

    // temp caching info for an inst
    wire [6:0] inst_caching_tag;
    wire [6:0] inst_caching_column;

    assign inst_caching_column = inst_addr[8:2];
    assign inst_caching_tag = inst_addr[17 : 9];

    // query info
    wire [6:0] query_inst_caching_tag;
    wire [6:0] query_inst_caching_column;
    wire query_inst_valid1;
    wire query_inst_valid2;
    wire [6:0] query_tag1;
    wire [6:0] query_tag2;

    assign query_inst_caching_column = query_addr[8:2];
    assign query_inst_caching_tag = query_addr[17 : 9];
    assign query_inst_valid1 = inst_valid1[query_inst_caching_column];
    assign query_inst_valid2 = inst_valid2[query_inst_caching_column];
    assign query_tag1 = inst_tag1[query_inst_caching_column];
    assign query_tag2 = inst_tag2[query_inst_caching_column];
    

    integer i;
    always @(posedge clk) begin
        if (rst == `RstDisable) begin
            if (cache_enable) begin
                if (!changing_pos[inst_caching_column]) begin
                    inst_cache1[inst_caching_column] <= inst_cache_i;
                    inst_tag1[inst_caching_column] <= inst_caching_tag;
                    inst_valid1[inst_caching_column] <= 1;
                    changing_pos[inst_caching_column] <= 1;
                end else if (changing_pos[inst_caching_column]) begin
                    inst_cache2[inst_caching_column] <= inst_cache_i;
                    inst_tag2[inst_caching_column] <= inst_caching_tag;
                    inst_valid2[inst_caching_column] <= 1;
                    changing_pos[inst_caching_column] <= 0; 
                end else begin
                    inst_cache1[inst_caching_column] <= inst_cache_i;
                    inst_tag1[inst_caching_column] <= inst_caching_tag;
                    inst_valid1[inst_caching_column] <= 1;
                    
                    changing_pos[inst_caching_column] <= 1;
                end
            end
        end
    end

    always @(clk) begin
        if (cache_query == 1) begin
            if (query_inst_valid1 && query_tag1 == query_inst_caching_tag) begin
                inst_hit_o <= 1;
                inst_cache_o <= inst_cache1[query_inst_caching_column];
            end else if (query_inst_valid2 && query_tag2 == query_inst_caching_tag) begin
                inst_hit_o <= 1;
                inst_cache_o <= inst_cache2[query_inst_caching_column];
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


//`define InstCacheBus 255:0

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
////    (* ram_style = "registers" *) reg [`InstBus] inst_cache1[`InstCacheBus];
////    (* ram_style = "registers" *) reg [6:0] inst_tag1[`InstCacheBus];
////    (* ram_style = "registers" *) reg inst_valid1[`InstCacheBus];
    
//    (* ram_style = "registers" *) reg [`InstBus] inst_cache1[`InstCacheBus];
//    (* ram_style = "registers" *) reg [7:0] inst_tag1[`InstCacheBus];
//    (* ram_style = "registers" *) reg inst_valid1[`InstCacheBus];
    
//    (* ram_style = "registers" *) reg [`InstBus] inst_cache2[`InstCacheBus];
//    (* ram_style = "registers" *) reg [7:0] inst_tag2[`InstCacheBus];
//    (* ram_style = "registers" *) reg inst_valid2[`InstCacheBus];
//        // for FIFO 2-way associative
//    (* ram_style = "registers" *) reg changing_pos[`InstCacheBus];
    
////    (* ram_style = "registers" *) reg [`InstBus] inst_cache2[`InstCacheBus];
////    (* ram_style = "registers" *) reg [6:0] inst_tag2[`InstCacheBus];
////    (* ram_style = "registers" *) reg inst_valid2[`InstCacheBus];


//    // temp caching info for an inst
//    wire [7:0] inst_caching_tag;
//    wire [7:0] inst_caching_column;

//    assign inst_caching_column = inst_addr[9:2];
//    assign inst_caching_tag = inst_addr[17 : 10];

//    // query info
//    wire [7:0] query_inst_caching_tag;
//    wire [7:0] query_inst_caching_column;
//    wire query_inst_valid1;
//    wire query_inst_valid2;
//    wire [7:0] query_tag1;
//    wire [7:0] query_tag2;

//    assign query_inst_caching_column = query_addr[9:2];
//    assign query_inst_caching_tag = query_addr[17 : 10];
//    assign query_inst_valid1 = inst_valid1[query_inst_caching_column];
//    assign query_inst_valid2 = inst_valid2[query_inst_caching_column];
//    assign query_tag1 = inst_tag1[query_inst_caching_column];
//    assign query_tag2 = inst_tag2[query_inst_caching_column];
    

//    integer i;
//    always @(posedge clk) begin
//        if (rst == `RstEnable) begin
//            for (i = 0; i < 256; i = i + 1) begin
//                inst_valid1[i] <= 0;
//                inst_valid2[i] <= 0;
//            end
//        end else begin
//            if (cache_enable) begin
//                 if (!changing_pos[inst_caching_column]) begin
//                    inst_cache1[inst_caching_column] <= inst_cache_i;
//                    inst_tag1[inst_caching_column] <= inst_caching_tag;
//                    inst_valid1[inst_caching_column] <= 1;
//                    changing_pos[inst_caching_column] <= 1;
//                end else if (changing_pos[inst_caching_column]) begin
//                    inst_cache2[inst_caching_column] <= inst_cache_i;
//                    inst_tag2[inst_caching_column] <= inst_caching_tag;
//                    inst_valid2[inst_caching_column] <= 1;
//                    changing_pos[inst_caching_column] <= 0; 
//                end else begin
//                    inst_cache1[inst_caching_column] <= inst_cache_i;
//                    inst_tag1[inst_caching_column] <= inst_caching_tag;
//                    inst_valid1[inst_caching_column] <= 1;
                    
//                    changing_pos[inst_caching_column] <= 1;
//                end
//            end
//        end
//    end

//    always @(clk) begin
//        if (cache_query == 1) begin
//            if (query_inst_valid1 && query_tag1 == query_inst_caching_tag) begin
//                inst_hit_o <= 1;
//                inst_cache_o <= inst_cache1[query_inst_caching_column];
//            end else if (query_inst_valid2 && query_tag2 == query_inst_caching_tag) begin
//                inst_hit_o <= 1;
//                inst_cache_o <= inst_cache2[query_inst_caching_column];
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