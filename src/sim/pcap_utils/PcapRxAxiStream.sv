`timescale 1ns / 1ps
`default_nettype none
/*******************************
* This Module opens a pcap file and sends all packets over axistream to a NetFPGA design
*
* TODO: timestamps in the pcap file are ignored at the moment
* TODO: deep test: axi interruptions (to test flow control) IMPORTANT
* TODO: at the moment always one clockcyle pause is between two packets. Is it valid axis without a break? --> implement it
*
* author: Ralf Kundel, TU Darmstadt
* date: 15.02.2018
********************************/

module pcap_rx_axi #(
    parameter FILENAME = "",
    parameter AXIS_DATA_WIDTH =64,
    parameter KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter ENABLE_INTERRUPTION = 0,
    parameter ENABLE_FAST_SEND = 0
)(
    input wire clk_i,
    input wire rst_i,

	output reg         m_axis_tvalid_o,
    input  wire        m_axis_tready_i,
    output reg [AXIS_DATA_WIDTH-1:0] m_axis_tdata_o,
    output reg  [KEEP_WIDTH-1:0]  m_axis_tkeep_o,
    output reg         m_axis_tlast_o,
    output wire [0:0]  m_axis_tuser_o

);

assign m_axis_tuser_o = 0;

integer rxFile;
reg [31:0] read32;
reg [7:0] read8;
initial begin
    rxFile = $fopen(FILENAME,"rb");
    if(! rxFile) begin
        $finish;
    end
    #100
    
    $fread(read32, rxFile);
    $display ("PCAP magic Number: 0x%h", read32);
    $fread(read32, rxFile); //file format
    $fread(read32, rxFile); //file format
    $fread(read32, rxFile); //accuracy
    $fread(read32, rxFile); //max length of captured packets
    $display ("Max length of captured Packets: 0x%h", read32);
    $fread(read32, rxFile); //data link type
    $display ("Data Link Type: 0x%h", read32);
    //End of global pcap header
    parse_packet_header();
    

end

integer packet_length;
reg send_packet, stop_send_packet;
reg [7:0] packet_data [2047:0]; //TODO: this assumes that a packet can not be bigger than 2048 byte
initial stop_send_packet = 0;
task parse_packet_header();
begin
    $fread(read32, rxFile);
    
    if($feof(rxFile)) begin
        $display("feof");
        stop_send_packet=1;
        return;
    end
    $display ("timestamp seconds: 0x%h", read32);
    $fread(read32, rxFile);
    $display ("timestamp microseconds: 0x%h", read32);
    $fread(read32, rxFile);
    $display ("number of octets: 0x%h", read32);
    $fread(read32, rxFile);
    packet_length = {{read32[7:0], read32[15:8], read32[23:16], read32[31:24]}}; //convert little endian
    $display ("actual packet length: 0x%h", packet_length);
    $display ("actual packet length: %d", packet_length);
    for(integer i=0; i < packet_length; i++) begin
        $fread(read8, rxFile);
        packet_data[i] = read8;
        //$display ("Data: 0x%h", read8);
    end
    send_packet=1;
    wait(send_packet == 0);
    parse_packet_header();
    
end
endtask

integer send_counter;

wire [31:0] to_send = packet_length - send_counter;
wire next_package_s = (send_counter == 0);
reg [8:0] interrupt_counter;
reg pause_s = 0;

always @(posedge clk_i) begin
    #1
    m_axis_tlast_o <= 1'b0;
    m_axis_tvalid_o <= 1'b0;
    m_axis_tkeep_o <= 0;
     pause_s <= 0;
    if(rst_i || stop_send_packet || pause_s) begin
        interrupt_counter <= 0;
        send_counter <= 0;
    end else begin
    
        if(interrupt_counter == 3 && ENABLE_INTERRUPTION) begin
            m_axis_tvalid_o <=0; 
             interrupt_counter <= 0;    
            
        end else if(to_send > 0) begin
            m_axis_tvalid_o <= 1'b1;
            if(to_send > KEEP_WIDTH) begin //number of bytes to be send is higher than axi stream width
                for(integer i=0; i < KEEP_WIDTH; i++)begin
                    m_axis_tdata_o[i*8 +: 8] <= packet_data[i+send_counter];
                end
                send_counter <= send_counter+KEEP_WIDTH;
                m_axis_tkeep_o <= {KEEP_WIDTH{1'b1}};
                interrupt_counter = interrupt_counter + 1;
            end else begin

                for(integer i=0; i < to_send; i++)begin
                    m_axis_tdata_o[i*8 +: 8] <= packet_data[i+send_counter];
                end
                for(integer i=to_send; i < KEEP_WIDTH; i++)begin
                    m_axis_tdata_o[i*8 +: 8] <= 8'bx;
                end
                send_counter <= send_counter+to_send;
                m_axis_tlast_o <= 1'b1;
                if (~ENABLE_FAST_SEND) 
                    pause_s <= 1;
                m_axis_tkeep_o <= (1'b1 << to_send)-1;
                send_packet <= 1'b0;
                send_counter <= 0;
                interrupt_counter <= 0;
            end
            
        end
    end
    
end


endmodule