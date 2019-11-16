`include "defines.v"

module stall_controller(
    input wire rst,
    input wire id_req,
    input wire mem_req,
    
    output reg [5:0] stall
);


always @ (*) begin
    if (rst == `ChipDisable) begin
        stall = 5'b0;
    end
    stall = 5'b0;
end

endmodule