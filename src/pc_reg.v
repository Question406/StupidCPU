`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire set_pc_i,
    input wire[`InstAddrBus] set_pc_add_i,
    
    // memctrl send here
    input wire mem_busy,
    input wire [7:0] mem_inst_factor_i,

    // MEM interrupts IF
    //input wire mem_interrupt,
    
    // send to memctrl
    // IF always request something
    output reg pc_memreq,
    output reg[`InstAddrBus] if_addr_req_o,

    // send to ID
    output wire get_inst,
    output reg[`InstAddrBus] if_pc_o,
    output reg[`RegBus] if_inst_o
);

    reg [3:0] state;
    reg [3:0] last_state; //state before 

    assign get_inst = (state == 4'b0000) ? 1 : 0;

    always @(set_pc_i) begin
        if (set_pc_i == `WriteEnable) begin
            if_pc_o <= set_pc_add_i;
            if_addr_req_o <= set_pc_add_i;
            if_inst_o <= `ZeroWord;
            state <= 4'b0000;
        end
    end

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            if_pc_o <= 0;
            state <= 4'b0000;
            pc_memreq <= 0;
            if_inst_o <= `ZeroWord;
            if_addr_req_o <= `ZeroWord;
        end else begin
            case (state)
                4'b0000: begin
                    if (!stall[0]) begin
                        if_pc_o <= if_addr_req_o;
                        //if_addr_req_o <= if_pc_o;
                        state <= 4'b0001;
                        pc_memreq <= 1;
                    end
                end
                4'b0001 : begin
                    if (!stall[0]) begin
                        state <= 4'b0010;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        if_addr_req_o <= if_pc_o;
                        last_state <= 4'b0010;
                        pc_memreq <= 0;
                    end
                end
                4'b0010: begin
                    if_inst_o = if_inst_o >> 8;
                    if_inst_o[31:24] = mem_inst_factor_i;
                    if (!stall[0]) begin
                        state <= 4'b0011;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        if_addr_req_o <= if_pc_o + 1;
                        last_state <= 4'b0011;
                        pc_memreq <= 0;
                    end
                end
                4'b0011: begin
                    // if_addr_req_o <= if_pc_o + 32'h2;
                    if_inst_o = if_inst_o >> 8;
                    if_inst_o[31:24] = mem_inst_factor_i;
                    if (!stall[0]) begin
                        state <= 4'b0100;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        last_state <= 4'b0100;
                        if_addr_req_o <= if_pc_o + 2;
                        pc_memreq <= 0;
                    end 
                end
                4'b0100: begin
                    // if_addr_req_o <= if_pc_o + 32'h3;
                    if_inst_o = if_inst_o >> 8;
                    if_inst_o[31:24] = mem_inst_factor_i;
                    if (!stall[0]) begin
                        state <= 4'b0101; 
                        pc_memreq <= 0;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        last_state <= 4'b0101;
                        if_addr_req_o <= if_pc_o + 3;
                    end
                end

                4'b0101: begin
                    state = 4'b0000;
                    if_inst_o = if_inst_o >> 8;
                    if_inst_o[31:24] = mem_inst_factor_i;
                end

                // interupt by mem
                4'b0110: begin
                    if (!stall[0]) begin
                        state <= 4'b0111;
                        pc_memreq <= 1;
                    end 
                end
                4'b0111: begin
                    if (!stall[0]) begin
                        state <= last_state;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end
                end
            endcase
        end
    end

endmodule