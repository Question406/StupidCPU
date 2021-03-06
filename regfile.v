`include "defines.v"

module regfile(
    input wire clk,
    input wire rst,
    
    input wire we,
    input wire[`RegAddrBus] waddr,
    input wire[`RegBus] wdata,
    
    input wire re1,
    input wire[`RegAddrBus] raddr1,
    output reg[`RegBus] rdata1,
    
    input wire re2,
    input wire[`RegAddrBus] raddr2,
    output reg[`RegBus] rdata2,
    
    input wire[`AluSelBus] ex_optype,
    input wire[`RegAddrBus] ex_wd,
    output reg id_stall_req_o
);

    reg[`RegBus] regs[0:`RegNum-1];

    integer i;  
    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regs[i] <= `ZeroWord;
        end
    end


    always @ (posedge clk) begin
        if (rst == `RstDisable) begin
            if ((we == `WriteEnable) && (waddr != `RegNumLog2'h0)) begin
                regs[waddr] <= wdata;
             //  $display("set ", waddr, " to ", $signed(wdata));
            end
        end
    end
    
    //integer i;

    always @(*) begin
        if (rst == `RstEnable) begin
            rdata1 <= `ZeroWord;
        end else if (raddr1 == `RegNumLog2'h0) begin
            rdata1 <= `ZeroWord;
        end else if ((raddr1 == waddr) && (we == `WriteEnable) && (re1 == `ReadEnable)) begin
            rdata1 <= wdata;
        end else if (re1 == `ReadEnable) begin
            rdata1 <= regs[raddr1];
        end else begin
            rdata1 <= `ZeroWord;
        end
    end     

    always @(*) begin
        if (rst == `RstEnable) begin
            rdata2 <= `ZeroWord;
        end else if (raddr2 == `RegNumLog2'h0) begin
            rdata2 <= `ZeroWord;
        end else if ((raddr2 == waddr) && (we == `WriteEnable) && (re2 == `ReadEnable)) begin
            rdata2 <= wdata;
        end else if (re2 == `ReadEnable) begin
            rdata2 <= regs[raddr2];
        end else begin
            rdata2 <= `ZeroWord;
        end
    end
    
    always @(*) begin
        if (rst == `RstEnable) begin
            id_stall_req_o <= 0;
        end if ((ex_optype == `LB || ex_optype == `LH || ex_optype == `LBU || ex_optype == `LHU || ex_optype == `LW)
                && (raddr1 == ex_wd || raddr2 == ex_wd)) begin
            id_stall_req_o <= 1;
        end else begin
            id_stall_req_o <= 0;
        end
    end

endmodule
