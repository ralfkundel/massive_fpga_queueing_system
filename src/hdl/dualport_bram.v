module dualport_bram #(
    parameter ADDR_WIDTH = 8,
    parameter MEM_DEPTH = 2**ADDR_WIDTH,
    parameter DATA_WIDTH = 32,
    parameter INIT_VALUE = 1'b0
)(
	input wire clk_i,
    // Port A
    input   wire                a_we_i,
    input   wire    [ADDR_WIDTH-1:0]  a_addr_i,
    input   wire    [DATA_WIDTH-1:0]  a_din_i,
    output  reg     [DATA_WIDTH-1:0]  a_dout_o,
     
    // Port B
    input   wire                b_we_i,
    input   wire    [ADDR_WIDTH-1:0]  b_addr_i,
    input   wire    [DATA_WIDTH-1:0]  b_din_i,
    output  reg     [DATA_WIDTH-1:0]  b_dout_o
);
    (* ram_style = "block" *)
	reg [DATA_WIDTH-1:0] memory [MEM_DEPTH-1:0];


	
	integer i;
	initial begin
		for (i = 0; i < MEM_DEPTH; i = i + 1) begin
			memory [i] = {DATA_WIDTH{INIT_VALUE}};
		end
	end

	// Port A
	always @(posedge clk_i) begin
		if(a_we_i) begin
			memory[a_addr_i] <= a_din_i;
		end
		// Read first, even when a write occur
		a_dout_o <= memory[a_addr_i];
	end
	 
	// Port B
	always @(posedge clk_i) begin
		if(b_we_i) begin
			memory[b_addr_i] <= b_din_i;
		end
		// Read first, even when a write occur
		b_dout_o <= memory[b_addr_i];
	end

endmodule
    