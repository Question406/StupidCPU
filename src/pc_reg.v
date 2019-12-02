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
    
    // send to memctrl
    // IF always request something
    output reg pc_memreq,
    output reg[`InstAddrBus] if_addr_req_o,

    // send to ID
    output wire get_inst,
    output reg[`InstAddrBus] if_pc_o,
    output reg[`RegBus] if_inst_o,

    // send to inst_cache
    // cache an inst
    output reg cache_enable,
    output reg[`InstAddrBus] inst_cache_addr_o,
    output reg[`InstBus] inst_cache_o,
    
    // query cache
    output reg cache_query,
    output reg[`InstAddrBus] query_addr,

    // inst_cache return inst
    input wire inst_hit,
    input wire [`InstBus] cache_inst_i,

    input wire predict_jump,

);

    reg [3:0] state;
    reg [3:0] last_state; //state before 

    assign get_inst = (state == 4'b0000) ? 1 : 0;
    //assign get_inst = (state == 4'b0000) ? 1 : 0;
    //assign cache_query = (state == 4'b0000) ? 1 : 0;

    always @(set_pc_i) begin
        if (set_pc_i == `WriteEnable) begin
            if_pc_o <= set_pc_add_i;
            if_addr_req_o <= set_pc_add_i;
            if_inst_o <= `ZeroWord;
            state <= 4'b0000;
        end
    end

    always @() begin
        if (predict_jump) begin
            
        end
    end

    wire[6:0] op_code = if_inst_o[6:0];
    wire[`RegBus] imm_B = {{20{if_inst_o[31]}},if_inst_o[7],if_inst_o[30:25],if_inst_o[11:8],1'b0};

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
                        
                        cache_enable <= 0;
                        cache_query <= 1;
                        query_addr <= if_addr_req_o;
                        last_state <= 4'b0000;
                    end
                end
                4'b0001 : begin
                    //if (!stall[0] && !inst_hit) begin
                    if (inst_hit) begin
                        if (!stall[0]) begin
                            state <= 4'b1000;
                            pc_memreq <= 0;
                            if_inst_o <= cache_inst_i;
                            if_addr_req_o <= if_pc_o + 32'h0004;
                            //$display("inst: ", cache_inst_i);
                            //$display("inst_hit get ", cache_inst_i);
                            last_state <= 4'b0000;
                        end
                    end else begin
                        if (!stall[0]) begin
                            state <= 4'b0010;
                            last_state <= 4'b0000;
                            if_addr_req_o <= if_addr_req_o + 1;
                            cache_query <= 0;
                        // end else if (!stall[0] && inst_hit) begin
                        //     state <= 4'b1000;
                        //     pc_memreq <= 0;
                        //     if_inst_o <= cache_inst_i;
                        //     if_addr_req_o <= if_pc_o + 32'h4;
                        //     $display("inst_hit get ", cache_inst_i);
                        end else if (stall[0]) begin 
                            state <= 4'b0110;
                            if_addr_req_o <= if_pc_o;
                            last_state <= 4'b0010;
                            pc_memreq <= 0;
                        end
                    end
                    // if (!stall[0]) begin
                    //         state <= 4'b0010;
                    //         if_addr_req_o <= if_addr_req_o + 1;
                    //         cache_query <= 0;
                    //     // end else if (!stall[0] && inst_hit) begin
                    //     //     state <= 4'b1000;
                    //     //     pc_memreq <= 0;
                    //     //     if_inst_o <= cache_inst_i;
                    //     //     if_addr_req_o <= if_pc_o + 32'h4;
                    //     //     $display("inst_hit get ", cache_inst_i);
                    //     end else if (stall[0]) begin 
                    //         state <= 4'b0110;
                    //         if_addr_req_o <= if_pc_o;
                    //         last_state <= 4'b0010;
                    //         pc_memreq <= 0;
                    //     end
                end
                4'b0010: begin
                    if_inst_o = if_inst_o >> 8;
                    if_inst_o[31:24] = mem_inst_factor_i;
                    if (!stall[0]) begin
                        state <= 4'b0011;
                        last_state <= 4'b0000;
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
                        last_state <= 4'b0000;
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
                        last_state <= 4'b0000;
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
                    last_state = 4'b0000;
                    if_inst_o = if_inst_o >> 8;
                    if_inst_o[31:24] = mem_inst_factor_i;

                    cache_enable = 1;
                    inst_cache_addr_o = if_pc_o;
                    inst_cache_o = if_inst_o;

                    if (op_code == `)
                end

                // idle cache hit state
                4'b1000: begin
                    state <= 4'b0000;
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