module virt_dualport_ram_bw #(
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
    input wire                        a_re_i,
    output wire                       a_ready_o,
    input   wire    [NUM_BYTES-1:0]   a_we_i,
    input   wire    [ADDR_WIDTH-1:0]  a_addr_i,
    input   wire    [DATA_WIDTH-1:0]  a_din_i,
    output  wire     [DATA_WIDTH-1:0]  a_dout_o,
     
    // Port B
    // Port B has priority over Port-A
    input wire                        b_re_i,
    input   wire    [NUM_BYTES-1:0]   b_we_i,
    input   wire    [ADDR_WIDTH-1:0]  b_addr_i,
    input   wire    [DATA_WIDTH-1:0]  b_din_i,
    output  wire    [DATA_WIDTH-1:0]  b_dout_o
);
assign a_ready_o = ~ (b_re_i || b_we_i);


    (* ram_style = "ultra" *)
	reg [DATA_WIDTH-1:0] memory [MEM_DEPTH-1:0];


    reg [DATA_WIDTH-1:0] a_dout_o_reg [READ_PIPE_STAGES_A:0];
	reg [DATA_WIDTH-1:0] b_dout_o_reg [READ_PIPE_STAGES_B:0];
    assign a_dout_o = a_dout_o_reg[0];
    assign b_dout_o = b_dout_o_reg[0];

    reg [DATA_WIDTH-1:0] dout_reg;
    
    always @(*) begin
        a_dout_o_reg[READ_PIPE_STAGES_A] = dout_reg;
        b_dout_o_reg[READ_PIPE_STAGES_B] = dout_reg;
    end

	integer i;
    //pipelined output registers
    always @(posedge clk_i) begin
        for(i = 0;i<READ_PIPE_STAGES_A;i=i+1) 
            a_dout_o_reg[i] <= a_dout_o_reg[i+1];
        for(i = 0;i<READ_PIPE_STAGES_B;i=i+1) 
            b_dout_o_reg[i] <= b_dout_o_reg[i+1];
    end


    wire    [ADDR_WIDTH-1:0]  addr_s = (b_re_i || |b_we_i) ? b_addr_i: a_addr_i;
    wire we_s = (|b_we_i) || (|a_we_i && ~b_re_i);
    wire re_s = a_re_i | b_re_i;
    wire [NUM_BYTES-1:0] we_bytemask_s = (|b_we_i)? b_we_i:a_we_i;
    wire    [DATA_WIDTH-1:0]  din_s = (|b_we_i)?b_din_i:a_din_i;

	always @(posedge clk_i) begin
        if(we_s) begin
          for(i = 0;i<NUM_BYTES;i=i+1) 
            if(we_bytemask_s[i])
                memory[addr_s][i*BYTE_WIDTH +: BYTE_WIDTH] <= din_s[i*BYTE_WIDTH +: BYTE_WIDTH];
        end else begin
            //if(re_s) begin
                dout_reg <=  memory[addr_s];
            //end
        end
    end
	


endmodule
