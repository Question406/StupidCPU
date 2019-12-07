`include "defines.v"
`timescale 1ns / 1ps

module predictor(
    input wire rst,

    // connect to if
    input wire get_predict,
    input wire [`InstAddrBus] now_pc,
    input wire [`InstAddrBus] now_branch_inst,

    // connect to ex
    input wire update_predict,
    input wire jump,
    input wire [`InstAddrBus] last_branch_pc,

    output reg jump_predict,
    output reg [`InstAddrBus] predict_pc
);

`define predictor_size 31:0

reg [1:0] global;
reg [1:0] local[3:0][`predictor_size];

wire hash_pos = now_pc[5:0];

always @(*) begin
    if (rst == 1) begin
        predict_pc <= 0;
        jump_predict <= 0;
    end else begin
        if (get_predict) begin
            case (local[global][hash_pos]) 
            2'b00 : begin
            
            end
            2'b01 : begin
            
            end
            2'b10 : begin
            
            end
            2'b11 : begin
            
            end
            endcase 
        end else if (update_predict) begin
            
        end

    end
end

endmodule
