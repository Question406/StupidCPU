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
    input wire wreg_i,
    
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,
    
    //TODO: maybe get to pc directly?
    // change pc
    output reg set_pc_o,
    output reg[`RegBus] pc_addr_o, // change pc to .
    
    // when branch taken
    output reg if_idflush_o,
    output reg id_exflush_o,
    
    // flushing the inst request in mem_ctrl
    output reg inst_flush,
    
    // data for mem write
    output reg[`RegBus] mem_w_data,
    //ATTENTION: maybe wire?
    output reg[`AluSelBus] mem_op_type,
    
    // for data forwarding
    output wire ex_forwarding_wd,
    output reg[`RegAddrBus] ex_forwarding_rd,
    output reg[`RegBus] ex_forwarding_data
    
);
    reg[`RegBus] logicout;

    assign ex_forwarding_wd = (aluop_i != `Inst_Branch) ? 0 : 1; 
    
    always @ (*) begin
        if (rst == `RstEnable) begin
            wd_o <= 0;
            wreg_o <= 0;
            wdata_o <= `ZeroWord;
            set_pc_o <= 0;
            pc_addr_o <= `ZeroWord;
            if_idflush_o <= 0;
            id_exflush_o <= 0;
            mem_w_data <= `ZeroWord;
            mem_op_type <= 6'b0;
            ex_forwarding_rd <= 0;
            ex_forwarding_data <= `ZeroWord;
            inst_flush <= 0;
        end else begin
            if_idflush_o <= `InstNoFlush;
            id_exflush_o <=  `InstNoFlush;
            inst_flush <= 0;
            set_pc_o <= `WriteDisable;
            ex_forwarding_rd <= 0;
            ex_forwarding_data <= `ZeroWord;

            mem_w_data <= 32'b0;
            case (aluop_i) 
                `Inst_LUI : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    wdata_o <= imm_i;
                end
                `Inst_AUIPC : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + imm_i;
                    wreg_o <= `WriteEnable;
                end
                //TODO: some branch inst jump directly, don't need to determine until ex
                `Inst_JAL : begin
                // jump to pc + imm_i
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + 3'b100;
                    wd_o <= wd_i;
                    set_pc_o <= `WriteEnable;
                    pc_addr_o <= pc_i + imm_i;
                    if_idflush_o <= `InstFlush;
                    id_exflush_o <= `InstFlush;
                    inst_flush <= 1;              
                end
                `Inst_JALR : begin
                 // jumpto rs1 + imm_i
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + 3'b100;
                    wd_o <= wd_i;
                    set_pc_o <= `WriteEnable;
                    pc_addr_o <=  reg1_i + imm_i;
                    if_idflush_o <= `InstFlush;
                    id_exflush_o <= `InstFlush;
                    inst_flush <= 1;
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
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    inst_flush <= 1;
                                end
                        end
                        `BNE : begin
                                if (reg1_i != reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    inst_flush <= 1;
                                end
                        end
                        `BLT : begin
                                if ($signed(reg1_i) < $signed(reg2_i)) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    inst_flush <= 1;
                                end
                        end
                        `BGE : begin
                                if ($signed(reg1_i) >= $signed(reg2_i)) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    inst_flush <= 1;
                                end
                        end
                        `BLTU : begin
                                if (reg1_i < reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    inst_flush <= 1;
                                end
                        end
                        `BGEU : begin
                                if (reg1_i >= reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                end
                        end
                    endcase
                end
                `Inst_Load: begin
                    wreg_o <= `WriteEnable;
                    wdata_o <= reg1_i + imm_i;
                    mem_op_type <= alusel_i;
                end
                `Inst_Save: begin
                    wreg_o <= `WriteEnable;
                    wdata_o <= reg1_i + imm_i;
                    mem_w_data <= reg2_i;
                    mem_op_type <= alusel_i;
                end
                `InstClass_LogicOP : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    case (alusel_i)
                        `ADDI : wdata_o = reg1_i + imm_i; 
                        `SLTI : wdata_o = ($signed(reg1_i) < $signed(imm_i));
                        `SLTIU : wdata_o = reg1_i < imm_i;
                        `XORI : wdata_o = reg1_i ^ imm_i;
                        `ORI : wdata_o = reg1_i | imm_i;
                        `ANDI : wdata_o = reg1_i & imm_i;                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                        `SLLI : wdata_o = reg1_i << imm_i[4:0];
                        `SRLI : wdata_o =  reg1_i >> imm_i[4:0];
                        `SRAI : wdata_o =  ($signed(reg1_i)) >>> imm_i[4:0];
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
                    wd_o <= 0;
                    wreg_o <= 0;
                    wdata_o <= `ZeroWord;
                    set_pc_o <= 0;
                    pc_addr_o <= `ZeroWord;
                    if_idflush_o <= 0;
                    id_exflush_o <= 0;
                    mem_w_data <= `ZeroWord;
                    mem_op_type <= 6'b0;
                    ex_forwarding_rd <= 0;
                    ex_forwarding_data <= `ZeroWord;
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
