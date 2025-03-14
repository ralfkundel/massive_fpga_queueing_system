`timescale 1ns / 1ps
//`default_nettype none
/*******************************
*
* author: Ralf Kundel, TU Darmstadt
* date: 28.08.2018
********************************/


module axis_fifo #(
	parameter ADDR_WIDTH = 10,
	parameter DATA_WIDTH = 64,
	parameter PACKET_SIZE_WIDTH = 11,
    parameter KEEP_WIDTH = DATA_WIDTH/8
)(
	input  wire                   clk_i,
	input  wire                   resetn_i,

    output wire                   s_axis_tready_o,
	input  wire                   s_axis_tvalid_i,
	input  wire [DATA_WIDTH-1:0]  s_axis_tdata_i,
    input  wire [KEEP_WIDTH-1:0]  s_axis_tkeep_i,
    input  wire                   s_axis_tlast_i,
    
	input  wire                   m_axis_tready_i,
	output reg  [DATA_WIDTH-1:0]  m_axis_tdata_o,
    output reg  [KEEP_WIDTH-1:0]  m_axis_tkeep_o,
    output reg                    m_axis_tlast_o,
    output reg                    m_axis_tvalid_o,
    
    output reg [PACKET_SIZE_WIDTH-1:0]          m_packet_length_o,   //in bytes
    
    output wire full_o,
    output wire empty_o
    
);

reg [ADDR_WIDTH:0]  addr_in, addr_in_old ,addr_out;

reg [DATA_WIDTH-1:0]            memory_data   [2**ADDR_WIDTH-1:0];
reg [KEEP_WIDTH-1:0]            memory_keep   [2**ADDR_WIDTH-1:0];
reg                             memory_last   [2**ADDR_WIDTH-1:0];
wire empty, full;
assign full_o = full;
assign empty_o = empty;


localparam PLENGTH_ADDR_WIDTH = ADDR_WIDTH;
reg [PLENGTH_ADDR_WIDTH-1+1:0]  plength_addr_in_s, plength_addr_out_s, next_plength_addr_out_s;
reg [PACKET_SIZE_WIDTH-1 : 0]   memory_plength [2**PLENGTH_ADDR_WIDTH-1:0]; //if we assume 65 byte min sized packets at 512 bit axis

//input:

assign empty = (addr_in == addr_out);
assign full =  (addr_in[ADDR_WIDTH] != addr_out[ADDR_WIDTH]) && (addr_in[ADDR_WIDTH-1:0] == addr_out[ADDR_WIDTH-1:0]); //when only the first bit differs, memory is full


assign s_axis_tready_o = ~full;


reg [PACKET_SIZE_WIDTH-1 : 0]   received_plength_s, new_received_plength_s;
localparam KEEP_WIDTH_LOG = $clog2(KEEP_WIDTH);
reg [KEEP_WIDTH_LOG:0]  num_rec_bytes_s;
reg store_rec_bytes_s;
reg store_data_s;
reg revert_rec_packet;

