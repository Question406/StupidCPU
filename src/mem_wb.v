`include "defines.v"

module mem_wb(
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus] mem_wd,
    input wire mem_wreg,
    input wire[`RegBus] mem_wdata,

    input wire[`AluSelBus] memop_type_i,
//    input wire[`RegBus] mem_w_data_i,

    // mem_wb need waiting for mem_ctrl send back data
    input wire need_wait,

    input wire mmem_finished,
    input [`RegBus] mmem_data,

    input wire [5:0] stall,
    
    output reg[`RegAddrBus] wb_wd,
    output reg wb_wreg, // FIXME: could be wire?
    output reg[`RegBus] wb_wdata,

    // FIXME: ????? what are these for ?
    output reg[`AluSelBus] memop_type_o,
    output reg[`RegBus] mem_w_data_o
);

    reg waiting_state;

    always @ (posedge clk) begin
        if (rst == `RstEnable) begin
            waiting_state <= 0;
            wb_wd <= `NOPRegAddr;
            wb_wreg <= `WriteDisable;
            wb_wdata <= `ZeroWord;
            mem_w_data_o <= `ZeroWord;
            memop_type_o <= 6'b0;
        end else if (mmem_finished) begin
            waiting_state <= 0;
            wb_wreg <= 1;
            wb_wdata <= mmem_data;
        end else if (need_wait) begin
            waiting_state <= 1;
            wb_wd <= mem_wd;
            wb_wreg <= 0;
        end else if (waiting_state == 0) begin
            if (stall[4] == `Stop && stall[5] == `NoStop) begin
                wb_wd <= `NOPRegAddr;
                wb_wreg <= `WriteDisable;
                wb_wdata <= `ZeroWord;
                mem_w_data_o <= `ZeroWord;
                memop_type_o <= 6'b0;

                waiting_state <= 0;
            end else if (stall [4] == `NoStop) begin
                wb_wd <= mem_wd;
                wb_wreg <= mem_wreg;
                wb_wdata <= mem_wdata;

                mem_w_data_o <= mem_wdata;
                memop_type_o <= memop_type_i;

                waiting_state <= 0;
            end
        end
    end
    
endmodule
