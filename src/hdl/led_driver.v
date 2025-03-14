`default_nettype none
`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: TU Darmstadt, Fachgebiet PS
// Engineer: Leonhard Nobach 
// 
// Create Date: 06/23/2015 02:47:58 PM
// Design Name: 
// Module Name: led_driver
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


module led_driver(
    input wire has_link_i,
    input wire on_frame_sent_i,
    input wire on_frame_received_i,
    output wire [1:0] led_o,
    input wire blink_i,
    input wire clk_i
    );

reg frame_sent_s = 1'b0;
reg frame_received_s = 1'b0;
reg lastblink_s = 1'b0;

reg blinkoff_tx_s = 1'b0;
reg blinkoff_rx_s = 1'b0;

always @(posedge clk_i)
begin
  if (on_frame_sent_i) frame_sent_s <= 1'b1;
  if (on_frame_received_i) frame_received_s <= 1'b1;
  lastblink_s <= blink_i;
  
  if (blink_i & !lastblink_s)
  begin
    if (frame_sent_s) blinkoff_tx_s <= 1'b1;
    if (frame_received_s) blinkoff_rx_s <= 1'b1;
    frame_sent_s <= 1'b0;
    frame_received_s <= 1'b0;
  end
  if (!blink_i & lastblink_s)
  begin
    blinkoff_tx_s <= 1'b0;
    blinkoff_rx_s <= 1'b0;
  end
  

end

assign led_o[0] = has_link_i & !blinkoff_tx_s;
assign led_o[1] = has_link_i & !blinkoff_rx_s;


    
endmodule
