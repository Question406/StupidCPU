`timescale 1ns / 1ps
module minsopc_tb();

    reg CLOCK_50;
    reg rst;
    
    initial begin
        CLOCK_50 = 1'b0;
        forever #10 CLOCK_50 = ~CLOCK_50;
    end
    
    initial begin
        rst = `RstEnable;//`RstEnable;
        #25 rst = `RstDisable;//`RstDisable;
        #1000 $stop;
    end
    
    min_sopc min_sopc0(
        .clk(CLOCK_50),
        .rst(rst)
    ); 
endmodule
