`include "defines.v"

module stall_controller(
    input wire rst,
    input wire id_req,
    input wire mem_req,
    input wire stop_stall,
    
    output reg [5:0] stall
);


always @ (*) begin
    if (rst == `RstEnable || stop_stall) begin
        stall <= 6'b0;
    end else begin
        if (mem_req) begin
            stall <= 6'b000111;
        end else if (id_req) begin
            stall <= 6'b000010;
        end else begin
            stall <= 6'b0;
        end
    end
end

endmodule