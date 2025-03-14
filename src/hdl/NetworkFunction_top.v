`timescale 1ns / 1ps
//`default_nettype none
/*******************************
*
* author: Ralf Kundel, TU Darmstadt
* date: 05.07.2018
********************************/


module NetworkFunctionTop #(
	parameter AXIS_WIDTH =64,
	parameter AXI_WIDTH =64,
	parameter AXI_ADDR_WIDTH = 32,
	parameter AXI_ID_WIDTH = 2,
	parameter QUEUE_ID_WIDTH = 32,      //The number of bits in the beginning of the packet which identifies the queue
	parameter WB_DATA_WIDTH = 32,
	parameter WB_ADDR_WIDTH = 32,
	parameter NUM_COUNTER = 1024,
	
	
	parameter NUMBER_QUEUES = 1024,
	parameter NUMBER_DESCRIPTORS = 2048
)(
    	//AXIS signals for Port 0 input
    // Uncomment the following to set interface specific parameter on the bus interface.
    //  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN <value>,PHASE <value>,FREQ_HZ <value>,LAYERED_METADATA <value>,HAS_TLAST <value>,HAS_TKEEP <value>,HAS_TSTRB <value>,HAS_TREADY <value>,TUSER_WIDTH <value>,TID_WIDTH <value>,TDEST_WIDTH <value>,TDATA_NUM_BYTES <value>" *)
    //(* X_INTERFACE_PARAMETER = "CLK_DOMAIN clk_i"*)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis0 TDATA" *)
    input wire [AXIS_WIDTH-1:0] s_axis0_tdata_i, // Transfer Data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis0 TKEEP" *)
    input wire [AXIS_WIDTH/8-1:0] s_axis0_axis_tkeep_i, // Transfer Null Byte Indicators (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis0 TLAST" *)
    input wire s_axis0_tlast_i, // Packet Boundary Indicator (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis0 TVALID" *)
    input wire s_axis0_tvalid_i, // Transfer valid (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 s_axis0 TREADY" *)
    output wire s_axis0_tready_o, // Transfer ready (optional)

	//AXIS signals for Port 1 output
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis1 TDATA" *)
    output wire [AXIS_WIDTH-1:0] m_axis1_tdata_o, // Transfer Data (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis1 TKEEP" *)
    output wire [AXIS_WIDTH/8-1:0] m_axis1_tkeep_o, // Transfer Null Byte Indicators (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis1 TLAST" *)
    output wire m_axis1_tlast_o, // Packet Boundary Indicator (optional)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis1 TVALID" *)
    output wire m_axis1_tvalid_o, // Transfer valid (required)
    (* X_INTERFACE_INFO = "xilinx.com:interface:axis:1.0 m_axis1 TREADY" *)
    input wire m_axis1_tready_i, // Transfer ready (optional)

    
    
    /* ###################################################################
                  Memory Interfaces for Rx and Tx handler
    ################################################################### */

	  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWID" *)
  // Uncomment the following to set interface specific parameter on the bus interface.
  //  (* X_INTERFACE_PARAMETER = "CLK_DOMAIN <value>,PHASE <value>,MAX_BURST_LENGTH <value>,NUM_WRITE_OUTSTANDING <value>,NUM_READ_OUTSTANDING <value>,SUPPORTS_NARROW_BURST <value>,READ_WRITE_MODE <value>,BUSER_WIDTH <value>,RUSER_WIDTH <value>,WUSER_WIDTH <value>,ARUSER_WIDTH <value>,AWUSER_WIDTH <value>,ADDR_WIDTH <value>,ID_WIDTH <value>,FREQ_HZ <value>,PROTOCOL <value>,DATA_WIDTH <value>,HAS_BURST <value>,HAS_CACHE <value>,HAS_LOCK <value>,HAS_PROT <value>,HAS_QOS <value>,HAS_REGION <value>,HAS_WSTRB <value>,HAS_BRESP <value>,HAS_RRESP <value>" *)
  output wire [AXI_ID_WIDTH-1:0] m0_axi_awid_o, // Write address ID (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWADDR" *)
  output wire [AXI_ADDR_WIDTH-1:0] m0_axi_awaddr_o, // Write address (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWLEN" *)
  output wire [7:0] m0_axi_awlen_o, // Burst length (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWSIZE" *)
  output wire [2:0] m0_axi_awsize_o, // Burst size (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWBURST" *)
  output wire [1:0] m0_axi_awburst_o, // Burst type (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWLOCK" *)
  output wire [0:0] m0_axi_awlock_o, // Lock type (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWCACHE" *)
  output wire [3:0] m0_axi_awcache_o, // Cache type (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWPROT" *)
  output wire [2:0] m0_axi_awprot_o, // Protection type (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWREGION" *)
  //output wire [3:0] <s_awregion>, // Write address slave region (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWQOS" *)
  output wire [3:0] m0_axi_awqos_o, // Transaction Quality of Service token (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWUSER" *)
  //output wire [<left_bound>:0] <s_awuser>, // Write address user sideband (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWVALID" *)
  output wire m0_axi_awvalid_o, // Write address valid (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler AWREADY" *)
  input wire m0_axi_awready_i, // Write address ready (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WID" *)
  output wire [AXI_ID_WIDTH-1:0] m0_axi_wid_o, // Write ID tag (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WDATA" *)
  output wire [AXI_WIDTH-1:0] m0_axi_wdata_o, // Write data (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WSTRB" *)
  output wire [AXI_WIDTH/8-1:0] m0_axi_wstrb_o, // Write strobes (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WLAST" *)
  output wire m0_axi_wlast_o, // Write last beat (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WUSER" *)
  //output wire [<left_bound>:0] <s_wuser>, // Write data user sideband (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WVALID" *)
  output wire m0_axi_wvalid_o, // Write valid (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler WREADY" *)
  input wire m0_axi_wready_i, // Write ready (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler BID" *)
  input wire [AXI_ID_WIDTH-1:0] m0_axi_bid_i, // Response ID (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler BRESP" *)
  input wire [1:0] m0_axi_bresp_i, // Write response (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler BUSER" *)
  //input wire [<left_bound>:0] <s_buser>, // Write response user sideband (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler BVALID" *)
  input wire m0_axi_bvalid_i, // Write response valid (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m0_axi_rx_handler BREADY" *)
  output wire m0_axi_bready_o, // Write response ready (optional)





  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARID" *)
  output wire [AXI_ID_WIDTH-1:0] m1_axi_arid_o, // Read address ID (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARADDR" *)
  output wire [AXI_ADDR_WIDTH-1:0] m1_axi_araddr_o, // Read address (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARLEN" *)
  output wire [7:0] m1_axi_arlen_o, // Burst length (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARSIZE" *)
  output wire [2:0] m1_axi_arsize_o, // Burst size (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARBURST" *)
  output wire [1:0] m1_axi_arburst_o, // Burst type (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARLOCK" *)
  output wire [0:0] m1_axi_arlock_o, // Lock type (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARCACHE" *)
  output wire [3:0] m1_axi_arcache_o, // Cache type (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARPROT" *)
  output wire [2:0] m1_axi_arprot_o, // Protection type (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARREGION" *)
  //output wire [3:0] <s_arregion>, // Read address slave region (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARQOS" *)
  output wire [3:0] m1_axi_arqos_o, // Quality of service token (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARUSER" *)
  //output wire [<left_bound>:0] <s_aruser>, // Read address user sideband (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARVALID" *)
  output wire m1_axi_arvalid_o, // Read address valid (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler ARREADY" *)
  input wire m1_axi_arready_i, // Read address ready (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RID" *)
  input wire [AXI_ID_WIDTH-1:0] m1_axi_rid_i, // Read ID tag (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RDATA" *)
  input wire [AXI_WIDTH-1:0] m1_axi_rdata_i, // Read data (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RRESP" *)
  input wire [1:0] m1_axi_rresp_i, // Read response (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RLAST" *)
  input wire m1_axi_rlast_i, // Read last beat (optional)
  //(* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RUSER" *)
  //input wire [<left_bound>:0] <s_ruser>, // Read user sideband (optional) //TODO
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RVALID" *)
  input wire m1_axi_rvalid_i, // Read valid (optional)
  (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 m1_axi_tx_handler RREADY" *)
  output wire m1_axi_rready_o, // Read ready (optional)

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 clk_i CLK" *)
    (* X_INTERFACE_PARAMETER = "ASSOCIATED_BUSIF s_axis0:m_axis1:m2_axis1:m0_axi_rx_handler:m1_axi_tx_handler, ASSOCIATED_RESET rst_i" *)
	input wire clk_i,
	
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 rst_i RST" *)
    // Supported parameter: POLARITY {ACTIVE_LOW, ACTIVE_HIGH}
    // Normally active low is assumed.  Use this parameter to force the level
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_HIGH" *)
	input wire rst_i,
	
    (* X_INTERFACE_PARAMETER = "POLARITY ACTIVE_LOW" *)
	output wire rstn_o,
	
	 (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_data_read" *) 
	output wire [WB_DATA_WIDTH-1:0]    wb_data_o,
	(* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_data_write" *)
    input wire [WB_DATA_WIDTH-1:0]    wb_data_i,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_addr" *)
    input wire [WB_ADDR_WIDTH-1:0]    wb_addr_i,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_we" *)
    input wire                        wb_we_i,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_cyc" *)
    input wire                        wb_cyc_i,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_stb" *)
    input wire [WB_DATA_WIDTH/8-1:0]  wb_stb_i,
    (* X_INTERFACE_INFO = "ralf.kundel:user:wishbone:1.0 s_wb wb_ack" *)
    output wire wb_ack_o
);
    assign rstn_o = ~ rst_i;

    localparam WB_SLAVE_SELECT_WIDTH = 8;
    localparam WB_SLAVE_ADDR_WIDTH = WB_ADDR_WIDTH - WB_SLAVE_SELECT_WIDTH - 2; 

     wire [WB_DATA_WIDTH-1:0]       qd_wb_data_read_s;
     wire [WB_DATA_WIDTH-1:0]       qd_wb_data_write_s;
     wire [WB_SLAVE_ADDR_WIDTH-1:0]    qd_wb_addr_s;
     wire                           qd_wb_we_s;
     wire                           qd_wb_cyc_s;
     wire [WB_DATA_WIDTH/8-1:0]     qd_wb_stb_s;
     wire                           qd_wb_ack_s;
     
      wire [WB_DATA_WIDTH-1:0]       sched_wb_data_read_s;
     wire [WB_DATA_WIDTH-1:0]       sched_wb_data_write_s;
     wire [WB_SLAVE_ADDR_WIDTH-1:0]    sched_wb_addr_s;
     wire                           sched_wb_we_s;
     wire                           sched_wb_cyc_s;
     wire [WB_DATA_WIDTH/8-1:0]     sched_wb_stb_s;
     wire                           sched_wb_ack_s;
     
     
     wire [WB_DATA_WIDTH-1:0]       counter_wb_data_read_s;
     wire [WB_DATA_WIDTH-1:0]       counter_wb_data_write_s;
     wire [WB_SLAVE_ADDR_WIDTH-1:0]    counter_wb_addr_s;
     wire                           counter_wb_we_s;
     wire                           counter_wb_cyc_s;
     wire [WB_DATA_WIDTH/8-1:0]     counter_wb_stb_s;
     wire                           counter_wb_ack_s;
    
    wb_interconnect #(
        .WB_DATA_WIDTH(32),
        .SLAVE_SELECT_WIDTH(WB_SLAVE_SELECT_WIDTH)
    )wb_interconnect_inst (
        .qd_wb_data_i(qd_wb_data_read_s),
        .qd_wb_data_o(qd_wb_data_write_s),
        .qd_wb_addr_o(qd_wb_addr_s),
        .qd_wb_we_o(qd_wb_we_s),
        .qd_wb_cyc_o(qd_wb_cyc_s),
        .qd_wb_stb_o(qd_wb_stb_s),
        .qd_wb_ack_i(qd_wb_ack_s),
        
        .sched_wb_data_i(sched_wb_data_read_s),
        .sched_wb_data_o(sched_wb_data_write_s),
        .sched_wb_addr_o(sched_wb_addr_s),
        .sched_wb_we_o(sched_wb_we_s),
        .sched_wb_cyc_o(sched_wb_cyc_s),
        .sched_wb_stb_o(sched_wb_stb_s),
        .sched_wb_ack_i(sched_wb_ack_s),
        
        .counter_wb_data_i(counter_wb_data_read_s),
        .counter_wb_data_o(counter_wb_data_write_s),
        .counter_wb_addr_o(counter_wb_addr_s),
        .counter_wb_we_o(counter_wb_we_s),
        .counter_wb_cyc_o(counter_wb_cyc_s),
        .counter_wb_stb_o(counter_wb_stb_s),
        .counter_wb_ack_i(counter_wb_ack_s),
        
        .wb_data_o(wb_data_o),
        .wb_data_i(wb_data_i),
        .wb_addr_i(wb_addr_i),
        .wb_we_i(wb_we_i),
        .wb_cyc_i(wb_cyc_i),
        .wb_stb_i(wb_stb_i),
        .wb_ack_o(wb_ack_o),
        
        .clk_i(clk_i),
        .rst_i(rst_i)
    
    );

  
  
  localparam PACKET_SIZE_WIDTH = 11; //sufficient for 2048 byte


  wire [PACKET_SIZE_WIDTH-1:0] rx0_axis_packet_length_s;
  wire [AXIS_WIDTH-1:0] rx0_axis_tdata_s; // Transfer Data (optional)
  wire [AXIS_WIDTH/8-1:0] rx0_axis_tkeep_s; // Transfer Null Byte Indicators (optional)
  wire rx0_axis_tlast_s; // Packet Boundary Indicator (optional)
  wire rx0_axis_tvalid_s; // Transfer valid (required)
  wire rx0_axis_tready_s; // Transfer ready (optional)


assign s_axis0_tready_o = 1'b1;
axis_fifo #(
    .ADDR_WIDTH( (AXIS_WIDTH==512)?9:10 ),
    .DATA_WIDTH(AXIS_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH)
) rx_fifo (
    //input stream
    .s_axis_tready_o(), //s_axis0_tready_o
    .s_axis_tvalid_i(s_axis0_tvalid_i),
    .s_axis_tdata_i(s_axis0_tdata_i),
    .s_axis_tkeep_i(s_axis0_axis_tkeep_i),
    .s_axis_tlast_i(s_axis0_tlast_i),
    //output stream
    .m_axis_tready_i(rx0_axis_tready_s),
    .m_axis_tdata_o(rx0_axis_tdata_s),
    .m_axis_tkeep_o(rx0_axis_tkeep_s),
    .m_axis_tlast_o(rx0_axis_tlast_s),
    .m_axis_tvalid_o(rx0_axis_tvalid_s),

    .m_packet_length_o(rx0_axis_packet_length_s),
    
    .clk_i(clk_i),
    .resetn_i(~rst_i)


);


    //c = "cutted"
  wire [PACKET_SIZE_WIDTH-1:0] rxc0_axis_packet_length_s;
  wire [AXIS_WIDTH-1:0] rxc0_axis_tdata_s; // Transfer Data (optional)
  wire [AXIS_WIDTH/8-1:0] rxc0_axis_tkeep_s; // Transfer Null Byte Indicators (optional)
  wire rxc0_axis_tlast_s; // Packet Boundary Indicator (optional)
  wire rxc0_axis_tvalid_s; // Transfer valid (required)
  wire rxc0_axis_tready_s; // Transfer ready (optional)
  wire [31:0] rxc0_queue_id_s;

queueIdCutter #(
    .AXIS_DATA_WIDTH(AXIS_WIDTH),
    .QUEUE_ID_WIDTH(32),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH)
) QueueIdCutter (
    .s_axis_tready_o(rx0_axis_tready_s),
    .s_axis_tvalid_i(rx0_axis_tvalid_s),
    .s_axis_tdata_i(rx0_axis_tdata_s),
    .s_axis_tkeep_i(rx0_axis_tkeep_s),
    .s_axis_tlast_i(rx0_axis_tlast_s),
    .s_axis_packet_length_i(rx0_axis_packet_length_s),
    
    .m_axis_tready_i(rxc0_axis_tready_s),
    .m_axis_tvalid_o(rxc0_axis_tvalid_s),
    .m_axis_tdata_o(rxc0_axis_tdata_s),
    .m_axis_tkeep_o(rxc0_axis_tkeep_s),
    .m_axis_tlast_o(rxc0_axis_tlast_s),
    .m_axis_packet_length_o(rxc0_axis_packet_length_s),
    .m_queue_id_o(rxc0_queue_id_s),
    
    .clk_i(clk_i),
    .rst_i(rst_i)

);



