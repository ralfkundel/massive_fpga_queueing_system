`timescale 1ns / 1ps
///////////////////////////////////////////////////////
// slow fifo which can accept data in every second clock cycle
 ////////////////////////////////////////////////////////
module simple_queue #(
    parameter WIDTH = 1,
    parameter DEPTH = 64
)(
    input wire clk_i,
    input wire rst_i,
    
    
    input wire [WIDTH-1:0] data_i,
    input wire valid_i,
    output reg ack_o,
    output wire ready_o,
    
    output reg [WIDTH-1:0] data_o,
    output reg valid_o,
    input wire pop_i
    

);
localparam ADDR_BITS = $clog2(DEPTH);

reg [WIDTH-1:0] mem [DEPTH-1:0];
reg [ADDR_BITS:0] in_pointer_s, out_pointer_s;

wire full = ((in_pointer_s[ADDR_BITS] != out_pointer_s[ADDR_BITS]) && (in_pointer_s[ADDR_BITS-1:0] == out_pointer_s[ADDR_BITS-1:0]));
wire empty = (in_pointer_s == out_pointer_s);

assign ready_o = !full && !ack_o;


always @(posedge clk_i) begin
    if(rst_i) begin
        in_pointer_s <= 0;
        ack_o <= 1'b0;
    end else begin
        if(valid_i && !full && !ack_o) begin
            mem[in_pointer_s[ADDR_BITS-1:0]] <= data_i;
            in_pointer_s <= in_pointer_s + 1;
            ack_o <= 1'b1;
        end else begin
            ack_o <= 1'b0;
        end
    end
end


wire [ADDR_BITS:0] inc_out_pointer_s = out_pointer_s +1;
wire inc_empty = (in_pointer_s == inc_out_pointer_s);

always @(posedge clk_i) begin
    if(rst_i) begin
        out_pointer_s <= 0;
        valid_o <= 1'b0;
    end else begin
        if(!empty && !valid_o) begin
            valid_o <= 1'b1;
            data_o <= mem[out_pointer_s[ADDR_BITS-1:0]];
        end else if(valid_o && pop_i) begin
            out_pointer_s <= inc_out_pointer_s;
            if(inc_empty) begin
                valid_o <= 1'b0;
            end else begin
                data_o <= mem[inc_out_pointer_s[ADDR_BITS-1:0]];
            end
        end
    end
end

endmodule