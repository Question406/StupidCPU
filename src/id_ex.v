`include "defines.v"

module id_ex(
    input wire clk,
    input wire rst,
    input wire[`RegBus] id_pc,
    input wire[`AluOpBus] id_aluop,
    input wire[`AluSelBus] id_alusel,
    input wire[`RegBus] id_reg1,
    input wire[`RegBus] id_reg2,
    input wire[`RegBus] imm_i,
    input wire[`RegAddrBus] id_wd,
    input wire id_wreg,
    
    input wire id_exflush_i,
    input wire [5:0] stall,
    
    output reg[`RegBus] ex_pc,
    output reg[`AluOpBus] ex_aluop,
    output reg[`AluSelBus] ex_alusel,
    output reg[`RegBus] ex_reg1, 
    output reg[`RegBus] ex_reg2,
    output reg[`RegBus] imm_o,
    output reg[`RegAddrBus] ex_wd,
    output reg ex_wreg
);

    always @ (posedge clk) begin
        if (rst == `RstEnable || id_exflush_i) begin
            ex_pc <= `ZeroWord;
            ex_aluop <= `Inst_NOP;
            ex_alusel <= `NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            imm_o <= `ZeroWord;
            ex_wd <= `NOPRegAddr;
            ex_wreg <= `WriteDisable;       
        end else if (stall[2] == `Stop && stall[3] == `NoStop) begin
            // ex_pc <= `ZeroWord;
            // ex_aluop <= `Inst_NOP;
            // ex_alusel <= `NOP;
            // ex_reg1 <= `ZeroWord;
            // ex_reg2 <= `ZeroWord;
            // imm_o <= `ZeroWord;
            // ex_wd <= `NOPRegAddr;
            // ex_wreg <= `WriteDisable;       
        end 
        else begin
            ex_pc <= id_pc;
            ex_aluop <= id_aluop;
            ex_alusel <= id_alusel;
            imm_o <= imm_i;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_wd <= id_wd;
            ex_wreg <= id_wreg;
        end
    end
endmodule
