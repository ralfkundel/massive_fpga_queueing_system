`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: TU Darmstadt, Fachgebiet PS
// Engineer: Leonhard Nobach
// 
// Create Date: 20.05.2015 16:57:28
// Design Name: 
// Module Name: TopLevelModule
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments: testee
// 
//////////////////////////////////////////////////////////////////////////////////


module TopLevelModule #(
    parameter SRC_MAC = 48'h5354_d333_b006, //currently not used
    parameter DST_MAC = 48'h5354_0000_0001, //currently not used
    
    parameter AXIS_WIDTH =64,
    parameter KEEP_WIDTH = AXIS_WIDTH/8,
    parameter AXI_WIDTH =64,
    parameter AXI_ID_WIDTH = 4
)(
    input wire [0:0] pcie_7x_mgt_0_rxn,
    input wire [0:0] pcie_7x_mgt_0_rxp,
    output wire [0:0] pcie_7x_mgt_0_txn,
    output wire [0:0] pcie_7x_mgt_0_txp,
    
    input wire PCIE_CLK_N,
    input wire PCIE_CLK_P,
    
     input wire pcie_sys_resetn,
    
    input wire FPGA_SYSCLK_N,
    input wire FPGA_SYSCLK_P,
    
    input wire DDR3_SYSCLK_N,
    input wire DDR3_SYSCLK_P,
    
    //AChtung: RX sind die ausgehenden signale und Tx die eingehenden (warum auch immer das digilent so gemacht hat)
    input wire ETH1_TX_P,
    input wire ETH1_TX_N,
    output wire ETH1_RX_P,
    output wire ETH1_RX_N,
        /*
    input wire ETH2_TX_P,
    input wire ETH2_TX_N,
    output wire ETH2_RX_P,
    output wire ETH2_RX_N,

    input wire ETH3_TX_P,
    output wire ETH3_RX_P,
    input wire ETH3_TX_N,
    output wire ETH3_RX_N,
    input wire ETH4_TX_P,
    output wire ETH4_RX_P,
    input wire ETH4_TX_N,
    output wire ETH4_RX_N,
    */
    
    input wire SFP_CLK_P,    //Should be 156.25 MHz
    input wire SFP_CLK_N,
    
    //SFP Specialties
    output wire [1:0] ETH1_LED,
    //input wire ETH1_MOD_DETECT,
    //inout [1:0] ETH1_RS,
    input wire ETH1_RX_LOS,
    output wire ETH1_TX_DISABLE,
    input wire ETH1_TX_FAULT,
    
        /*
    
    output wire [1:0] ETH2_LED,
    //input wire ETH2_MOD_DETECT,
    //inout [1:0] ETH2_RS,
    input wire ETH2_RX_LOS,
    output wire ETH2_TX_DISABLE,
    input wire ETH2_TX_FAULT,
    
    
    output wire [1:0] ETH3_LED,
    output wire [1:0] ETH4_LED,

    output wire [1:0] ETH3_LED,
    input wire ETH3_MOD_DETECT,
    //inout [1:0] ETH3_RS,
    input wire ETH3_RX_LOS,
    output wire ETH3_TX_DISABLE,
    input wire ETH3_TX_FAULT,
    
    output wire [1:0] ETH4_LED,
    input wire ETH4_MOD_DETECT,
    //inout [1:0] ETH4_RS,
    input wire ETH4_RX_LOS,
    output wire ETH4_TX_DISABLE,
    input wire ETH4_TX_FAULT,
    */
    
    
    inout wire [63:0]ddr3_dq,
    inout wire [7:0]ddr3_dqs_n,
    inout wire [7:0]ddr3_dqs_p,
    output wire [15:0]ddr3_addr,
    output wire [2:0]ddr3_ba,
    output wire ddr3_ras_n,
    output wire ddr3_cas_n,
    output wire ddr3_we_n,
    output wire ddr3_reset_n,
    output wire [0:0]ddr3_ck_p,
    output wire [0:0]ddr3_ck_n,
    output wire [0:0]ddr3_cke,
    output wire [0:0]ddr3_cs_n,
    output wire [7:0]ddr3_dm,
    output wire [0:0]ddr3_odt,
    
    //input wire PCIE_CLK_N,
    //input wire PCIE_CLK_P,
    
    
    ////I2C zeugs
    //inout wire I2C_FPGA_SCL,
    //inout wire I2C_FPGA_SDA,
    //output wire I2C_MUX_RESET,
    //input wire SFP_CLK_ALARM_B,
    
    input wire [0:0] BTN

      );


     
      /*****************************************************************/
    
     //TODO
      wire clk156;  //Core clock
      wire reset; //TODO
    
      wire blink_s;
      
      //Drives the very slow blink clock
      blink_driver #(
        .REG_SIZE(25)
      ) blink_driver_inst (
       .clk_i(clk156),
       .blink_o(blink_s),
       .reset_i(reset)
      );
     

      
      // ================ ETH 1 Logic ======
      
      
      wire [7:0] eth1_pcspma_status;   //currently only for debugging
      wire [1:0] eth1_mac_status_vector;   //currently only for debugging
      wire [447:0] eth1_pcs_pma_status_vector;   //currently only for debugging
      wire eth1_rx_statistics_valid;
      wire eth1_tx_statistics_valid;
      
      
               
       led_driver eth1_led_dr (
                //.has_link(eth1_pcs_pma_status_vector[226]),
                .has_link_i(!ETH1_RX_LOS), //Imprecise. TODO: use the above if it works
                .on_frame_sent_i(eth1_tx_statistics_valid), //TODO missing in block design
                .on_frame_received_i(eth1_rx_statistics_valid), //TODO missing in block design
                .led_o(ETH1_LED),
                .blink_i(blink_s),
                .clk_i(clk156)
       );
     
     /* 
      // ================ ETH 2 Logic ======
       
     
      
      wire [7:0] eth2_pcspma_status;   //currently only for debugging
      wire [1:0] eth2_mac_status_vector;   //currently only for debugging
      wire [447:0] eth2_pcs_pma_status_vector;   //currently only for debugging
      wire eth2_rx_statistics_valid;
      wire eth2_tx_statistics_valid;
   
         
       led_driver eth2_led_dr (
                  //.has_link(eth2_pcs_pma_status_vector[226]),
                  .has_link_i(!ETH2_RX_LOS), //Imprecise. TODO: use the above if it works
                  .on_frame_sent_i(eth2_tx_statistics_valid), //TODO missing in block design
                  .on_frame_received_i(eth2_rx_statistics_valid), //TODO missing in block design
                  .led_o(ETH2_LED),
                  .blink_i(blink_s),
                  .clk_i(clk156)
       );
       
       */

      wire [79:0] mac_tx_configuration_vector;
      wire [79:0] mac_rx_configuration_vector;
      assign mac_tx_configuration_vector [79:32] = SRC_MAC;   //Transmitter Pause Frame Source Address TODO:LSB/MSB-Swap
      assign mac_tx_configuration_vector [30:16] = 1518;      //Programmed MTU
      assign mac_tx_configuration_vector [14] = 0;            //TX MTU Enable
      assign mac_tx_configuration_vector [10] = 0;            //Deficit Idle Count Enable: provides greater performance if no LAN mode.
      assign mac_tx_configuration_vector [9] = 0;             //Transmitter LAN/WAN Mode (LAN=0) 
      assign mac_tx_configuration_vector [8] = 0;             //Transmitter IFG Adjust Enable (may be significant. If 1, set the IFG Adjust!)
      assign mac_tx_configuration_vector [7] = 0;             //Preserve Preamble: We don't want custom preambles, so 0
      assign mac_tx_configuration_vector [5] = 0;             //Transmit Flow Control Enable: We don't need this in a first step.
      assign mac_tx_configuration_vector [4] = 1;             //We want jumbo frames: But we have to see..
      assign mac_tx_configuration_vector [3] = 0;             //Transmitter In-Band FCS Enable: We want the FCS to be done by the MAC, so 0
      assign mac_tx_configuration_vector [2] = 1;             //Transmitter VLAN Enable: We want VLAN tagged frames. But why VLAN-agnostic?
      assign mac_tx_configuration_vector [1] = 1;             //Transmitter Enable: The transmitter should work.
      assign mac_tx_configuration_vector [0] = 0;             //Transmitter Reset: We don't want the reset.
      
      
      //Tx Configuration
      assign mac_rx_configuration_vector [79:32] = DST_MAC;   //Receiver Pause Frame Source Address TODO:LSB/MSB-Swap
      assign mac_rx_configuration_vector [30:16] = 1518;      //Programmed MTU
      assign mac_rx_configuration_vector [14] = 0;            //RX MTU Enable
      assign mac_rx_configuration_vector [10] = 0;            //Reconciliation Sublayer Fault Inhibit
      assign mac_rx_configuration_vector [9] = 1;             //Control Frame Length Check Disable
      assign mac_rx_configuration_vector [8] = 1;             //Receiver Length/Type Error Disable
      assign mac_rx_configuration_vector [7] = 0;             //Preserve Preamble: We don't want custom preambles, so 0
      assign mac_rx_configuration_vector [5] = 0;             //Receive Flow Control Enable: We don't need this in a first step.
      assign mac_rx_configuration_vector [4] = 1;             //We want jumbo frames: But we have to see..
      assign mac_rx_configuration_vector [3] = 0;             //Receiver In-Band FCS Enable: We want the FCS to be removed by the MAC, so 0, But ALWAYS checked
      assign mac_rx_configuration_vector [2] = 1;             //Receiver VLAN Enable: We want VLAN tagged frames. But why VLAN-agnostic?
      assign mac_rx_configuration_vector [1] = 1;             //Receiver Enable: The transmitter should work.
      assign mac_rx_configuration_vector [0] = 0;             //Receiver Reset: We don't want the reset.

      wire [535:0] pcs_pma_configuration_vector;     

      pcs_pma_conf pcs_pma_conf_inst (
          .pcs_pma_configuration_vector(pcs_pma_configuration_vector)
      );
      
`default_nettype wire

 synth_infrastructure synth_infrastructure_inst (
 
     .pcie_7x_mgt_0_rxn(pcie_7x_mgt_0_rxn),
     .pcie_7x_mgt_0_rxp(pcie_7x_mgt_0_rxp),
     .pcie_7x_mgt_0_txn(pcie_7x_mgt_0_txn),
     .pcie_7x_mgt_0_txp(pcie_7x_mgt_0_txp),
     .pcie_clk_i_clk_p(PCIE_CLK_P),
     .pcie_clk_i_clk_n(PCIE_CLK_N),
     .pcie_sys_rst_i(pcie_sys_resetn),
 
    .clk_156_o(clk156),
    .reset_0(1'b0),
    .rst_o(reset),
    
    .FPGA_SYS_CLK_clk_n(FPGA_SYSCLK_N),
    .FPGA_SYS_CLK_clk_p(FPGA_SYSCLK_P),
    
    .DDR3_SYS_CLK_clk_n(DDR3_SYSCLK_N),
    .DDR3_SYS_CLK_clk_p(DDR3_SYSCLK_P),
    
    .DDR3_addr(ddr3_addr),
    .DDR3_ba(ddr3_ba),
    .DDR3_cas_n(ddr3_cas_n),
    .DDR3_ck_n(ddr3_ck_n),
    .DDR3_ck_p(ddr3_ck_p),
    .DDR3_cke(ddr3_cke),
    .DDR3_cs_n(ddr3_cs_n),
    .DDR3_dm(ddr3_dm),
    .DDR3_dq(ddr3_dq),
    .DDR3_dqs_n(ddr3_dqs_n),
    .DDR3_dqs_p(ddr3_dqs_p),
    .DDR3_odt(ddr3_odt),
    .DDR3_ras_n(ddr3_ras_n),
    .DDR3_reset_n(ddr3_reset_n),
    .DDR3_we_n(ddr3_we_n),
    
    .rx_config(mac_rx_configuration_vector),
    .tx_config(mac_tx_configuration_vector),
    .pcs_pma_config(pcs_pma_configuration_vector),
    
    .ref_clk_n(SFP_CLK_N),
    .ref_clk_p(SFP_CLK_P),
    
    .singal_detect_0(!ETH1_RX_LOS),
    .tx_disable_0_o(ETH1_TX_DISABLE),
    .tx_fault_0_i(ETH1_TX_FAULT),
    .rxn0(ETH1_TX_N),    
    .rxp0(ETH1_TX_P),
    .txn0(ETH1_RX_N),
    .txp0(ETH1_RX_P)
    
    /*
    
    .singal_detect_1(!ETH2_RX_LOS),
    .tx_disable_1_o(ETH2_TX_DISABLE),
    .tx_fault_1_i(ETH2_TX_FAULT),
    .txn1(ETH2_RX_N),
    .txp1(ETH2_RX_P),
    .rxn1(ETH2_TX_N),
    .rxp1(ETH2_TX_P)
    */
    );


endmodule






















