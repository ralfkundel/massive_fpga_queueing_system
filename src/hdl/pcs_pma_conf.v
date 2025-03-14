`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2015 11:48:01
// Design Name: 
// Module Name: pcs_pma_conf
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pcs_pma_conf(

    output wire [535:0] pcs_pma_configuration_vector

    );
    
    assign pcs_pma_configuration_vector[0] = 0;         //PMA Loopback Mode (1.0.0)
    assign pcs_pma_configuration_vector[15] = 0;        //PMA Reset (1.0.15)
    assign pcs_pma_configuration_vector[16] = 0;        //Global PMD Transmit Disable (1.9.0)
    assign pcs_pma_configuration_vector[110] = 0;       //10GBaseR/KR Loopback 0 = Do not use(3.0.14)
    assign pcs_pma_configuration_vector[111] = 0;       //PCS Reset (3.0.15)
    assign pcs_pma_configuration_vector[169:112] = 58'b0;   //; Test Pattern Seed A0-3  (3.37-3.34)
    assign pcs_pma_configuration_vector[233:176] = 58'b0;   //; Test Pattern Seed B0-3  (3.41-3.38)
    assign pcs_pma_configuration_vector[240] = 0;       //Data Pattern Select (3.42.0)
    assign pcs_pma_configuration_vector[241] = 0;         //Test Pattern Select (3.42.1)
    assign pcs_pma_configuration_vector[242] = 0;         //RX Test Pattern Checking Enable (3.42.2)
    assign pcs_pma_configuration_vector[243] = 0;         //TX Test Pattern Enable (3.42.3)
    assign pcs_pma_configuration_vector[244] = 0;         //PRBS31 TX Test Pattern Enable (3.42.4)
    assign pcs_pma_configuration_vector[245] = 0;         //PRBS31 TX Test Pattern Checking Enable  (3.42.5)
    
    assign pcs_pma_configuration_vector[399:384] = 16'b0;     //125mus timer control (3.65535.15:0)
    
    assign pcs_pma_configuration_vector[512] = 0;         //Reset: Set PMA Link Status (1.1.2)      //TODO: stimmt das?
    assign pcs_pma_configuration_vector[513] = 0;         //Reset: Clear PMA/PMD Link Faults (1.8.10/1.8.11)
    assign pcs_pma_configuration_vector[516] = 0;         //Reset: Set PCS Link Status (3.1.2)
    assign pcs_pma_configuration_vector[517] = 0;         //Reset: Clear PCS Link Faults (3.8.10/3.8.11)
    assign pcs_pma_configuration_vector[518] = 0;         //Reset: MDIO Register 3.33: 10GBase-R Status 2
    assign pcs_pma_configuration_vector[519] = 0;         //Reset: MDIO Register 3.43: 10GBase-R Test Pattern Counter
    
    
    //Data Pattern Select (3.42.0)
    
    
endmodule
