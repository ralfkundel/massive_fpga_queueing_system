module dualport_ram_bw #(
    parameter READ_PIPE_STAGES_A = 0,
    parameter READ_PIPE_STAGES_B = 0,
    parameter ADDR_WIDTH = 8,
    parameter MEM_DEPTH = 2**ADDR_WIDTH,
    parameter NUM_BYTES = 4,
    parameter BYTE_WIDTH = 8,
    parameter DATA_WIDTH = NUM_BYTES*BYTE_WIDTH
)(
	input wire clk_i,
    // Port A
    input   wire    [NUM_BYTES-1:0]   a_we_i,
    input   wire    [ADDR_WIDTH-1:0]  a_addr_i,
    input   wire    [DATA_WIDTH-1:0]  a_din_i,
    output  wire     [DATA_WIDTH-1:0]  a_dout_o,
     
    // Port B
    input   wire    [NUM_BYTES-1:0]   b_we_i,
    input   wire    [ADDR_WIDTH-1:0]  b_addr_i,
    input   wire    [DATA_WIDTH-1:0]  b_din_i,
    output  wire    [DATA_WIDTH-1:0]  b_dout_o
);
    (* ram_style = "ultra" *)
	reg [DATA_WIDTH-1:0] memory [MEM_DEPTH-1:0];


	
	integer i;



	// Port A
    reg [DATA_WIDTH-1:0] a_dout_o_reg [READ_PIPE_STAGES_A:0];
    assign a_dout_o = a_dout_o_reg[0];
    
    always @(posedge clk_i) begin
        for(i = 0;i<READ_PIPE_STAGES_A;i=i+1) 
            a_dout_o_reg[i] <= a_dout_o_reg[i+1];
    end


	always @(posedge clk_i) begin
	
      for(i = 0;i<NUM_BYTES;i=i+1) 
        if(a_we_i[i])
            memory[a_addr_i][i*BYTE_WIDTH +: BYTE_WIDTH] <= a_din_i[i*BYTE_WIDTH +: BYTE_WIDTH];
        
		if(~|a_we_i) begin
		  a_dout_o_reg[READ_PIPE_STAGES_A] <= memory[a_addr_i];
		end
	end
	
	
	
	// Port B
	
	reg [DATA_WIDTH-1:0] b_dout_o_reg [READ_PIPE_STAGES_B:0];
    assign b_dout_o = b_dout_o_reg[0];
    
    always @(posedge clk_i) begin
        for(i = 0;i<READ_PIPE_STAGES_B;i=i+1) 
            b_dout_o_reg[i] <= b_dout_o_reg[i+1];
    end
	 
	always @(posedge clk_i) begin
	
      for(i = 0;i<NUM_BYTES;i=i+1) 
        if(b_we_i[i])
            memory[b_addr_i][i*BYTE_WIDTH +: BYTE_WIDTH] <= b_din_i[i*BYTE_WIDTH +: BYTE_WIDTH];
        
		if(~|b_we_i) begin
		  b_dout_o_reg[READ_PIPE_STAGES_B] <= memory[b_addr_i];
		end
	end

endmodule