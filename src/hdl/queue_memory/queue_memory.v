`timescale 1ns / 1ns

module queue_memory #(
    parameter QUEUE_ID_WIDTH = 32,
    parameter WB_SLAVE_ADDR_WIDTH = 1,
    parameter ADDR_WIDTH = 32,
    parameter PACKET_SIZE_WIDTH = 11, //internally byte alligned --> 16 byte
    
    parameter WB_DATA_WIDTH = 32,
    
    parameter QUEUE_DEPTH_LENGTH = 24, //byte aligned
    
    parameter NUM_QUEUES = 64,
    parameter SIZE_DESCRIPTOR_MEM = 128
)(
	input  wire                             clk_i,
    input  wire                             rst_i,
    
    input wire			                    wb_queue_depth_cyc_i,
    input wire[WB_SLAVE_ADDR_WIDTH-1:0]     wb_queue_depth_adr_i,
    input wire                              wb_queue_depth_we_i,
    input wire[WB_DATA_WIDTH-1:0]           wb_queue_depth_dat_i,
    output wire 		                    wb_queue_depth_ack_o,
    output wire [WB_DATA_WIDTH-1:0]         wb_queue_depth_dat_o,
    
    
    //enqueue interface
    input wire [PACKET_SIZE_WIDTH -1 : 0]   p_len_i,
    input wire [ADDR_WIDTH-1:0]             p_addr_i,
    input wire [QUEUE_ID_WIDTH-1:0 ]        p_queue_id_i,
    input wire                              p_valid_i,
    output wire                             p_accept_ready_o,
    
    //free_mem interface - used for taildrop
    output wire [ADDR_WIDTH-1:0]            free_mem_addr_o,
    output reg                              free_mem_o,
    input  wire                             free_mem_ack_i,
    
    //dequeue interface
    input wire [QUEUE_ID_WIDTH-1:0 ]         pop_queue_id_base_i,
    input wire                               pop_set_base_queue_id_i,
    output reg                               pop_set_base_ready_o,
    
    
      output wire [2:0] push_state_o,
      output wire [3:0] pop_state_o,
    
    output reg                               pop_id_valid_o,
    output reg  [QUEUE_ID_WIDTH-1:0 ]        pop_queue_id_o,
    input wire                               pop_i,
    
    output reg [ADDR_WIDTH-1:0]             pop_addr_o,
    output reg [PACKET_SIZE_WIDTH -1 : 0]   pop_len_o,
    output reg [QUEUE_DEPTH_LENGTH-1:0]     pop_queue_len_o,
    output reg                               valid_o
);
`define ADDITIONAL_PIPE_STAGES
`define SINGLE_PORT_URAM_NOT //SINGLE_PORT_URAM_NOT


always @(*) begin
    if(PACKET_SIZE_WIDTH > 16)begin
        $finish(); //internally always 16 bit
    end
end
localparam PACKET_SIZE_WIDTH_INTERNAL = 16;

reg next_valid_o;

//debug counter
reg[31:0] num_packet_push_s, num_packet_pop_s;

always@(posedge clk_i) begin
    if(rst_i) begin
        num_packet_push_s <= 0;
        num_packet_pop_s <= 0;
    end else begin
        if(p_valid_i && p_accept_ready_o) begin
            num_packet_push_s = num_packet_push_s + 1;
        end
        if (pop_i && valid_o) begin
            num_packet_pop_s <= num_packet_pop_s + 1;
        end
    end 
end

    wire [PACKET_SIZE_WIDTH -1 : 0]   p_len_s;
    wire [ADDR_WIDTH-1:0]             p_addr_s;
    wire [QUEUE_ID_WIDTH-1:0 ]        p_queue_id_s;
    wire                              p_valid_s;
    reg                               p_pop_s;
    
    
    simple_queue #(
        .WIDTH(PACKET_SIZE_WIDTH+ADDR_WIDTH+QUEUE_ID_WIDTH),
        .DEPTH(4)
    )enqueue_job_queue_inst (
        .rst_i(rst_i),
        .clk_i(clk_i),
        
        .data_i({p_len_i, p_addr_i, p_queue_id_i}),
        .valid_i(p_valid_i),
        .ack_o(),
        .ready_o(p_accept_ready_o),
        
        .data_o({p_len_s, p_addr_s, p_queue_id_s}),
        .valid_o(p_valid_s),
        .pop_i(p_pop_s)
    
    );



localparam PARA_LOOKUP_ADDR_WIDTH = 5;
localparam PARA_LOOKUP = 2**PARA_LOOKUP_ADDR_WIDTH;
localparam NUM_VALID_BLOCKS = (NUM_QUEUES + PARA_LOOKUP - 1)/PARA_LOOKUP; //always round up. so for 1025 queues and 32 para lookups 33 blocks are required
localparam DESCRIPTOR_MEM_ADDR_WIDTH = 24;//$clog2(SIZE_DESCRIPTOR_MEM);
localparam VALID_MEM_ADDRESS_WIDH = $clog2(NUM_VALID_BLOCKS);

localparam DESCRIPTOR_MEM_DATA_WIDTH = ADDR_WIDTH + PACKET_SIZE_WIDTH_INTERNAL + DESCRIPTOR_MEM_ADDR_WIDTH; //address and length of the packet in the memory+ address of the next packet of the same queue in the descriptor memory
localparam QUEUE_MEM_WIDTH = QUEUE_DEPTH_LENGTH + DESCRIPTOR_MEM_ADDR_WIDTH + DESCRIPTOR_MEM_ADDR_WIDTH; //first pointer and last pointer
localparam QUEUE_MEM_ADDRESS_WIDTH = $clog2(NUM_QUEUES);
localparam QUEUE_MEM_WIDTH_BYTES = QUEUE_MEM_WIDTH/8;

/********************************************************
Memories
********************************************************/


reg  [QUEUE_MEM_ADDRESS_WIDTH-1:0]  addr_queues_push_s;
wire [QUEUE_MEM_WIDTH-1:0]          data_read_queues_push_s;
wire [QUEUE_DEPTH_LENGTH-1:0]      data_read_queues_push_length_s;
wire [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]   data_read_queues_push_first_s, data_read_queues_push_last_s;
assign {data_read_queues_push_length_s, data_read_queues_push_first_s, data_read_queues_push_last_s} = data_read_queues_push_s;

reg  [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]   data_read_queues_push_last_s_reg, data_read_queues_push_last_s_reg2;
reg  [QUEUE_DEPTH_LENGTH-1:0]      data_read_queues_push_length_s_reg, data_read_queues_push_length_s_reg_incremented_s;

wire  [QUEUE_MEM_WIDTH_BYTES-1:0]    write_queues_push_s;
reg write_queues_push_lengths_s, write_queues_push_first_s, write_queues_push_last_s;
assign write_queues_push_s = { {3{write_queues_push_lengths_s}}, {3{write_queues_push_first_s}}, {3{write_queues_push_last_s}} };
wire  [QUEUE_MEM_WIDTH-1:0]          data_write_queues_push_s;
reg [QUEUE_DEPTH_LENGTH-1:0]      data_write_queues_push_length_s;
reg [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]   data_write_queues_push_first_s, data_write_queues_push_last_s;
assign data_write_queues_push_s = {data_write_queues_push_length_s, data_write_queues_push_first_s, data_write_queues_push_last_s};



reg  [QUEUE_MEM_ADDRESS_WIDTH-1:0]  addr_queues_pop_s;
wire [QUEUE_MEM_WIDTH-1:0]          data_read_queues_pop_s;
wire [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]   data_read_queues_pop_first_s, data_read_queues_pop_last_s;
wire [QUEUE_DEPTH_LENGTH-1:0]          data_read_queues_pop_length_s;
assign {data_read_queues_pop_length_s, data_read_queues_pop_first_s, data_read_queues_pop_last_s} = data_read_queues_pop_s;

reg  [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]   data_read_queues_pop_first_s_reg, data_read_queues_pop_last_s_reg;
reg [QUEUE_DEPTH_LENGTH-1:0]           data_read_queues_pop_length_s_reg;


wire  [QUEUE_MEM_WIDTH_BYTES-1:0]    write_queues_pop_s;
reg write_queues_pop_lengths_s, write_queues_pop_first_s, write_queues_pop_last_s;
assign write_queues_pop_s = { {3{write_queues_pop_lengths_s}}, {3{write_queues_pop_first_s}}, {3{write_queues_pop_last_s}} };
wire  [QUEUE_MEM_WIDTH-1:0]          data_write_queues_pop_s;
reg [QUEUE_DEPTH_LENGTH-1:0]      data_write_queues_pop_length_s;
reg [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]   data_write_queues_pop_first_s, data_write_queues_pop_last_s;
assign data_write_queues_pop_s = {data_write_queues_pop_length_s, data_write_queues_pop_first_s, data_write_queues_pop_last_s};

wire ready_queue_mem_push_s;
reg re_queue_push_s, re_queue_pop_s;


`ifdef SINGLE_PORT_URAM

