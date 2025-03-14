module packet_counter #(
    parameter WB_DATA_WIDTH = 1,
    parameter WB_ADDR_WIDTH = 24,
    parameter QUEUE_ID_WIDTH = 1,
    parameter NUM_COUNTER = 1,
    parameter PACKET_SIZE_WIDTH = 1
)(
    input wire clk_i,
    input wire rst_i,
    
    
    input wire			               wb_cyc_i,
    input wire[WB_ADDR_WIDTH-1:0]                 wb_adr_i,
    input wire                         wb_we_i,
    input wire[WB_DATA_WIDTH-1:0]      wb_dat_i, 
    output reg                         wb_ack_o,
    output reg  [WB_DATA_WIDTH-1:0]    wb_dat_o,
    
    //check interface
    input wire [QUEUE_ID_WIDTH-1:0] c_id_i,
    input wire [PACKET_SIZE_WIDTH-1: 0] p_len_i,
    input wire count_i

);

    wire [QUEUE_ID_WIDTH+PACKET_SIZE_WIDTH - 1 : 0] job_queue_input_s = {c_id_i, p_len_i};
    wire [QUEUE_ID_WIDTH+PACKET_SIZE_WIDTH - 1 : 0] job_queue_output_s;
    wire [QUEUE_ID_WIDTH-1:0] c_id_s;
    wire [PACKET_SIZE_WIDTH-1: 0] p_len_s;
    reg  [PACKET_SIZE_WIDTH-1: 0] p_len_s_reg;
    assign {c_id_s, p_len_s} = job_queue_output_s;
    wire count_s;
    reg pop_s;

    simple_queue #(
        .WIDTH(72),
        .DEPTH(16)
    )input_queue (
        .rst_i(rst_i),
        .clk_i(clk_i),
        
        .data_i(job_queue_input_s),
        .valid_i(count_i),
        .ack_o(),
        .ready_o(),
        
        .data_o(job_queue_output_s),
        .valid_o(count_s),
        .pop_i(pop_s)
    );

reg [31:0] next_addr_counter_write_s, addr_counter_write_s, addr_counter_s;

reg counter_read_enable_b_s;
reg counter_write_b_s;
localparam BYTE_COUNTER_WIDTH = 37;
localparam PACKET_COUNTER_WIDTH = 64 - BYTE_COUNTER_WIDTH;
wire [BYTE_COUNTER_WIDTH-1:0] data_counter_read_bytes_s;
wire [PACKET_COUNTER_WIDTH-1:0] data_counter_read_packets_s;
reg [BYTE_COUNTER_WIDTH-1:0] data_counter_write_bytes_s, data_counter_write_bytes_s_reg, data_counter_write_bytes_s_reg2;
reg [PACKET_COUNTER_WIDTH-1:0] data_counter_write_packets_s, data_counter_write_packets_s_reg, data_counter_write_packets_s_reg2; 
reg [2:0] state, next_state;
localparam STATE_IDLE = 0;
localparam STATE_READ_COUNTER = 1;
localparam STATE_READ_COUNTER2 = 2;
localparam STATE_INCREMENT = 3;
localparam STATE_PRE_WRITE = 4;
localparam STATE_WRITE = 5;
localparam STATE_RESET = 6;

