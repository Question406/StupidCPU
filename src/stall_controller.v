`include "defines.v"

module stall_controller(
    input wire rst,
    input wire id_req,
    input wire mem_req,
    
    output reg [5:0] stall
);


always @ (*) begin
    if (rst == `RstEnable) begin
        stall <= 6'b0;
    end else begin
        if (mem_req) begin
            stall <= 6'b011000;
        end else if (id_req) begin
            stall <= 6'b011100;
        end else begin
            stall <= 6'b0;
        end
    end
end

endmodule