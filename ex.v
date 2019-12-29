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
    
    // data for mem write
    output reg[`RegBus] mem_w_data,
    //ATTENTION: maybe wire?
    output reg[`AluSelBus] mem_op_type,
    
    // for data forwarding
    output wire ex_forwarding_wd
//    output wire[`RegAddrBus] ex_forwarding_rd,
//    output wire[`RegBus] ex_forwarding_data
);
    
    assign ex_forwarding_wd = (aluop_i == `Inst_Load || aluop_i == `Inst_Save) ? 0 : wreg_o; 
//    assign ex_forwarding_rd = wd_o;
//    assign ex_forwarding_data = wdata_o;
    
    
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
            mem_op_type <= `NOP;
        end else begin
            if_idflush_o <= `InstNoFlush;
            id_exflush_o <=  `InstNoFlush;
            set_pc_o <= `WriteDisable;
            mem_op_type <= alusel_i;
            mem_w_data <= 32'b0;
            wdata_o <= `ZeroWord;
            pc_addr_o <= `ZeroWord;
            wd_o <= 0;
            case (aluop_i) 
                `Inst_LUI : begin
//                    if (`DEBUG) begin
//                        $display("LUI ", wd_i, " ", imm_i);
//                        $display("watchingpc ", pc_i);
//                    end
                    
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    wdata_o <= imm_i;
                end
                `Inst_AUIPC : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    wdata_o <= pc_i + imm_i;
                    
//                    if (`DEBUG) begin
//                        $display("AUIPC ", wd_i, " ", pc_i + imm_i);
//                        $display("watchingpc ", pc_i);
//                    end
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
                    
//                    if (`DEBUG) begin
//                        $display("JAL ", wd_i, " ", pc_i + 3'b100);
//                        $display("jump to ", pc_i + imm_i);
//                        $display("watchingpc ", pc_i);
//                    end            
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
                    
//                    if (`DEBUG) begin
//                        $display("JALR ", wd_i, " ", pc_i + 3'b100);
//                        $display("jump to ", reg1_i + imm_i);
//                        $display("watchingpc ", pc_i);
//                    end
                end
                `Inst_Branch : begin
                    set_pc_o <= `WriteDisable;
                    wd_o <= 5'b00000;
                    wreg_o <= `WriteDisable;
                    wdata_o <= `ZeroWord;
                    case (alusel_i)
                        `BEQ : begin
                                if (reg1_i == reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    
//                                    if (`DEBUG) begin
//                                        $display("BEQ ");
//                                        $display("jump to ", pc_i + imm_i);
//                                        $display("watchingpc ", pc_i);
//                                    end
                                end
                        end
                        `BNE : begin
                                if (reg1_i != reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    
//                                    if (`DEBUG) begin
//                                        $display("BNE ");
//                                        $display("jump to ", pc_i + imm_i);
//                                        $display("watchingpc ", pc_i);
//                                    end
                                end
                        end
                        `BLT : begin
                                if ($signed(reg1_i) < $signed(reg2_i)) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    
//                                    if (`DEBUG) begin
//                                        $display("BLT ");
//                                        $display("jump to ", pc_i + imm_i);
//                                        $display("watchingpc ", pc_i);
//                                    end
                                end
                        end
                        `BGE : begin
                                if ($signed(reg1_i) >= $signed(reg2_i)) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    
//                                    if (`DEBUG) begin
//                                        $display("BGE ");
//                                        $display("jump to ", pc_i + imm_i);
//                                        $display("watchingpc ", pc_i);
//                                    end
                                end
                        end
                        `BLTU : begin
                                if (reg1_i < reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    
//                                    if (`DEBUG) begin
//                                        $display("BLTU ");
//                                        $display("jump to ", pc_i + imm_i);
//                                        $display("watchingpc ", pc_i);
//                                    end
                                end
                        end
                        `BGEU : begin
                                if (reg1_i >= reg2_i) begin
                                    set_pc_o <= `WriteEnable;
                                    pc_addr_o <= pc_i + imm_i;
                                    if_idflush_o <= `InstFlush;
                                    id_exflush_o <= `InstFlush;
                                    
//                                    if (`DEBUG) begin
//                                        $display("BGEU ");
//                                        $display("jump to ", pc_i + imm_i);
//                                        $display("watchingpc ", pc_i);
//                                        $display("1 ", reg1_i, " 2 ", reg2_i);
//                                    end
                                end
                        end
                        default: begin
                        end
                    endcase
                end
                `Inst_Load: begin
                    wreg_o <= `WriteEnable;
                    wdata_o <= reg1_i + imm_i;
                    wd_o <= wd_i;
                    mem_op_type <= alusel_i;
                    
