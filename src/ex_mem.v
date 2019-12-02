`include "defines.v"

module ex_mem(
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus] ex_wd,
    input wire ex_wreg,
    input wire[`RegBus] ex_wdata,
    input wire[`RegBus] mmem_data_i,
    input wire[`AluSelBus] mem_op_type_i,

    input wire [5:0] stall,
    
    output reg[`RegAddrBus] mem_wd,
    output reg mem_wreg,
    output reg[`RegBus] mem_wdata,
    output reg[`RegBus] mmem_data_o,
    output reg[`AluSelBus] mem_op_type_o
);

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mmem_data_o <= `ZeroWord;
            mem_op_type_o <= `NOP;
        end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
            mem_wd <= `NOPRegAddr;
            mem_wreg <= `WriteDisable;
            mem_wdata <= `ZeroWord;
            mmem_data_o <= `ZeroWord;
            mem_op_type_o <= `NOP;
        end else if (stall[2] == `NoStop) begin
            mem_wd <= ex_wd;
            mem_wreg <= ex_wreg;
            mem_wdata <= ex_wdata;
            mmem_data_o <= mmem_data_i;
            mem_op_type_o <= mem_op_type_i;
        end
    end
    
endmodule    