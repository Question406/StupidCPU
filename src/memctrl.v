`include "defines.v"

module memctrl(
    input wire clk,
    input wire rst,
    
    // memory request from if
    input wire if_req_in, // equal to lw
    input wire [`RegBus] addr_if_in,
    
    input wire inst_flush,
    
    // memory request from mem
    input wire mem_req_in,
    input wire [`RegBus] addr_mem_in,
    input wire [`RegBus] data_mem_in,
    input wire [3:0] mem_req_type, // lb, lh, lw, sb, sh, sw
    
    // response to if (send inst to if_id)
    output reg get_inst,
    output reg [`InstAddrBus] output_pc, 
    output reg [`InstBus] output_inst,
        
    // response to mem
    output reg ls_done,
    output reg [`RegBus] output_data,
    
//    output reg [`RegBus] output_pc,
//    output reg [  `RegBus] output_data, // data get from main memory

    output wire mem_busy, // tell if && mem whether could send request 
    
    // connect to main memory
    input wire [7:0] data_get,
    
    output wire mmem_r_w, // main memory read or write
    output wire [`RegBus] mmem_addr, // addr needed in main memory
    output reg [7:0] mmem_data // data needed to be stored in main memory
);

    localparam 
        IF_0 = 4'b0001,
        IF_1 = 4'b0010,
        IF_2 = 4'b0011,
        IF_3 = 4'b0100;
        

reg if_mem; // ATTENTION: 0 for if, 1 for mem
reg busy;
reg r_w; // read or write, 0 for read 1 for write
reg [2:0] countdown; // still need several cycle to finish read or write
reg [2:0] output_length;
reg[`RegBus] addr_now;
reg[`RegBus] data_writing;
reg flag;

    assign mem_busy = busy;
    assign mmem_addr = addr_now;
    assign mmem_r_w = r_w;

always @ (posedge clk) begin
    //busy <= (busy || mem_req_in || if_req_in) ? 1 : 0;
    busy <= (busy || if_req_in) ? 1 : 0;
    
    if (rst) begin
        output_data <= `ZeroWord;
        addr_now <= `ZeroWord;
        r_w <= 1'b0;
        countdown <= 3'b000;
        output_length <= 3'b000;
        flag <= 1'b0;
        mmem_data <= 8'b0;
        get_inst <= 0;
        output_pc <= `ZeroWord;
        output_inst <= `ZeroWord;
        busy <= 0;
        ls_done <= 0;
    end
    else begin
        if (~busy) begin
            ls_done <= 0;
            
            if (mem_req_in) begin
                if_mem <= 1'b1;
                busy <= 1'b1;
                addr_now <= addr_mem_in;
                flag <= 1'b1;           
                data_writing <= data_mem_in; 
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
                    `mem_LBU : begin
                        r_w <= 1'b0;
                        countdown <= 3'b010;
                        output_length <= 3'b010;
                    end
                    `mem_LHU : begin
                        countdown <= 3'b010;
                        output_length <= 3'b010;
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
                        data_writing <= `ZeroWord;
                    end
                endcase 
            end else if (if_req_in) begin
                if_mem <= 1'b0;
                get_inst <= 1'b0;
                output_pc <= addr_if_in;
                output_inst <= `ZeroWord;
                busy <= 1'b1;
                addr_now <= addr_if_in;
                //flag <= 1'b1;
                r_w <= 0;
                countdown <= 3'b100;
                output_length <= 3'b100;
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
                        ls_done <= 1;
                    end else begin
                        // finished read
                        if (if_mem == 0) begin
                            get_inst <= 1'b1;
                            // output_inst = (output_data >> ((6'b000100 - output_length) << 3));
                            output_data = output_data >> 8;
                            output_data[31:24] = data_get;
                            output_inst <= output_data ;
                            //output_data = (output_data >> ((6'b000100 - output_length) << 3));
                            r_w <= 0;
                        end else begin
                            ls_done <= 1;
                            output_data <= (output_data >> ((6'b000100 - countdown) << 3));
                        end
                    end
                    end else begin
                        if(r_w == 1'b0) begin
                            output_data = output_data >> 8;
                            output_data[31:24] = data_get;
                        end else begin
                            mmem_data = data_writing[7:0];
                            data_writing = data_writing >> 8;
                            flag <= 1'b0;
                        end 
                        countdown <= countdown - 1'b1;
                        addr_now <= addr_now + 1'b1;
                    end
        end
    end    
end

always @(inst_flush) begin
    if (inst_flush == 1) begin
        if (busy && if_mem == 0) begin
            if_mem <= 0;
            output_data <= `ZeroWord;
            addr_now <= `ZeroWord;
            r_w <= 1'b0;
            countdown <= 3'b000;
            output_length <= 3'b000;
            flag <= 1'b0;
            mmem_data <= 8'b0;
            get_inst <= 0;
            output_pc <= `ZeroWord;
            output_inst <= `ZeroWord;
            busy <= 0;
        end
    end
end
endmodule