virt_dualport_ram_bw #(
    .ADDR_WIDTH(QUEUE_MEM_ADDRESS_WIDTH),
    .MEM_DEPTH(NUM_QUEUES),
    .NUM_BYTES(QUEUE_MEM_WIDTH_BYTES),
    .READ_PIPE_STAGES_A(1),
    .READ_PIPE_STAGES_B(1)
    //.DATA_WIDTH(QUEUE_MEM_WIDTH)
 //   .INIT_VALUE(1'b1)
) queues_mem_inst (
    .clk_i(clk_i),
    
    .a_ready_o(ready_queue_mem_push_s),
    .a_re_i(re_queue_push_s),
    .a_we_i(write_queues_push_s),
    .a_addr_i(addr_queues_push_s),
    .a_din_i(data_write_queues_push_s),
    .a_dout_o(data_read_queues_push_s),
    
    .b_re_i(re_queue_pop_s),
    .b_we_i(write_queues_pop_s),
    .b_addr_i(addr_queues_pop_s),
    .b_din_i(data_write_queues_pop_s),
    .b_dout_o(data_read_queues_pop_s)
);

`else
assign ready_queue_mem_push_s = 1'b1;
dualport_ram_bw #(
    .ADDR_WIDTH(QUEUE_MEM_ADDRESS_WIDTH),
    .MEM_DEPTH(NUM_QUEUES),
    .NUM_BYTES(QUEUE_MEM_WIDTH_BYTES),
    .READ_PIPE_STAGES_A(1),
    .READ_PIPE_STAGES_B(1)
    //.DATA_WIDTH(QUEUE_MEM_WIDTH)
 //   .INIT_VALUE(1'b1)
) queues_mem_inst (
    .clk_i(clk_i),
    
    .a_we_i(write_queues_push_s),
    .a_addr_i(addr_queues_push_s),
    .a_din_i(data_write_queues_push_s),
    .a_dout_o(data_read_queues_push_s),
    
    .b_we_i(write_queues_pop_s),
    .b_addr_i(addr_queues_pop_s),
    .b_din_i(data_write_queues_pop_s),
    .b_dout_o(data_read_queues_pop_s)
);
`endif