//                    if (`DEBUG) begin
//                        case (alusel_i)  
//                            `LB : begin
//                                $display("LB ", wd_i, " ", reg1_i+imm_i);    
//                                $display("watchingpc ", pc_i);
//                            end
//                            `LH : begin
//                                $display("LH ", wd_i, " ", reg1_i+imm_i);
//                                $display("watchingpc ", pc_i);
//                            end
//                            `LW : begin
//                                $display("LW ", wd_i, " ", reg1_i+imm_i);
//                                $display("watchingpc ", pc_i);
//                            end
//                            `LBU : begin
//                                $display("LBU ", wd_i, " ", reg1_i+imm_i);
//                                $display("watchingpc ", pc_i);
//                            end
//                            `LHU : begin
//                                $display("LHU ", wd_i, " ", reg1_i+imm_i);
//                                $display("watchingpc ", pc_i);
//                            end
//                        endcase 
//                    end
                end
                `Inst_Save: begin
                    wreg_o <= `WriteDisable;
                    wdata_o <= reg1_i + imm_i;
                    mem_w_data <= reg2_i;
                    mem_op_type <= alusel_i;
//                    if (`DEBUG) begin
//                        case (alusel_i)  
//                            `SB : begin
//                                $display("SB ", reg1_i + imm_i, " ", reg2_i);    
//                                $display("watchingpc ", pc_i);
//                            end
//                            `SH : begin
//                                $display("SH ", reg1_i + imm_i, " ", reg2_i);    
//                                $display("watchingpc ", pc_i);
//                            end
//                            `SW : begin
//                                $display("SW ", reg1_i + imm_i, " ", reg2_i);
//                                $display("watchingpc ", pc_i);
//                            end
//                        endcase 
//                    end
                end
                `Inst_LogicOP : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    case (alusel_i)
                        `ADDI : begin
                            wdata_o <= reg1_i + imm_i;
                        end 
                        `SLTI : begin
                            wdata_o <= ($signed(reg1_i) < $signed(imm_i));
                        end
                        `SLTIU : begin
                            wdata_o <= reg1_i < imm_i;
                        end
                        `XORI : begin
                            wdata_o <= reg1_i ^ imm_i;
                        end
                        `ORI : begin
                            wdata_o <= reg1_i | imm_i;
                        end
                        `ANDI :begin
                             wdata_o <= reg1_i & imm_i;
                         end                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               
                        `SLLI :begin
                             wdata_o <= reg1_i << imm_i[4:0];
                        end
                        `SRLI : begin   
                            wdata_o <=  reg1_i >> imm_i[4:0];
                        end
                        `SRAI : begin
                            wdata_o <=  ($signed(reg1_i)) >>> imm_i[4:0];
                        end
                        default : begin
                        end
                    endcase
//                    if (`DEBUG) begin
//                        $display("LogicOP ", wd_i, " ", wdata_o);
//                        $display("watchingpc ", pc_i);
//                    end
                end
                `Inst_ALU : begin
                    wd_o <= wd_i;
                    wreg_o <= `WriteEnable;
                    case (alusel_i)
                        `ADD : begin
                            wdata_o <= reg1_i + reg2_i;
                        end
                        `SUB : begin
                            wdata_o <= reg1_i - reg2_i;
                        end
                        `SLL : begin
                            wdata_o <= reg1_i << reg2_i[4:0];
                        end
                        `SLT : begin
                            wdata_o <= $signed(reg1_i) < $signed(reg2_i);
                        end
                        `SLTU : begin
                            wdata_o <= reg1_i < reg2_i;
                        end
                        `XOR : begin    
                            wdata_o <= reg1_i ^ reg2_i;
                        end
                        `SRL :begin
                             wdata_o <= reg1_i >> reg2_i[4:0];
                        end
                        `SRA :begin
                             wdata_o <= $signed(reg1_i) >>> $signed(reg2_i);
                        end
                        `OR :begin
                             wdata_o <= reg1_i | reg2_i;
                        end
                        `AND : begin
                            wdata_o <= reg1_i & reg2_i;
                        end
                        default : begin
                        end
                    endcase
//                    if (`DEBUG) begin
//                        $display("ALU ", wd_i, " ", wdata_o);
//                        $display("watchingpc ", pc_i);
//                    end
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
                    mem_op_type <= `NOP;
                end
            endcase
        end
    end

endmodule