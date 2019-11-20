`include "defines.v"

module mem(
    input wire clk,
    input wire rst,
    input wire[`RegAddrBus] wd_i,
    input wire wreg_i,
    input wire[`RegBus] wdata_i,
    
    // connect with memctrl
    input wire[7:0] memctrl_data_in,
    
    input wire[`RegBus] mem_w_data_i, // data write to memory
    input wire[`AluSelBus] mem_op_type_i,
    
    // ask for stall when mem need multiple cycles to finish
    output reg mem_stall_req,

    // connect to mem_ctrl
    output reg mem_req,
    output reg mem_r_w,
    output reg[`RegBus] mem_req_addr,
    output reg[7:0] mem_req_data,
    
    // insts don't need to connect with mem_ctrl
    output reg[`RegAddrBus] wd_o,
    output reg wreg_o,
    output reg[`RegBus] wdata_o
);

reg working;
reg load_save;
reg [3:0] state;
reg [`RegBus] read_data;

    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o <= 0;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            mem_req_addr <= `ZeroWord;
            mem_req_data <= `ZeroWord;
            mem_stall_req <= 0;
            mem_req <= 0;
            state <= 4'b0000;
            working <= 0;
        end else begin
            if (working == 0 && (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                mem_op_type_i == `LHU || mem_op_type_i == `LBU || mem_op_type_i == `SB || 
                mem_op_type_i == `SH || mem_op_type_i == `SW)) begin
                working <= 1;
                state <= 4'b0000;
                read_data <= `ZeroWord;
                mem_stall_req <= 1;
            end
        end
    end

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            wd_o <= `NOPRegAddr;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
            mem_req_addr <= `ZeroWord;
            mem_req_data <= `ZeroWord;
            mem_req <= 0;
            mem_stall_req <= 0;
        end else if (working) begin
            case (state) 
                4'b0000 : begin
                    state = 4'b0001;
                    mem_req = 1;
                    mem_req_addr = wdata_i;
                    if (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                        mem_op_type_i == `LHU || mem_op_type_i == `LBU) begin
                            mem_r_w <= 0;
                    end else if (mem_op_type_i == `SB || mem_op_type_i == `SH || mem_op_type_i == `SW) begin
                            mem_r_w <= 1;
                            mem_req_data <= mem_w_data_i[7:0];
                    end
                end

                4'b0001 : begin                    
                    if (mem_op_type_i == `LH || mem_op_type_i == `LW || 
                        mem_op_type_i == `LHU || mem_op_type_i == `LBU) begin
                            mem_req <= 1;
                            mem_r_w <= 0;
                            mem_req_addr <= mem_req_addr + 1;
                            state <= 4'b0010;
                    end else if (mem_op_type_i == `SH || mem_op_type_i == `SW) begin
                            mem_r_w <= 1;
                            mem_req_data <= mem_w_data_i[15:8];
                            mem_req_addr <= mem_req_addr + 1;
                            state <= 4'b0010;
                    end else if (mem_op_type_i == `SB) begin
                        state<= 4'b0110;
                        mem_stall_req <= 0;
                    end
                end
                
                4'b0010 : begin
                    if (mem_op_type_i == `LB) begin
                        mem_req <= 0;
                        state<= 4'b0110;
                        mem_stall_req <= 0;
                        wreg_o <= wreg_i;
                        wd_o <= wd_i;
                        wdata_o <= {{24{memctrl_data_in[7]}}, memctrl_data_in};
                        mem_stall_req <= 0;
                    end else if (mem_op_type_i == `LBU) begin
                        mem_req <= 0;
                        state<= 4'b0110;
                        mem_stall_req <= 0;
                        wreg_o <= wreg_i;
                        wd_o <= wd_i;
                        wdata_o <= {24'b0 , memctrl_data_in};
                    end else begin
                        if (mem_op_type_i == `LH || mem_op_type_i == `LHU || mem_op_type_i == `LW) begin
                            state <= 4'b0011;
                            mem_req <= 1;
                            mem_r_w <= 0;
                            mem_req_addr <= mem_req_addr + 1;
                            case (mem_op_type_i)
                                `LH : begin
                                    read_data[15:8] <= memctrl_data_in;
                                end
                                `LHU : begin
                                    read_data[15:8] <= memctrl_data_in;
                                end
                                `LW : begin
                                    read_data[31:24] <= memctrl_data_in;
                                end
                            endcase 
                        end else if (mem_op_type_i == `SW) begin
                            state <= 4'b0011;
                            mem_req <= 1;
                            mem_r_w <= 1;
                            mem_req_addr <= mem_req_addr + 1;
                            mem_req_data <= mem_w_data_i[23:16];
                        end else if (mem_op_type_i == `SH) begin
                            state<= 4'b0110;
                            mem_stall_req <= 0;
                        end
                    end
                end
                4'b0011 : begin
                    if (mem_op_type_i == `LH) begin
                        mem_req <= 0;
                        state<= 4'b0110;
                        mem_stall_req <= 0;
                        wreg_o <= wreg_i;
                        wd_o <= wd_i;
                        wdata_o <= {{16{read_data[15]}}, read_data[15:8], memctrl_data_in};
                    end else if (mem_op_type_i == `LHU) begin
                        mem_req <= 0;
                        state<= 4'b0110;                        
                        mem_stall_req <= 0;
                        wreg_o <= wreg_i;
                        wd_o <= wd_i;
                        wdata_o <= {16'b0, read_data[15:8], memctrl_data_in};
                    end else begin
                        if (mem_op_type_i == `LW) begin
                            state <= 4'b0100;
                            mem_req <= 1;
                            mem_r_w <= 0;
                            mem_req_addr <= mem_req_addr + 1;
                            read_data[23:16] <= memctrl_data_in;
                        end else if (mem_op_type_i == `SW) begin
                            state <= 4'b0100;
                            mem_req <= 1;
                            mem_r_w <= 1;
                            mem_req_addr <= mem_req_addr + 1;
                            mem_req_data <= mem_w_data_i[31:24];
                            state<= 4'b0110;
                            mem_stall_req <= 0;
                        end
                    end
                end
                4'b0100 : begin
                    if (mem_op_type_i == `LW) begin
                        state <= 4'b0101;
                        mem_req <= 1;
                        mem_r_w <= 0;
                        mem_req_addr <= mem_req_addr + 1;
                        read_data[15:8] <= memctrl_data_in;
                    end 
                end

                4'b0101 : begin
                    if (mem_op_type_i == `LW) begin
                        state<= 4'b0110;
                        mem_stall_req <= 0;
                        mem_req <= 0;
                        mem_r_w <= 0;
                        wreg_o <= wreg_i;
                        wd_o <= wd_i;
                        wdata_o <= {read_data[31:8], memctrl_data_in};
                    end
                end

                // anything done state, need one cycle to flush current inst
                4'b0110 : begin
                    working <= 0;
                    state <= 4'b0000;
                    mem_req <= 0;
                    mem_r_w <= 0;
                end
            endcase
        end else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            wdata_o <= wdata_i;
        end
    end

endmodule