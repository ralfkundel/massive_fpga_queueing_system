`timescale 1ns / 1ps
`default_nettype none
/*******************************
* This Testbench can be used to test the pcap rx and tx to axis modules.
* Only a test for the testing environment
*
* author: Ralf Kundel, TU Darmstadt
* date: 15.02.2018
********************************/
module rxtx_tb #(
    parameter PCAP_FILENAME_i = "../../../../sim_inputs/input.pcap",
    parameter PCAP_FILENAME_o = "../../../../sim_outputs/out.pcap",
    parameter AXIS_DATA_WIDTH =64,
    parameter KEEP_WIDTH = AXIS_DATA_WIDTH/8
)(

);


reg clk,rst;
initial clk = 0;
always #(5.000) clk = ~clk;
initial begin
    rst = 0;
    #10;
    rst = 1;
    #20;
    rst=0;
end



	wire        rx_axis_tvalid_s;
    wire        rx_axis_tready_s;// = ready;
    wire [AXIS_DATA_WIDTH-1:0] rx_axis_tdata_s;
    wire  [KEEP_WIDTH-1:0]  rx_axis_tkeep_s;
    wire         rx_axis_tlast_s;
    wire [0:0] rx_axis_tuser_s;
    
    wire        tx_axis_tvalid_s;
     wire        tx_axis_tready_s;// = ready;
     wire [AXIS_DATA_WIDTH-1:0] tx_axis_tdata_s;
     wire  [KEEP_WIDTH-1:0]  tx_axis_tkeep_s;
     wire         tx_axis_tlast_s;
     wire [0:0] tx_axis_tuser_s;

pcap_rx_axi #(
    .FILENAME(PCAP_FILENAME_i),
    .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH),
    .ENABLE_INTERRUPTION(1'b1)
    )
 packetRx(
    .m_axis_tvalid_o(rx_axis_tvalid_s),
    .m_axis_tready_i(rx_axis_tready_s),
    .m_axis_tdata_o(rx_axis_tdata_s),
    .m_axis_tkeep_o(rx_axis_tkeep_s),
    .m_axis_tlast_o(rx_axis_tlast_s),
    .m_axis_tuser_o(rx_axis_tuser_s),
 
    .clk_i(clk),
    .rst_i(rst)
 );
 
 axis_fifo #(
 )fifo_inst (
    .clk_i(clk),
    .resetn_i(~rst),
    
    .s_axis_tready_o(rx_axis_tready_s),
    .s_axis_tvalid_i(rx_axis_tvalid_s),
    .s_axis_tdata_i(rx_axis_tdata_s),
    .s_axis_tkeep_i(rx_axis_tkeep_s),
    .s_axis_tlast_i(rx_axis_tlast_s),
    
    .m_axis_tready_i(tx_axis_tready_s),
    .m_axis_tdata_o(tx_axis_tdata_s),
    .m_axis_tkeep_o(tx_axis_tkeep_s),
    .m_axis_tlast_o(tx_axis_tlast_s),
    .m_axis_tvalid_o(tx_axis_tvalid_s)
 
 );
 
 

 
 pcap_tx_axi #(
     .FILENAME(PCAP_FILENAME_o),
     .AXIS_DATA_WIDTH(AXIS_DATA_WIDTH)
     )
  packetTx(
     .s_axis_tvalid_i(tx_axis_tvalid_s),
     .s_axis_tready_o(tx_axis_tready_s),
     .s_axis_tdata_i(tx_axis_tdata_s),
     .s_axis_tkeep_i(tx_axis_tkeep_s),
     .s_axis_tlast_i(tx_axis_tlast_s),
     .s_axis_tuser_i(tx_axis_tuser_s),
  
     .clk_i(clk),
     .rst_i(rst)
  );

endmodule