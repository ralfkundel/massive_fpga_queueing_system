///////////////////////////////////////////////////////////
//
// Project  : AMIDAR
// Function : AXI Slave BlockRAM
// File     : cdbram.v
// Created  : 15.04.2016
//
// Author   : Sven Himer (sven.himer@gmail.com)
// Notes    : 4 Spaces = 1 Tab
//
///////////////////////////////////////////////////////////
`timescale 1ps / 1ps
`default_nettype none
`include "AXI_definitions.vh" 
module cdbram #(
	parameter mem_depth_p = 1024*128,
	parameter mem_initfile_p = "",
	parameter ADDR_WIDTH = $clog2(mem_depth_p)
) (
	input wire clk_i,
	input wire rst_i,
	// WRITE ADDRESS
    input wire [`AXI_ID_WIDTH-1:0] AXI_AWID,
    input wire [31 : 0] AXI_AWADDR,
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
    input wire [31 : 0] AXI_WDATA,
    input wire [3 : 0] AXI_WSTRB,
    input wire AXI_WLAST,
    input wire AXI_WVALID,
    output reg AXI_WREADY,
	// B Thing
    output wire [`AXI_ID_WIDTH-1:0] AXI_BID,
    output wire [1 : 0] AXI_BRESP,
    output reg AXI_BVALID,
    input wire AXI_BREADY,
	// Read ADDR
    input wire [`AXI_ID_WIDTH-1:0] AXI_ARID,
    input wire [31 : 0] AXI_ARADDR,
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
    output wire [`AXI_ID_WIDTH-1:0] AXI_RID,
    output wire [31 : 0] AXI_RDATA,
    output wire [1 : 0] AXI_RRESP,
    output reg AXI_RLAST,
    output reg AXI_RVALID,
    input wire AXI_RREADY
);

reg [`AXI_ID_WIDTH-1:0] AXI_bid_r;
reg [`AXI_ID_WIDTH-1:0] AXI_rid_r;

assign AXI_BID = AXI_bid_r;
assign AXI_RID = AXI_rid_r;

always @(posedge clk_i)
begin
	if (AXI_ARVALID) begin
		AXI_rid_r <= AXI_ARID;
	end
	if (AXI_AWVALID) begin
		AXI_bid_r <= AXI_AWID;
	end
end

//TODO: for read only:
/*
reg [`AXI_ID_WIDTH-1:0] AXI_rid_r;

assign AXI_BID = 0;
assign AXI_RID = AXI_rid_r;

always @(posedge clk_i)
begin
	if (AXI_ARVALID) begin
		AXI_rid_r <= AXI_ARID;
	end
end
*/

	assign AXI_BRESP = 0;
	assign AXI_RRESP = 0;

