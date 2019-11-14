`include "defines.v"

module memctrl(
    input wire clk,
    input wire rst,
    
    // memory request from if
    input wire if_req_in, // equal to lw
    input wire [`RegBus] addr_if_in,
    
    // memory request from mem
    input wire mem_req_in,
    input wire [`RegBus] addr_mem_in,
    input wire [`RegBus] data_mem_in,
    input wire [3:0] mem_req_type, // lb, lh, lw, sb, sh, sw
    
    // to cpu 
    output reg [`RegBus] output_pc,
    output reg [`RegBus] output_data, // data get from main memory
    output wire mem_busy, // tell if && mem whether could send request 
    
    // connect to main memory
    input wire [`RegBus] data_get,
    
    output wire mmem_r_w, // main memory read or write
    output wire [`RegBus] mmem_addr, // addr needed in main memory
    output reg [`RegBus] mmem_data // data needed to be stored in main memory
);

reg busy;
reg r_w; // read or write, 0 for read 1 for write
reg [2:0] countdown; // still need several cycle to finish read or write
reg [2:0] output_length; 
reg[`RegBus] addr_now;
reg[`RegBus] data_writing;
reg flag;

always @ (posedge clk) begin
    if (rst) begin
        output_data <= `ZeroWord;
    end
    else begin
        if (~busy) begin
            if (mem_req_in) begin
                busy <= 1'b1;
                addr_now <= addr_mem_in;
                flag <= 1'b1;                
                case (mem_req_type)
                    `mem_LB : begin
                        r_w <= 1'b0;
                        countdown <= 3'b001;
                        output_length <= 3'b001;
                    end
                    `mem_LH : begin
                        r_w <= 1'b0;
                        countdown <= 3'b010;
                        output_length <= 3'b010;
                    end
                    `mem_LW : begin
                        r_w <= 1'b0;
                        countdown <= 3'b011;
                        output_length <= 3'b011;
                    end
                    `mem_SB : begin
                        r_w <= 1'b1;
                        countdown <= 3'b001;
                        output_length <= 3'b001;
                    end
                    `mem_SH : begin
                        r_w <= 1'b1;
                        countdown <= 3'b010;
                        output_length <= 3'b010;
                    end
                    `mem_SW : begin
                        r_w <= 1'b1;
                        countdown <= 3'b011;
                        output_length <= 3'b011;
                    end
                    default : begin
                        busy <= 1'b0;           
                        addr_now <= 0;
                        countdown <= 0;
                        output_length <= 0;  
                    end
                endcase 
            end else if (if_req_in) begin
                busy <= 1'b1;
                addr_now <= addr_if_in;
                flag <= 1'b1;
                countdown <= 3'b011;
                output_length <= 3'b011;
            end else begin
                output_data <= `ZeroWord;
            end
            
        end else begin
            if (countdown == 0) begin
                busy <= 1'b0;
                if (r_w == 1'b1) begin
                    // finished write
                    r_w <= 0;
                    mmem_data <= `ZeroWord;
                end else begin
                    // finished read
                    //output_data <= output_data >> (6'b000100 - re_length) << 3;
                    r_w <= 0; 
                end
            end else begin
                if (r_w == 1'b0) begin
                    output_data = output_data >> 8;
                    output_data[31:24] = data_get;
                end else begin
                    mmem_data = data_writing[7:0];
                    data_writing = data_writing >> 8;
                    flag <= 1'b0;
                end 
                countdown <= countdown - 1'b1;
                addr_now <= (flag) ? addr_now : addr_now + 1'b1;
            end
        end
    end
             
end
    
endmodule
