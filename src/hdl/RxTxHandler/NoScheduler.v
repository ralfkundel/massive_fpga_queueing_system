module NoScheduler #(
    parameter QUEUE_ID_WIDTH = 1,
    parameter AXI_ADDR_WIDTH = 1,
    parameter PACKET_SIZE_WIDTH = 1
)(

    input wire clk_i,
    input wire rst_i,
    
    //queue mem interface
    output wire [QUEUE_ID_WIDTH-1:0 ]         pop_queue_id_base_o,
    output reg                                pop_set_base_queue_id_o, //high for one clock cycle
    input wire                                pop_set_base_ready_i,
    
    input wire [QUEUE_ID_WIDTH-1:0 ]        pop_queue_id_i,
    input wire                               pop_id_valid_i,
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

    assign pop_queue_id_base_o = 5;
    /**********************************************************
    Begin No Scheduler
    **********************************************************/
    
    reg [2:0] counter_s, next_counter_s;
    reg [1:0] scheduler_state, next_scheduler_state;

    reg store_packet_in_scheduler_s;
        
    reg sleep_startup_s; //TODO: for sim parameter
    initial begin
        sleep_startup_s = 0;
        #11000
        sleep_startup_s = 1;
    end
    
    always@(*) begin
        next_scheduler_state = 0;
        next_counter_s = counter_s;
        pop_set_base_queue_id_o = 1'b0;
        pop_o = 1'b0;
        valid_packet_o = 1'b0;
        store_packet_in_scheduler_s = 1'b0;
        case(scheduler_state)
            0: begin //initial state
                pop_set_base_queue_id_o = sleep_startup_s;//1'b1;
                if(pop_set_base_ready_i && sleep_startup_s)
                    next_scheduler_state = 1;
            end
            1: begin
                next_scheduler_state = 1;
                if(pop_id_valid_i)
                    next_counter_s = counter_s +1;
                if(counter_s == 4) begin    //wait four clock cycle for metering
                    next_scheduler_state = 2;
                    next_counter_s  = 0;
                end
            end
            2: begin
               pop_o = 1'b1;
               next_scheduler_state = 2;
                if(valid_i) begin
                   next_scheduler_state = 3;
                   store_packet_in_scheduler_s = 1'b1;
               end
            end
            3: begin
                next_scheduler_state = 3;
                valid_packet_o = 1'b1;
                if(ack_from_tx_handler_i) begin
                    pop_set_base_queue_id_o = 1'b1;
                    if(pop_set_base_ready_i)begin
                        next_scheduler_state = 1;
                    end else begin
                        next_scheduler_state = 0;
                    end
                end
            end

        endcase
    end
    
    always @(posedge clk_i) begin
        if(rst_i) begin
            counter_s <= 0;
            scheduler_state <= 0;
        end else begin
            counter_s <= next_counter_s;
            scheduler_state <= next_scheduler_state;
            
        end
        if(store_packet_in_scheduler_s) begin
            addr_packet_scheduler_o <= pop_addr_i;
            length_packet_scheduler_o <= pop_len_i;
        end
    
    end 
    
endmodule