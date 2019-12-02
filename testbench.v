// testbench top module file
// for simulation only

`timescale 10ns/1ps
module testbench;

reg clk;
reg rst;

riscv_top #(.SIM(1)) top(
    .EXCLK(clk),
    .btnC(rst),
    .Tx(),
    .Rx(),
    .led()
);

initial begin
  clk=0;
  rst=1;
  repeat(5) #1 clk=!clk;
  rst=0; 
  forever #1 clk=!clk;

  $finish;
end

endmodule