//begin valid mem
reg                                 write_valid_push_s;
reg  [VALID_MEM_ADDRESS_WIDH-1:0]   addr_valid_push_s;
wire [PARA_LOOKUP-1:0]              data_read_valid_push_s;
reg [PARA_LOOKUP-1:0]              data_read_valid_push_s_reg;
reg  [PARA_LOOKUP-1:0]              data_write_valid_push_s;

reg                                 write_valid_pop_s;
reg  [VALID_MEM_ADDRESS_WIDH-1:0]   addr_valid_pop_s;
wire [PARA_LOOKUP-1:0]              data_read_valid_pop_s;
reg [PARA_LOOKUP-1:0]              data_read_valid_pop_s_reg;
reg  [PARA_LOOKUP-1:0]              data_write_valid_pop_s;

//TODO das macht slack auf der pop seite
dualport_bram #(
    .ADDR_WIDTH(VALID_MEM_ADDRESS_WIDH),
    .MEM_DEPTH(NUM_VALID_BLOCKS),
    .DATA_WIDTH(PARA_LOOKUP),
    .INIT_VALUE(1'b0)
) valid_mem_inst (
    .clk_i(clk_i),
    
    .a_we_i(write_valid_push_s),
    .a_addr_i(addr_valid_push_s),
    .a_din_i(data_write_valid_push_s),
    .a_dout_o(data_read_valid_push_s),
    
    .b_we_i(write_valid_pop_s),
    .b_addr_i(addr_valid_pop_s),
    .b_din_i(data_write_valid_pop_s),
    .b_dout_o(data_read_valid_pop_s)
);


//descriptor mem instance
localparam DESCRIPTOR_MEM_DATA_WIDTH_BYTES = DESCRIPTOR_MEM_DATA_WIDTH/8;
reg  [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]        addr_descriptor_push_s;
wire  [DESCRIPTOR_MEM_DATA_WIDTH_BYTES-1:0]      write_descriptor_push_s;
reg write_descriptor_push_addr_s, write_descriptor_push_length_s, write_descriptor_push_next_s;
assign write_descriptor_push_s = { {4{write_descriptor_push_addr_s}}, {2{write_descriptor_push_length_s}}, {3{write_descriptor_push_next_s}} };
reg [ADDR_WIDTH-1:0] data_write_descriptor_addr_push_s; 
reg [PACKET_SIZE_WIDTH_INTERNAL-1:0] data_write_descriptor_length_push_s;
reg [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] data_write_descriptor_next_push_s;
wire [DESCRIPTOR_MEM_DATA_WIDTH-1:0]            data_write_descriptor_push_s;
assign data_write_descriptor_push_s = {data_write_descriptor_addr_push_s, data_write_descriptor_length_push_s, data_write_descriptor_next_push_s};

reg  [DESCRIPTOR_MEM_ADDR_WIDTH-1:0]        addr_descriptor_pop_s;
wire [DESCRIPTOR_MEM_DATA_WIDTH-1:0]            data_read_descriptor_pop_s;
wire [ADDR_WIDTH-1:0] data_read_descriptor_addr_pop_s; 
wire [PACKET_SIZE_WIDTH_INTERNAL-1:0] data_read_descriptor_length_pop_s;
wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] data_read_descriptor_next_pop_s; //pointer to next descriptor
assign {data_read_descriptor_addr_pop_s, data_read_descriptor_length_pop_s, data_read_descriptor_next_pop_s} = data_read_descriptor_pop_s;


reg [ADDR_WIDTH-1:0] data_read_descriptor_addr_pop_s_reg; 
reg [PACKET_SIZE_WIDTH_INTERNAL-1:0] data_read_descriptor_length_pop_s_reg;
reg [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] data_read_descriptor_next_pop_s_reg; //pointer to next descriptor

wire ready_descriptor_mem_push_s;
reg re_descriptor_pop_s;

`ifdef SINGLE_PORT_URAM
virt_dualport_ram_bw #(
    .ADDR_WIDTH(DESCRIPTOR_MEM_ADDR_WIDTH),
    .MEM_DEPTH(SIZE_DESCRIPTOR_MEM),
    .NUM_BYTES(DESCRIPTOR_MEM_DATA_WIDTH_BYTES),
    .READ_PIPE_STAGES_B(1)
    //.INIT_VALUE(1'b1)
) descriptor_mem_inst (
    .clk_i(clk_i),
    
    .a_ready_o(ready_descriptor_mem_push_s),
    .a_re_i(1'b0),
    .a_we_i(write_descriptor_push_s),
    .a_addr_i(addr_descriptor_push_s),
    .a_din_i(data_write_descriptor_push_s),
    .a_dout_o(),
    
    .b_re_i(re_descriptor_pop_s),
    .b_we_i(32'b0),
    .b_addr_i(addr_descriptor_pop_s),
    .b_dout_o(data_read_descriptor_pop_s)
);
`else
assign ready_descriptor_mem_push_s = 1'b1; //as we have a dual port ram

