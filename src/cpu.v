// RISCV32I CPU top module
// port modification allowed for debugging purposes

//`include "D:\\ComputerSystem\\Stupid_CPU\\Stupid_CPU.srcs\\sources_1\\new\\defines.v"
`include "I:\\518030910421\\src\\defines.v"
//`include "defines.v"

module cpu(
    input  wire                 clk_in,			// system clock signal
    input  wire                 rst_in,			// reset signal
    input  wire					        rdy_in,			// ready signal, pause cpu when low

    input  wire [ 7:0]          mem_din,		// data input bus
    output wire [ 7:0]          mem_dout,		// data output bus
    output wire [31:0]          mem_a,			// address bus (only 17:0 is used)
    output wire                 mem_wr,			// write/read signal (1 for write)

	output wire [31:0]			dbgreg_dout		// cpu register output (debugging demo)
);

// implementation goes here

// Specifications:
// - Pause cpu(freeze pc, registers, etc.) when rdy_in is low
// - Memory read takes 2 cycles(wait till next cycle), write takes 1 cycle(no need to wait)
// - Memory is of size 128KB, with valid address ranging from 0x0 to 0x20000
// - I/O port is mapped to address higher than 0x30000 (mem_a[17:16]==2'b11)
// - 0x30000 read: read a byte from input
// - 0x30000 write: write a byte to output (write 0x00 is ignored)
// - 0x30004 read: read clocks passed since cpu starts (in dword, 4 bytes)
// - 0x30004 write: indicates program stop (will output '\0' through uart tx)

    wire[`InstAddrBus] pc;
    wire[`InstAddrBus] if_id_pc; 
    
    wire[`InstAddrBus] id_pc_i;
    wire[`InstBus] id_inst_i;
    
    wire[`AluOpBus] id_aluop_o;
    wire[`AluSelBus] id_alusel_o;
    wire[`RegBus] id_reg1_o;
    wire[`RegBus] id_reg2_o;
    wire id_wreg_o;
    wire[`RegAddrBus] id_wd_o;
    
    wire[`AluOpBus] ex_aluop_i;
    wire[`AluSelBus] ex_alusel_i;
    wire[`RegBus] ex_reg1_i;
    wire[`RegBus] ex_reg2_i;
    wire ex_wreg_i;
    wire[`RegAddrBus] ex_wd_i;
    
    wire ex_wreg_o;
    wire[`RegAddrBus] ex_wd_o;
    wire[`RegBus] ex_wdata_o;
    
    wire mem_wreg_i;
    wire[`RegAddrBus] mem_wd_i;
    wire[`RegBus] mem_wdata_i;
    
    wire mem_wreg_o;
    wire[`RegAddrBus] mem_wd_o;
    wire[`RegBus] mem_wdata_o;
    
    wire wb_wreg_i;
    wire[`RegAddrBus] wb_wd_i;
    wire[`RegBus] wb_wdata_i;
    
    wire reg1_read;
    wire reg2_read;
    wire[`RegBus] reg1_data;
    wire[`RegBus] reg2_data;
    wire[`RegAddrBus] reg1_addr;
    wire[`RegAddrBus] reg2_addr;
    
    wire set_pc;
    wire [`RegBus] set_pc_addr;

wire if_req;
wire [`InstAddrBus] addr_if;
wire mem_busy;

wire [`InstBus] if_inst;
wire [`InstAddrBus] if_pc;

wire ex_forwarding_wd;
wire[`RegBus] ex_forwarding_data;
wire[`RegAddrBus] ex_forwarding_rd;

wire [5:0] stall;

wire mem_stall_req;
wire id_stall_req;

wire inst_flush;

wire stop_stall;

stall_controller stall_controller0(
    .stall(stall),
    .rst(rst_in),
    .stop_stall(stop_stall),
    .id_req(id_stall_req),
    .mem_req(mem_stall_req) 
);
    
wire [7:0] output_data;

