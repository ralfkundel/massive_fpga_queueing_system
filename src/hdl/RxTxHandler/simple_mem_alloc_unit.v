module mem_alloc_unit #(
    parameter PACKET_SIZE_WIDTH = 11,
	parameter AXI_ADDR_WIDTH = 32,
	parameter PARA_LOOKUP = 32,
	parameter NUM_MEM_BLOCKS = 2**4,          //at least the number of bucket blocks
	parameter PARA_LOOKUP_ADDR_WIDTH = $clog2(PARA_LOOKUP)
)(

    input wire clk_i,
    input wire rst_i,
    
    output reg [AXI_ADDR_WIDTH-1:0] next_addr_o,
    output reg  next_addr_valid_o,
    //packet length i should have the value of the current packet at the same clockcycle than ack_i
    input wire [PACKET_SIZE_WIDTH-1:0]  packet_length_i,
    input wire addr_ack_i,
    
    input wire [AXI_ADDR_WIDTH-1:0] free_mem_addr_i,
    input wire free_mem_i,
    output reg free_mem_ack_o
    
);
localparam NUM_VALID_BLOCKS = (NUM_MEM_BLOCKS + PARA_LOOKUP - 1)/PARA_LOOKUP; //always round up. so for 1025 queues and 32 para lookups 33 blocks are required
localparam VALID_MEM_ADDRESS_WIDH = $clog2(NUM_VALID_BLOCKS-1); //-1 as if we have 4096 blocks, the blocks are 0->4095


localparam PACKET_ADDRESS_BITS = 11; //for 2^11 bytes max packet size

reg                                 write_valid_malloc_s;
reg  [VALID_MEM_ADDRESS_WIDH-1:0]   addr_valid_malloc_s;
wire [PARA_LOOKUP-1:0]              data_read_valid_malloc_s;
reg  [PARA_LOOKUP-1:0]              data_write_valid_malloc_s;


reg                                 write_valid_free_s;
reg  [VALID_MEM_ADDRESS_WIDH-1:0]   addr_valid_free_s;
wire [PARA_LOOKUP-1:0]              data_read_valid_free_s;
reg  [PARA_LOOKUP-1:0]              data_write_valid_free_s;


dualport_bram #(
    .ADDR_WIDTH(VALID_MEM_ADDRESS_WIDH),
    .MEM_DEPTH(NUM_VALID_BLOCKS),
    .DATA_WIDTH(PARA_LOOKUP),
    .INIT_VALUE(1'b0)
) ext_memory_occupied_mem (
    .clk_i(clk_i),
    
    .a_we_i(write_valid_malloc_s),
    .a_addr_i(addr_valid_malloc_s),
    .a_din_i(data_write_valid_malloc_s),
    .a_dout_o(data_read_valid_malloc_s),
    
    .b_we_i(write_valid_free_s),
    .b_addr_i(addr_valid_free_s),
    .b_din_i(data_write_valid_free_s),
    .b_dout_o(data_read_valid_free_s)
);

/********************************************************
ALLOC MACHINE
********************************************************/

wire [PARA_LOOKUP-1:0]              first_free_pointer_s;
wire [PARA_LOOKUP_ADDR_WIDTH-1:0]   first_free_pointer_bin_s = one_hot_converter(first_free_pointer_s);

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

