`include "defines.v"

module dcache(
    input wire rst,
    input wire clk,
    
    input wire dcache_enable,
    input wire [`RegBus] dcache_data_i,
    input wire [`RegBus] dcache_addr,
    
    input wire query_enable,
    input wire [`RegBus] query_addr,
    input wire [`AluSelBus] query_type,
    
    output reg dcache_get,
    output reg [`RegBus] dcache_data_o
); 

`define DataCacheBus 255:0
`define DataTagBus 7:0 

    (* ram_style = "registers" *) reg [`RegBus] data_cache[`DataCacheBus];
    (* ram_style = "registers" *) reg [`DataTagBus] data_tag[`DataCacheBus];
    (* ram_style = "registers" *) reg data_valid[`DataCacheBus];
    
    wire [7:0] data_caching_tag;
    wire [7:0] data_caching_column;

    assign data_caching_column = dcache_addr[9:2];
    assign data_caching_tag = dcache_addr[17 : 10];
    
    wire [7:0] query_tag;
    wire [7:0] query_column;
    wire [1:0] byte_offset;
    wire query_valid;
    
    assign query_tag = query_addr[17:10];
    assign query_column = query_addr[9:2];
    assign byte_offset = query_addr[1:0];
    assign query_valid = data_valid[query_column];
    
    wire [7:0] tag;
    assign tag = data_tag[query_column];
 
 integer i;
 
// initial begin
//    for (i = 0; i < 256; i = i + 1) begin
//        data_cache[i] <= 0;
//        data_tag[i] <= 0;
//        data_valid[i] <= 0;
//    end
// end 
 
    
// caching data
always @(posedge clk) begin
    if (rst == 0) begin
        if (dcache_enable) begin
                //$display("caching ", dcache_addr);
                data_cache[data_caching_column] <= dcache_data_i;
                data_tag[data_caching_column] <= data_caching_tag;
                data_valid[data_caching_column] <= 1;
            end
    end
end

always @(*) begin
    if (rst == `RstEnable) begin
        dcache_get = 0;
        dcache_data_o = 0;
    end
    else if (rst == 0) begin
       // $display("querying ", query_addr);
        if (query_enable && query_tag == tag) begin
            case (query_type)
                `LB : begin
                    dcache_get = 1;
                    case (byte_offset) 
                         2'b00 : begin
                                dcache_data_o = {{24{data_cache[query_column][7]}}, data_cache[query_column][7:0]}; 
                         end
                         2'b01 : begin
                                dcache_data_o = {{24{data_cache[query_column][15]}}, data_cache[query_column][15:8]};
                         end
                         2'b10 : begin
                                dcache_data_o = {{24{data_cache[query_column][23]}}, data_cache[query_column][23:16]};
                         end
                         2'b11 : begin
                                dcache_data_o = {{24{data_cache[query_column][31]}}, data_cache[query_column][31:24]};
                         end
                    endcase
                end
                `LBU : begin
                    dcache_get = 1;
                    case (byte_offset) 
                         2'b00 : begin
                                dcache_data_o = {24'b0, data_cache[query_column][7:0]};                                
                         end
                         2'b01 : begin
                                dcache_data_o = {24'b0, data_cache[query_column][15:8]};
                         end
                         2'b10 : begin
                                dcache_data_o = {24'b0, data_cache[query_column][23:16]};
                         end
                         2'b11 : begin
                                dcache_data_o = {24'b0, data_cache[query_column][31:24]};
                         end
                    endcase
                end
                `LH : begin
                    dcache_get = 1;
                    case (byte_offset) 
                         2'b00 : begin
                                dcache_data_o = {{16{data_cache[query_column][15]}}, data_cache[query_column][15:0]};                                
                         end
                         2'b10 : begin
                                dcache_data_o = {{16{data_cache[query_column][31]}}, data_cache[query_column][31:16]};
                         end
                    endcase
                end
                `LHU : begin
                    dcache_get = 1;
                    case (byte_offset) 
                         2'b00 : begin
                                dcache_data_o = {16'b0, data_cache[query_column][15:0]};                                
                         end
                         2'b10 : begin
                                dcache_data_o = {16'b0, data_cache[query_column][31:16]};
                         end
                    endcase
                end
                `LW : begin
                    dcache_get = 1;
                    dcache_data_o = data_cache[query_column];
                end
                default: begin
                    dcache_get = 0;
                    dcache_data_o = 0;
                end 
            endcase        
        end else begin
            dcache_get = 0;
            dcache_data_o = 0;
        end
    end
end

endmodule