wire [AXI_ADDR_WIDTH-1:0]       next_rx_addr_s;
wire                            next_rx_addr_valid_s;
wire                            rx_addr_ack_s;
wire [PACKET_SIZE_WIDTH-1:0]    rx_packet_length_s;

wire                        free_mem_ack_s;
wire                        free_mem_s;
wire [AXI_ADDR_WIDTH-1:0]   free_mem_addr_s;

wire                        free1_mem_ack_s;
wire                        free1_mem_s;
wire [AXI_ADDR_WIDTH-1:0]   free1_mem_addr_s;

wire                        free2_mem_ack_s;
wire                        free2_mem_ready_s;
wire                        free2_mem_s;
wire [AXI_ADDR_WIDTH-1:0]   free2_mem_addr_s;


job_arbiter #(
    .WIDTH(AXI_ADDR_WIDTH),
    .DEPTH(4)
) free_mem_queues_inst (
    .p1_data_i(free1_mem_addr_s),
    .p1_valid_i(free1_mem_s),
    .p1_ack_o(free1_mem_ack_s),
    .p1_ready_o(),
    
    .p2_data_i(free2_mem_addr_s),
    .p2_valid_i(free2_mem_s), //TODO for future use in queue_mem taildrop
    .p2_ack_o(free2_mem_ack_s),
    .p2_ready_o(free2_mem_ready_s),
    
    .out_data_o(free_mem_addr_s),
    .out_valid_o(free_mem_s),
    .out_pop_i(free_mem_ack_s),

    .clk_i(clk_i),
    .rst_i(rst_i)

);

