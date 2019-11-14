`ifndef DEFINES_V
`define DEFINES_V

`define RstEnable     1'b1
`define RstDisable    1'b0
`define InstFlush     1'b1
`define InstNoFlush   1'b0
`define ZeroWord      32'h00000000
`define WriteEnable   1'b1
`define WriteDisable  1'b0
`define ReadEnable    1'b1
`define ReadDisable   1'b0
`define AluOpBus      3:0
`define AluSelBus     5:0
`define InstValid     1'b0
`define InstInvalid   1'b1
`define True_v        1'b1
`define False_v       1'b0
`define ChipEnable    1'b1
`define ChipDisable   1'b0

`define Stop  1'b1
`define NoStop 1'b0

`define EXE_ORI       6'b001101
`define EXE_NOP       6'b000000

`define EXE_LUI       7'b0110111

`define EXE_OR_OP     8'b00100101
`define EXE_NOP_OP    8'b00000000

`define EXE_RES_LOGIC 3'b001
`define EXE_RES_NOP   8'b00000000

`define InstAddrBus   31:0
`define InstBus       31:0
`define InstMemNum    131071
`define InstMemNumLog2 17

`define RegAddrBus    4:0
`define RegBus        31:0
`define RegWidth      32
`define DoubleRegWidth 64
`define DoubleRegBus  63:0
`define RegNum        32
`define RegNumLog2    5
`define NOPRegAddr    5'b00000

// for inst class
`define InstClass_LUI 7'b0110111
`define InstClass_AUIPC 7'b0010111
`define InstClass_JAL 7'b1101111
`define InstClass_JALR 7'b1100111
`define InstClass_Branch 7'b1100011
`define InstClass_Load 7'b0000011
`define InstClass_Save 7'b0100011
`define InstClass_LogicOP 7'b0010011
`define InstClass_ALUOp 7'b0110011

`define Inst_LUI  4'b0000
`define Inst_AUIPC 4'b0001
`define Inst_JAL 4'b0010
`define Inst_JALR 4'b0011
`define Inst_Branch 4'b0100
`define Inst_Load 4'b0101
`define Inst_Save 4'b0110
`define Inst_ALU 4'b0111
`define Inst_LogicOP 4'b1000

`define BEQ 6'b000000
`define BNE 6'b000001
`define BLT 6'b000010
`define BGE 6'b000011
`define BLTU 6'b000100
`define BGEU 6'b000101
`define LB 6'b000110
`define LH 6'b000111
`define LW 6'b001000
`define LBU 6'b001001
`define LHU 6'b001010
`define SB 6'b001011
`define SH 6'b001100
`define SW 6'b001101
`define ADDI 6'b001110
`define SLTI 6'b001111
`define SLTIU 6'b010000
`define XORI 6'b010001
`define ORI 6'b010010
`define ANDI 6'b010011
`define SLLI 6'b010100
`define SRLI 6'b010101
`define SRAI 6'b010110
`define ADD 6'b010111
`define SUB 6'b011000
`define SLL 6'b011001
`define SLT 6'b011010
`define SLTU 6'b011011
`define XOR 6'b011100
`define SRL 6'b011101
`define SRA 6'b011110
`define OR 6'b011111
`define AND 6'b100000

//for memctrl
// 3'b000 means no mem op
`define mem_LB 3'b001
`define mem_LH 3'b010
`define mem_LW 3'b011
`define mem_SB 3'b100
`define mem_SH 3'b101
`define mem_SW 3'b110

`endif