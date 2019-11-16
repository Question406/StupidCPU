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
    
    // ask for stall when mem need multiple cycles to finish
    output wire mem_stall_req,

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

    assign mem_stall_req = (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                            mem_op_type_i == `LHU || mem_op_type_i == `LBU || mem_op_type_i == `SB || 
                            mem_op_type_i == `SH || mem_op_type_i == `SW)? 1 : 0;

    assign mem_req = (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                        mem_op_type_i == `LHU || mem_op_type_i == `LBU || mem_op_type_i == `SB || 
                        mem_op_type_i == `SH || mem_op_type_i == `SW)? 1 : 0;

    assign need_wait = (mem_busy == 0 && (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                        mem_op_type_i == `LHU || mem_op_type_i == `LBU)) ? 1 : 0;
                        

    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
        end else begin
            if (mem_busy == 0 && (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                mem_op_type_i == `LHU || mem_op_type_i == `LBU || mem_op_type_i == `SB || 
                mem_op_type_i == `SH || mem_op_type_i == `SW)) begin
                case (mem_op_type_i)
                    `LB : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_LB;
                    end
                    `LH : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_LH;
                    end
                    `LW : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_LW;
                    end
                    `LHU : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_LHU;
                    end
                    `LBU : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_LBU;
                    end
                    `SB : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_SB;
                        mem_req_data <= mem_w_data_i;
                    end
                    `SH : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_SH;
                        mem_req_data <= mem_w_data_i;
                    end
                    `SW : begin
                        mem_req_addr <= wdata_i;
                        mem_req_type <= `mem_SW;
                        mem_req_data <= mem_w_data_i;
                    end
                    default : begin
                        wd_o <= wd_i;
                        wreg_o <= wreg_i;
                        wdata_o <= wdata_i;
                    end
                endcase
            end else begin
                wd_o <= wd_i;
                wreg_o <= wreg_i;
                wdata_o <= wdata_i;
            end
        end
    end
endmodule
