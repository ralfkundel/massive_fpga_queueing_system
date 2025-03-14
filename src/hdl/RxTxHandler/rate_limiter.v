module rate_limiter #(
    parameter WB_DATA_WIDTH = 1,
    parameter QUEUE_ID_WIDTH = 1,
    parameter NUM_ENTRIES = 1,
    parameter PACKET_SIZE_WIDTH = 1,
    parameter MAX_BUCKET_SIZE = 4000,
    parameter NUM_ENTRY_BITS = $clog2(NUM_ENTRIES),
    parameter CLOCK_DIVIDER = 1248,
    parameter QUEUE_ID_OFFSET = 3       //number of bits (lsb) which are ignored for addressing this queue
)(
    input wire clk_i,
    input wire rst_i,
    
    
    input wire			              wb_cyc_i,
    input wire[17-1:0]                 wb_adr_i,
    input wire                          wb_we_i,
    input wire[WB_DATA_WIDTH-1:0]     wb_dat_i, 
    output reg                          wb_ack_o,
    output reg  [WB_DATA_WIDTH-1:0]     wb_dat_o,
    
    //check interface
    input wire [QUEUE_ID_WIDTH-1:0] id_i,
    input wire                      id_valid_i,
    output reg                      ok_o,
    output reg                      ok_valid_o,
    output reg [QUEUE_ID_WIDTH-1:0] next_id_o,

    //update interface
    input wire                         drop_it_i,
    input wire                         take_it_i,
    input wire [PACKET_SIZE_WIDTH-1:0] update_plen_i
);


reg [17:0] bucket_max_val_config;
localparam MTU = 1600; //TODO: must be set correctly!!!

localparam BUCKET_VAL_WIDTH = 15;
localparam TIMESTAMP_WIDTH = 36 - BUCKET_VAL_WIDTH;
localparam RATE_MEM_WIDTH = 18;

localparam BUCKET_VAL_MAX_VAL = 2**BUCKET_VAL_WIDTH - 1;

wire [QUEUE_ID_WIDTH-QUEUE_ID_OFFSET-1:0] id_s = id_i[QUEUE_ID_WIDTH-1:QUEUE_ID_OFFSET];


/*****************************************************
                Lokal Timer
*******************************************************/
reg [TIMESTAMP_WIDTH-1:0] local_time_s;
localparam FOO = $clog2(CLOCK_DIVIDER);
reg [FOO-1:0] help_counter_s;

always @(posedge clk_i) begin
    if(rst_i) begin
        local_time_s <= 0;
        help_counter_s <=0;
    end else begin
    help_counter_s <= help_counter_s +1;
    if ( help_counter_s == CLOCK_DIVIDER-1) begin
        help_counter_s <= 0;
        local_time_s <= local_time_s + 1;
    end
    end
end


/******************************************
Memories
******************************************/
reg [BUCKET_VAL_WIDTH+TIMESTAMP_WIDTH-1:0] bucket_mem [NUM_ENTRIES - 1: 0];
reg [RATE_MEM_WIDTH-1:0] rate_mem [NUM_ENTRIES - 1: 0];

integer i;
initial begin
    for(i=0; i < NUM_ENTRIES; i = i + 1) begin
        bucket_mem[i] = 0;
        rate_mem [i] = 1;
    end
end

reg [TIMESTAMP_WIDTH-1:0] local_time_s_reg;

reg [TIMESTAMP_WIDTH-1:0] data_read_timestamp_s;
reg [BUCKET_VAL_WIDTH-1:0] data_read_bucket_val_s;
reg [RATE_MEM_WIDTH-1:0] data_read_rate_mem_s;

reg [QUEUE_ID_WIDTH-QUEUE_ID_OFFSET-1:0] id_s_reg;

//BUCKET_VAL_WIDTH
reg [18-1:0] new_bucket_val_s, next_new_bucket_val_s, data_write_bucket_val_s;

reg [TIMESTAMP_WIDTH-1:0] next_diff_time_s, diff_time_s;

reg [2:0] state, next_state;
localparam state_idle = 0;
localparam state_compute_new_bucket1 = 1;
localparam state_compute_new_bucket2 = 2;
localparam state_compute_and_decide = 3;
localparam state_decide_and_write  = 4;
reg read_mem_s;
reg write_bucket_s;
reg save_local_time_s;

reg grant_packet_sending_s;


