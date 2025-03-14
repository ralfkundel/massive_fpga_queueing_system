///////////////////////////////////////////////////////////
//
// Function : AXI Slave BlockRAM
//		with the delay parameters different ddr3 delays can be simulated
// Created  : 15.04.2016
//
// Authors  : Sven Himer (sven.himer@gmail.com)
// Notes    : Ralf Kundel (ralf.kundel@kom.tu-darmstadt.de)
//
///////////////////////////////////////////////////////////
`timescale 1ps / 1ps
//`default_nettype none
module dc_bram_rw #(
	parameter [63:0] mem_depth_p = 1024*128,
	parameter mem_initfile_p = "",
	parameter init_mem_on_start = 0,
	parameter address_delay_time_p = 2,
	parameter data_delay_time_read_p = 2,
	parameter data_delay_time_write_p = 2,
	parameter p_wait_counter = 30, //TODO
	parameter ADDR_WIDTH = 0, //$clog2(mem_depth_p),
    parameter AXI_ID_WIDTH = 4,
    parameter AXI_DATA_WIDTH = 32
) (
	input wire clk_i,
	input wire rst_i,
	input wire init_dc_bram_i,
	// WRITE ADDRESS
    input wire [AXI_ID_WIDTH-1:0] AXI_AWID,
    input wire [ADDR_WIDTH-1 : 0] AXI_AWADDR,
    input wire [7 : 0] AXI_AWLEN,
    input wire [2 : 0] AXI_AWSIZE,
    input wire [1 : 0] AXI_AWBURST,
    input wire AXI_AWLOCK,
    input wire [3 : 0] AXI_AWCACHE,
    input wire [2 : 0] AXI_AWPROT,
    input wire [3 : 0] AXI_AWQOS,
    input wire AXI_AWVALID,
    output reg AXI_AWREADY,
	// Write Data
    input wire [AXI_DATA_WIDTH-1 : 0] AXI_WDATA,
    input wire [AXI_DATA_WIDTH/8 : 0] AXI_WSTRB, //TODO unused
    input wire AXI_WLAST,
    input wire AXI_WVALID,
    output reg AXI_WREADY,
	// B Thing
    output wire [AXI_ID_WIDTH-1:0] AXI_BID,
    output wire [1 : 0] AXI_BRESP,
    output reg AXI_BVALID,
    input wire AXI_BREADY,
    
	// Read ADDR
    input wire [AXI_ID_WIDTH-1:0] AXI_ARID,
    input wire [ADDR_WIDTH-1: 0] AXI_ARADDR,
    input wire [7 : 0] AXI_ARLEN,
    input wire [2 : 0] AXI_ARSIZE,
    input wire [1 : 0] AXI_ARBURST,
    input wire AXI_ARLOCK,
    input wire [3 : 0] AXI_ARCACHE,
    input wire [2 : 0] AXI_ARPROT,
    input wire [3 : 0] AXI_ARQOS,
    input wire AXI_ARVALID,
    output reg AXI_ARREADY,
	// WRITE ADDR
    output wire [AXI_ID_WIDTH-1:0] AXI_RID,
    output reg [AXI_DATA_WIDTH-1 : 0] AXI_RDATA,
    output wire [1 : 0] AXI_RRESP,
    output reg AXI_RLAST,
    output reg AXI_RVALID,
    input wire AXI_RREADY
);
assign init_dc_bram_i = 0;
localparam p_axi_address_align_bits = $clog2(AXI_DATA_WIDTH/8); //Cut of bits for address computation

	assign AXI_BRESP = 0;
	assign AXI_RRESP = 0;

reg [AXI_ID_WIDTH-1:0] M00_AXI_bid_r;
reg [AXI_ID_WIDTH-1:0] M00_AXI_rid_r;

assign AXI_BID = M00_AXI_bid_r;
assign AXI_RID = M00_AXI_rid_r;

always @(posedge clk_i)
begin
	if (AXI_ARVALID && AXI_ARREADY) begin
		M00_AXI_rid_r <= AXI_ARID;
	end
	if (AXI_AWVALID && AXI_AWREADY) begin
		M00_AXI_bid_r <= AXI_AWID;
	end
