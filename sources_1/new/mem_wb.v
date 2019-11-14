`include "defines.v"

module mem_wb(
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus] mem_wd,
    input wire mem_wreg,
    input wire[`RegBus] mem_wdata,
    input wire[`AluSelBus] memop_type_i,
    input wire[`RegBus] mem_w_data_i,

    
    output reg[`RegAddrBus] wb_wd,
    output reg wb_wreg,
    output reg[`RegBus] wb_wdata,
    output reg[`AluSelBus] memop_type_o,
    output reg[`RegBus] mem_w_data_o
);
    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
            mem_w_data_o <= `ZeroWord;
            memop_type_o <= 6'b0;
        end else begin
            wb_wd <= mem_wd;
            wb_wreg <= mem_wreg;
            wb_wdata <= mem_wdata;

            mem_w_data_o <= mem_w_data_i;
            memop_type_o <= memop_type_i;
        end
    end
    
endmodule
