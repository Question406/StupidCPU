`include "defines.v"

//TODO: Do set_pc_o need to pass through ctrl?  

module ctrl(
    input wire rst,
    input wire stallreq_id,
    input wire stallreq_ex,
    
    input wire set_pc_i, 
    input wire set_pc_add_i,
//    output wire[4:0] flush,
//    output wire set_pc_o,
//    output wire[`InstAddrBus] set_pc_add_o,
    
    output reg[5:0] stall
);

//    assign flush = (set_pc_i == `WriteEnable ? 5'b00111: 5'b11111);
//    assign set_pc_o = set_pc_i;
//    assign set_pc_add_o = set_pc_add_i;

    always @ (*) begin
        if (rst == `RstEnable) begin
            stall <= 6'b000000;
        end else if (stallreq_ex == `Stop) begin
            stall <= 6'b001111;
        end else if (stallreq_id == `Stop) begin
            stall <= 6'b000111;
        end else begin
            stall <= 6'b000000;
        end
    end
endmodule
