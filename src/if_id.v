 `include "defines.v"

module if_id(
    input wire clk,
    input wire rst,
    
    // connect to pc_reg
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

integer i;

        always @ (posedge clk) begin
            if (rst == `RstEnable || if_idflush_i) begin
                i = 0;
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
            end else if (get_inst && stall[0] == `NoStop) begin
                //FIXME:
                // $display("if_id pass");
                // $display(if_pc, " ", if_inst);
                //$display(i);
                i = i + 1;
                id_pc <= if_pc;
                id_inst <= if_inst;
            end else if (!get_inst && stall[1] == `NoStop) begin
                id_pc <= `ZeroWord;
                id_inst <= `ZeroWord;
            end
        end
    
endmodule