always @(*) begin
    next_state = state_idle;
    read_mem_s = 1'b0;
    write_bucket_s = 1'b0;
    grant_packet_sending_s = 1'b0;
    next_new_bucket_val_s = new_bucket_val_s;
    data_write_bucket_val_s = new_bucket_val_s;
    
    next_diff_time_s <= local_time_s_reg - data_read_timestamp_s;
    
    save_local_time_s = 1'b0;
    
    ok_valid_o = 1'b0;
    next_id_o = 0;
    
    
    case(state)
        state_idle: begin
            if(id_valid_i) begin
                read_mem_s = 1'b1;
                next_state = state_compute_new_bucket1;
            end
            save_local_time_s = 1'b1;
        end
        state_compute_new_bucket1: begin
            next_diff_time_s <= local_time_s_reg - data_read_timestamp_s;
            next_state = state_compute_new_bucket2;
        end
        
        state_compute_new_bucket2: begin
            next_new_bucket_val_s =  (data_read_rate_mem_s*diff_time_s); //TODO possible log path for synthesis
            next_state = state_compute_and_decide;
        end
        
        state_compute_and_decide: begin
            next_new_bucket_val_s = data_read_bucket_val_s + new_bucket_val_s;
            data_write_bucket_val_s = next_new_bucket_val_s;
            grant_packet_sending_s = 1'b0;
            next_state = state_decide_and_write;
            write_bucket_s = 1'b1;
            if(next_new_bucket_val_s < data_read_bucket_val_s || next_new_bucket_val_s > bucket_max_val_config) begin
               data_write_bucket_val_s = bucket_max_val_config;
               grant_packet_sending_s = 1'b1;
            end else begin
                if(next_new_bucket_val_s >= MTU)
                    grant_packet_sending_s = 1'b1;
            end
        end
        state_decide_and_write: begin
            next_state = state_decide_and_write;
            ok_valid_o = 1'b1;
            grant_packet_sending_s = ok_o;
            next_id_o = (ok_o && data_read_bucket_val_s > (MTU + update_plen_i) ) ? {id_s_reg, {QUEUE_ID_OFFSET {1'b0}} } : {id_s_reg + 1, {QUEUE_ID_OFFSET {1'b0}}};
            
            if(take_it_i) begin
                write_bucket_s = 1'b1;
                data_write_bucket_val_s = data_read_bucket_val_s - update_plen_i;
                next_state = state_idle;
            end else if(drop_it_i) begin
                next_state = state_idle;
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
    if(read_mem_s) begin
        id_s_reg <= id_s;
        {data_read_bucket_val_s, data_read_timestamp_s} <= bucket_mem[id_s];
        data_read_rate_mem_s <= rate_mem[id_s];
        
    end
    if(write_bucket_s) begin
        bucket_mem[id_s_reg] <= {data_write_bucket_val_s, local_time_s_reg};
        {data_read_bucket_val_s, data_read_timestamp_s} <=  {data_write_bucket_val_s, local_time_s_reg};
    end
    
    diff_time_s <= next_diff_time_s;
    
    new_bucket_val_s <= next_new_bucket_val_s;
    ok_o <= grant_packet_sending_s;
    if(save_local_time_s)
        local_time_s_reg <= local_time_s;
end





/**********************************************************************
            Wishbone State machine
**********************************************************************/

reg [WB_DATA_WIDTH-1:0]     wb_dat_i_reg;
reg [17-1:0]                 wb_adr_i_reg;

reg next_wb_ack_o;

reg [1:0] wb_state, next_wb_state;
localparam wb_state_idle = 0;
localparam wb_state_write = 1;
localparam wb_state_read = 2;
localparam wb_state_read_final = 3;

reg take_addr_data_s;
reg write_max_bucket_size_s;
reg write_new_rate_s;
reg read_rate_s;

always @(*) begin
    next_wb_ack_o = 1'b0;
    
    next_wb_state = wb_state_idle;
    
    take_addr_data_s = 1'b0;
    write_max_bucket_size_s = 1'b0;
    write_new_rate_s = 1'b0;
    read_rate_s = 1'b0;
    
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
            if(wb_adr_i_reg == {17{1'b1}}) begin
                write_max_bucket_size_s = 1'b1;
            end else begin
                write_new_rate_s = 1'b1;
            end
        end
        
        wb_state_read: begin
            next_wb_state = wb_state_read_final;
        end
        
        wb_state_read_final: begin
            next_wb_ack_o = 1'b1;
            if(wb_adr_i_reg == {17{1'b1}}) begin
                read_rate_s = 1'b0;
            end else begin
                read_rate_s = 1'b1;
            end
        end
    endcase
end

reg [WB_DATA_WIDTH-1:0] tmp1_s, tmp2_s;
always @(posedge clk_i) begin
    if(rst_i) begin
        wb_state <= wb_state_idle;
        bucket_max_val_config <= 2000;
    end else begin
        wb_state <= next_wb_state;
        if(write_max_bucket_size_s) begin
            if(wb_dat_i_reg > BUCKET_VAL_MAX_VAL)
                bucket_max_val_config <= BUCKET_VAL_MAX_VAL;
            else
                bucket_max_val_config <= wb_dat_i_reg;
        end
    end
    wb_ack_o <= next_wb_ack_o;
    
    if(take_addr_data_s) begin
        wb_dat_i_reg <= wb_dat_i;
        wb_adr_i_reg <= wb_adr_i;
    end
    
    if (write_new_rate_s) begin
        rate_mem[wb_adr_i_reg] <= wb_dat_i_reg;
    end
    
    tmp1_s <= {{WB_DATA_WIDTH-RATE_MEM_WIDTH{1'b0}}, rate_mem[wb_adr_i_reg]};
    tmp2_s <= { {WB_DATA_WIDTH-18{1'b0}} ,bucket_max_val_config};
    if(read_rate_s) begin
        wb_dat_o <= tmp1_s;
    end else begin
        wb_dat_o <= tmp2_s; //18bit value + zero padding
    end
end


endmodule