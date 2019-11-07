`include "defines.v"

module min_sopc(
    input wire clk,
    input wire rst    
);

    wire[`InstAddrBus] inst_addr;
    wire[`InstBus] inst;
    wire rom_ce;
    
    control control0(
        .clk(clk), .rst(rst), .rom_addr_o(inst_addr),   //input 
        .rom_data_i(inst), .rom_ce_o(rom_ce) //output
    );
    
    inst_rom inst_rom0(
        .ce(rom_ce), .addr(inst_addr), //input
        .inst(inst) //output
    );
    
    
endmodule