wire mmem_req;
wire [`RegBus] addr_mem;
wire [7:0] data_mem;
wire [3:0] mem_req_type;

wire mem_take_if;

wire [7:0] mem_inst_factor;

wire get_inst;
wire [`RegBus] if_req_addr;
wire mem_req_r_w;

memctrl memctrl0(
    .clk(clk_in), .rst(rst_in),
    .if_req_in(if_req), .addr_if_in(if_req_addr),

    .mem_req_in(mmem_req), 
    .addr_mem_in(addr_mem), 
    .data_mem_in(data_mem), 
    .mem_req_r_w(mem_req_r_w),
    
    .data_get(mem_din), .mmem_r_w(mem_wr), .mmem_addr(mem_a), .mmem_data(mem_dout),

    .output_data(output_data),

    .inst_factor_o(mem_inst_factor)
);

// for cache
wire cache_enable;
wire [`InstAddrBus] inst_cache_addr;
wire [`InstBus] inst_cache;

wire inst_hit;
wire [`InstBus] inst_hit_cache;

wire cache_query;
wire [`InstAddrBus] cache_query_addr;


pc_reg pc_reg0(
    .clk(clk_in), .rst(rst_in),

    .stall(stall),
    
    .mem_inst_factor_i(mem_inst_factor),
    
    .pc_memreq(if_req), .if_addr_req_o(if_req_addr),
    
    .get_inst(get_inst), .if_pc_o(addr_if), .if_inst_o(if_inst),

    .set_pc_i(set_pc), .set_pc_add_i(set_pc_addr),

    .cache_enable(cache_enable), 
    .inst_cache_addr_o(inst_cache_addr), 
    .inst_cache_o(inst_cache),

    .cache_query(cache_query), .query_addr(cache_query_addr),
    .inst_hit(inst_hit), .cache_inst_i(inst_hit_cache)
);

inst_cache instcache0(
    .rst(rst_in),

    .cache_query(cache_query), .query_addr(cache_query_addr),

    .cache_enable(cache_enable), .inst_addr(inst_cache_addr), .inst_cache_i(inst_cache),

    .inst_hit_o(inst_hit), .inst_cache_o(inst_hit_cache)
);


wire if_idflush;
wire id_exflush;

