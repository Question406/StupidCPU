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
    
    input wire load_done,
        
    output reg[`RegBus] ex_pc,
    output reg[`AluOpBus] ex_aluop,
    output reg[`AluSelBus] ex_alusel,
    output reg[`RegBus] ex_reg1, 
    output reg[`RegBus] ex_reg2,
    output reg[`RegBus] imm_o,
    output reg[`RegAddrBus] ex_wd,
    output reg ex_wreg,

    output wire id_stall_req
);

    reg last_load;
    assign id_stall_req = (last_load) ? 1 : 0;
    //assign id_stall_req = 0;

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
            last_load <= 0;
         //end
        end else if (load_done == 1) begin
            last_load <= 0;
//            ex_pc <= id_pc;
//            ex_aluop <= id_aluop;
//            ex_alusel <= id_alusel;
//            imm_o <= imm_i;
//            ex_reg1 <= id_reg1;
//            ex_reg2 <= id_reg2;
//            ex_wd <= id_wd;
//            ex_wreg <= id_wreg;
        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin
            ex_pc <= `ZeroWord;
            ex_aluop <= `Inst_NOP;
            ex_alusel <= `NOP;
            ex_reg1 <= `ZeroWord;
            ex_reg2 <= `ZeroWord;
            imm_o <= `ZeroWord;
            ex_wd <= `NOPRegAddr;
            ex_wreg <= `WriteDisable;
        end 
        else if (stall[1] == `NoStop) begin
            ex_pc <= id_pc;
            ex_aluop <= id_aluop;
            ex_alusel <= id_alusel;
            imm_o <= imm_i;
            ex_reg1 <= id_reg1;
            ex_reg2 <= id_reg2;
            ex_wd <= id_wd;
            ex_wreg <= id_wreg;
//            if (id_aluop ==  `LB || id_aluop == `LH ||id_aluop == `LW || 
//                    id_aluop == `LHU || id_aluop == `LBU) begin
            if (id_aluop ==  `Inst_Load || id_aluop == `Inst_Save) begin
                last_load <= 1;
            end
        end
    end
endmodule