localparam NUM_MEM_BLOCKS = 2**($clog2(NUMBER_DESCRIPTORS)+1); 

mem_alloc_unit #(
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .NUM_MEM_BLOCKS(NUM_MEM_BLOCKS)
    ) mem_alloc_unit_inst (
        .clk_i(clk_i),
        .rst_i(rst_i),
        
        .next_addr_o(next_rx_addr_s),
        .next_addr_valid_o(next_rx_addr_valid_s),
        .packet_length_i(rx_packet_length_s),
        .addr_ack_i(rx_addr_ack_s),
        
        .free_mem_addr_i(free_mem_addr_s),
        .free_mem_i(free_mem_s),
        .free_mem_ack_o(free_mem_ack_s)
        
    );
    
    

wire eqm_valid_s;
wire [PACKET_SIZE_WIDTH-1:0]    eqm_packet_length_s;
wire [QUEUE_ID_WIDTH-1:0]       eqm_queue_id_s;
wire [AXI_ADDR_WIDTH-1:0]       eqm_addr_s;
wire eqm_p_accept_ready_s;

AxisToAxi_rx_handler #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .DATA_WIDTH(AXI_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH)
) rx_handler (
    .clk_i(clk_i),
    .reset_i(rst_i),
    
    //memory alloc unit interface
    .next_addr_i(next_rx_addr_s),
    .next_addr_valid_i(next_rx_addr_valid_s),
    .packet_length_o(rx_packet_length_s),
    .addr_ack_o(rx_addr_ack_s),
    
    //AXI memory interface
    .axi_awid_o(m0_axi_awid_o), // Write address ID
    .axi_awaddr_o(m0_axi_awaddr_o), // Write address
    .axi_awlen_o(m0_axi_awlen_o), // Burst length
    .axi_awsize_o(m0_axi_awsize_o), // Burst size
    .axi_awburst_o(m0_axi_awburst_o), // Burst type
    .axi_awlock_o(m0_axi_awlock_o), // Lock type
    .axi_awcache_o(m0_axi_awcache_o), // Cache type
    .axi_awprot_o(m0_axi_awprot_o), // Protection type
    .axi_awqos_o(m0_axi_awqos_o), // Transaction Quality of Service token
    .axi_awvalid_o(m0_axi_awvalid_o), // Write address valid
    .axi_awready_i(m0_axi_awready_i), // Write address ready
    .axi_wid_o(m0_axi_wid_o), // Write ID tag
    .axi_wdata_o(m0_axi_wdata_o), // Write data
    .axi_wstrb_o(m0_axi_wstrb_o), // Write strobes
    .axi_wlast_o(m0_axi_wlast_o), // Write last beat
    .axi_wvalid_o(m0_axi_wvalid_o), // Write valid
    .axi_wready_i(m0_axi_wready_i), // Write ready
    .axi_bid_i(m0_axi_bid_i), // Response ID
    .axi_bresp_i(m0_axi_bresp_i), // Write res
    .axi_bvalid_i(m0_axi_bvalid_i), // Write response valid
    .axi_bready_o(m0_axi_bready_o), // Write response ready
    
    
    //AXIS input nic interface
    .s_axis_tready_o(rxc0_axis_tready_s),
    .s_axis_tvalid_i(rxc0_axis_tvalid_s),
    .s_axis_tdata_i(rxc0_axis_tdata_s),
    .s_axis_tkeep_i(rxc0_axis_tkeep_s),
    .s_axis_tlast_i(rxc0_axis_tlast_s),
    .s_axis_packet_length_i(rxc0_axis_packet_length_s),
    .s_axis_queue_id_i(rxc0_queue_id_s),
    
    //eqm manager
    .eqm_valid_o(eqm_valid_s),
    .eqm_packet_length_o(eqm_packet_length_s),
    .eqm_queue_id_o(eqm_queue_id_s),
    .eqm_addr_o(eqm_addr_s),
    .eqm_ready_i(eqm_p_accept_ready_s)

);
wire [QUEUE_ID_WIDTH-1:0 ]  pop_queue_id_base_s, pop_queue_id_s;
wire pop_set_base_ready_s, pop_set_base_queue_id_s;
wire id_valid_s, pop_s, valid_dequeue_s;
wire [AXI_ADDR_WIDTH-1:0] pop_addr_s;
wire [PACKET_SIZE_WIDTH -1 : 0]   pop_len_s;



