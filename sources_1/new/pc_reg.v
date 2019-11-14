`include "defines.v"

module pc_reg(
    input wire clk,
    input wire rst,
    input wire[5:0] stall,
    input wire set_pc_i,
    input wire[`InstAddrBus] set_pc_add_i,
    
    // memctrl send here
    input wire mem_busy,
    
    // send to memctrl
    output wire pc_memreq,
    output reg[`InstAddrBus] pc,
    output reg ce
);
    always @(posedge clk) begin
        if (rst == `RstEnable) begin
            ce <= `ChipDisable;
        end else begin
            ce <= `ChipEnable;
        end
    end
    
    always @(posedge clk) begin
        if (ce == `ChipDisable) begin
            pc <= 32'h00000000;           
        end else if (set_pc_i == `WriteEnable) begin
            pc <= set_pc_add_i;
        end else if (mem_busy == 0) begin
            pc <= pc + 4'h4;
        end
    end
    
    assign pc_memreq = (mem_busy || ce == `ChipDisable) ? 0 : 1; 
    
//    always @(posedge clk) begin
//        if (mem_busy == 0) begin
//            pc_memreq <= 1;
//        end else begin
        
//        end
//    end

endmodule