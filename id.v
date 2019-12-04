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

    input wire last_load,
    
    // ask for stall
    output wire id_stall_req, 
    
    // to reg
    output reg reg1_read_o,
    output reg reg2_read_o,
    output reg[`RegAddrBus] reg1_addr_o,
    output reg[`RegAddrBus] reg2_addr_o,
    
    // to ex
    output reg[`RegBus] id_pc_o,
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
    
    // tell whthether data hazard 

    assign id_stall_req = (last_load) ? 1 : 0;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            aluop_o <= `Inst_NOP;
            alusel_o <= `NOP;
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= `NOPRegAddr;
            reg2_addr_o <= `NOPRegAddr;
            imm_o = `ZeroWord;
            //last_load <= 1'b0;
        end else begin
            if (last_load == 0) begin
//            $display("id doing\n");
//            $display(pc_i, " ", inst_i);
            id_pc_o <= pc_i;
            aluop_o <= `Inst_NOP;
            alusel_o <= `NOP;
            wreg_o <= `WriteDisable;
            reg1_read_o <= 1'b0;
            reg2_read_o <= 1'b0;
            reg1_addr_o <= rs1;//inst_i[19:15]; //rs1 
            reg2_addr_o <= rs2;//inst_i[24:20]; //rs2
            imm_o <= `ZeroWord;
            case (op_code)
                `InstClass_LUI : begin
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;//inst_i[];// rd
                    imm_o <= imm_U;
                    aluop_o <= `Inst_LUI;
                    
                    //last_load <= 1'b0;
                end
                `InstClass_AUIPC : begin
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_U;
                    aluop_o <= `Inst_AUIPC;
                    
                    //last_load <= 1'b0;
                end
                `InstClass_JAL : begin
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_J;        
                    aluop_o <= `Inst_JAL;
                    
                    //last_load <= 1'b0;            
                end
                `InstClass_JALR : begin
                    reg1_read_o <= 1'b1;
                    reg1_addr_o <= rs1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_I;
                    aluop_o <= `Inst_JALR;
                    
                    //last_load <= 1'b0;
                end
                `InstClass_Branch : begin
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    aluop_o <= `Inst_Branch;
                    imm_o <= imm_B;
                    case (funct3)
                        3'b000 : alusel_o <= `BEQ;
                        3'b001 : alusel_o <= `BNE;
                        3'b100 : alusel_o <= `BLT;
                        3'b101 : alusel_o <= `BGE;
                        3'b110 : alusel_o <= `BLTU;
                        3'b111 : alusel_o <= `BGEU;
                    endcase
                    
                   // last_load <= 1'b0;
                end
                `InstClass_Load : begin
                    //last_load <= 1'b1;
                    
                    reg1_read_o <= 1'b1;
                    reg1_addr_o <= rs1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_I;
                    aluop_o <= `Inst_Load;
                    
                    case (funct3)
                        3'b000 : alusel_o <= `LB;
                        3'b001 : alusel_o <= `LH;
                        3'b010 : alusel_o <= `LW;
                        3'b100 : alusel_o <= `LBU;
                        3'b101 : alusel_o <= `LHU;    
                    endcase
                end
                `InstClass_Save : begin
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    imm_o <= imm_S;
                    aluop_o <= `Inst_Save;
                    case (funct3)
                        3'b000 : alusel_o <= `SB;
                        3'b001 : alusel_o <= `SH;
                        3'b010 : alusel_o <= `SW;
                    endcase
                    
                    //last_load <= 1'b0;
                end
                `InstClass_LogicOP : begin
                    reg1_read_o <= 1'b1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    imm_o <= imm_I;
                    aluop_o <= `Inst_LogicOP;
                    case (funct3)
                        3'b000 : alusel_o <= `ADDI;
                        3'b010 : alusel_o <= `SLTI;
                        3'b011 : alusel_o <= `SLTIU;
                        3'b100 : alusel_o <= `XORI;
                        3'b110 : alusel_o <= `ORI;
                        3'b111 : alusel_o <= `ANDI;
                        3'b001 : alusel_o <= `SLLI;
                        3'b101 : alusel_o <= `SRLI;
                        3'b101 : alusel_o <= `SRAI;
                    endcase
                    
                    //last_load <= 1'b0;
                end
                `InstClass_ALUOp : begin
                    reg1_read_o <= 1'b1;
                    reg2_read_o <= 1'b1;
                    wreg_o <= `WriteEnable;
                    wd_o <= rd;
                    aluop_o <= `Inst_ALU;
                    case (funct3)
                        3'b000 : alusel_o <= (funct7 == 7'b0000000) ? `ADD : `SUB;
                        3'b001 : alusel_o <= `SLL;
                        3'b010 : alusel_o <= `SLT;
                        3'b011 : alusel_o <= `SLTU;
                        3'b100 : alusel_o <= `XOR;
                        3'b101 : alusel_o <= (funct7 == 7'b0000000) ? `SRL : `SRA;
                        3'b110 : alusel_o <= `OR;
                        3'b111 : alusel_o <= `AND;
                    endcase
                    
                    //last_load <= 1'b0;
                end
                default: begin  
                    id_pc_o <= `ZeroWord;
                    aluop_o <= `Inst_NOP;
                    alusel_o <= `NOP;
                    wd_o <= `NOPRegAddr;
                    wreg_o <= `WriteDisable;
                    reg1_read_o <= 1'b0;
                    reg2_read_o <= 1'b0;
                    reg1_addr_o <= `NOPRegAddr;
                    reg2_addr_o <= `NOPRegAddr;
                    imm_o <= `ZeroWord;
                    //last_load <= 1'b0;
                end
            endcase
        end          

        end
    end 
    
    // with data forwarding
    always @(*) begin 
        if (rst == `RstEnable) begin 
            reg1_o <= `ZeroWord;
        end else if ((reg1_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg1_addr_o) && (ex_wdata_i != `ZeroWord)) begin
            reg1_o <= ex_wdata_i;
        end else if ((reg1_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg1_addr_o) && (mem_wdata_i != `ZeroWord)) begin
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
        end else if ((reg2_read_o == 1'b1) && (ex_wreg_i == 1'b1) && (ex_wd_i == reg2_addr_o) && (ex_wdata_i != `ZeroWord)) begin
            reg2_o <= ex_wdata_i;
        end else if ((reg2_read_o == 1'b1) && (mem_wreg_i == 1'b1) && (mem_wd_i == reg2_addr_o) && (mem_wdata_i != `ZeroWord)) begin
            reg2_o <= mem_wdata_i;
        end else if (reg2_read_o == 1'b1) begin
            reg2_o <= reg2_data_i;
        end else begin
            reg2_o <= `ZeroWord;
        end
    end

endmodule