/*
	// Write ADDr
    input wire [31 : 0] AXI_AWADDR,
    input wire [7 : 0] AXI_AWLEN,
    input wire AXI_AWVALID,
    output wire AXI_AWREADY,
	// Write Data
    input wire [31 : 0] AXI_WDATA,
    input wire [3 : 0] AXI_WSTRB,
    input wire AXI_WLAST,
    input wire AXI_WVALID,
    output wire AXI_WREADY,
	// B Thing
    output wire [3 : 0] AXI_BID,
    output wire [1 : 0] AXI_BRESP,
    output wire AXI_BVALID,
    input wire AXI_BREADY,
	// Read ADDR
    input wire [31 : 0] AXI_ARADDR,
    input wire [7 : 0] AXI_ARLEN,
    input wire AXI_ARVALID,
    output wire AXI_ARREADY,
	// Read Data
    output wire [31 : 0] AXI_RDATA,
    output wire [1 : 0] AXI_RRESP,
    output wire AXI_RLAST,
    output wire AXI_RVALID,
    input wire AXI_RREADY
*/

	localparam lp_state_idle = 0;
	localparam lp_state_ar_ack = 1;
	localparam lp_state_read = 2;
	localparam lp_state_wait_read = 3;
	localparam lp_state_aw_ack = 4;
	localparam lp_state_wait_write = 5;
	localparam lp_state_write_ack = 6;
	localparam lp_state_write_wait_ack = 7;
	
	reg [3:0] curr_state;
	reg [7:0] next_state;
	
	reg [31:0] addr_reg;
	reg [31:0] len_reg;
	reg [31:0] len_ct_reg;

	reg mem_we;
	reg inc_ct;
	

	always @(posedge clk_i) begin
		if(rst_i) begin
			curr_state <= lp_state_idle;
			addr_reg <= 0;
			len_ct_reg <= 0;
		end else begin
			// State Transition
			curr_state <= next_state;
			// Address Save Register
			if (curr_state == lp_state_idle) begin
				len_ct_reg <= 0; 
				if (AXI_ARVALID) begin
					addr_reg <= AXI_ARADDR;
					len_reg <= AXI_ARLEN;
				end	else if (AXI_AWVALID) begin
					addr_reg <= AXI_AWADDR;
					len_reg <= AXI_AWLEN;
				end
			end else begin
				// Position Register
				if (inc_ct == 1'b1) begin
					len_ct_reg <= len_ct_reg + 1'b1;
				end
			end		
		end
	end
		
	always @(*) begin
		next_state = lp_state_idle;
		mem_we = 0;
		inc_ct = 0;
		AXI_ARREADY = 0;
		AXI_RVALID = 0;
		AXI_RLAST = 0;
		AXI_WREADY = 0;
		AXI_BVALID = 0;
		AXI_AWREADY = 0;
		case (curr_state) 
			lp_state_idle : begin
				// Set Read Adress and Size
				if (AXI_ARVALID) begin
					next_state = lp_state_ar_ack;
				end else if (AXI_AWVALID) begin
					next_state = lp_state_aw_ack;
				end
			end
			lp_state_ar_ack: begin
//				$display("ACK READ");
				AXI_ARREADY = 1;
				if (AXI_ARVALID) begin
					next_state = lp_state_read;
				end else begin
					next_state = lp_state_ar_ack;
				end
			end

			lp_state_read: begin
//				$display("READ");
				next_state = lp_state_read;
				AXI_RVALID = 1'b1;
				if (AXI_RREADY) begin
					inc_ct = 1'b1;
					if (len_reg == len_ct_reg) begin
						AXI_RLAST = 1;
//						$display("LAST READ");
						next_state = lp_state_idle;
					end 
				end
			end
			
			lp_state_aw_ack: begin
				AXI_AWREADY = 1;
				if (AXI_AWVALID) begin
					next_state = lp_state_wait_write;
				end else begin
					next_state = lp_state_aw_ack;
				end
			end
			
			lp_state_wait_write: begin
				next_state = lp_state_wait_write;
				AXI_WREADY = 1;
				if (AXI_WVALID) begin
					mem_we = 1'b1;
					inc_ct = 1'b1;
					if (AXI_WLAST) begin
						next_state = lp_state_write_ack;
					end
				end
			end
			
			lp_state_write_ack: begin
				AXI_BVALID = 1;
				next_state = lp_state_write_ack;
				if (AXI_BREADY) begin
					next_state = lp_state_idle;
				end
			end
			
			default: begin
				next_state = lp_state_idle;
			end
		endcase
	end 
	
	wire [31:0] mem_addr;
	assign mem_addr = addr_reg[31:2] + ((inc_ct & ~mem_we) ? (len_ct_reg + 1) : len_ct_reg);
	
	// Instance of BlockRAM
	BlockRAM_Memory_MIF #(
		.width_p (32),
		.depth_p (mem_depth_p),
		.initfile_p (mem_initfile_p)
	) memory (
		.clk_i (clk_i),
		.rst_i (rst_i),
		
		.addr_i (mem_addr[ADDR_WIDTH-1:0]),
		
		.we_i (mem_we),
		.data_i (AXI_WDATA),
		
		.data_o (AXI_RDATA)
	);
	
endmodule
