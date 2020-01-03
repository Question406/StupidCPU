 `include "defines.v"

module if_id(
    input wire clk,
    input wire rst,

    input wire[5:0] stall,
    
    // connect to pc_reg
    input wire get_inst,
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    
    input wire if_idflush_i,
    
    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
    
);

        always @ (posedge clk) begin
            if (rst == `RstEnable || if_idflush_i) begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
            end else if (get_inst && stall[0] == `NoStop) begin
                    id_pc <= if_pc;
                    id_inst <= if_inst;
                end else if (!get_inst && stall[1] == `NoStop) begin
                    id_pc <= `ZeroWord;
                    id_inst <= `ZeroWord;
                end
        end
    
endmodule

