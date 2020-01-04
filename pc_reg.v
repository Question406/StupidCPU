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
    //output reg pc_memreq,
    output wire pc_memreq,
    output reg[`InstAddrBus] if_addr_req_o,

    // send to ID
    output reg get_inst,
    output reg[`InstAddrBus] if_pc_o,
    output reg[`RegBus] if_inst_o,

    // send to inst_cache
    // cache an inst
    output reg cache_enable,
//    output reg[`InstAddrBus] inst_cache_addr_o,
//    output reg[`InstBus] inst_cache_o,
    
//    // query cache
    output reg cache_query,
    output wire[`InstAddrBus] query_addr,

    // inst_cache return inst
    input wire inst_hit,
    input wire [`InstBus] cache_inst_i,
    
    input wire jump_predict,
    input wire [`InstAddrBus] predict_addr,
    output reg get_predict,
    output reg jump
);

    reg [3:0] state = 4'b0000;
    reg [3:0] last_state; //state before 
    
    reg [7:0] byte0;
    reg [7:0] byte1;
    reg [7:0] byte2;

    //assign get_inst = (state == 4'b0000) ? 1 : 0;
    wire[6:0] op_code = byte0[6:0];
    wire[6:0] cache_inst_op_code = cache_inst_i[6:0];
    
    assign pc_memreq = 1;
    
    assign query_addr = if_addr_req_o;

    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            if_pc_o <= 0;
            state <= 4'b0000;
           // pc_memreq <= 0;
            if_inst_o <= `ZeroWord;
            if_addr_req_o <= `ZeroWord;
            byte0 <= 0;
            byte1 <= 0;
            byte2 <= 0;
            
            jump <= 0;
            get_predict <= 0;
            get_inst <= 0;
        end else if (set_pc_i == `WriteEnable) begin
                if_pc_o <= set_pc_add_i;
                if_addr_req_o <= set_pc_add_i;
                if_inst_o <= `ZeroWord;
                state <= 4'b0000;
                get_inst <= 0;
        end else begin
            case (state)
                4'b0000: begin
                    if (!stall[0]) begin
                        get_predict <= 0;
                        if_pc_o <= if_addr_req_o;
                        state <= 4'b0001;
                        //pc_memreq <= 1;
                        get_inst <= 0;
                        
                        cache_enable <= 0;
                        cache_query <= 1;
                        last_state <= 4'b0000;
                    end 
                end
                4'b0001 : begin
                        if (!stall[0]) begin
                            if (inst_hit) begin
                                if (cache_inst_op_code == `InstClass_Branch) begin
                                    //pc_memreq <= 0;
                                    last_state <= 4'b0000;
                                    if_pc_o <= if_addr_req_o;
                                    if_inst_o <= cache_inst_i;
                                    state <= 4'b1000;
                                    get_inst <= 0;
                                    
                                    get_predict <= 1;
                                end else begin
                                    state <= 4'b0001;
                                   // pc_memreq <= 1;
                                    if_inst_o <= cache_inst_i;
                                    if_addr_req_o <= if_addr_req_o + 32'h0004;
                                    if_pc_o <= if_addr_req_o;

                                    last_state <= 4'b0000;
                                    get_inst <= 1;
                                    jump <= 0;
                                end
                            end else if (!inst_hit) begin
                                state <= 4'b0010;
                                last_state <= 4'b0000;
                                if_addr_req_o <= if_addr_req_o + 1;
                                if_pc_o <= if_addr_req_o;
                                cache_query <= 0;
                                jump <= 0;
                                get_inst <= 0;
                            end
                        end else if (stall[0]) begin
                            state <= 4'b0110;
                            cache_query <= 0;
                            if_addr_req_o <= if_pc_o;
                            last_state <= 4'b0010;
                           // pc_memreq <= 0;
                            get_inst <= 0;
                        end
                end
                4'b0010: begin
                    if (!stall[0]) begin
                        state <= 4'b0011;
                        last_state <= 4'b0000;
                        if_addr_req_o <= if_addr_req_o + 1;
                        byte0 <= mem_inst_factor_i;
                        get_inst <= 0;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        if_addr_req_o <= if_pc_o + 1;
                        last_state <= 4'b0011;
                        //pc_memreq <= 0;
                        byte0 <= mem_inst_factor_i;
                        get_inst <= 0;
                    end
                end
                4'b0011: begin
                    if (!stall[0]) begin
                        state <= 4'b0100;
                        last_state <= 4'b0000;
                        if_addr_req_o <= if_addr_req_o + 1;
                        byte1 <= mem_inst_factor_i;
                        get_inst <= 0;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        last_state <= 4'b0100;
                        if_addr_req_o <= if_pc_o + 2;
                        //pc_memreq <= 0;
                        byte1 <= mem_inst_factor_i;
                        get_inst <= 0;
                    end 
                end
                4'b0100: begin
                    if (!stall[0]) begin
                        state <= 4'b0101; 
                        last_state <= 4'b0000;
                        //pc_memreq <= 0;
                        if_addr_req_o <= if_addr_req_o + 1;
                        byte2 <= mem_inst_factor_i;
                        get_inst <= 0;
                    end else if (stall[0]) begin
                        state <= 4'b0110;
                        last_state <= 4'b0101;
                        if_addr_req_o <= if_pc_o + 3;
                        byte2 <= mem_inst_factor_i;
                        get_inst <= 0;
                    end
                end

                4'b0101: begin
                   if_inst_o <= {mem_inst_factor_i, byte2, byte1, byte0};
                   cache_enable <= 1;
                   if (op_code == `InstClass_Branch) begin
                        state <= 4'b1000;
                        get_predict <= 1;
                        get_inst <= 0;
                    end else begin
                        state <= 4'b0000;
                        last_state <= 4'b0000;
                        get_inst <= 1;
                    end

                end

                // wait for predictor
                4'b1000: begin
                    if (!stall[0]) begin
                        cache_enable <= 0;
                        get_predict <= 0;
                        jump <= jump_predict;
                        state <= 4'b0001;
                        cache_query <= 1;
                        get_inst <= 1;
                        if_addr_req_o <= predict_addr;        
                    end if (stall[0]) begin
                        get_predict <= 1;
                    end
                end

                // interupt by mem
                4'b0110: begin
//                    if (!stall[0]) begin
//                        state <= 4'b0111;
//                        pc_memreq <= 1;
//                    end
                    if (!stall[0]) begin
                        state <= last_state;
                        if_addr_req_o <= if_addr_req_o + 1;
                    end
                end
//                4'b0111: begin
//                    if (!stall[0]) begin
//                        state <= last_state;
//                        if_addr_req_o <= if_addr_req_o + 1;
//                    end
//                end
                default : begin
                
                end
            endcase
        end
    end

endmodule