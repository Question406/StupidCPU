`include "defines.v"

module mem(
    input wire rst,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,
    
    // whether can send request to mem_ctrl
    input wire mem_busy,
    
    input wire[`RegBus] mem_w_data_i,
    input wire[`AluSelBus] mem_op_type_i,

    // connect to mem_ctrl
    output wire mem_req,
    output reg[`RegBus] mem_req_addr,
    output reg[`RegBus] mem_req_data,
    output reg[3:0] mem_req_type, 
    
    // insts don't need to connect with mem_ctrl
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o,

    // tell mem_wb wait for load && store insts
    output wire need_wait
);

    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
        end else begin
            if (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                mem_op_type_i == `LHU || mem_op_type_i == `SB || mem_op_type_i == `SW) begin

            end else begin
                wd_o <= wd_i;
                wreg_o <= wreg_i;
                wdata_o <= wdata_i;
            end

            case (mem_op_type_i)
                `LB : begin

                end
                `LH : begin
                    
                end
                `LW : begin
                    
                end
                `LHU : begin
                    
                end
                `SB : begin
                    
                end
                `SH : begin
                    
                end
                `SW : begin
                    
                end
                default : begin
                    wd_o <= wd_i;
                    wreg_o <= wreg_i;
                    wdata_o <= wdata_i;
                end
            endcase 
        end
    end
endmodule
