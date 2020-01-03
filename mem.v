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
    //output wire mem_stall_req,

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

//reg working;
reg [3:0] state;
reg [`RegBus] read_data;
reg work_done;

reg [7:0] byte0;
reg [7:0] byte1;
reg [7:0] byte2;

//assign mem_stall_req = (working) ? 1 : 0;

    always @(*) begin
        if (rst == `RstEnable) begin
            mem_stall_req <= 0;
        end else begin
            mem_stall_req <= (work_done == 0 && (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || 
                    mem_op_type_i == `LHU || mem_op_type_i == `LBU || mem_op_type_i == `SB || 
                    mem_op_type_i == `SH || mem_op_type_i == `SW)) ? 1 : 0;
        end
    end

    always @(*) begin
        if (rst == `RstEnable) begin
            wd_o <= 0;
            wreg_o <= `WriteDisable;
            wdata_o <= `ZeroWord;
        end else begin
            wd_o <= wd_i;
            wreg_o <= wreg_i;
            if (mem_op_type_i == `LB || mem_op_type_i == `LH || mem_op_type_i == `LW || mem_op_type_i == `LHU || mem_op_type_i == `LBU) begin
                wdata_o <= read_data;
            end else begin
                wdata_o <= wdata_i;
            end
        end
    end 

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            mem_req <= 0;
            mem_r_w <= 0;
            work_done <= 0;
            mem_req_addr <= `ZeroWord;
            mem_req_data <= `ZeroWord;
            state <= 4'b0000;
            byte0 <= 0;
            byte1 <= 0;
            byte2 <= 0;
            read_data <= 0;
        end else if (mem_stall_req) begin
            case (state) 
                4'b0000 : begin
                    state <= 4'b0001;
                    mem_req <= 1;
                    mem_req_addr <= wdata_i;

                    work_done <= 0;
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
                            work_done <= 0;

                    end else if (mem_op_type_i == `SH || mem_op_type_i == `SW) begin
                            mem_r_w <= 1;
                            mem_req_data <= mem_w_data_i[15:8];
                            mem_req_addr <= mem_req_addr + 1;
                            state <= 4'b0010;
                            work_done <= 0;
                    end else if (mem_op_type_i == `SB) begin
                        //state<= 4'b0110;
                        state<= 4'b0000;
                        work_done <= 1;
                        mem_req <= 0;
                        mem_r_w <= 0;

                        //mem_stall_req <= 0;
                    end
                end
                
                4'b0010 : begin
                    if (mem_op_type_i == `LB) begin
                        mem_req <= 0;
                        //state<= 4'b0110;
                        state<= 4'b0000;
                       // mem_stall_req <= 0;
                        //wdata_o <= {{24{memctrl_data_in[7]}}, memctrl_data_in};
                        read_data <= {{24{memctrl_data_in[7]}}, memctrl_data_in};

                        work_done <= 1;
                        mem_req <= 0;
                        mem_r_w <= 0;

                        //mem_stall_req <= 0;
                    end else if (mem_op_type_i == `LBU) begin
                        mem_req <= 0;
                        //state<= 4'b0110;
                        state<= 4'b0000;
                        //mem_stall_req <= 0;
                        //wdata_o <= {24'b0 , memctrl_data_in};
                        read_data <= {24'b0 , memctrl_data_in};
                        work_done <= 1;
                        mem_req <= 0;
                        mem_r_w <= 0;

                    end else begin
                        if (mem_op_type_i == `LH || mem_op_type_i == `LHU || mem_op_type_i == `LW) begin
                            state <= 4'b0011;
                            mem_req <= 1;
                            mem_r_w <= 0;
                            mem_req_addr <= mem_req_addr + 1;
//                            read_data = read_data >> 8;
//                            read_data[31:24] = memctrl_data_in;
                            byte0 <= memctrl_data_in;
                            work_done <= 0;
                        end else if (mem_op_type_i == `SW) begin
                            state <= 4'b0011;
                            mem_req <= 1;
                            mem_r_w <= 1;
                            mem_req_addr <= mem_req_addr + 1;
                            mem_req_data <= mem_w_data_i[23:16];
                            work_done <= 0;
                        end else if (mem_op_type_i == `SH) begin
                            //state<= 4'b0110;
                            state<= 4'b0000;
                            work_done <= 1;
                            mem_req <= 0;
                            mem_r_w <= 0;
                            //mem_stall_req <= 0;
                        end
                    end
                end
                4'b0011 : begin
                    if (mem_op_type_i == `LH) begin
                        mem_req <= 0;
                        //state<= 4'b0110;
                        state<= 4'b0000;
                        //mem_stall_req <= 0;
                        //wdata_o <= {{16{memctrl_data_in[7]}}, memctrl_data_in, read_data[31:24]};
                        //read_data <= {{16{memctrl_data_in[7]}}, memctrl_data_in, read_data[31:24]};
                        read_data <= {{16{memctrl_data_in[7]}}, memctrl_data_in, byte0};
                        work_done <= 1;
                        mem_req <= 0;
                        mem_r_w <= 0;
                    end else if (mem_op_type_i == `LHU) begin
                        mem_req <= 0;
                        //state<= 4'b0110;
                        state<= 4'b0000;                        
                        //mem_stall_req <= 0;
                        //wdata_o <= {16'b0, memctrl_data_in, read_data[31:24]};
                        //read_data <= {16'b0, memctrl_data_in, read_data[31:24]};
                        read_data <= {16'b0, memctrl_data_in, byte0};
                        work_done <= 1;
                        mem_req <= 0;
                        mem_r_w <= 0;
                    end else begin
                        if (mem_op_type_i == `LW) begin
                            state <= 4'b0100;
                            mem_req <= 1;
                            mem_r_w <= 0;
                            mem_req_addr <= mem_req_addr + 1;
                            //read_data[23:16] <= memctrl_data_in;
//                            read_data = read_data >> 8;
//                            read_data[31:24] = memctrl_data_in;
                            byte1 <= memctrl_data_in;
                            work_done <= 0;
                        end else if (mem_op_type_i == `SW) begin
                            state <= 4'b0100;
                            mem_req <= 1;
                            mem_r_w <= 1;
                            mem_req_addr <= mem_req_addr + 1;
                            mem_req_data <= mem_w_data_i[31:24];
                            //state<= 4'b0110;
                            state<= 4'b0100;
                            work_done <= 0;

 
                            //mem_stall_req <= 0;
                        end
                    end
                end
                4'b0100 : begin
                    if (mem_op_type_i == `LW) begin
                        state <= 4'b0101;
                        mem_req <= 1;
                        mem_r_w <= 0;
                        mem_req_addr <= mem_req_addr + 1;
                        //read_data[15:8] <= memctrl_data_in;
//                        read_data = read_data >> 8;
//                        read_data[31:24] = memctrl_data_in;
                        byte2 <= memctrl_data_in;
                        work_done <= 0;

                    end else if (mem_op_type_i == `SW) begin
                        mem_req <= 0;
                        mem_r_w <= 0;
                        work_done <= 1;
                        state<= 4'b0000;
                    end
                end

                4'b0101 : begin
                    if (mem_op_type_i == `LW) begin
                        //state<= 4'b0110;
                        state<= 4'b0000;
                        //mem_stall_req <= 0;
                        mem_req <= 0;
                        mem_r_w <= 0;
                        //wdata_o <= {memctrl_data_in, read_data[31:8]};
                        read_data <= {memctrl_data_in, byte2, byte1, byte0};
                        work_done <= 1;
                        // if (`DEBUG) begin
                        //     $display("read ", wdata_o);
                        // end
                    end
                end
                default : begin
                end

                // anything done state, need one cycle to flush current inst
//                4'b0110 : begin
//                    //state <= 4'b0111;
//                    state <= 4'b0000;
//                    work_done <= 1;
//                    load_done <= 0;
//                    mem_req <= 0;
//                    mem_r_w <= 0;
//                end
//                4'b0111 : begin
//                    state <= 4'b0000;
//                end
            endcase
        end else begin
            work_done <= 0;
            state <= 4'b0000;
        end
    end

endmodule