end

	// Idle
	localparam lp_state_idle_read = 0;
	localparam lp_state_idle_write = 0;
	// Read States
	localparam lp_state_ar_ack = 1;
	localparam lp_state_read = 2;
	localparam lp_state_wait_read = 3;
	// Write States
	localparam lp_state_aw_ack = 4;
	localparam lp_state_wait_write = 5;
	localparam lp_state_write_ack = 6;
	localparam lp_state_write_wait_ack = 7;
	localparam lp_state_write_wait_test = 8;


	reg [3:0] curr_state_read;
	reg [3:0] next_state_read;
	
	reg [3:0] curr_state_write;
	reg [3:0] next_state_write;
	
	reg [ADDR_WIDTH-1:0] addr_reg_read;
	reg [31:0] len_reg_read;
	reg [31:0] len_ct_reg_read;

	reg [ADDR_WIDTH-1:0] addr_reg_write;
	reg [31:0] len_reg_write;
	reg [31:0] len_ct_reg_write;

	// Steuersignale
	reg mem_we;
	reg inc_ct_read;
	reg inc_ct_write;	

	reg [15:0] counter_read;	
	reg incrcounter_read;	
	reg [15:0] counter_write;	
	reg incrcounter_write;	

	reg incr_wait_counter;
	reg [15:0] wait_counter;

	reg [15:0] wr_wait_counter;
	reg incr_wr_wait_counter;

	always @(posedge clk_i) begin
		if(rst_i) begin
			curr_state_read <= lp_state_idle_read;
			curr_state_write <= lp_state_idle_write;
			addr_reg_read <= 0;
			len_reg_read <= 0;
			len_ct_reg_read <= 0;
			addr_reg_write <= 0;
			len_reg_write <= 0;
			len_ct_reg_write <= 0;
			counter_read <= 0;
			wait_counter <= 0;
			wr_wait_counter <= 0;
		end else begin
			if(incr_wait_counter) begin
				wait_counter <= wait_counter + 1;
			end else begin
				wait_counter <= 0;
			end
			
			if(incr_wr_wait_counter) begin
				wr_wait_counter <= wr_wait_counter + 1;
			end else begin
				wr_wait_counter <= 0;
			end
	
			if(incrcounter_read) begin
				counter_read <= counter_read + 1;
			end else begin
				counter_read <= 0;
			end
			if(incrcounter_write) begin
				counter_write <= counter_write + 1;
			end else begin
				counter_write <= 0;
			end
			// State Transition
			curr_state_read <= next_state_read;
			curr_state_write <= next_state_write;
			// Address Save Register (Read)
			if (curr_state_read == lp_state_idle_read) begin
				len_ct_reg_read <= 0; 
				if (AXI_ARVALID) begin
					addr_reg_read <= AXI_ARADDR;
					len_reg_read <= AXI_ARLEN;
				end
			end else begin
				// Position Register (Read)
				if (inc_ct_read == 1'b1) begin
					len_ct_reg_read <= len_ct_reg_read + 1'b1;
				end
			end	
			// Address Save Register (Write)
			if (curr_state_write == lp_state_idle_write) begin
				len_ct_reg_write <= 0; 
				if (AXI_AWVALID) begin
					addr_reg_write <= AXI_AWADDR;
					len_reg_write <= AXI_AWLEN;
				end
			end else begin
				// Position Register (Write)
				if (inc_ct_write == 1'b1) begin
					len_ct_reg_write <= len_ct_reg_write + 1'b1;
				end
			end				
		end
	end

	always @(*) begin
		next_state_read = lp_state_idle_read;
		inc_ct_read = 0;
		AXI_ARREADY = 0;
		AXI_RVALID = 0;
		AXI_RLAST = 1'b1;
		incrcounter_read = 0;
		incr_wait_counter = 0;
		case (curr_state_read) 
			lp_state_idle_read : begin
				// Set Read Adress and Size
				if (AXI_ARVALID) begin
					incrcounter_read = 1;
					if(counter_read == address_delay_time_p) begin
						next_state_read = lp_state_ar_ack;
						incrcounter_read = 0;
						AXI_ARREADY = 1;
					end
				end
			end
			lp_state_ar_ack: begin
				next_state_read = lp_state_ar_ack;
				if (AXI_RREADY) begin
					incrcounter_read = 1;
					if(counter_read == data_delay_time_read_p) begin
						next_state_read = lp_state_read;
					end
				end
			end
			lp_state_read: begin
				next_state_read = lp_state_read;
				incr_wait_counter = 1;
				AXI_RVALID = 1'b1;
				AXI_RLAST = 1'b0;
				if(wait_counter == p_wait_counter) begin
					next_state_read = lp_state_wait_read;
					incr_wait_counter = 0;
				end
				if (AXI_RREADY) begin
					inc_ct_read = 1'b1;
					if (len_reg_read == len_ct_reg_read) begin
						AXI_RLAST = 1'b1;
						next_state_read = lp_state_idle_read;
					end 
				end
			end		
			lp_state_wait_read: begin
                AXI_RLAST = 1'b0;
				incr_wait_counter = 1;
				if(wait_counter == p_wait_counter)
					next_state_read = lp_state_read;
				else
					next_state_read = lp_state_wait_read;
			end	
			default: begin
				next_state_read = lp_state_idle_read;
			end
		endcase
	end 
	
	// State Transition Write
	always @(*) begin
		next_state_write = lp_state_idle_write;
		mem_we = 0;
		inc_ct_write = 0;
		AXI_WREADY = 0;
		AXI_BVALID = 0;
		AXI_AWREADY = 0;
		incrcounter_write = 0;
		incr_wr_wait_counter = 0;
		case (curr_state_write) 
			lp_state_idle_write : begin
				// Set Write Adress and Size
				if (AXI_AWVALID) begin
					incrcounter_write = 1;
					if(counter_write == address_delay_time_p) begin
						next_state_write = lp_state_aw_ack;
						incrcounter_write = 0;
						AXI_AWREADY = 1;
					end
				end
			end
			lp_state_aw_ack: begin
				next_state_write = lp_state_aw_ack;
				if (AXI_WVALID) begin
					incrcounter_write = 1;
					if(counter_write == data_delay_time_write_p) begin
						next_state_write = lp_state_wait_write;
					end
				end
			end			
			lp_state_wait_write: begin
				incr_wr_wait_counter = 1;
				next_state_write = lp_state_wait_write;
				if(wr_wait_counter == p_wait_counter) begin
						next_state_write = lp_state_write_wait_test;
						incr_wr_wait_counter = 0;
				end

				
				AXI_WREADY = 1;				
				if (AXI_WVALID) begin
					mem_we = 1'b1;
					inc_ct_write = 1'b1;
					if (AXI_WLAST) begin
						next_state_write = lp_state_write_ack;
					end
				end
				
				


			end			
			lp_state_write_ack: begin
				AXI_BVALID = 1;
				next_state_write = lp_state_write_ack;
				if (AXI_BREADY) begin
					next_state_write = lp_state_idle_write;					
				end
			end		

			lp_state_write_wait_test : begin
				incr_wr_wait_counter = 1;
				if(wr_wait_counter == p_wait_counter)
					next_state_write = lp_state_wait_write;
				else
					next_state_write = lp_state_write_wait_test;
			end
					
			default: begin
				next_state_write = lp_state_idle_write;
			end
		endcase
	end 	
	
	wire [ADDR_WIDTH-1:0] mem_addr_write;
	assign mem_addr_write = addr_reg_write[ADDR_WIDTH-1:p_axi_address_align_bits] + ((inc_ct_write & ~mem_we) ? (len_ct_reg_write + 1) : len_ct_reg_write);
	
	wire [ADDR_WIDTH-1:0] mem_addr_read;
	assign mem_addr_read = addr_reg_read[ADDR_WIDTH-1:p_axi_address_align_bits] + ((inc_ct_read) ? (len_ct_reg_read + 1) : len_ct_reg_read);

	// Memory
	reg [AXI_DATA_WIDTH-1:0] mem [0:(mem_depth_p-1)];

	integer i;
	initial begin
	   if(init_mem_on_start)
		  set_mem(mem_initfile_p);
	end

	always @(*) 
		if(init_dc_bram_i)
			set_mem(mem_initfile_p);

	task set_mem;
		input filename;
		reg [30*8-1:0] filename;
		begin
			// Init Mem
			for (i = 0; i < mem_depth_p; i = i + 1) begin
				mem[i] = {(AXI_DATA_WIDTH){1'b0}};
			end
			$display("set_mem");
			$readmemb(filename, mem);
		end
	endtask


	
	// Read Port
	always @(posedge clk_i) begin
		AXI_RDATA <= mem[mem_addr_read];
	end 

	// Write Port
	always @(posedge clk_i) begin
		if (mem_we) begin
		      $display("write bram address: %h \t data: %h", mem_addr_write, AXI_WDATA);
			mem[mem_addr_write] <= AXI_WDATA;
			$display("after: %h", mem[mem_addr_write]);
		end 
	end 			
	
endmodule
