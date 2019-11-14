/*`include "defines.v"

module id(
    input wire rst,
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,
    
    input wire[`RegBus] reg1_data_i,
    input wire[`RegBus] reg2_data_i,
    
    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`RegAddrBus] reg1_addr_o,
    output reg[`RegAddrBus] reg2_addr_o,
    
    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] imm_o,
    output reg[`RegBus] reg1_o,
    output reg[`RegBus] reg2_o,
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o
);
    
    wire[5:0] op = inst_i[31:26];
    wire[4:0] op2 = inst_i[10:6];
    wire[5:0] op3 = inst_i[5:0];
    wire[4:0] op4 = inst_i[20:16];
    
    reg[`RegBus] imm;
    reg instvalid;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm <= 32'h0;
        end else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= inst_i[15:11];
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= inst_i[25:21];
            reg2_addr_o <= inst_i[20:16];
            imm <= `ZeroWord;
            
            case (op)
                `EXE_ORI : begin
                    wreg_o <= `WriteEnable;
                    aluop_o <= `EXE_OR_OP;
                    alusel_o <= `EXE_RES_LOGIC;
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b0;
                    imm <= {16'h0, inst_i[15:0]};
                    wd_o <= inst_i[20:16];
                    instvalid <= `InstValid;
                end
                default: begin
                end
           endcase
        end          
    end 
    
    always @(*) begin 
        if (rst == `RstEnable) begin 
            reg1_o <= `ZeroWord;
        end else if (reg1_read_o==1'b1) begin 
            reg1_o<= reg1_data_i;
        end else if (reg1_read_o == 1'b0) begin
            reg1_o <= imm;
        end else begin
            reg1_o <= `ZeroWord;
          end
    end
        
    always @(*) begin
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else if (reg2_read_o == 1'b0) begin
            reg2_o <= imm;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end
    
    
endmodule
*/