integer i;
always @(*) begin
    num_rec_bytes_s = 0;
    for (i=0; i < KEEP_WIDTH; i=i+1) begin
        if (s_axis_tkeep_i[i] == 1'b1) begin
            num_rec_bytes_s = i+1;
        end
    end
end

localparam wait_for_data_istate = 2'b00;
localparam store_istate = 2'b01;
localparam wait_bc_full_istate = 2'b10;
reg [1:0] istate = wait_for_data_istate, next_istate = wait_for_data_istate;
//Input:
always @(*) begin
    new_received_plength_s = 0;
    next_istate = wait_for_data_istate;
    store_rec_bytes_s = 1'b0;
    store_data_s = 1'b0;
    revert_rec_packet = 1'b0;
    
    case (istate)
    
        wait_for_data_istate: begin
            if(s_axis_tvalid_i) begin
                if(full) begin
                    next_istate = wait_bc_full_istate;
                end else begin
                    next_istate = store_istate;
                    new_received_plength_s =  num_rec_bytes_s;
                    store_data_s = 1'b1;
                    if(s_axis_tlast_i) begin
                        next_istate = wait_for_data_istate;
                        store_rec_bytes_s = 1'b1;
                    end
                end
            end
        end
        
        store_istate: begin
            next_istate = store_istate;
            new_received_plength_s = received_plength_s;
            
            if(s_axis_tvalid_i) begin
                store_data_s = 1'b1;
                new_received_plength_s = received_plength_s + num_rec_bytes_s;
                if(s_axis_tlast_i) begin
                    next_istate = wait_for_data_istate;
                    store_rec_bytes_s = 1'b1;
                end
            end
            
            if(full) begin
                next_istate = wait_bc_full_istate;
                revert_rec_packet = 1'b1;
                store_data_s = 1'b0;
                store_rec_bytes_s = 1'b0;
                if(s_axis_tlast_i && s_axis_tvalid_i) begin
                    next_istate = wait_for_data_istate;
                end
            end
        end
        
        wait_bc_full_istate: begin
            next_istate = wait_bc_full_istate;
                if(s_axis_tlast_i && s_axis_tvalid_i) begin
                    next_istate = wait_for_data_istate;
                end
        end
    endcase
end

//Input:
always @(posedge clk_i) begin
    if(~resetn_i) begin
        istate <= wait_for_data_istate;
        addr_in  <= 0;
        addr_in_old <= 0;
        plength_addr_in_s <= 0;
        received_plength_s <= 0;
    end else begin
        istate <= next_istate;
        received_plength_s <= new_received_plength_s;
        
        if (store_data_s) begin
                memory_data[addr_in[ADDR_WIDTH-1:0]] <= s_axis_tdata_i;
                memory_keep[addr_in[ADDR_WIDTH-1:0]] <= s_axis_tkeep_i;
                memory_last[addr_in[ADDR_WIDTH-1:0]] <= s_axis_tlast_i;
                addr_in <= addr_in + 1;
        end
        
        if (store_rec_bytes_s) begin
            memory_plength[plength_addr_in_s[PLENGTH_ADDR_WIDTH-1:0]] <= new_received_plength_s;
            plength_addr_in_s <= plength_addr_in_s + 1;
            addr_in_old <= addr_in + 1;
        end
        if (revert_rec_packet) begin
            addr_in <= addr_in_old;
        end
        
    end
end


//output:
localparam wait_for_data_ostate = 2'b00;
localparam send_ostate = 2'b01;
localparam wait_for_slave_ostate = 2'b10;
reg [1:0] ostate, next_ostate;
reg send_next_data_s, send_no_data_s;
//Output:
always @(*) begin
    next_ostate = wait_for_data_ostate;
    next_plength_addr_out_s = plength_addr_out_s;
    send_next_data_s = 1'b0;
    send_no_data_s = 1'b0;
    
    case (ostate)
        wait_for_data_ostate: begin
            if(plength_addr_out_s != plength_addr_in_s) begin
                next_ostate = send_ostate;
                 send_next_data_s = 1'b1;
            end
        end
        send_ostate: begin
            if(m_axis_tlast_o && m_axis_tready_i) begin   //send last data
                next_ostate = wait_for_data_ostate;
                next_plength_addr_out_s = plength_addr_out_s + 1;
                send_no_data_s = 1'b1;
                if(next_plength_addr_out_s != plength_addr_in_s) begin
                    next_ostate = send_ostate;
                    send_next_data_s = 1'b1;
                    send_no_data_s = 1'b0;
                end
            end else begin
                if(m_axis_tready_i) begin //send normal data
                    next_ostate = send_ostate;
                    send_next_data_s = 1'b1;
                end else begin //slave can not receive data
                    next_ostate = wait_for_slave_ostate;
                     send_next_data_s = 1'b0;
                end
            end
        end
        
        wait_for_slave_ostate: begin
            next_ostate = wait_for_slave_ostate;
            if(m_axis_tready_i) begin
                if(m_axis_tlast_o) begin
                    next_ostate = wait_for_data_ostate;
                    next_plength_addr_out_s = plength_addr_out_s + 1;
                    send_no_data_s = 1'b1;
                end else begin //normal continue sending
                    next_ostate = send_ostate;
                    send_next_data_s = 1'b1;
                end
            end
        end
    endcase
    
end

//Output:
always @(posedge clk_i) begin
    if(~resetn_i) begin
        ostate <= wait_for_data_ostate;
        addr_out <= 0;
        plength_addr_out_s <= 0;
        m_axis_tdata_o   <= 'bx;
        m_axis_tkeep_o   <= 0;
        m_axis_tlast_o   <= 0;
        m_axis_tvalid_o  <= 0;
    end else begin
        ostate <= next_ostate;
        if(send_next_data_s) begin
            m_axis_tdata_o   <= memory_data[addr_out[ADDR_WIDTH-1:0]];
            m_axis_tkeep_o   <= memory_keep[addr_out[ADDR_WIDTH-1:0]];
            m_axis_tlast_o   <= memory_last[addr_out[ADDR_WIDTH-1:0]];
            m_axis_tvalid_o  <= 1'b1;
            addr_out <= addr_out + 1;
            m_packet_length_o <= memory_plength[next_plength_addr_out_s[PLENGTH_ADDR_WIDTH-1:0]];
        end
        if(send_no_data_s) begin
            m_axis_tlast_o   <= 0;
            m_axis_tvalid_o <= 1'b0;
        end
        plength_addr_out_s <= next_plength_addr_out_s;
    end
end

endmodule
