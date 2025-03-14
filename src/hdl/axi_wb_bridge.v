module axi_wb_bridge #(
    parameter DATA          = 32,
    parameter ADDR          = 32,
    parameter AXI_ID_WIDTH  = 0,
    parameter AXI_USER_WIDTH = 0,
    // derived; don't touch
    parameter STRB          = (DATA/8)
) (

    // system
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 axi_clk CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axi0, ASSOCIATED_RESET rst" *)
    input   wire                    axi_clk,
    input   wire                    wb_clk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst RST" *)
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
    input   wire                    rst,

    // ** AXI **

    // read command
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARREADY" *)
    output  reg	                    axi_ar_ready,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARVALID" *)
    input   wire                    axi_ar_valid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARADDR" *)
    input   wire    [ADDR-1:0]      axi_ar_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARID" *)
    input   wire    [AXI_ID_WIDTH-1:0]  axi_ar_id,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARUSER" *)
    input   wire    [AXI_USER_WIDTH-1:0] axi_ar_user,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARLEN" *)
    input   wire    [7:0]           axi_ar_len, //will be ignored
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARSIZE" *)
    input   wire    [2:0]           axi_ar_size, //will be ignored
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARBURST" *)
    input   wire    [1:0]           axi_ar_burst, //will be ignored
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARLOCK" *)
    input   wire                    axi_ar_lock, //will be ignored
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARCACHE" *)
    input   wire    [3:0]           axi_ar_cache, //will be ignored
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARPROT" *)
    input   wire    [2:0]           axi_ar_prot, //will be ignored
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARREGION" *)
    input   wire    [3:0]           axi_ar_region, //will be ignored
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 ARQOS" *)
    input   wire    [3:0]           axi_ar_qos, //will be ignored
    
    // read data/response
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RREADY" *)
    input   wire                    axi_r_ready,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RVALID" *)
    output  reg                     axi_r_valid,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RLAST" *)
    output  reg                     axi_r_last,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RDATA" *)
    output  reg     [DATA-1:0]      axi_r_data,
        (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RRESP" *)
    output  wire     [1:0]           axi_r_resp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RID" *)
    output   reg    [AXI_ID_WIDTH-1:0]  axi_r_id,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 RUSER" *)
    output   wire    [AXI_USER_WIDTH-1:0] axi_r_user,

    // write command
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWREADY" *)
    output  reg                    axi_aw_ready,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWVALID" *)
    input   wire                    axi_aw_valid,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWADDR" *)
    input   wire    [ADDR-1:0]      axi_aw_addr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWID" *)
    input   wire    [AXI_ID_WIDTH-1:0]  axi_aw_id,
     (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWUSER" *)
    input   wire    [AXI_USER_WIDTH-1:0] axi_aw_user,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWLEN" *)
    input   wire    [7:0]           axi_aw_len, //will be ignored
        (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWSIZE" *)
    input   wire    [2:0]           axi_aw_size, //will be ignored
          (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWBURST" *)
    input   wire    [1:0]           axi_aw_burst, //will be ignored
            (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWLOCK" *)
    input   wire                    axi_aw_lock, //will be ignored
          (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWCACHE" *)
    input   wire    [3:0]           axi_aw_cache, //will be ignored
            (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWPROT" *)
    input   wire    [2:0]           axi_aw_prot, //will be     
        (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWREGION" *)
    input   wire    [3:0]           axi_aw_region, //will be ignored
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 AWQOS" *)
    input   wire    [3:0]           axi_aw_qos, //will be ignored

    // write data
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WREADY" *)
    output  reg                     axi_w_ready,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WVALID" *)
    input   wire                    axi_w_valid,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WLAST" *)
    input   wire                    axi_w_last,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WDATA" *)
    input   wire    [DATA-1:0]      axi_w_data,
        (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WSTRB" *)
    input   wire    [STRB-1:0]      axi_w_strb,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WID" *)
    input   wire    [AXI_ID_WIDTH-1:0]  axi_w_id,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 WUSER" *)
    input   wire    [AXI_USER_WIDTH-1:0] axi_w_user,

    // write response
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 BREADY" *)
    input   wire                    axi_b_ready,
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 BVALID" *)
    output  reg                     axi_b_valid,
    
      (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 BRESP" *) 
    output  wire     [1:0]           axi_b_resp,
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 BID" *)
    output   reg    [AXI_ID_WIDTH-1:0]  axi_b_id,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi0 BUSER" *)
    output   wire    [AXI_USER_WIDTH-1:0] axi_b_user,


    // ** Wishbone **

    // cycle
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_cyc" *)
    output  reg                    wb_cyc_o,

    // address
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_stb" *)
    output  reg                     wb_stb_o,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_we" *)
    output  reg                     wb_we_o,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_addr" *)
    output  reg     [ADDR-1:0]      wb_adr_o,
    output  wire     [2:0]           wb_cti_o,   // incrementing (3'b010) or end (3'b111)

    // data
	(* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_data_write" *)
    output  reg     [DATA-1:0]      wb_dat_o,
    output  wire     [STRB-1:0]      wb_sel_o,

    // response
    input   wire                    wb_stall_i, // pipelined only
        (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_ack" *)
    input   wire                    wb_ack_i,
    input   wire                    wb_err_i,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 m_wb wb_data_read" *)
    input   wire    [DATA-1:0]      wb_dat_i
);


assign axi_b_resp = 0;
assign wb_cti_o = 3'b000;
assign wb_sel_o = 3'b111;
assign axi_r_resp = 0;

always @(posedge axi_clk) begin
    if (axi_ar_valid && axi_ar_ready) begin
        axi_r_id <= axi_ar_id;
    end
    
    if (axi_w_valid & axi_w_ready) begin
        axi_b_id <= axi_w_id;
    end

end


reg [DATA-1:0] read_data, write_data;
reg [ADDR-1:0] address;
reg [ADDR-1:0] take_address_a;
reg take_address_s, take_address_read, take_address_write;
reg read_data_valid, read_data_signal;
reg set_data_valid, set_take_data;
reg axi_b_valid_s;
reg write_wb_finish;

localparam
	axi_state_num = 5,
	state_idle = 1,
	state_read_accepted_address = 2,
	state_read_valid_data = 4,
	state_write_accepted_address = 8,
	state_write_valid_data = 16;
	
reg [axi_state_num-1:0] axi_state, next_axi_state;

always@(*) begin
	next_axi_state = state_idle;
	take_address_s = 1'b0;
	take_address_a = 1'b0;
	take_address_read = 1'b0;
	take_address_write = 1'b0;
	axi_w_ready = 1'b0;
	axi_r_valid = 1'b0;
	axi_r_data = 0;
	axi_b_valid_s = 1'b0;
	set_take_data = 1'b0;
	axi_r_last = 1'b0;
	case(axi_state)
		state_idle: begin
			if(axi_ar_valid) begin
				next_axi_state = state_read_accepted_address;
				take_address_s = 1'b1;
				take_address_read = 1'b1;
				take_address_a = axi_ar_addr;
			end
			else
			if(axi_aw_valid) begin
				next_axi_state = state_write_accepted_address;
				take_address_s = 1'b1;
                take_address_write = 1'b1;
				take_address_a = axi_aw_addr;
			end
		end

		state_read_accepted_address: begin
			next_axi_state = state_read_accepted_address;
			if(read_data_valid && axi_r_ready) begin
				next_axi_state = state_read_valid_data;
			end
		end

		state_read_valid_data: begin
			axi_r_valid = 1'b1;	
			axi_r_data = read_data;
			axi_r_last = 1'b1; 
		end

		state_write_accepted_address: begin
			next_axi_state = state_write_accepted_address;
			axi_w_ready = 1'b1;
			if(axi_w_valid) begin
				next_axi_state = state_write_valid_data;
				set_take_data = 1'b1;			
			end
		end
		state_write_valid_data: begin
			next_axi_state = state_write_valid_data;
			axi_w_ready = 1'b1;
			if(write_wb_finish) begin
				next_axi_state = state_idle;
				axi_b_valid_s = 1'b1;
			end
		end

	endcase
end

reg start_wb_write_reg;
reg start_wb_read_reg;
reg non_idle;
always@(posedge axi_clk)begin
	if(rst) begin
		axi_state <= state_idle;
	end else begin
		axi_state <= next_axi_state;
	end
	if(take_address_s)
        address <= take_address_a;
            
    if(set_take_data)
        write_data <= axi_w_data;
        if(set_take_data)
			start_wb_write_reg <= 1'b1;
		else if(non_idle)
				start_wb_write_reg <= 1'b0;
		if(take_address_read)	
			start_wb_read_reg <= 1'b1;
		else if(non_idle)
			start_wb_read_reg <= 1'b0;
    axi_ar_ready <= take_address_read;
    axi_aw_ready <= take_address_write;
    axi_b_valid <= axi_b_valid_s;
end	


///////////////////////////////////////////////////////
///////////  WB Logic /////////////////////////////////
reg set_write_data_wb;

localparam
	wb_state_num = 3,
//	state_idle = 1,
	state_wb_read = 2,
	state_wb_write = 4;
reg [wb_state_num-1:0] wb_state, next_wb_state;
reg write_wb_finish_s;

always@(*) begin
	next_wb_state = state_idle;
	wb_cyc_o = 1'b0;
	wb_stb_o = 1'b0;
	wb_we_o = 1'b0;
	set_data_valid = 1'b0;
	set_write_data_wb = 1'b0;
	write_wb_finish_s = 1'b0;
	non_idle = 1'b1;
	
	case(wb_state)
		state_idle: begin
			if(start_wb_read_reg)
				next_wb_state = state_wb_read;
			if(start_wb_write_reg) begin
				next_wb_state = state_wb_write;
				set_write_data_wb = 1'b1;
			end
			non_idle = 1'b0;
		end
		state_wb_read: begin
			next_wb_state = state_wb_read;
			wb_stb_o = 1'b1;
			wb_cyc_o = 1'b1;
				if(wb_ack_i) begin
					next_wb_state = state_idle;
					set_data_valid = 1'b1;
				end
		end
		state_wb_write: begin
			next_wb_state = state_wb_write;
			set_data_valid = 1'b0;
			wb_stb_o = 1'b1;
			wb_cyc_o = 1'b1;
			wb_we_o = 1'b1;
			set_write_data_wb = 1'b1;
			if(wb_ack_i) begin
				next_wb_state = state_idle;
				set_data_valid = 1'b1;
				write_wb_finish_s = 1'b1;
			end

		end

	endcase
end

always@(posedge wb_clk)begin
	if(rst) begin
		wb_state <= state_idle;
		wb_adr_o <= 0;
		read_data_valid <= 0;
		read_data <= 1'b0;
		wb_dat_o <= 0;
	end else begin
		wb_state <= next_wb_state;
		wb_adr_o <= address;
		if(set_data_valid) begin
			read_data_valid <= 1;
			read_data <= wb_dat_i;
		end
		else 
			read_data_valid <= 0;

		if(set_write_data_wb)
			wb_dat_o <= write_data;
			
	end
	write_wb_finish <= write_wb_finish_s;
end

endmodule