`include "defines.v"

module id(
    input wire rst,
    input wire[`InstAddrBus] pc_i,
    input wire[`InstBus] inst_i,

    // data forwarding from ex
    input wire ex_wreg_i,
    input wire [`RegBus] ex_wdata_i,
    input wire [`RegAddrBus] ex_wd_i,
    
    // data forwarding from mem
    input wire mem_wreg_i,
    input wire[`RegBus] mem_wdata_i,
    input wire[`RegAddrBus] mem_wd_i,

    // reg data from regfile
    input wire[`RegBus] reg1_data_i,
    input wire[`RegBus] reg2_data_i,
    
    // to reg
    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`RegAddrBus] reg1_addr_o,
    output reg[`RegAddrBus] reg2_addr_o,
    
    // to ex
    output reg[`AluOpBus] aluop_o,
    output reg[`AluSelBus] alusel_o,
    output reg[`RegBus] imm_o,
    output reg[`RegBus] reg1_o,
    output reg[`RegBus] reg2_o,
    output reg wreg_o,
    output reg[`RegAddrBus] wd_o
);
    
    wire[6:0] op_code = inst_i[6:0];
    wire[4:0] op2 = inst_i[11:7];
    wire[3:0] funct3 = inst_i[14:12];
    wire[4:0] rd = inst_i[11:7];
    wire[4:0] rs1 = inst_i[19:15];
    wire[4:0] rs2 = inst_i[24:20];
    wire[7:0] funct7 = inst_i[31:25];
    wire[`RegBus] imm_I = {{21{inst_i[31]}}, inst_i[30:20]};
    wire[`RegBus] imm_S = {{21{inst_i[31]}},inst_i[30:25],inst_i[11:7]};
    wire[`RegBus] imm_B = {{20{inst_i[31]}},inst_i[7],inst_i[30:25],inst_i[11:8],1'b0};
    wire[`RegBus] imm_U = {inst_i[31:12], {12'b0}};
    wire[`RegBus] imm_J = {{12{inst_i[31]}}, inst_i[19:12], inst_i[20], inst_i[30:21], 1'b0};
    
    reg instvalid;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            instvalid <= `InstValid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm_o = `ZeroWord;
        end else begin
            aluop_o <= `EXE_NOP_OP;
            alusel_o <= `EXE_RES_NOP;
            wreg_o <= `WriteDisable;
            instvalid <= `InstInvalid;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= rs1;//inst_i[19:15]; //rs1 
            reg2_addr_o <= rs2;//inst_i[24:20]; //rs2
            reg1_o <= 32'b0;
            reg2_o <= 32'b0;
            imm_o = `ZeroWord;
            aluop_o <= 3'b0;
            alusel_o <= 5'b0;
            case (op_code)
                `InstClass_LUI : begin
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;//inst_i[];// rd
                    imm_o <= imm_U;
                    aluop_o <= `Inst_LUI;
                end
                `InstClass_AUIPC : begin
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_U;
                    aluop_o <= `Inst_AUIPC;
                end
                `InstClass_JAL : begin
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_U;        
                    aluop_o <= `Inst_JAL;            
                end
                `InstClass_JALR : begin
                    reg1_read_o <= 1'b1;
                    reg1_addr_o <= rs1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_I;
                    aluop_o <= `Inst_JALR;
                end
                `InstClass_Branch : begin
                    aluop_o <= `Inst_Branch;
                    imm_o <= imm_B;
                    case (funct3)
                        3'b000 : alusel_o = `BEQ;
                        3'b001 : alusel_o = `BNE;
                        3'b100 : alusel_o = `BLT;
                        3'b101 : alusel_o = `BGE;
                        3'b110 : alusel_o = `BLTU;
                        3'b111 : alusel_o = `BGEU;
                    endcase
                end
                `InstClass_Load : begin
                    reg1_read_o <= 1'b1;
                    reg1_addr_o <= rs1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_I;
                    aluop_o <= `Inst_Load;
                    
                    case (funct3)
                        3'b000 : alusel_o = `LB;
                        3'b001 : alusel_o = `LH;
                        3'b010 : alusel_o = `LW;
                        (3'b100) : alusel_o = `LBU;
                        3'b101 : alusel_o = `LHU;    
                    endcase
                end
                `InstClass_Save : begin
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    imm_o <= imm_S;
                    aluop_o <= `Inst_Save;
                    case (funct3)
                        3'b000 : alusel_o = `SB;
                        3'b001 : alusel_o = `SH;
                        3'b010 : alusel_o = `SW;
                    endcase
                end
                `InstClass_LogicOP : begin
                    reg1_read_o <= 1'b1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_I;
                    aluop_o <= `Inst_LogicOP;
                    case (funct3)
                        3'b000 : alusel_o = `ADDI;
                        3'b010 : alusel_o = `SLTI;
                        3'b011 : alusel_o = `SLTIU;
                        3'b100 : alusel_o = `XORI;
                        3'b110 : alusel_o = `ORI;
                        3'b111 : alusel_o = `ANDI;
                        3'b001 : alusel_o = `SLLI;
                        3'b101 : alusel_o = `SRLI;
                        3'b101 : alusel_o = `SRAI;
                    endcase
                end
                `InstClass_ALUOp : begin
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    aluop_o <= `InstClass_ALUOp;
                    case (funct3)
                        3'b000 : alusel_o = (funct7 == 7'b0000000) ? `ADD : `SUB;
                        3'b001 : alusel_o = `SLL;
                        3'b010 : alusel_o = `SLT;
                        3'b011 : alusel_o = `SLTU;
                        3'b100 : alusel_o = `XOR;
                        3'b101 : alusel_o = (funct7 == 7'b0000000) ? `SRL : `SRA;
                        3'b110 : alusel_o = `OR;
                        3'b111 : alusel_o = `AND;
                    endcase
                end
                default: begin  
                    aluop_o <= `EXE_NOP_OP;
                    alusel_o <= `EXE_RES_NOP;
                    wd_o <= `NOPRegAddr;
                    wreg_o <= `WriteDisable;
                    instvalid <= `InstValid;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b0;
                    reg1_addr_o <= `NOPRegAddr;
                    reg2_addr_o <= `NOPRegAddr;
                    imm_o = `ZeroWord;
                end
            endcase
        end          
    end 
    
    // data forwarding
    always @(*) begin 
        if (rst == `RstEnable) begin 
            reg1_o <= `ZeroWord;
        end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o)) begin
            reg1_o <= ex_wdata_i;
        end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o)) begin
            reg1_o <= mem_wdata_i;
        end else if (reg1_read_o == 1'b1) begin 
            reg1_o <= reg1_data_i;
        end else begin
            reg1_o <= `ZeroWord;
        end
    end
        
    always @(*) begin
        if (rst == `RstEnable) begin
            reg2_o <= `ZeroWord;
        end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o)) begin
            reg2_o <= ex_wdata_i;
        end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o)) begin
            reg2_o <= mem_wdata_i;
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end

endmodule