queue_memory #(
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),    //length of the header preambel
    .WB_SLAVE_ADDR_WIDTH(WB_SLAVE_ADDR_WIDTH),
    .ADDR_WIDTH(AXI_ADDR_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
    
    .NUM_QUEUES(NUMBER_QUEUES),
    .SIZE_DESCRIPTOR_MEM(NUMBER_DESCRIPTORS)

) queue_memoy_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .wb_queue_depth_cyc_i(qd_wb_cyc_s),
    .wb_queue_depth_adr_i(qd_wb_addr_s),
    .wb_queue_depth_we_i(qd_wb_we_s),
    .wb_queue_depth_dat_i(qd_wb_data_write_s),
    .wb_queue_depth_ack_o(qd_wb_ack_s),
    .wb_queue_depth_dat_o(qd_wb_data_read_s),
    
    .p_len_i(eqm_packet_length_s),
    .p_addr_i(eqm_addr_s),
    .p_queue_id_i(eqm_queue_id_s),
    .p_valid_i(eqm_valid_s),
    .p_accept_ready_o(eqm_p_accept_ready_s),
    
    .free_mem_ack_i(free2_mem_ack_s),
    .free_mem_o(free2_mem_s),
    .free_mem_addr_o(free2_mem_addr_s),
    
    
    .pop_queue_id_base_i(pop_queue_id_base_s),
    .pop_set_base_queue_id_i(pop_set_base_queue_id_s),
    .pop_set_base_ready_o(pop_set_base_ready_s),
    
    .pop_id_valid_o(id_valid_s),
    .pop_queue_id_o(pop_queue_id_s),
    .pop_i(pop_s),
    
    .pop_len_o(pop_len_s),
    .pop_addr_o(pop_addr_s),
    .pop_queue_len_o(),
    .valid_o(valid_dequeue_s)
);
wire valid_packet_s;
wire [AXI_ADDR_WIDTH-1:0] addr_packet_scheduler_s;
wire [PACKET_SIZE_WIDTH -1 : 0] length_packet_scheduler_s;
wire ack_from_tx_handler_s;
wire [QUEUE_ID_WIDTH-1:0 ] queue_id_scheduler_s;

