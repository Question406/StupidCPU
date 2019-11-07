`include "defines.v"

module ex(
    input wire rst,
    input wire[`RegBus] pc_i, 
    input wire[`AluOpBus] aluop_i,
    input wire[`AluSelBus] alusel_i,
    input wire[`RegBus] imm_i,
    input wire[`RegBus] reg1_i,
    input wire[`RegBus] reg2_i,
    input wire[`RegAddrBus] wd_i,
    input wire[`RegBus] wdata,
    input wire wreg_i,
    
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,
    
    //TODO: maybe get to pc directly?
    // change pc
    output reg set_pc_o,
    output reg[`RegBus] pc_addr_o, // change pc to .
    
    // data for mem write
    output reg[`RegBus] mem_w_data,
    output reg[`AluSelBus] mem_op_type,
    
    // for data forwarding
    output reg[`RegAddrBus] ex_forwarding_rd,
    output reg[`RegBus] ex_forwarding_data
    
);
    reg[`RegBus] logicout;
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            logicout <= `ZeroWord;
        end else begin
            case (aluop_i) 
                 `Inst_LUI : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    wdata_o <= wdata;
                 end
                 `Inst_AUIPC : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + imm_i;
                    wreg_o <= `WriteEnable;
                 end
                 `Inst_JAL : begin
                 // jump to pc + imm_i
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + 3'b100;
                    wd_o <= wd_i;
                    set_pc_o <= `WriteEnable;
                    pc_addr_o <= pc_i + imm_i;
                 end
                 `Inst_JALR : begin
                 // jumpto rs1 + imm_i
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + 3'b100;
                    wd_o <= wd_i;
                    set_pc_o <= `WriteEnable;
                    pc_addr_o <=  reg1_i + imm_i;
                 end
                 `Inst_Branch : begin
                    set_pc_o <= `WriteEnable;
                    wd_o <= 5'b00000;
                    wreg_o <= `WriteDisable;
                    case (alusel_i)
                        `BEQ : begin
                                if (reg1_i == reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                end
                        end
                        `BNE : begin
                                if (reg1_i != reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                end
                        end
                        `BLT : begin
                                if ($signed(reg1_i) < $signed(reg2_i)) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                end
                        end
                        `BGE : begin
                                if ($signed(reg1_i) >= $signed(reg2_i)) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                end
                        end
                        `BLTU : begin
                                if (reg1_i < reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                end
                        end
                        `BGEU : begin
                                if (reg1_i >= reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                end
                        end
                    endcase
                 end
                 `Inst_Load: begin
                    wdata_o <= reg1_i + imm_i;
                    mem_w_data <= 32'b0;
                    mem_op_type <= alusel_i;
                 end
                 `Inst_Save: begin
                    wdata_o <= reg1_i + imm_i;
                    mem_w_data <= reg2_i;
                    mem_op_type <= alusel_i;
                 end
                 `InstClass_LogicOP : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    case (alusel_i)
                        `ADDI : wdata_o = wdata + imm_i; 
                        `SLTI : wdata_o = ($signed(wdata) < $signed(imm_i));
                        `SLTIU : wdata_o = wdata < imm_i;
                        `XORI : wdata_o = wdata ^ imm_i;
                        `ORI : wdata_o = wdata | imm_i;
                        `ANDI : wdata_o = wdata & imm_i;
                        `SLLI : wdata_o = wdata << imm_i[4:0];
                        `SRLI : wdata_o =  wdata >> imm_i[4:0];
                        `SRAI : wdata_o =  ($signed(wdata)) >>> imm_i[4:0];
                    endcase
                 end
                 `InstClass_ALUOp : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    case (alusel_i)
                        `ADD : wdata_o = reg1_i + reg2_i;
                        `SUB : wdata_o = reg1_i - reg2_i;
                        `SLL : wdata_o = reg1_i << reg2_i[4:0];
                        `SLT : wdata_o = $signed(reg1_i) < $signed(reg2_i);
                        `SLTU : wdata_o = reg1_i < reg2_i;
                        `XOR : wdata_o = reg1_i ^ reg2_i;
                        `SRL : wdata_o = reg1_i >> reg2_i[4:0];
                        `SRA : wdata_o = $signed(reg1_i) >>> $signed(reg2_i);
                        `OR : wdata_o = reg1_i | reg2_i;
                        `AND : wdata_o = reg1_i & reg2_i;
                    endcase
                 end
                 default : begin
                    
                 end
            endcase
        end
    end
    
//    always @ (*) begin
//        wd_o <= wd_i;
//        wreg_o <= wreg_i;
//        case (alusel_i)
//            `EXE_RES_LOGIC: begin
//                wdata_o <= logicout;
//            end
//            default : begin
//                wdata_o <= `ZeroWord;
//            end
//        endcase
//    end
    
endmodule
