`timescale 1ns / 1ps
`default_nettype none
/*******************************
* This Module receives packets over axis and writes them in a pcap file
* 
* TODO: deep test: simulate flow control with tready_o to zero
*
* author: Ralf Kundel, TU Darmstadt
* date: 15.02.2018
********************************/
module pcap_tx_axi #(
    parameter FILENAME = "",
    parameter AXIS_DATA_WIDTH =64,
    parameter KEEP_WIDTH = AXIS_DATA_WIDTH/8,
    parameter ENABLE_INTERRUPTION = 0
)(
    input wire clk_i,
    input wire rst_i,

	input wire         s_axis_tvalid_i,
    output  reg        s_axis_tready_o,
    input wire [AXIS_DATA_WIDTH-1:0] s_axis_tdata_i,
    input wire  [KEEP_WIDTH-1:0]  s_axis_tkeep_i,
    input wire         s_axis_tlast_i,
    input wire [0:0]  s_axis_tuser_i

);


integer txFile;
initial begin
    txFile = $fopen(FILENAME);
    if(! txFile) begin
        $finish;
    end
    writeBytesToFile(32'hd4c3b2a1, 6'd4); //Magic Number
    writeBytesToFile(16'h0200, 6'd2); //File Format Major revision //TODO
    writeBytesToFile(16'h0400, 6'd2); //File Format Minor revision
    writeBytesToFile(32'h0, 6'd4);
    writeBytesToFile(32'h0, 6'd4);
    writeBytesToFile(32'hffff0000, 6'd4);
    writeBytesToFile(32'h01000000, 6'd4);
    
    //$fclose(txFile);
    $fflush(txFile);
end


function writeBytesToFile;
input [511:0]data;
input [5:0] numBytes;
begin
    case(numBytes)
       1: $fwrite(txFile, "%C", data[7:0]);
       2: $fwrite(txFile, "%C%C", data[15:8], data[7:0]);
       3: $fwrite(txFile, "%C%C%C", data[23:16], data[15:8], data[7:0]);
       4: $fwrite(txFile, "%C%C%C%C", data[31:24], data[23:16], data[15:8], data[7:0]);
       5: $fwrite(txFile, "%C%C%C%C%C",  data[39:32], data[31:24], data[23:16], data[15:8], data[7:0]);
       6: $fwrite(txFile, "%C%C%C%C%C%C",  data[47:40], data[39:32], data[31:24], data[23:16], data[15:8], data[7:0]);
       7: $fwrite(txFile, "%C%C%C%C%C%C%C",  data[55:48], data[47:40], data[39:32], data[31:24], data[23:16], data[15:8], data[7:0]);
       8: $fwrite(txFile, "%C%C%C%C%C%C%C%C", data[63:56], data[55:48], data[47:40], data[39:32], data[31:24], data[23:16], data[15:8], data[7:0]);
    endcase
end
endfunction

reg [7:0] packet_data [2047:0];
reg[31:0] packet_length;
reg [63:0] rec_time, next_rec_time;

reg state, next_state;
reg take_data_s;

always @(*) begin
    next_state = 0;
    next_rec_time = rec_time;
    case(state)
        0: begin
            if(s_axis_tvalid_i) begin
                next_state = 1;
                next_rec_time = $time;
            end
        end
        1: begin
            next_state = 1;
            if (s_axis_tlast_i) begin
                next_state = 0;
            end
        
        end
    endcase
end

reg [8:0] interrupt_counter;
reg interrupt_startup_enabled_s;
initial begin
    #10
    interrupt_startup_enabled_s = 1;
    @(~rst_i); 
    #800
    interrupt_startup_enabled_s = 0;
    
end

wire [64:0] num_bytes_in_current_cycle = s_axis_tkeep_i+1;

always @(posedge clk_i) begin

    if(rst_i) begin
        packet_length = 0;
        state <= 0;
        interrupt_counter <= 0;
    end else begin
        rec_time = next_rec_time;
        state <= next_state;
        if(state == 1)
            interrupt_counter <= interrupt_counter + 1;
        if(s_axis_tvalid_i) begin
            integer current_length = $clog2(num_bytes_in_current_cycle);
            $display("%d", current_length);
            if(s_axis_tready_o) begin
                for(integer i=0; i < current_length; i++) begin
                         packet_data[i + packet_length] = s_axis_tdata_i[i*8 +: 8];
                end
                packet_length = packet_length + current_length;
                if(s_axis_tlast_i) begin
                    write_packet();
                    packet_length = 0;
                    interrupt_counter <= 0;
                end
            end
        end
    end
end

always @(posedge clk_i) begin
    #1
    if( (interrupt_counter == 3 && ENABLE_INTERRUPTION) || interrupt_startup_enabled_s) begin
        s_axis_tready_o <= 1'b0;
    end else begin
        s_axis_tready_o <= 1'b1;
    end
end


task write_packet();
reg [31:0] w_length;
begin
    $display("time %h", rec_time);
   //big to little endian converter
   for(integer w = 1; w>=0; w--) begin
    for(integer i=0; i <4; i++) begin
        writeBytesToFile(rec_time[(w*32+8*i)+:8], 6'd1);
    end
   end
    w_length = {{packet_length[7:0], packet_length[15:8], packet_length[23:16], packet_length[31:24]}};
    writeBytesToFile(w_length, 6'd4);
    writeBytesToFile(w_length, 6'd4);
     //write packet data
    for(integer i=0; i < packet_length; i++) begin
        writeBytesToFile(packet_data[i], 6'd1);
    end
    $fflush(txFile);
end
endtask;

endmodule
