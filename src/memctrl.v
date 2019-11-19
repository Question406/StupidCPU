`include "defines.v"

module memctrl(
    input wire clk,
    input wire rst,
    
    // memory request from if
    input wire if_req_in,
    input wire [`InstAddrBus] addr_if_in,
    
    // memory request from mem
    input wire mem_req_in,
    input wire mem_req_r_w,
    input wire [`RegBus] addr_mem_in,
    input wire [7:0] data_mem_in,
    
    // response to if (send inst to if_id)
    output reg [7:0] inst_factor_o,

    // response to mem
    output reg [7:0] output_data,
    
    output wire mem_busy, // tell if && mem whether could send request
    
    output reg mem_take_if, 
    
    // connect to main memory
    input wire [7:0] data_get,
    output reg mmem_r_w, // main memory read or write
    output reg [`RegBus] mmem_addr, // addr needed in main memory
    output reg [7:0] mmem_data // data needed to be stored in main memory
);

reg if_mem;

always @ (*) begin
    if (rst) begin
        mmem_r_w <= 0;
        mmem_addr <= 0;
        mmem_data <= 0;
        if_mem <= 0;
    end
    else begin
        mmem_r_w <= 0;
        mmem_addr <= `ZeroWord;
        mmem_data <= `ZeroWord;
        if (mem_req_in) begin
            if_mem <= 1;
            mmem_r_w <= mem_req_r_w;
            mmem_addr <= addr_mem_in;
            mmem_data <= data_mem_in;
        end else if (if_req_in) begin
            mmem_r_w <= 0;
            mmem_addr <= addr_if_in;
            if_mem <= 0;
        end else begin

        end
    end
end

always @(data_get) begin
    if (if_mem == 1) begin
        output_data <= data_get;
    end else if (if_mem == 0) begin
        //$display("get_data : ", data_get);
        inst_factor_o <= data_get;
    end
end 

endmodule