dualport_ram_bw #(
    .ADDR_WIDTH(DESCRIPTOR_MEM_ADDR_WIDTH),
    .MEM_DEPTH(SIZE_DESCRIPTOR_MEM),
    .NUM_BYTES(DESCRIPTOR_MEM_DATA_WIDTH_BYTES),
    .READ_PIPE_STAGES_B(1)
    //.INIT_VALUE(1'b1)
) descriptor_mem_inst (
    .clk_i(clk_i),
    
    .a_we_i(write_descriptor_push_s),
    .a_addr_i(addr_descriptor_push_s),
    .a_din_i(data_write_descriptor_push_s),
    .a_dout_o(),
    
    .b_we_i(32'b0),
    .b_addr_i(addr_descriptor_pop_s),
    .b_dout_o(data_read_descriptor_pop_s)
);
`endif

/********************************************************
Descriptor Mem Manager
********************************************************/
wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] next_descriptor_addr_s; //out
wire next_descriptor_addr_valid_s; //out
reg ack_descriptor_addr_s; //in

wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free_descriptor_addr_s; //out
reg free_descriptor_valid_s; //out
wire free_descriptor_ack_s; //in

wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free_drop_descriptor_addr_s;
reg free_drop_descriptor_valid_s;
wire free_drop_descriptor_ack_s;

descriptor_mem_manager # ( 
     .DESCRIPTOR_MEM_ADDR_WIDTH(DESCRIPTOR_MEM_ADDR_WIDTH),
     .SIZE_DESCRIPTOR_MEM(SIZE_DESCRIPTOR_MEM),
     .PARA_LOOKUP_ADDR_WIDTH(PARA_LOOKUP_ADDR_WIDTH),
     .PARA_LOOKUP(PARA_LOOKUP)
) descriptor_mem_manager_inst (
    .clk_i(clk_i),
    .rst_i(rst_i),
    
    .free_descriptor_addr_o(next_descriptor_addr_s),
    .free_descriptor_addr_valid_o(next_descriptor_addr_valid_s),
    
    .ack_descriptor_addr_i(ack_descriptor_addr_s),
    
    .free1_addr_i(free_descriptor_addr_s),
    .free1_valid_i(free_descriptor_valid_s),
    .free1_ack_o(free_descriptor_ack_s),
    
    .free2_addr_i(free_drop_descriptor_addr_s),
    .free2_valid_i(free_drop_descriptor_valid_s),
    .free2_ack_o(free_drop_descriptor_ack_s)
    
);



/********************************************************
Registers for the stored input data
********************************************************/
reg [QUEUE_ID_WIDTH-1:0 ] p_queue_id_push_reg_s;
reg [QUEUE_ID_WIDTH-1:0 ] p_queue_id_push_reg2_addr_queue_s;
reg [QUEUE_ID_WIDTH-1:0 ] p_queue_id_push_reg2_addr_valid_s;

/*********************************************************
               Max Queue Length Memory
*********************************************************/
wire [QUEUE_DEPTH_LENGTH-1:0] max_queue_length_s;
reg [QUEUE_DEPTH_LENGTH-1:0] max_queue_length_s_reg;
queue_length_mem #(
    .MAX_QUEUE_LENGTH_WIDTH(QUEUE_DEPTH_LENGTH)
)queue_length_mem_inst (
     .queue_id_i(p_queue_id_push_reg_s),
     .max_queue_length_o(max_queue_length_s),
     
     .wb_cyc_i(wb_queue_depth_cyc_i),
     .wb_adr_i(wb_queue_depth_adr_i),
     .wb_we_i(wb_queue_depth_we_i),
     .wb_dat_i(wb_queue_depth_dat_i),
     .wb_ack_o(wb_queue_depth_ack_o),
     .wb_dat_o(wb_queue_depth_dat_o),
     
     
    .clk_i(clk_i),
    .rst_i(rst_i)
);

/********************************************************
********************************************************/
localparam [DESCRIPTOR_MEM_ADDR_WIDTH-1:0] LAST_PACKET_POINTER = {DESCRIPTOR_MEM_ADDR_WIDTH{1'b1}};


/********************************************************
conflict resolution signals
    The id range is the prefix of the id - equal to valid mem address ranges
********************************************************/
            
reg push_lock_valid_s;
reg [QUEUE_ID_WIDTH-PARA_LOOKUP_ADDR_WIDTH-1:0] push_lock_id_range_s;

reg pop_lock_valid_s, next_pop_lock_valid_s;
reg [QUEUE_ID_WIDTH-PARA_LOOKUP_ADDR_WIDTH-1:0] pop_lock_id_range_s, next_pop_lock_id_range_s;

reg debug_locked_push, debug_locked_pop;  //debug signals


/******************************************************
Push state machine
******************************************************/
reg [PACKET_SIZE_WIDTH -1 : 0] p_len_i_reg;
reg [ADDR_WIDTH-1:0] p_addr_s_reg;

reg  [PARA_LOOKUP-1:0] valid_mem_push_mask_reg_s;

reg take_queue_id_push_s;
reg save_descriptor_addr_s; //save address where the new packet is stored in the descriptor memory
reg [DESCRIPTOR_MEM_ADDR_WIDTH-1:0] addr_descriptor_mem_new_push_reg_s, addr_descriptor_mem_new_push_reg2_qFirst_s, addr_descriptor_mem_new_push_reg2_qLast_s, addr_descriptor_mem_new_push_reg2_descriptor_s, addr_descriptor_mem_new_push_reg2_free_s;

reg insert_in_empty_queue_s, next_insert_in_empty_queue_s;

assign free_mem_addr_o = p_addr_s_reg;
assign free_drop_descriptor_addr_s = addr_descriptor_mem_new_push_reg2_free_s;

reg [2:0] push_state, next_push_state;
assign push_state_o = push_state;
localparam state_push_idle = 0;
localparam state_push_reg_stage = 1;
localparam state_push_reg2_stage = 2;
localparam state_push_update_queue = 3;
localparam state_push_write_queue =4;
localparam state_push_drop = 5;
localparam state_push_drop_buck = 6;
localparam state_push_drop_ext = 7;
always @(*) begin
    next_push_state = state_push_idle;
    p_pop_s = 1'b0;
    
    take_queue_id_push_s = 1'b0;
    write_queues_push_lengths_s = 1'b0;
    write_queues_push_first_s = 1'b0;
    write_queues_push_last_s = 1'b0;
    
    data_write_queues_push_length_s = p_len_i_reg;
    data_write_queues_push_first_s = addr_descriptor_mem_new_push_reg2_qFirst_s;
    data_write_queues_push_last_s = addr_descriptor_mem_new_push_reg2_qLast_s;

    addr_queues_push_s = 128'bx;
    
    re_queue_push_s = 1'b0;
    
    next_insert_in_empty_queue_s = ((data_read_valid_push_s_reg & valid_mem_push_mask_reg_s) == {PARA_LOOKUP{1'b0}});
    
    write_descriptor_push_addr_s = 1'b0;
    write_descriptor_push_length_s = 1'b0;
    write_descriptor_push_next_s = 1'b0;

    data_write_descriptor_addr_push_s = 32'bx;
    data_write_descriptor_length_push_s = 32'bx;
    data_write_descriptor_next_push_s = 32'bx;

    addr_descriptor_push_s = 0;
    save_descriptor_addr_s = 1'b0;
    ack_descriptor_addr_s = 1'b0;
    
    write_valid_push_s = 1'b0;
    addr_valid_push_s = 128'bx;
    
    free_mem_o = 1'b0;
    free_drop_descriptor_valid_s = 1'b0;
    
    push_lock_valid_s = 1'b1;
    push_lock_id_range_s = p_queue_id_push_reg_s [QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
    debug_locked_push = 1'b0;
    case (push_state)
    
        state_push_idle: begin
            push_lock_valid_s = 1'b0;
            re_queue_push_s = 1'b1;
            
            push_lock_id_range_s = p_queue_id_s [QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
            debug_locked_push = p_valid_s && next_descriptor_addr_valid_s  && (pop_lock_valid_s && pop_lock_id_range_s == push_lock_id_range_s );
            
            if(ready_descriptor_mem_push_s && ready_queue_mem_push_s && p_valid_s && next_descriptor_addr_valid_s  && ~(pop_lock_valid_s && pop_lock_id_range_s == push_lock_id_range_s )) begin 
                
                push_lock_valid_s = 1'b1;
                
                 p_pop_s = 1'b1;
                 next_push_state = state_push_reg_stage;
                 take_queue_id_push_s = 1'b1;
                 
                 addr_queues_push_s = p_queue_id_s;
                 
                 addr_valid_push_s = p_queue_id_s  [QUEUE_ID_WIDTH-1 : PARA_LOOKUP_ADDR_WIDTH];
                 
                 write_descriptor_push_addr_s = 1'b1;
                 write_descriptor_push_length_s = 1'b1;
                 write_descriptor_push_next_s = 1'b1;
                
                 data_write_descriptor_addr_push_s = p_addr_s;
                 data_write_descriptor_length_push_s = p_len_s;
                 data_write_descriptor_next_push_s = LAST_PACKET_POINTER;
                 
                 addr_descriptor_push_s = next_descriptor_addr_s;
                 save_descriptor_addr_s = 1'b1;
                 ack_descriptor_addr_s = 1'b1;  //take the descriptor address from the descriptor mem manager
                 
                 //if(~(ready_descriptor_mem_push_s && ready_queue_mem_push_s)) begin
                    //TODO???
                 //end
                 
             end    
        end
        
        state_push_reg_stage: begin
            next_push_state = state_push_reg2_stage;
            
        end
        
        state_push_reg2_stage: begin
               next_push_state = state_push_update_queue;
        end
        
        
        state_push_update_queue: begin
            if(data_read_queues_push_length_s_reg > max_queue_length_s_reg) begin
                next_push_state = state_push_drop;
                 free_mem_o = 1'b1;
                 free_drop_descriptor_valid_s = 1'b1;
            end else begin
               next_push_state = state_push_write_queue;
               next_insert_in_empty_queue_s = ((data_read_valid_push_s_reg & valid_mem_push_mask_reg_s) == {PARA_LOOKUP{1'b0}}) ;
            end
        end
       
        
        state_push_write_queue: begin
            //packet fits in queue --> normal case
            next_push_state = state_push_idle;
            addr_descriptor_push_s = data_read_queues_push_last_s_reg2;      
            data_write_descriptor_next_push_s = addr_descriptor_mem_new_push_reg2_descriptor_s; 
            addr_queues_push_s = p_queue_id_push_reg2_addr_queue_s;
            
            write_queues_push_lengths_s = 1'b1;
            write_queues_push_last_s = 1'b1;
            data_write_queues_push_first_s = addr_descriptor_mem_new_push_reg2_qFirst_s;
         
            write_valid_push_s = 1'b1;
            addr_valid_push_s = p_queue_id_push_reg2_addr_valid_s [QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
            
            if(insert_in_empty_queue_s) begin  
                    //Insert in an empty queue
                    write_queues_push_first_s = 1'b1;
                    data_write_queues_push_length_s = p_len_i_reg;
                    
            end else begin
                    data_write_queues_push_length_s = data_read_queues_push_length_s_reg_incremented_s;
                    write_descriptor_push_next_s = 1'b1;
            end
            
            if(~(ready_descriptor_mem_push_s && ready_queue_mem_push_s) ) begin //TODO queue wait
                next_push_state = state_push_write_queue;
            end
        end
        
        state_push_drop: begin
            next_push_state = state_push_drop;
            //The received packet will be dropped
            free_mem_o = 1'b1;
            free_drop_descriptor_valid_s = 1'b1;
            
            if(free_mem_ack_i && free_drop_descriptor_ack_s) begin
                next_push_state = state_push_idle;
            end else begin
                if (free_drop_descriptor_ack_s) begin
                    next_push_state = state_push_drop_ext;
                end
                if (free_mem_ack_i) begin
                    next_push_state = state_push_drop_buck;
                end
            end
        end
        
        state_push_drop_ext: begin // in this case the descriptor mem free was acked but the external mem memory has not yet acknowledged the free
            next_push_state = state_push_drop_ext;
            free_mem_o = 1'b1;
            if (free_mem_ack_i) begin
                next_push_state = state_push_idle;
            end
        end
        
        state_push_drop_buck: begin  // in this case the external mem free was acked but the descriptor mem memory has not yet acknowledged the free
            next_push_state = state_push_drop_buck;
            free_drop_descriptor_valid_s = 1'b1;
            if (free_drop_descriptor_ack_s) begin
                next_push_state = state_push_idle;
            end
        end
    endcase
end

always @(posedge clk_i) begin
    if (rst_i) begin
        push_state <= state_push_idle;
    end else begin
        push_state <= next_push_state;
    end
        
    if (push_state == state_push_reg_stage) begin
        data_read_valid_push_s_reg <= data_read_valid_push_s;
    end
    
    if(push_state == state_push_reg2_stage) begin
        data_read_queues_push_last_s_reg <= data_read_queues_push_last_s;    
        data_read_queues_push_length_s_reg <= data_read_queues_push_length_s;
    end
    
    data_read_queues_push_last_s_reg2 <= data_read_queues_push_last_s_reg;
    data_read_queues_push_length_s_reg_incremented_s <= data_read_queues_push_length_s_reg + p_len_i_reg;  
    max_queue_length_s_reg <= max_queue_length_s;
    
    if(take_queue_id_push_s) begin
        p_queue_id_push_reg_s <= p_queue_id_s;
        p_len_i_reg <= p_len_s;
        p_addr_s_reg <= p_addr_s;
    end
    
    p_queue_id_push_reg2_addr_queue_s <= p_queue_id_push_reg_s;
    p_queue_id_push_reg2_addr_valid_s <= p_queue_id_push_reg_s;

    addr_descriptor_mem_new_push_reg2_qFirst_s <= addr_descriptor_mem_new_push_reg_s;
    addr_descriptor_mem_new_push_reg2_qLast_s <= addr_descriptor_mem_new_push_reg_s;
    addr_descriptor_mem_new_push_reg2_descriptor_s <= addr_descriptor_mem_new_push_reg_s;
    addr_descriptor_mem_new_push_reg2_free_s <= addr_descriptor_mem_new_push_reg_s;
    
    insert_in_empty_queue_s <= next_insert_in_empty_queue_s;
    
    //only needed if inserted in empty queue
    valid_mem_push_mask_reg_s <= (1<< (p_queue_id_push_reg_s[PARA_LOOKUP_ADDR_WIDTH-1:0]));
    data_write_valid_push_s <= data_read_valid_push_s_reg | valid_mem_push_mask_reg_s;
    
    
    if(save_descriptor_addr_s) begin
        addr_descriptor_mem_new_push_reg_s  <= addr_descriptor_push_s;
    end
end




/********************************************************
Read logic
*********************************************************/


assign free_descriptor_addr_s = data_read_queues_pop_first_s_reg;

reg [QUEUE_ID_WIDTH-1:0 ] non_empty_queue_pop_s, non_empty_queue_pop_s_reg, next_non_empty_queue_pop_s, pop_queue_s;
reg next_non_empty_queue_valid_s;

reg pop_last_packet_s, next_pop_last_packet_s;
reg pop_take_descriptor_mem_data_s, next_pop_take_descriptor_mem_data_s;

reg  [PARA_LOOKUP-1:0]  non_empty_queue_inv_one_hot_s_reg;

reg [PARA_LOOKUP-1:0] queue_search_mask_s;
wire [PARA_LOOKUP-1:0] search_results_s = queue_search_mask_s & data_read_valid_pop_s_reg;

wire [PARA_LOOKUP-1:0]            search_result_s; //one hot vector which contains search result
wire                              search_result_valid_s = (search_result_s != {PARA_LOOKUP{1'b0}});

wire [PARA_LOOKUP-1:0] c;
generate
		assign c = { (~search_results_s [PARA_LOOKUP-2:0] & c [PARA_LOOKUP-2:0]), 1'b1 };
	    assign search_result_s = search_results_s & c;
endgenerate

wire [PARA_LOOKUP_ADDR_WIDTH-1:0] search_result_bin_s = one_hot_converter(search_result_s);
function integer one_hot_converter; //converts one hot to unsigned decimal
    input one_hot_vector; 
    reg [PARA_LOOKUP-1:0] one_hot_vector;
    integer i; 
    for (i=PARA_LOOKUP - 1; i>=0; i=i-1) begin
        if (one_hot_vector[i]) begin
            one_hot_converter = i;
        end
    end
endfunction 

/******************************************************
Pop state machine
******************************************************/

reg [3:0] pop_state, next_pop_state;
assign pop_state_o = pop_state;
localparam state_pop_idle = 0;
localparam state_pop_pre_search = 1;
localparam state_pop_search = 2;
localparam state_pop_pre_pre_found = 3;
localparam state_pop_wait_queue_mem_1 = 4;
localparam state_pop_pre_found = 5;
localparam state_pop_found = 6;
localparam state_pop_found_wait_descriptor = 7;
localparam state_pop_found_n_wait = 8;
localparam state_pop_dequeue = 9;
localparam state_pop_wait_descriptor_free_ack = 10;


always @(*) begin
    next_pop_state = state_pop_idle;

    addr_descriptor_pop_s = data_read_queues_pop_first_s_reg; //valid 3 clock cycles after pre_pre_found
    
    next_non_empty_queue_pop_s = non_empty_queue_pop_s;
    
    addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];
    data_write_valid_pop_s = data_read_valid_pop_s_reg & non_empty_queue_inv_one_hot_s_reg; 
    write_valid_pop_s = 1'b0;
    
    addr_queues_pop_s = non_empty_queue_pop_s;
    
    write_queues_pop_lengths_s = 1'b0;
    write_queues_pop_first_s = 1'b0;
    write_queues_pop_last_s = 1'b0;
    
    data_write_queues_pop_length_s = {QUEUE_DEPTH_LENGTH{1'b0}};
    data_write_queues_pop_first_s = LAST_PACKET_POINTER;
    data_write_queues_pop_last_s = LAST_PACKET_POINTER;
    
    re_queue_pop_s =1'b0;
    
    pop_id_valid_o = 1'b0;
    pop_queue_id_o = {QUEUE_ID_WIDTH{1'bx}};
    pop_set_base_ready_o = 1'b0;
    
    next_pop_last_packet_s = 1'b0;
    
    next_pop_lock_valid_s = 1'b1;
    next_pop_lock_id_range_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
    debug_locked_pop = 1'b0;
    
    next_valid_o = 1'b0;
    next_pop_take_descriptor_mem_data_s = 1'b0;
    
    re_descriptor_pop_s = 1'b0;
    
    free_descriptor_valid_s = 1'b0;
    
    case (pop_state)
        state_pop_idle: begin
            pop_set_base_ready_o = 1'b1;
            next_pop_lock_valid_s = 1'b0;
            next_non_empty_queue_pop_s = pop_queue_id_base_i;
            if( pop_set_base_queue_id_i) begin
                next_pop_state = state_pop_pre_search;
            end
        end
        state_pop_pre_search: begin
            next_pop_state = state_pop_search;
            next_pop_lock_valid_s = 1'b0;
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;
            if (next_non_empty_queue_pop_s > (NUM_QUEUES-1)) begin
                next_non_empty_queue_pop_s = 0;
            end
            addr_valid_pop_s = next_non_empty_queue_pop_s[QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
        end
        
        state_pop_search: begin
            next_pop_state = state_pop_search;
            next_pop_lock_valid_s = 1'b0;
            
            if(search_result_valid_s) begin
                next_pop_lock_id_range_s = pop_lock_id_range_s;
                next_pop_lock_valid_s = 1'b1; 
                next_non_empty_queue_pop_s = {non_empty_queue_pop_s_reg [QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH], search_result_bin_s};
                //found a non empty queue

                debug_locked_pop = (push_lock_valid_s && push_lock_id_range_s == next_non_empty_queue_pop_s[QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH]);
                if( ~(push_lock_valid_s && push_lock_id_range_s == next_non_empty_queue_pop_s[QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH])) begin
                    next_pop_state = state_pop_pre_pre_found;
                end else begin
                        next_pop_state = state_pop_search;
                end

            end else begin
                next_non_empty_queue_pop_s = {non_empty_queue_pop_s [QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH] + 1, {PARA_LOOKUP_ADDR_WIDTH{1'b0}}};
                if (next_non_empty_queue_pop_s > (NUM_QUEUES-1)) begin
                    next_non_empty_queue_pop_s = 0;
                end
            end
            
            addr_valid_pop_s = next_non_empty_queue_pop_s[QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
        end
        
        state_pop_pre_pre_found:begin
            next_pop_lock_valid_s = 1'b1; //TODO? 
            //non_empty_queue_pop_s is stable on the found ID
            re_queue_pop_s =1'b1;
            next_pop_state = state_pop_wait_queue_mem_1; 
            addr_queues_pop_s = non_empty_queue_pop_s;
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;
            pop_id_valid_o = 1'b1;
            pop_queue_id_o = non_empty_queue_pop_s;
            addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];
        end       
        
        state_pop_wait_queue_mem_1: begin //as queue memory has READ_PIPE_STAGES_A==1, this stage can be removed if number of queues is small enough
            //in this clock cycle: data_read_queues_pop_XXX_s is valid
            
            addr_queues_pop_s = non_empty_queue_pop_s;
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;
            pop_id_valid_o = 1'b1;
            pop_queue_id_o = non_empty_queue_pop_s;
            addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];

            next_pop_state = state_pop_pre_found;
        end
        
 
        state_pop_pre_found:begin
            //in this clock cycle: data_read_queues_pop_XXX_s_reg is valid
            next_pop_state = state_pop_found;
            addr_descriptor_pop_s = data_read_queues_pop_first_s_reg; //
            pop_id_valid_o = 1'b1;
            addr_queues_pop_s = non_empty_queue_pop_s;  //read pointer
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;
            pop_queue_id_o = non_empty_queue_pop_s;
            addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];
        end
        
        
        state_pop_found: begin
            next_pop_state = state_pop_found_wait_descriptor;
            re_descriptor_pop_s = 1'b1;
            next_pop_take_descriptor_mem_data_s = 1'b1; //if state_pop_found_wait_descriptor is not enabled as 1CC read
            addr_queues_pop_s = non_empty_queue_pop_s;  //read pointer
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;
            pop_id_valid_o = 1'b1;
            pop_queue_id_o = non_empty_queue_pop_s;
            addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];
        end
        
        state_pop_found_wait_descriptor: begin
            next_pop_state = state_pop_found_n_wait;
            next_pop_take_descriptor_mem_data_s = 1'b1;
            addr_queues_pop_s = non_empty_queue_pop_s;  //read pointer
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;
            pop_id_valid_o = 1'b1;
            pop_queue_id_o = non_empty_queue_pop_s;
            addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];
        end
        
        state_pop_found_n_wait: begin
            //in this clock cycle data_read_descriptor_pop_XXX_s is valid
            next_pop_state = state_pop_found_n_wait;
            addr_queues_pop_s = non_empty_queue_pop_s;  //read pointer
            next_non_empty_queue_pop_s = non_empty_queue_pop_s;

            pop_id_valid_o = 1'b1;
            pop_queue_id_o = non_empty_queue_pop_s;

            addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1: PARA_LOOKUP_ADDR_WIDTH];
            
            pop_set_base_ready_o = 1'b1;
            if( pop_set_base_queue_id_i) begin
                next_non_empty_queue_pop_s = pop_queue_id_base_i;
                next_pop_state = state_pop_pre_search;
            end
            
            
            if (pop_i) begin
                next_pop_state = state_pop_dequeue;
                free_descriptor_valid_s = 1'b1;
            end
            
            next_pop_last_packet_s = (data_read_queues_pop_first_s_reg == data_read_queues_pop_last_s_reg);
        end


        state_pop_dequeue: begin
                next_pop_state = state_pop_idle;
                next_pop_lock_valid_s = 1'b1;
                next_valid_o = 1'b1;
                
                //write pointer
                addr_queues_pop_s = non_empty_queue_pop_s;
                
                if(pop_last_packet_s) begin  //if we pop the last packet of a queue
                
                    write_queues_pop_lengths_s = 1'b1;
                    write_queues_pop_first_s = 1'b1;
                    write_queues_pop_last_s = 1'b1;
                    
                    data_write_queues_pop_length_s = {QUEUE_DEPTH_LENGTH{1'b0}};
                    data_write_queues_pop_first_s = LAST_PACKET_POINTER;
                    data_write_queues_pop_last_s = LAST_PACKET_POINTER;
                
                    addr_valid_pop_s = non_empty_queue_pop_s[QUEUE_ID_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH];
                    write_valid_pop_s = 1'b1; //write the valid memory
                end else begin //just move the pointer to the second queue entry
                    write_queues_pop_lengths_s = 1'b1;
                    write_queues_pop_first_s = 1'b1;
                    write_queues_pop_last_s = 1'b0;
                    
                    
                    data_write_queues_pop_length_s = data_read_queues_pop_length_s_reg - data_read_descriptor_length_pop_s_reg;
                    data_write_queues_pop_first_s = data_read_descriptor_next_pop_s_reg;
                end
                
                

                free_descriptor_valid_s = 1'b1;
                if (free_descriptor_ack_s) begin
                    pop_set_base_ready_o = 1'b1;
                end else begin
                    next_pop_lock_valid_s = 1'b1;
                    next_pop_state = state_pop_wait_descriptor_free_ack;
                end
                
        end
        state_pop_wait_descriptor_free_ack: begin
            next_pop_state = state_pop_wait_descriptor_free_ack;
            free_descriptor_valid_s = 1'b1;
            if (free_descriptor_ack_s) begin
                next_pop_lock_valid_s = 1'b0;
                next_pop_state = state_pop_idle;
            end
            
        end
        
    endcase
end

    

always @(posedge clk_i) begin
    if (rst_i) begin
        pop_state <= state_pop_idle;
    end else begin
        pop_state <= next_pop_state;
    end
    
    if (pop_state == state_pop_pre_found) begin
        data_read_queues_pop_first_s_reg <= data_read_queues_pop_first_s;
        data_read_queues_pop_last_s_reg <= data_read_queues_pop_last_s;
        data_read_queues_pop_length_s_reg <= data_read_queues_pop_length_s;
    end

    pop_take_descriptor_mem_data_s <= next_pop_take_descriptor_mem_data_s;
    if(pop_take_descriptor_mem_data_s) begin
        data_read_descriptor_addr_pop_s_reg <= data_read_descriptor_addr_pop_s;
        data_read_descriptor_length_pop_s_reg <= data_read_descriptor_length_pop_s;
        data_read_descriptor_next_pop_s_reg <= data_read_descriptor_next_pop_s;

    end

    non_empty_queue_pop_s <= next_non_empty_queue_pop_s;
    non_empty_queue_pop_s_reg <= non_empty_queue_pop_s;
    

    pop_lock_valid_s <= next_pop_lock_valid_s;
    pop_lock_id_range_s <= next_pop_lock_id_range_s; 
    
    data_read_valid_pop_s_reg <= data_read_valid_pop_s;
    
    pop_addr_o <= data_read_descriptor_addr_pop_s_reg;
    pop_len_o <= data_read_descriptor_length_pop_s_reg;
    pop_queue_len_o <= data_read_queues_pop_length_s_reg;
    
    
    pop_last_packet_s <= next_pop_last_packet_s;

    queue_search_mask_s <= ({PARA_LOOKUP{1'b1}} << non_empty_queue_pop_s[PARA_LOOKUP_ADDR_WIDTH-1:0]);
    non_empty_queue_inv_one_hot_s_reg <= ~( 1 << (non_empty_queue_pop_s[PARA_LOOKUP_ADDR_WIDTH-1:0]));


    valid_o <= next_valid_o;
    
end

endmodule