//`define NoScheduler
`define SimpleScheduler
//`define HierarchicalScheduler

`ifdef NoScheduler
assign sched_wb_ack_s = 1'b0;
assign sched_wb_data_read_s = 0;
NoScheduler #(
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH)

) NoScheduler_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),

    .pop_queue_id_base_o(pop_queue_id_base_s),
    .pop_set_base_queue_id_o(pop_set_base_queue_id_s),
    .pop_set_base_ready_i(pop_set_base_ready_s),
    
    .pop_queue_id_i(pop_queue_id_s),
    .pop_o(pop_s),
    .pop_id_valid_i(id_valid_s),
    
    .pop_addr_i(pop_addr_s),
    .pop_len_i(pop_len_s),
    .valid_i(valid_dequeue_s),
    
    //TX Handler Interface
    .valid_packet_o(valid_packet_s),
    .addr_packet_scheduler_o(addr_packet_scheduler_s),
    .length_packet_scheduler_o(length_packet_scheduler_s),
    .ack_from_tx_handler_i(ack_from_tx_handler_s)
    
);
`elsif SimpleScheduler

SimpleScheduler #(
    .NUM_CUSTOMERS(NUMBER_QUEUES/8),
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
    
    .WB_ADDR_WIDTH(WB_SLAVE_ADDR_WIDTH),
    .WB_DATA_WIDTH(WB_DATA_WIDTH)

) SimpleScheduler_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    
     .wb_cyc_i(sched_wb_cyc_s),
    .wb_adr_i(sched_wb_addr_s),
    .wb_we_i(sched_wb_we_s),
    .wb_dat_i(sched_wb_data_write_s),
    .wb_ack_o(sched_wb_ack_s),
    .wb_dat_o(sched_wb_data_read_s),

    .pop_queue_id_base_o(pop_queue_id_base_s),
    .pop_set_base_queue_id_o(pop_set_base_queue_id_s),
    .pop_set_base_ready_i(pop_set_base_ready_s),
    
    .pop_queue_id_i(pop_queue_id_s),
    .pop_o(pop_s),
    .id_valid_i(id_valid_s),
    
    .pop_addr_i(pop_addr_s),
    .pop_len_i(pop_len_s),
    .valid_i(valid_dequeue_s),
    
    //TX Handler Interface
    .valid_packet_o(valid_packet_s),
    .addr_packet_scheduler_o(addr_packet_scheduler_s),
    .length_packet_scheduler_o(length_packet_scheduler_s),
    .ack_from_tx_handler_i(ack_from_tx_handler_s)
    
);
`elsif HierarchicalScheduler

HierarchicalScheduler #(
    .NUM_CUSTOMERS(NUMBER_QUEUES/8),
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
    
    .WB_ADDR_WIDTH(WB_SLAVE_ADDR_WIDTH),
    .WB_DATA_WIDTH(WB_DATA_WIDTH),
    
    .NUM_QUEUES(NUMBER_QUEUES)

) HierarchicalScheduler_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    
     .wb_cyc_i(sched_wb_cyc_s),
    .wb_adr_i(sched_wb_addr_s),
    .wb_we_i(sched_wb_we_s),
    .wb_dat_i(sched_wb_data_write_s),
    .wb_ack_o(sched_wb_ack_s),
    .wb_dat_o(sched_wb_data_read_s),

    .pop_queue_id_base_o(pop_queue_id_base_s),
    .pop_set_base_queue_id_o(pop_set_base_queue_id_s),
    .pop_set_base_ready_i(pop_set_base_ready_s),
    
    .pop_queue_id_i(pop_queue_id_s),
    .pop_o(pop_s),
    .id_valid_i(id_valid_s),
    
    .pop_addr_i(pop_addr_s),
    .pop_len_i(pop_len_s),
    .valid_i(valid_dequeue_s),
    
    //TX Handler Interface
    .valid_packet_o(valid_packet_s),
    .queue_id_scheduler_o(queue_id_scheduler_s),
    .addr_packet_scheduler_o(addr_packet_scheduler_s),
    .length_packet_scheduler_o(length_packet_scheduler_s),
    .ack_from_tx_handler_i(ack_from_tx_handler_s)
    
);

`endif



