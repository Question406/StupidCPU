`include "defines.v"

module inst_rom(
    input wire ce,
    input wire[`InstAddrBus] addr,
    
    output reg[`InstAddrBus] addr_o,
    output reg[`InstBus] inst
);

    reg[7:0] inst_mem[0: `InstMemNum - 1];
    integer i;
    initial begin
        for (i = 0; i < `InstMemNum; i = i + 1) begin
            inst_mem[i] = 0;
        end
        $readmemh("D:\\ComputerSystem\\project_3\\project_3.srcs\\sources_1\\new\\inst_rom.data", inst_mem);
        for (i = 4090; i < 4180; i = i + 1) begin
            $display("%d", inst_mem[i]);
        end
        $display("dump inst_mem end\n");
    end
    always @ (*) begin
        if (ce == `ChipDisable) begin
            inst <= `ZeroWord;
        end else begin
            addr_o <= addr;
            i = addr[`InstMemNumLog2 + 1 : 0];
            $display("%d\n", i);
            //inst <= inst_mem[addr[`InstMemNumLog2 + 1 : 2]];
            inst <= {inst_mem[i + 3], inst_mem[i + 2], inst_mem[i + 1], inst_mem[i]};
            $display("%d\n", inst);
            $display("get inst done");
            //$display(
            //inst <= int_mem[addr[]];
        end
    end

endmodule