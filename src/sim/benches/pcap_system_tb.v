`timescale 1ns / 1ps
//`default_nettype none
/*******************************
* This Testbench simulates the complete queueing core
* The test packets are read from a pcap file
* the outgoing packets are stored in PCAP files
*
* author: Ralf Kundel, TU Darmstadt
* date: 16.02.2018
********************************/
module pcap_system_tb #(
    parameter PCAP_FILENAME_i = "../../../../sim_inputs/input.pcap",
    parameter WB_FILENAME_i = "../../../../sim_inputs/wb_m.txt",
    parameter PCAP_FILENAME_o = "../../../../sim_outputs/out.pcap",
    parameter AXIS_WIDTH =64,
    parameter AXIS_KEEP_WIDTH = AXIS_WIDTH/8,
    parameter AXI_WIDTH =256,
    parameter AXI_ID_WIDTH = 2
)(

);

    reg clk, rst;
    wire rst_s;
    always #(3.200) clk = ~clk; //AXIS clock
    initial begin
        clk = 0;
        rst = 0;
        #10;
        rst = 1;
        #20;
        rst=0;
        
    end

	wire                        port0_ingoing_axis_tvalid_s;
    wire                        port0_ingoing_axis_tready_s;
    wire [AXIS_WIDTH-1:0]       port0_ingoing_axis_tdata_s;
    wire  [AXIS_KEEP_WIDTH-1:0] port0_ingoing_axis_tkeep_s;
    wire                        port0_ingoing_axis_tlast_s;
    wire [0:0]                  port0_ingoing_axis_tuser_s;
    
    wire                        port1_outgoing_axis_tvalid_s;
    wire                        port1_outgoing_axis_tready_s;
    wire [AXIS_WIDTH-1:0]       port1_outgoing_axis_tdata_s;
    wire  [AXIS_KEEP_WIDTH-1:0] port1_outgoing_axis_tkeep_s;
    wire                        port1_outgoing_axis_tlast_s;
    wire [0:0]                  port1_outgoing_axis_tuser_s;
    
    


pcap_rx_axi #(
    .FILENAME(PCAP_FILENAME_i),
    .AXIS_DATA_WIDTH(AXIS_WIDTH)
    )
 packetRxPort0(
    .m_axis_tvalid_o(port0_ingoing_axis_tvalid_s),
    .m_axis_tready_i(port0_ingoing_axis_tready_s),
    .m_axis_tdata_o(port0_ingoing_axis_tdata_s),
    .m_axis_tkeep_o(port0_ingoing_axis_tkeep_s),
    .m_axis_tlast_o(port0_ingoing_axis_tlast_s),
    .m_axis_tuser_o(port0_ingoing_axis_tuser_s),
 
    .clk_i(clk),
    .rst_i(rst_s)
 );
 
 pcap_tx_axi #(
     .FILENAME(PCAP_FILENAME_o),
     .AXIS_DATA_WIDTH(AXIS_WIDTH)
     )
  packetTx(
     .s_axis_tvalid_i(port1_outgoing_axis_tvalid_s),
     .s_axis_tready_o(port1_outgoing_axis_tready_s),
     .s_axis_tdata_i(port1_outgoing_axis_tdata_s),
     .s_axis_tkeep_i(port1_outgoing_axis_tkeep_s),
     .s_axis_tlast_i(port1_outgoing_axis_tlast_s),
     .s_axis_tuser_i(port1_outgoing_axis_tuser_s),
  
     .clk_i(clk),
     .rst_i(rst_s)
  );

	
	wire			wb_cyc_s;
	wire			wb_stb_s;
	wire[32-1:0]	wb_adr_s;
	wire			wb_we_s;
	wire[31:0]	    wb_dat_w_s;
    wire[31:0]      wb_dat_r_s;
	
	wire			wb_ack_s;

wb_master_sim #(
    .FILENAME(WB_FILENAME_i),
    .DATA_WIDTH(32),
    .ADDR_WIDTH(32)
) wb_master (
    .clk_i(clk),
    .rst_i(rst_s),
    
    .wb_data_i(wb_dat_r_s),
    .wb_data_o(wb_dat_w_s),
    .wb_addr_o(wb_adr_s),
    .wb_we_o(wb_we_s),
    .wb_cyc_o(wb_cyc_s),
    .wb_stb_o(wb_stb_s),
    .wb_ack_i(wb_ack_s)

);

//`default_nettype wire

 sim_infrastructure sim_infrastructure_inst (
 
    .s_axis0_tdata(port0_ingoing_axis_tdata_s),
    .s_axis0_tkeep(port0_ingoing_axis_tkeep_s),
    .s_axis0_tlast(port0_ingoing_axis_tlast_s),
    .s_axis0_tready(port0_ingoing_axis_tready_s),
    .s_axis0_tvalid(port0_ingoing_axis_tvalid_s),
    
    .m_axis1_tdata(port1_outgoing_axis_tdata_s),
    .m_axis1_tkeep(port1_outgoing_axis_tkeep_s),
    .m_axis1_tlast(port1_outgoing_axis_tlast_s),
    .m_axis1_tready(port1_outgoing_axis_tready_s),
    .m_axis1_tvalid(port1_outgoing_axis_tvalid_s),
    
    .s_wb_wb_data_read(wb_dat_r_s),
    .s_wb_wb_data_write(wb_dat_w_s),
    .s_wb_wb_addr(wb_adr_s),
    .s_wb_wb_we(wb_we_s),
    .s_wb_wb_cyc(wb_cyc_s),
    .s_wb_wb_stb(wb_stb_s),
    .s_wb_wb_ack(wb_ack_s),

    .clk_i(clk),
    .ext_rst(rst),
    .rst_o(rst_s)
    );
    

endmodule
