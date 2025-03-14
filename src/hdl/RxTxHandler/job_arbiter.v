`timescale 1ns / 1ps

module job_arbiter #(
    parameter WIDTH = 4,
    parameter DEPTH = 4
)(
    input wire clk_i,
    input wire rst_i,
    
    //inport 1 - high priority
    input wire [WIDTH-1:0] p1_data_i,
    input wire p1_valid_i,
    output wire p1_ack_o,
    output wire p1_ready_o,
    
    //inport 2 - low priority
    input wire [WIDTH-1:0] p2_data_i,
    input wire p2_valid_i,
    output wire p2_ack_o,
    output wire p2_ready_o,
    
    //outport
    output reg [WIDTH-1:0] out_data_o,
    output reg out_valid_o,
    input wire out_pop_i
    

);
    wire  [WIDTH-1:0] p1_data_s, p2_data_s;
    wire p1_valid_s, p2_valid_s;
    reg p1_pop_s, p2_pop_s;
    
    reg [1:0] state, next_state;
    localparam state_idle = 0;
    localparam state_valid1 = 1;
    localparam state_valid2 = 2;
        
    
    always @(*) begin
        out_data_o = p1_data_s;
        out_valid_o = p1_valid_s;
        p1_pop_s = 1'b0;
        p2_pop_s = 1'b0;
        
        
        next_state = state_idle;
        case (state) 
            state_idle: begin
            if(p1_valid_s) begin
                next_state = state_valid1;
            end else if (p2_valid_s) begin
                next_state = state_valid2;
                out_data_o = p2_data_s;
                out_valid_o = 1'b1;
            end
            
            end
            state_valid1: begin
                next_state = state_valid1;
                if(out_pop_i) begin
                    next_state = state_idle;
                    p1_pop_s = 1'b1;
                end
            end
            
            state_valid2: begin
                next_state = state_valid2;
                out_data_o = p2_data_s;
                out_valid_o = 1'b1;
                if(out_pop_i) begin
                    next_state = state_idle;
                    p2_pop_s = 1'b1;
                end
            end
        endcase
    
    end
    
    always @(posedge clk_i) begin
        if(rst_i) begin
            state <= state_idle;
        end else begin
            state <= next_state;
        end
    end
    

    simple_queue #(
        .WIDTH(WIDTH),
        .DEPTH(32)
    )p1_queue_inst (
        .rst_i(rst_i),
        .clk_i(clk_i),
        
        .data_i(p1_data_i),
        .valid_i(p1_valid_i),
        .ack_o(p1_ack_o),
        .ready_o(p1_ready_o),
        
        .data_o(p1_data_s),
        .valid_o(p1_valid_s),
        .pop_i(p1_pop_s)
    
    );
    
    
    simple_queue #(
        .WIDTH(WIDTH),
        .DEPTH(32)
    )p2_queue_inst (
        .rst_i(rst_i),
        .clk_i(clk_i),
        
        .data_i(p2_data_i),
        .valid_i(p2_valid_i),
        .ack_o(p2_ack_o),
        .ready_o(p2_ready_o),
        
        .data_o(p2_data_s),
        .valid_o(p2_valid_s),
        .pop_i(p2_pop_s)
    
    );

endmodule