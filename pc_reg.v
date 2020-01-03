`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire set_pc_i,
    input wire[`InstAddrBus] set_pc_add_i,
    
    // memctrl send here
    input wire [7:0] mem_inst_factor_i,
    
    // send to memctrl
    // IF always request something
    output wire pc_memreq,
    output reg[`InstAddrBus] if_addr_req_o,

    // send to ID
    output reg get_inst,
//    output wire get_inst,
    output reg[`InstAddrBus] if_pc_o,
    output reg[`RegBus] if_inst_o,

    // send to inst_cache
    // cache an inst
    output reg cache_enable,
//    output reg[`InstAddrBus] inst_cache_addr_o,
    output reg[`InstBus] inst_cache_o,
    
//    // query cache
    output reg cache_query,
    output reg [`InstAddrBus] query_addr,

    // inst_cache return inst
    input wire inst_hit,
    input wire [`InstBus] cache_inst_i
);

    reg [3:0] state = 4'b0000;
    reg [3:0] last_state; //state before 
    reg [7:0] byte0;
    reg [7:0] byte1;
    reg [7:0] byte2;
    
    //assign query_addr = if_addr_req_o;
    assign pc_memreq = 1; 
    
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            if_pc_o <= 0;
            state <= 4'b0000;
            if_inst_o <= `ZeroWord;
            if_addr_req_o <= `ZeroWord;
            byte0 <= 0;
            byte1 <= 0;
            byte2 <= 0;
            get_inst <= 0;
            query_addr <= 0;
            inst_cache_o <= `ZeroWord;
        end else if (set_pc_i == `WriteEnable) begin
                if_pc_o <= set_pc_add_i;
                if_addr_req_o <= set_pc_add_i;
                query_addr <= set_pc_add_i;
                if_inst_o <= `ZeroWord;
                inst_cache_o <= `ZeroWord;
                state <= 4'b0000;
                get_inst <= 0;
        end else begin
            case (state)
                4'b0000: begin
                    if (!stall[0]) begin
                        if_pc_o <= if_addr_req_o;
                        state <= 4'b0001;
                        cache_enable <= 0;
                        cache_query <= 1;
                        get_inst <= 0;
                        last_state <= 4'b0000;
                    end else begin
                        get_inst <= 0;
                    end
                end
                4'b0001 : begin
                        if (!stall[0]) begin
                            if (inst_hit) begin
                                state <= 4'b0001;
                                if_inst_o <= cache_inst_i;
                                if_addr_req_o <= if_addr_req_o + 32'h0004;
                                query_addr <= if_addr_req_o + 32'h004;
                                if_pc_o <= if_addr_req_o;
                                last_state <= 4'b0000;
                                get_inst <= 1;
                            end else if (!inst_hit) begin
                                state <= 4'b0010;
                                last_state <= 4'b0000;
                                if_addr_req_o <= if_addr_req_o + 1;
                                if_pc_o <= if_addr_req_o;
                                cache_query <= 0;
                                get_inst <= 0;
                            end
                        end else if (stall[0]) begin
                            state <= 4'b0110;
                            cache_query <= 0;
                            if_addr_req_o <= if_pc_o;
                            last_state <= 4'b0010;
                            get_inst <= 0;
                        end                 
                end
                4'b0010: begin
                    if (!stall[0]) begin
                        state <= 4'b0011;
                        last_state <= 4'b0000;
                        if_addr_req_o <= if_addr_req_o + 1;
                        byte0 <= mem_inst_factor_i;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        if_addr_req_o <= if_pc_o + 1;
                        last_state <= 4'b0011;
                        byte0 <= mem_inst_factor_i;
                    end
                end
                4'b0011: begin
                    if (!stall[0]) begin
                        state <= 4'b0100;
                        last_state <= 4'b0000;
                        if_addr_req_o <= if_addr_req_o + 1;
                        byte1 <= mem_inst_factor_i;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        last_state <= 4'b0100;
                        if_addr_req_o <= if_pc_o + 2;
                        byte1 <= mem_inst_factor_i;
                    end 
                end
                4'b0100: begin
                    if (!stall[0]) begin
                        state <= 4'b0101; 
                        last_state <= 4'b0000;
                        if_addr_req_o <= if_addr_req_o + 1;
                        byte2 <= mem_inst_factor_i;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        last_state <= 4'b0101;
                        if_addr_req_o <= if_pc_o + 3;
                        byte2 <= mem_inst_factor_i;
                    end
                end

                4'b0101: begin
                    state <= 4'b0000;
                    last_state <= 4'b0000;
                    if_inst_o <= {mem_inst_factor_i, byte2, byte1, byte0};
                    inst_cache_o <= {mem_inst_factor_i, byte2, byte1, byte0};
                    query_addr <= if_addr_req_o;
                    cache_enable <= 1;
                    get_inst <= 1;
                end

                // interupt by mem
                4'b0110: begin
                    get_inst <= 0;
                    if (!stall[0]) begin
                        state <= last_state;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end
                end
                default : begin
                
                end
            endcase
        end
    end

endmodule