wire [PARA_LOOKUP-1:0] c;
generate
		assign c = { (data_read_valid_malloc_s [PARA_LOOKUP-2:0] & c [PARA_LOOKUP-2:0]), 1'b1 };
	    assign first_free_pointer_s = ~data_read_valid_malloc_s & c;
endgenerate


reg  [VALID_MEM_ADDRESS_WIDH-1:0]   addr_valid_malloc_s_reg;
reg [AXI_ADDR_WIDTH-1:0] next_addr_o_s;

wire malloc_found_free_s = data_read_valid_malloc_s != {PARA_LOOKUP{1'b1}}; //if all bits are high we have no hit

reg [1:0] alloc_state, next_alloc_state;
localparam alloc_state_search = 0;
localparam alloc_state_found = 1;
localparam alloc_state_wait_for_write = 2;
localparam alloc_state_write = 3;
always @(*) begin
    next_alloc_state = alloc_state_search;
    
    next_addr_o_s = {AXI_ADDR_WIDTH{1'bx}};
    
    write_valid_malloc_s = 1'b0;
    addr_valid_malloc_s = 0;
    data_write_valid_malloc_s = {PARA_LOOKUP{1'bx}};
    
    next_addr_valid_o = 1'b0;
    
    
    
    case(alloc_state)
        alloc_state_search: begin
            addr_valid_malloc_s = addr_valid_malloc_s_reg + 1;
            
            if(malloc_found_free_s) begin //hit
                next_alloc_state = alloc_state_found;
                addr_valid_malloc_s = addr_valid_malloc_s_reg;
                next_addr_o_s = {addr_valid_malloc_s_reg, first_free_pointer_bin_s, {PACKET_ADDRESS_BITS{1'b0}}};
            end else
            
            if(addr_valid_malloc_s == NUM_VALID_BLOCKS) begin
                addr_valid_malloc_s = 0;
            end
            
        end
        
        alloc_state_found: begin
            next_alloc_state = alloc_state_found;
            next_addr_o_s = next_addr_o;
            addr_valid_malloc_s = addr_valid_malloc_s_reg;
            
            next_addr_valid_o = 1'b1;
            if(addr_ack_i) begin
                if(!free_lock && !write_valid_free_s) begin
                    next_alloc_state = alloc_state_write;
                    write_valid_malloc_s = 1'b1;
                    data_write_valid_malloc_s = (data_read_valid_malloc_s | (1<< next_addr_o[PACKET_ADDRESS_BITS+PARA_LOOKUP_ADDR_WIDTH-1: PACKET_ADDRESS_BITS]));
                end else begin
                    next_alloc_state = alloc_state_wait_for_write;
                end
            end
        end
        
        alloc_state_wait_for_write: begin
            next_alloc_state = alloc_state_wait_for_write;
            addr_valid_malloc_s = addr_valid_malloc_s_reg;
            if(!free_lock) begin
                next_alloc_state = alloc_state_write;
                write_valid_malloc_s = 1'b1;
                data_write_valid_malloc_s = (data_read_valid_malloc_s | (1<< next_addr_o[PACKET_ADDRESS_BITS+PARA_LOOKUP_ADDR_WIDTH-1: PACKET_ADDRESS_BITS]));
            end
            
        end
        
        alloc_state_write: begin
            next_alloc_state = alloc_state_search;
            addr_valid_malloc_s = addr_valid_malloc_s_reg;
        end
        
    endcase
end
reg [31:0] num_mallocs;
always @(posedge clk_i) begin
    if (rst_i) begin
        alloc_state <= alloc_state_search;
        addr_valid_malloc_s_reg <= 0;
        num_mallocs <= 0;
        //next_addr_o <= 0;
    end else begin
        alloc_state <= next_alloc_state;
        addr_valid_malloc_s_reg <= addr_valid_malloc_s;
        if(next_addr_valid_o && addr_ack_i) begin
            num_mallocs = num_mallocs +1;
        end
    end
    next_addr_o <= next_addr_o_s;
end


/**********************************************
FREE
**********************************************/
reg [1:0] free_state, next_free_state;
localparam free_state_idle = 0;
localparam free_state_write = 1;
//localparam alloc_state_write = 2;


always @(*) begin
    next_free_state =    free_state_idle;
    addr_valid_free_s = free_mem_addr_i[AXI_ADDR_WIDTH-1:PARA_LOOKUP_ADDR_WIDTH + PACKET_ADDRESS_BITS];
    write_valid_free_s = 1'b0;
    data_write_valid_free_s = {PARA_LOOKUP{1'bx}};
    free_mem_ack_o = 1'b0;
    next_free_lock = 1'b0;

    
    case ( free_state)
        free_state_idle: begin
            if(free_mem_i && ~addr_ack_i) begin
                next_free_state = free_state_write;
            end
        end
        free_state_write: begin
            next_free_state =    free_state_write;
            data_write_valid_free_s = data_read_valid_free_s & ~(1 << free_mem_addr_i[PACKET_ADDRESS_BITS+PARA_LOOKUP_ADDR_WIDTH-1:PACKET_ADDRESS_BITS]);
            if(~addr_ack_i) begin
                next_free_state = free_state_idle;
                write_valid_free_s = 1'b1;
                free_mem_ack_o = 1'b1;
                next_free_lock = 1'b1;
            end else begin
                next_free_state = free_state_idle; //in this case we have to read again ...
            end
        end
        
    endcase
end
reg [31:0] num_frees;
reg free_lock, next_free_lock;
always @(posedge clk_i) begin
    if (rst_i) begin
        free_state <= free_state_idle;
        num_frees = 0;
    end else begin
        free_state <= next_free_state;
        if(free_mem_ack_o) begin
            num_frees = num_frees + 1;
        end
    end
    free_lock <= next_free_lock;
end


endmodule