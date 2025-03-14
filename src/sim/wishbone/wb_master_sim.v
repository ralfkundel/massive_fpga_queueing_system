`timescale 1ns / 1ps
`default_nettype none

module wb_master_sim #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32,
    parameter FILENAME = "/home/USER/any/file.txt"

)(
    input wire clk_i,
    input wire rst_i,
    
    input wire [DATA_WIDTH-1:0]    wb_data_i,
    output wire [DATA_WIDTH-1:0]   wb_data_o,
    output wire [ADDR_WIDTH-1:0]   wb_addr_o,
    output wire                    wb_we_o,
    output reg                     wb_cyc_o,
    output wire [DATA_WIDTH/8-1:0] wb_stb_o,
    
    
    input wire wb_ack_i
    
    

);
assign wb_we_o = 1'b1;
assign wb_stb_o = {DATA_WIDTH/8-{1'b1}};

integer rxFile;
initial begin
    rxFile = $fopen(FILENAME,"r");
    if(! rxFile) begin
        $finish;
    end
end

reg [ADDR_WIDTH-1:0] read_address;
reg [DATA_WIDTH-1:0] read_data;

reg get_next_data_s, reached_end_s;


always @ (posedge clk_i) begin
    if(rst_i) begin
        reached_end_s <= 1'b0;
    end else if (!$feof(rxFile)) begin
        if(get_next_data_s) begin
            $fscanf(rxFile,"%h\n",read_address);
            $fscanf(rxFile,"%h\n",read_data);
        end
    end else begin
        reached_end_s <= 1'b1;
    end

end

reg [1:0] state, next_state;
localparam state_idle = 0;
localparam state_write = 1;


assign wb_data_o = read_data;
assign wb_addr_o = read_address;

always@(*) begin
    get_next_data_s = 1'b0;
    wb_cyc_o = 1'b0;
    
    case (state)
        state_idle:begin 
            if(!reached_end_s) begin
                get_next_data_s = 1'b1;
                next_state = state_write;
            end
        end
        
        
        state_write: begin
            next_state = state_write;
            wb_cyc_o = 1'b1;
            if(wb_ack_i) begin
                next_state = state_idle;
            end
        end
        
        
        
    endcase
end


always @(posedge clk_i) begin
    if(rst_i)begin
        state <= state_idle;
    end else begin
        state <= next_state;
    end

end


endmodule