if_id if_id0(
    .clk(clk_in), .rst(rst_in),

    .stall(stall),

    .get_inst(get_inst), .if_pc(addr_if), .if_inst(if_inst),

    .id_pc(id_pc_i), .if_idflush_i(if_idflush),
    .id_inst(id_inst_i)
);

    wire [`RegBus] imm;
    wire [`RegBus] imm_ex;
    
    wire [`RegBus] id_ex_pc;

id id0(
    .rst(rst_in), .pc_i(id_pc_i), .inst_i(id_inst_i),
    .reg1_data_i(reg1_data), .reg2_data_i(reg2_data),
    .reg1_read_o(reg1_read), .reg2_read_o(reg2_read),
    .reg1_addr_o(reg1_addr), .reg2_addr_o(reg2_addr),

    .ex_wreg_i(ex_wreg_o),
    .ex_wdata_i(ex_wdata_o),
    .ex_wd_i(ex_wd_o),

    .mem_wreg_i(mem_wreg),
    .mem_wdata_i(mem_wdata),
    .mem_wd_i(mem_wd),

    .id_stall_req(id_stall_req),
    
    .aluop_o(id_aluop_o), .alusel_o(id_alusel_o),
    .reg1_o(id_reg1_o), .reg2_o(id_reg2_o),
    .id_pc_o(id_ex_pc),
    .imm_o(imm),
    .wd_o(id_wd_o), .wreg_o(id_wreg_o)       
);

regfile regfile1(
    .clk(clk_in), .rst(rst_in),
    .we(wb_wreg_i), .waddr(wb_wd_i),
    .wdata(wb_wdata_i), .re1(reg1_read),
    .raddr1(reg1_addr), .rdata1(reg1_data),
        
    .re2(reg2_read), .raddr2(reg2_addr),
    .rdata2(reg2_data)
);

wire [`RegBus] ex_pc;

    id_ex id_ex0(
        .clk(clk_in), .rst(rst_in),
        .stall(stall),

        .id_pc(id_ex_pc),
        .id_aluop(id_aluop_o), .id_alusel(id_alusel_o),
        .id_reg1(id_reg1_o), .id_reg2(id_reg2_o),
        .imm_i(imm),
        .id_wd(id_wd_o), .id_wreg(id_wreg_o),
        
        .id_exflush_i(id_exflush),

        .ex_pc(ex_pc),
        .ex_aluop(ex_aluop_i), .ex_alusel(ex_alusel_i),
        .ex_reg1(ex_reg1_i), .ex_reg2(ex_reg2_i), .imm_o(imm_ex),
        .ex_wd(ex_wd_i), .ex_wreg(ex_wreg_i)
    );

    wire[`AluSelBus] mem_op_type;
    wire [`RegBus] mmem_data;
    
    ex ex0(
        .rst(rst_in),
        .pc_i(ex_pc),

        .aluop_i(ex_aluop_i), .alusel_i(ex_alusel_i),
        .reg1_i(ex_reg1_i),  .reg2_i(ex_reg2_i),
        .imm_i(imm_ex),
        .wd_i(ex_wd_i), .wreg_i(ex_wreg_i),
        
        .if_idflush_o(if_idflush), .id_exflush_o(id_exflush),
        .inst_flush(inst_flush),
        
        .set_pc_o(set_pc), .pc_addr_o(set_pc_addr), 
        
        .wd_o(ex_wd_o), .wreg_o(ex_wreg_o),
        .wdata_o(ex_wdata_o),

        .mem_w_data(mmem_data), .mem_op_type(mem_op_type)

        // .ex_forwarding_wd(ex_forwarding_wd), 
        // .ex_forwarding_rd(ex_forwarding_rd), 
        // .ex_forwarding_data(ex_forwarding_data)
    );
    
    wire[`AluSelBus] mem_op;
    wire [`RegBus] to_mem_data;

    ex_mem ex_mem0(
        .clk(clk_in), .rst(rst_in),

        .stall(stall),

        .ex_wd(ex_wd_o), .ex_wreg(ex_wreg_o),
        .ex_wdata(ex_wdata_o),
        .mmem_data_i(mmem_data), .mem_op_type_i(mem_op_type),

        .mem_wd(mem_wd_i),  .mem_wreg(mem_wreg_i),
        .mem_wdata(mem_wdata_i), 
        .mmem_data_o(to_mem_data), .mem_op_type_o(mem_op)
    );
    
    wire need_wait;

    mem mem0(
        .clk(clk_in),
        .rst(rst_in),
        .wd_i(mem_wd_i), .wreg_i(mem_wreg_i),
        .wdata_i(mem_wdata_i),

        .mem_w_data_i(to_mem_data), .mem_op_type_i(mem_op),

        .memctrl_data_in(output_data),

        .mem_stall_req(mem_stall_req),

        .mem_req(mmem_req), .mem_req_addr(addr_mem), .mem_req_data(data_mem), .mem_r_w(mem_req_r_w),

        .wd_o(mem_wd_o), .wreg_o(mem_wreg_o),
        .wdata_o(mem_wdata_o)
    );    

    mem_wb mem_wb0(
        .clk(clk_in),  .rst(rst_in),

        .stall(stall),
        
        .stop_stall(stop_stall),

        .mem_wd(mem_wd_o), .mem_wreg(mem_wreg_o),
        .mem_wdata(mem_wdata_o),
        
        .wb_wd(wb_wd_i), .wb_wreg(wb_wreg_i),
        .wb_wdata(wb_wdata_i)
    );


always @(posedge clk_in)
    begin
    if (rst_in)
        begin
        
        end
    else if (!rdy_in)
        begin
        
        end
    else
        begin

        end
end

endmodule