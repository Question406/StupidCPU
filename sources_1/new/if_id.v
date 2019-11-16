`include "defines.v"

module if_id(
    input wire clk,
    input wire rst,
    
    // connect to mem
    input wire get_inst,
    input wire[`InstAddrBus] if_pc,
    input wire[`InstBus] if_inst,
    
    input wire if_idflush_i,
    
    input wire[5:0] stall,
    
    output reg[`InstAddrBus] id_pc,
    output reg[`InstBus] id_inst
    
);

//    always @ (posedge clk) begin
//        if (rst == `RstEnable) begin
//            id_pc <= `ZeroWord;
//            id_inst <= `ZeroWord;
//        end else if (stall[1] == `Stop && stall[2] == `NoStop) begin
//            id_pc <= `ZeroWord;
//            id_inst <= `ZeroWord;
//        end else if (stall[1] == `NoStop) begin
//            id_pc <= if_pc;
//            id_inst <= if_inst;
//        end
//    end

        always @ (posedge clk) begin
            if (rst == `RstEnable || if_idflush_i) begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
            end else begin
                if (get_inst == 1'b1 && stall[1] == `NoStop) begin
                    id_pc <= if_pc;
                    id_inst <= if_inst;
                end else begin
                    id_pc <= `ZeroWord;
                    id_inst <= `ZeroWord;
                end
            end
        end
    
endmodule

