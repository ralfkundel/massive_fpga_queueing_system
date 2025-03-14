module wb_interconnect #(
    parameter WB_DATA_WIDTH = 32,
    parameter WB_ADDR_WIDTH = 32,
    parameter SLAVE_SELECT_WIDTH = 8
)(
    input wire clk_i,
    input wire rst_i,
    
    //wb interface for queue depth (qd) memory
    input wire [WB_DATA_WIDTH-1:0]    qd_wb_data_i,
    output wire [WB_DATA_WIDTH-1:0]    qd_wb_data_o,
    output wire [WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH-1:0]    qd_wb_addr_o,
    output reg                         qd_wb_we_o,
    output reg                         qd_wb_cyc_o,
    output wire [WB_DATA_WIDTH/8-1:0]  qd_wb_stb_o,
    input wire qd_wb_ack_i,

    //wb interface for scheduler
    input wire [WB_DATA_WIDTH-1:0]    sched_wb_data_i,
    output wire [WB_DATA_WIDTH-1:0]    sched_wb_data_o,
    output wire [WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH-1:0]    sched_wb_addr_o,
    output reg                         sched_wb_we_o,
    output reg                         sched_wb_cyc_o,
    output wire [WB_DATA_WIDTH/8-1:0]  sched_wb_stb_o,
    input wire sched_wb_ack_i,
    
    //wb interface for counter
    input wire [WB_DATA_WIDTH-1:0]    counter_wb_data_i,
    output wire [WB_DATA_WIDTH-1:0]    counter_wb_data_o,
    output wire [WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH-1:0]    counter_wb_addr_o,
    output reg                         counter_wb_we_o,
    output reg                         counter_wb_cyc_o,
    output wire [WB_DATA_WIDTH/8-1:0]  counter_wb_stb_o,
    input wire counter_wb_ack_i,
        
    output reg [WB_DATA_WIDTH-1:0]    wb_data_o,
    input wire [WB_DATA_WIDTH-1:0]    wb_data_i,
    input wire [WB_ADDR_WIDTH-1:0]    wb_addr_i,
    input wire                        wb_we_i,
    input wire                        wb_cyc_i,
    input wire [WB_DATA_WIDTH/8-1:0]  wb_stb_i,
    output reg wb_ack_o
);

assign qd_wb_data_o = wb_data_i;
assign qd_wb_addr_o = wb_addr_i [WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH-1:2];
assign qd_wb_stb_o = wb_stb_i;

assign sched_wb_data_o = wb_data_i;
assign sched_wb_addr_o = wb_addr_i [WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH-1:2];
assign sched_wb_stb_o = wb_stb_i;

assign counter_wb_data_o = wb_data_i;
assign counter_wb_addr_o = wb_addr_i [WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH-1:2];
assign counter_wb_stb_o = wb_stb_i;

wire [SLAVE_SELECT_WIDTH-1:0] slave_select_addr_s = wb_addr_i[WB_ADDR_WIDTH-1:WB_ADDR_WIDTH-SLAVE_SELECT_WIDTH];

always @(*) begin
    wb_data_o = 0;
    wb_ack_o = 1'b0;
    
    qd_wb_we_o = 1'b0;
    qd_wb_cyc_o = 1'b0;
    
    sched_wb_we_o = 1'b0;
    sched_wb_cyc_o = 1'b0;
    counter_wb_we_o = 1'b0;
    counter_wb_cyc_o = 1'b0;
    
    case(slave_select_addr_s)
        0: begin
            wb_data_o = qd_wb_data_i;
            qd_wb_we_o = wb_we_i;
            qd_wb_cyc_o = wb_cyc_i;
            wb_ack_o = qd_wb_ack_i;
        end

        1: begin
            wb_data_o = sched_wb_data_i;
            sched_wb_we_o = wb_we_i;
            sched_wb_cyc_o = wb_cyc_i;
            wb_ack_o = sched_wb_ack_i;
        end    
        
        
        2: begin
            wb_data_o = counter_wb_data_i;
            counter_wb_we_o = wb_we_i;
            counter_wb_cyc_o = wb_cyc_i;
            wb_ack_o = counter_wb_ack_i;
        end    
        
        
        
    
    endcase

end
  

endmodule