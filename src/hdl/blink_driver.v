`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: TU Darmstadt, Fachgebiet PS
// Engineer: Leonhard Nobach
//
// Create Date: 06/23/2015 03:01:35 PM
// Design Name: 
// Module Name: blink_driver
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


module blink_driver #(

    parameter REG_SIZE = 25
    
    //200 MHz / 2^25 = 5,96 Hz > Blink frequency

 )(
    input wire clk_i,
    output wire blink_o,
    input wire reset_i
);
    
reg[REG_SIZE-1:0] c = 0;

always @(posedge clk_i) begin
    if(reset_i) begin
        c <= 0;
    end else begin
        c <= c+1;
    end
end

assign blink_o = c[REG_SIZE-1];



    
endmodule


















