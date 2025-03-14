module queue_length_mem #(
    parameter WB_ADDR_WIDTH = 22,
    parameter WB_DATA_WIDTH = 32,
    parameter QUEUE_ID_WIDTH = 32,
    parameter MAX_QUEUE_LENGTH_WIDTH = 24

) (
    input wire [QUEUE_ID_WIDTH-1:0] queue_id_i,
    output reg [MAX_QUEUE_LENGTH_WIDTH-1:0] max_queue_length_o,


	input wire			              wb_cyc_i,
    input wire[WB_ADDR_WIDTH-1:0]	  wb_adr_i,
	input wire			              wb_we_i,
	input wire[WB_DATA_WIDTH-1:0]     wb_dat_i,
	
    output reg			              wb_ack_o,
    output reg[WB_DATA_WIDTH-1:0]     wb_dat_o,

    input wire clk_i,
    input wire rst_i

);

wire [2:0] id_sufix_s = queue_id_i [2:0];


reg [MAX_QUEUE_LENGTH_WIDTH-3-1:0] mem [7:0];

integer i;
initial begin
    for(i=0; i < 8; i = i+1) begin
        mem[i] <= 1 << (i + 4);
    end
end

always @ (posedge clk_i) begin
    max_queue_length_o <= ({mem[id_sufix_s], 3'b0});
end

always @(posedge clk_i) begin
    if(rst_i) begin
        wb_ack_o <= 1'b0;
    end else begin
        if(wb_cyc_i && ~wb_ack_o) begin
            wb_ack_o <= 1'b1;
            if(wb_we_i) begin
                mem[wb_adr_i[2:0]] <= wb_dat_i [WB_DATA_WIDTH-1:3];
            end
        end else begin
            wb_ack_o <= 1'b0;
        end
    end
    wb_dat_o <= {mem[wb_adr_i[2:0]],  3'b0};
end


endmodule