packet_counter #(
    .WB_DATA_WIDTH(WB_DATA_WIDTH),
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),
    .NUM_COUNTER(NUM_COUNTER),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH)
) packet_counter_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .wb_cyc_i(counter_wb_cyc_s),
    .wb_adr_i(counter_wb_addr_s),
    .wb_we_i(counter_wb_we_s),
    .wb_dat_i(counter_wb_data_write_s),
    .wb_ack_o(counter_wb_ack_s),
    .wb_dat_o(counter_wb_data_read_s),
    
    .c_id_i(queue_id_scheduler_s),
    .p_len_i(length_packet_scheduler_s),
    .count_i(valid_packet_s)

);


AxiToAxis_tx_handler #(
    .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
    .DATA_WIDTH(AXI_WIDTH),
    .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
    .AXI_ID_WIDTH(AXI_ID_WIDTH),
    .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH)
) tx_handler (
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    //Scheduler interface
    .valid_packet_i(valid_packet_s),
    .addr_packet_scheduler_i(addr_packet_scheduler_s),
    .length_packet_scheduler_i(length_packet_scheduler_s),
    .ack_from_tx_handler_o(ack_from_tx_handler_s),
    
    .m_axi_arid_o(m1_axi_arid_o),
    .m_axi_araddr_o(m1_axi_araddr_o),
    .m_axi_arlen_o(m1_axi_arlen_o),
    .m_axi_arsize_o(m1_axi_arsize_o),
    .m_axi_arburst_o(m1_axi_arburst_o),
    .m_axi_arlock_o(m1_axi_arlock_o),
    .m_axi_arcache_o(m1_axi_arcache_o),
    .m_axi_arprot_o(m1_axi_arprot_o),
    .m_axi_arqos_o(m1_axi_arqos_o),
    .m_axi_arvalid_o(m1_axi_arvalid_o),
    .m_axi_arready_i(m1_axi_arready_i),
    .m_axi_rid_i(m1_axi_rid_i),
    .m_axi_rdata_i(m1_axi_rdata_i),
    .m_axi_rresp_i(m1_axi_rresp_i),
    .m_axi_rlast_i(m1_axi_rlast_i),
    .m_axi_rvalid_i(m1_axi_rvalid_i),
    .m_axi_rready_o(m1_axi_rready_o),
    
    
    .m_axis_tready_i(m_axis1_tready_i),
    .m_axis_tvalid_o(m_axis1_tvalid_o),
    .m_axis_tdata_o(m_axis1_tdata_o),
    .m_axis_tkeep_o(m_axis1_tkeep_o),
    .m_axis_tlast_o(m_axis1_tlast_o),
    
    .free_mem_ack_i(free1_mem_ack_s),
    .free_mem_o(free1_mem_s),
    .free_mem_addr_o(free1_mem_addr_s)
);



endmodule

