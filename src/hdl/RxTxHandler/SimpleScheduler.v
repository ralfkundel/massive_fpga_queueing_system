module SimpleScheduler #(
    parameter NUM_QUEUES = 1,
    parameter NUM_CUSTOMERS = 1,

    parameter QUEUE_ID_WIDTH = 1,
    parameter AXI_ADDR_WIDTH = 1,
    parameter PACKET_SIZE_WIDTH = 1,
    
    parameter WB_ADDR_WIDTH = 1,
    parameter WB_DATA_WIDTH = 1
)(

    input wire clk_i,
    input wire rst_i,
    
    input wire			              wb_cyc_i,
    input wire[WB_ADDR_WIDTH-1:0]      wb_adr_i,
    input wire                          wb_we_i,
    input wire[WB_DATA_WIDTH-1:0]     wb_dat_i, 
    output reg                          wb_ack_o,
    output reg [WB_DATA_WIDTH-1:0]     wb_dat_o,

    
    //queue mem interface
    output reg  [QUEUE_ID_WIDTH-1:0 ]         pop_queue_id_base_o,
    output reg                                pop_set_base_queue_id_o, //high for one clock cycle
    input wire                                pop_set_base_ready_i,
    
    input wire [QUEUE_ID_WIDTH-1:0 ]        pop_queue_id_i,
    input wire                               id_valid_i,
    output reg                               pop_o,
    
    input wire [AXI_ADDR_WIDTH-1:0]             pop_addr_i,
    input wire [PACKET_SIZE_WIDTH -1 : 0]   pop_len_i,
    input wire                               valid_i,
    
    //TX Handler interface
    output reg valid_packet_o,
    output reg [AXI_ADDR_WIDTH-1:0] addr_packet_scheduler_o,
    output reg [PACKET_SIZE_WIDTH -1 : 0] length_packet_scheduler_o,
    input wire ack_from_tx_handler_i
    
);


    wire [19-1:0] inner_address = wb_adr_i[19-1:0];
    wire [2:0] outer_address = wb_adr_i[22-1:19];
    
    reg 			             wb_rl1_cyc_s;
    wire[17-1:0]                 wb_rl1_adr_s = inner_address;
    reg                          wb_rl1_we_s;
    wire[WB_DATA_WIDTH-1:0]      wb_rl1_dat_r_s;
    wire                         wb_rl1_ack_s;
    wire [WB_DATA_WIDTH-1:0]     wb_rl1_dat_w_s = wb_dat_i;
    
    always @(*) begin
        wb_ack_o = 1'b0;
        wb_dat_o = 0;
        wb_rl1_cyc_s = 1'b0;
        wb_rl1_we_s = 1'b0;
        
        case (outer_address)
            0: begin //scheduler
            
            end
            
            1: begin //simple rate limiter
                wb_rl1_cyc_s = wb_cyc_i;
                wb_rl1_we_s = wb_we_i;
                wb_dat_o = wb_rl1_dat_r_s;
                wb_ack_o = wb_rl1_ack_s;
            end
        
        endcase
    
    end

    
    reg id_valid_s;
    wire ok_s, ok_valid_s;
    reg drop_it_s;
    reg take_it_s;
    
    wire [QUEUE_ID_WIDTH-1:0] next_id_s;
 
    
    rate_limiter #(
        .WB_DATA_WIDTH(WB_DATA_WIDTH),
        .QUEUE_ID_WIDTH(QUEUE_ID_WIDTH),
        .NUM_ENTRIES(NUM_CUSTOMERS),
        .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH),
        .QUEUE_ID_OFFSET(3)
    )rate_limiter_inst (
        .wb_cyc_i(wb_rl1_cyc_s),
        .wb_adr_i(wb_rl1_adr_s),
        .wb_we_i(wb_rl1_we_s),
        .wb_dat_i(wb_rl1_dat_w_s),
        .wb_ack_o(wb_rl1_ack_s),
        .wb_dat_o(wb_rl1_dat_r_s),

        .id_i(pop_queue_id_i),
        .id_valid_i(id_valid_s),
        .ok_o(ok_s),
        .ok_valid_o(ok_valid_s),
        .next_id_o(next_id_s),
        
        .drop_it_i(drop_it_s),
        .take_it_i(take_it_s),
        .update_plen_i(pop_len_i),
        
        .clk_i(clk_i),
        .rst_i(rst_i)
        
    
    );
    
    /**********************************************************
    Begin Simple Scheduler
    **********************************************************/
    
   reg [QUEUE_ID_WIDTH-1:0 ]        pop_queue_id_i_reg;
   
   
    reg [2:0] scheduler_state, next_scheduler_state;
    localparam state_idle = 0;
    localparam state_wait_for_queue_mem = 1;
    localparam state_wait_for_scheduler = 2;
    localparam state_wait_for_packet_data = 3;
    localparam state_give_to_TX_handler = 4;
        
        
        
    reg store_packet_in_scheduler_s;
    reg [QUEUE_ID_WIDTH-1:0] next_pop_queue_id_base_o ;
        
    reg sleep_startup_s; //TODO: for sim parameter
    initial begin
        sleep_startup_s = 0;
        #400000
        sleep_startup_s = 1;
    end
    
    
    
    always@(*) begin
        next_scheduler_state = state_idle;
        
        pop_set_base_queue_id_o = 1'b0;
        next_pop_queue_id_base_o = pop_queue_id_base_o;
        pop_o = 1'b0;
        valid_packet_o = 1'b0;
        
        store_packet_in_scheduler_s = 1'b0;
        id_valid_s = 1'b0;
        
        drop_it_s = 1'b0;
        take_it_s = 1'b0;
        
        case(scheduler_state)
            state_idle: begin //initial state
                pop_set_base_queue_id_o = sleep_startup_s;//1'b1;
                if(pop_set_base_ready_i && sleep_startup_s)
                    next_scheduler_state = state_wait_for_queue_mem;
            end
            
            state_wait_for_queue_mem: begin
                next_scheduler_state = state_wait_for_queue_mem;
                if(id_valid_i) begin
                    id_valid_s = 1'b1;
                    next_scheduler_state = state_wait_for_scheduler;
                end
            end
            
            state_wait_for_scheduler: begin
                next_scheduler_state = state_wait_for_scheduler;
                if(ok_valid_s) begin
                    if(ok_s) begin
                        pop_o = 1'b1;
                        next_scheduler_state = state_wait_for_packet_data;
                        next_pop_queue_id_base_o = pop_queue_id_i_reg;
                    end else begin
                        drop_it_s = 1'b1;
                        next_pop_queue_id_base_o = next_id_s;
                        next_scheduler_state = state_idle;
                    end
                end
            end
            
            state_wait_for_packet_data: begin
                next_scheduler_state = state_wait_for_packet_data;
                pop_o = 1'b1;
                if(valid_i) begin
                     store_packet_in_scheduler_s = 1'b1;
                     take_it_s = 1'b1;
                     next_scheduler_state = state_give_to_TX_handler;
                end
            end
            
            state_give_to_TX_handler: begin
                next_scheduler_state = state_give_to_TX_handler;
                valid_packet_o = 1'b1;
                if(ack_from_tx_handler_i) begin
                    pop_set_base_queue_id_o = 1'b1; 
                    if(pop_set_base_ready_i)begin
                        next_scheduler_state = state_wait_for_queue_mem;
                    end else begin
                        next_scheduler_state = state_idle;
                    end
                end
            end

        endcase
    end

    always @(posedge clk_i) begin
        if(rst_i) begin
            scheduler_state <= state_idle;
            pop_queue_id_base_o <= 0;
        end else begin
            scheduler_state <= next_scheduler_state;
            pop_queue_id_base_o <= next_pop_queue_id_base_o;
            
        end
        if(store_packet_in_scheduler_s) begin
            addr_packet_scheduler_o <= pop_addr_i;
            length_packet_scheduler_o <= pop_len_i;
        end
        if(id_valid_s) begin
                    pop_queue_id_i_reg <= pop_queue_id_i; 
        end
    
    end 
    
endmodule