always@(*) begin
    next_state = STATE_IDLE;
    counter_read_enable_b_s = 1'b0;
    counter_write_b_s = 1'b0;
    data_counter_write_bytes_s = {BYTE_COUNTER_WIDTH{1'b0}};
    data_counter_write_packets_s = {PACKET_COUNTER_WIDTH{1'b0}};
    next_addr_counter_write_s = 0;
    pop_s = 1'b0;
    addr_counter_s = c_id_s;
    case(state)
        STATE_RESET: begin
            next_state = STATE_RESET;
            addr_counter_s = addr_counter_write_s;
            next_addr_counter_write_s = addr_counter_write_s+1;
            counter_write_b_s = 1'b1;
            if (next_addr_counter_write_s >= NUM_COUNTER) begin
                next_state = STATE_IDLE;
            end
        end
        STATE_IDLE: begin
            //p_len_s is valid
            if(count_s) begin
                counter_read_enable_b_s = 1'b1;
                next_state = STATE_READ_COUNTER;
            end
        end
        STATE_READ_COUNTER: begin
             //p_len_s_reg is valid
            next_state = STATE_READ_COUNTER2;
        end
        STATE_READ_COUNTER2: begin
            next_state = STATE_INCREMENT;
        end
        STATE_INCREMENT: begin
            next_state = STATE_PRE_WRITE;
            data_counter_write_bytes_s = data_counter_read_bytes_s + p_len_s_reg;
            data_counter_write_packets_s = data_counter_read_packets_s + 1;
        end
        STATE_PRE_WRITE: begin
            next_state = STATE_WRITE;
        end
        STATE_WRITE: begin
            counter_write_b_s = 1'b1;
            pop_s = 1'b1;
            next_state = STATE_IDLE;
        end
    endcase
end

always @(posedge clk_i) begin
    if(rst_i) begin
        state <= STATE_RESET;
        addr_counter_write_s <= 0;
    end else begin
        state <= next_state;
        addr_counter_write_s <= next_addr_counter_write_s;
    end
    data_counter_write_bytes_s_reg <= data_counter_write_bytes_s;
    data_counter_write_packets_s_reg <= data_counter_write_packets_s;
    data_counter_write_bytes_s_reg2 <= data_counter_write_bytes_s_reg;
    data_counter_write_packets_s_reg2 <= data_counter_write_packets_s_reg;
    p_len_s_reg <= p_len_s;
end

wire [63:0] data_counter_read_wb_s;
reg wb_read_s;
wire wb_read_ready_s;
wire [31:0] addr_counter_wb_s;

virt_dualport_ram_bw #(
    .ADDR_WIDTH(32),
    .MEM_DEPTH(NUM_COUNTER),
    .NUM_BYTES(64/8),
    .READ_PIPE_STAGES_A(4),
    .READ_PIPE_STAGES_B(2)
    //.DATA_WIDTH(QUEUE_MEM_WIDTH)
 //   .INIT_VALUE(1'b1)
) counter_mem (
    .clk_i(clk_i),
    
    .a_ready_o(wb_read_ready_s),
    .a_re_i({8{wb_read_s}}),
    .a_we_i(0),
    .a_addr_i(addr_counter_wb_s),
    .a_din_i(0),
    .a_dout_o(data_counter_read_wb_s),
    
    .b_re_i(counter_read_enable_b_s),
    .b_we_i({8{counter_write_b_s}}),
    .b_addr_i(addr_counter_s),
    .b_din_i({data_counter_write_packets_s_reg2, data_counter_write_bytes_s_reg2}),
    .b_dout_o({data_counter_read_packets_s, data_counter_read_bytes_s})
);


reg [WB_DATA_WIDTH-1:0]     wb_dat_i_reg;
assign addr_counter_wb_s = wb_dat_i_reg;
reg [WB_ADDR_WIDTH-1:0]                 wb_adr_i_reg;

reg next_wb_ack_o;

reg [32-1:0] data_read_wb_lower_s;
reg [32-1:0] data_read_wb_higher_s;

reg [WB_DATA_WIDTH-1:0] next_wb_dat_s;

reg [2:0] wb_state, next_wb_state;
localparam wb_state_idle = 0;
localparam wb_state_write = 1;
localparam wb_state_read = 2;
localparam wb_state_read_cntr1 = 3;
localparam wb_state_read_cntr2 = 4;
localparam wb_state_read_cntr3 = 5;
localparam wb_state_read_cntr4 = 6;
localparam wb_state_read_cntr5 = 7;

reg take_addr_data_s;
reg take_data_wb_reg_s;


always @(*) begin
    next_wb_ack_o = 1'b0;
    
    next_wb_state = wb_state_idle;
    
    take_addr_data_s = 1'b0;
    
    next_wb_dat_s = 32'hcafebabe;
    take_data_wb_reg_s = 1'b0;
    wb_read_s = 1'b0;  
    
    case(wb_state)
        wb_state_idle: begin
            if(wb_cyc_i) begin
                take_addr_data_s = 1'b1;
                if(wb_we_i) begin
                    next_wb_state = wb_state_write;
                    next_wb_ack_o = 1'b1;
                end else begin
                    next_wb_state = wb_state_read;   
                end
            end
        end
        
        wb_state_write: begin
            next_wb_state = wb_state_write;
            wb_read_s = 1'b1;
            if(wb_read_ready_s) begin
                next_wb_state = wb_state_read_cntr1;
            end
        end
        wb_state_read_cntr1: begin
            next_wb_state = wb_state_read_cntr2;
        end
        wb_state_read_cntr2: begin
            next_wb_state = wb_state_read_cntr3;
        end
        wb_state_read_cntr3: begin
            next_wb_state = wb_state_read_cntr4;
        end
        
        wb_state_read_cntr4: begin
            next_wb_state = wb_state_read_cntr5;
        end
        
        wb_state_read_cntr5: begin
            take_data_wb_reg_s = 1'b1;
        end
        
        wb_state_read: begin
            next_wb_state = wb_state_idle;
            next_wb_ack_o = 1'b1;
            if(wb_adr_i_reg == 1) begin
                next_wb_dat_s = data_read_wb_lower_s;
            end else if(wb_adr_i_reg == 2) begin
                next_wb_dat_s = data_read_wb_higher_s;
            end
        end

        
    endcase
end

reg [WB_DATA_WIDTH-1:0] tmp1_s, tmp2_s;
always @(posedge clk_i) begin
    if(rst_i) begin
        wb_state <= wb_state_idle;
    end else begin
        wb_state <= next_wb_state;

    end
    wb_ack_o <= next_wb_ack_o;
    wb_dat_o <= next_wb_dat_s;
    
    if(take_addr_data_s) begin
        wb_dat_i_reg <= wb_dat_i;
        wb_adr_i_reg <= wb_adr_i;
    end
    if(take_data_wb_reg_s)
        {data_read_wb_higher_s, data_read_wb_lower_s} <= data_counter_read_wb_s;

end




endmodule
