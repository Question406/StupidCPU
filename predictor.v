`include "defines.v"
`timescale 1ns / 1ps

module predictor(
    input wire rst,
    input wire clk,

    // connect to if
    input wire get_predict,
    input wire [`InstAddrBus] now_pc,
    input wire [`InstAddrBus] now_branch_inst,

    // connect to ex
    input wire update_predict,
    input wire predict_success,
    input wire [`InstAddrBus] last_branch_pc,

    output reg jump_predict,
    output reg [`InstAddrBus] predict_pc
);

`define predictor_size 127:0

reg [1:0] global;
reg [1:0] local[3:0][`predictor_size];

wire [6:0] hash_pos = now_pc[6:0];
wire [6:0] update_hash_pos = last_branch_pc[6:0];
wire [`RegBus] imm = {{20{now_branch_inst[31]}},now_branch_inst[7],now_branch_inst[30:25],now_branch_inst[11:8],1'b0};

//wire [1:0] local_status = local[global][hash_pos];

integer i;
//initial begin
//    for (i = 0; i < 256; i = i + 1) begin
//        local[2'b00][i] = 2'b00;
//        local[2'b01][i] = 2'b00;
//        local[2'b10][i] = 2'b00;
//        local[2'b11][i] = 2'b00;
//    end
//end

always @(posedge clk) begin
    if (rst) begin
        global <= 0;
    end
    else  if (update_predict) begin
            case (local[global][update_hash_pos])
                2'b00 : local[global][update_hash_pos] = (predict_success) ? 2'b00 : 2'b01;
                2'b01 : local[global][update_hash_pos] = (predict_success) ? 2'b00 : 2'b10;
                2'b10 : local[global][update_hash_pos] = (predict_success) ? 2'b11 : 2'b01;
                2'b11 : local[global][update_hash_pos] = (predict_success) ? 2'b11 : 2'b10;
                default : begin
                    local[global][update_hash_pos] = (predict_success) ? 2'b00 : 2'b01;
                end
            endcase
            
            case (global)
                2'b00 : global = (predict_success) ? (2'b00) : (2'b01);
                2'b01 : global = (predict_success) ? (2'b00) : (2'b10);
                2'b10 : global = (predict_success) ? (2'b11) : (2'b01);
                2'b11 : global = (predict_success) ? (2'b11) : (2'b10);
            endcase
        end
end

always @(*) begin
    if (rst == 1) begin
        predict_pc <= 0;
        jump_predict <= 0;
    end else if (get_predict) begin
            //if (local[global][hash_pos] == 2'b00 || local[global][hash_pos] == 2'b01) begin
            //jump_predict <= (local[global][hash_pos] == 2'b10 ||local[global][hash_pos] == 2'b11) ? 1 : 0;
            //end else if (local[global][hash_pos] == 2'b00 || local[global][hash_pos] == 2'b01) begin
            if (local[global][hash_pos] == 2'b10 || local[global][hash_pos] == 2'b11) begin
                jump_predict <= 1;
                predict_pc <= now_pc + imm;
            end else begin
                jump_predict <= 0;
                predict_pc <= now_pc + 32'h0004;
            end
            
            //predict_pc <= (local[global][hash_pos] == 2'b10 || local[global][hash_pos] == 2'b11) ? (now_pc + imm) : (now_pc + 4);
        end else begin
            jump_predict <= 0;
            predict_pc <= `ZeroWord;
        end
end

endmodule

