module descriptor_mem_manager# (
     parameter DESCRIPTOR_MEM_ADDR_WIDTH=1,
     parameter SIZE_DESCRIPTOR_MEM = 1,
     parameter PARA_LOOKUP_ADDR_WIDTH = 1,
     parameter PARA_LOOKUP = 1
    

) (
    input wire clk_i,
    input wire rst_i,
    
    output reg [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free_descriptor_addr_o,
    output reg free_descriptor_addr_valid_o,
    input wire ack_descriptor_addr_i,
    
    
    input wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free1_addr_i,
    input wire free1_valid_i,
    output wire free1_ack_o,
    
    input wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free2_addr_i,
    input wire free2_valid_i,
    output wire free2_ack_o

);

reg [31:0] num_descriptor_free1; //DEBUG Signal
reg [31:0] num_descriptor_free2; //DEBUG Signal
always@(posedge clk_i) begin
    if(rst_i) begin
        num_descriptor_free1 <= 0;
        num_descriptor_free2 <= 0;
    end else begin
        if(free1_valid_i && free1_ack_o) begin
            num_descriptor_free1 <= num_descriptor_free1 + 1;
        end
        if(free2_valid_i && free2_ack_o) begin
            num_descriptor_free2 <= num_descriptor_free2 + 1;
        end
    end
end

 wire [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free_addr_i;
 wire free_valid_i;
 reg  free_ack_o;
 
 job_arbiter #(
     .WIDTH(DESCRIPTOR_MEM_ADDR_WIDTH),
     .DEPTH(4)
 ) free_descriptor_mem_inst (
     .p1_data_i(free1_addr_i),
     .p1_valid_i(free1_valid_i),
     .p1_ack_o(free1_ack_o),
     .p1_ready_o(),
     
     .p2_data_i(free2_addr_i),
     .p2_valid_i(free2_valid_i), //TODO for future use in queue_mem taildrop
     .p2_ack_o(free2_ack_o),
     .p2_ready_o(),
     
     .out_data_o(free_addr_i),
     .out_valid_o(free_valid_i),
     .out_pop_i(free_ack_o),
 
     .clk_i(clk_i),
     .rst_i(rst_i)
 
 );

localparam [DESCRIPTOR_MEM_ADDR_WIDTH-1:0] last_packet_pointer = {DESCRIPTOR_MEM_ADDR_WIDTH{1'b1}};

reg [31:0] num_descriptor_allocs; //Debug signal
reg [31:0] num_descriptor_frees; //Debug signal

reg next_free_descriptor_addr_valid_o_reg; //only for statistics
always@(posedge clk_i) begin
    next_free_descriptor_addr_valid_o_reg <= next_free_descriptor_addr_valid_o;
    if(rst_i) begin
        num_descriptor_allocs <= 0;
        num_descriptor_frees <= 0;
    end else begin
        if(free_valid_i && free_ack_o) begin
            num_descriptor_frees <= num_descriptor_frees + 1;
        end
        if(next_free_descriptor_addr_valid_o_reg && ack_descriptor_addr_i) begin
            num_descriptor_allocs <= num_descriptor_allocs +1;
        end
    end
    if(next_free_descriptor_addr_o == last_packet_pointer && next_free_descriptor_addr_valid_o) begin
        $finish();
    end 
end

reg [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] free_addr_i_reg;

/************************************************************
            descriptor Allocator Unit
************************************************************/

localparam descriptor_FREE_ADDR_WIDTH = $clog2(SIZE_DESCRIPTOR_MEM) - PARA_LOOKUP_ADDR_WIDTH;
localparam NUM_descriptor_FREE_BLOCKS = (SIZE_DESCRIPTOR_MEM+PARA_LOOKUP-1)/PARA_LOOKUP;


reg [PARA_LOOKUP-1:0]       descriptor_mem_free [NUM_descriptor_FREE_BLOCKS-1:0];
integer i;
initial begin
    for(i = 0; i < NUM_descriptor_FREE_BLOCKS; i=i+1) begin
        descriptor_mem_free[i] = {PARA_LOOKUP{1'b1}}; //TODO do this by reset in hardware
    end
end

reg [descriptor_FREE_ADDR_WIDTH-1:0] addr_descriptor_free_s, addr_read_descriptor_free_s_reg;
reg [PARA_LOOKUP-1:0]            data_read_descriptor_free_s;
reg                              write_descriptor_free_s;
reg [PARA_LOOKUP-1:0]            data_write_descriptor_free_s;

    reg [DESCRIPTOR_MEM_ADDR_WIDTH-1: 0] next_free_descriptor_addr_o;
    reg next_free_descriptor_addr_valid_o;

reg [2:0] ba_state, next_ba_state;
localparam ba_state_idle = 0;
localparam ba_state_found = 1;
localparam ba_state_free = 2;

always @(*) begin
    next_ba_state = ba_state_idle;
    next_free_descriptor_addr_valid_o = 1'b0;
    next_free_descriptor_addr_o = (addr_read_descriptor_free_s_reg << PARA_LOOKUP_ADDR_WIDTH) + one_hot_converter(data_read_descriptor_free_s);
    
    write_descriptor_free_s = 1'b0;
    addr_descriptor_free_s = addr_read_descriptor_free_s_reg;
    data_write_descriptor_free_s = 0;
    
    free_ack_o  = 1'b0;
    
    case (ba_state)
       ba_state_idle: begin
            
           addr_descriptor_free_s = addr_read_descriptor_free_s_reg + 1; 
            
            if(free_valid_i) begin 
                next_ba_state = ba_state_free;
                addr_descriptor_free_s = free_addr_i[DESCRIPTOR_MEM_ADDR_WIDTH-1 : PARA_LOOKUP_ADDR_WIDTH];
            end else
            if (data_read_descriptor_free_s != 0) begin
                next_ba_state = ba_state_found;
                addr_descriptor_free_s = addr_read_descriptor_free_s_reg;
            end

       end
       ba_state_found: begin
            next_ba_state = ba_state_found;
            next_free_descriptor_addr_valid_o = 1'b1;
            next_free_descriptor_addr_o = (addr_read_descriptor_free_s_reg << PARA_LOOKUP_ADDR_WIDTH) + one_hot_converter(data_read_descriptor_free_s);

            if (last_packet_pointer == next_free_descriptor_addr_o) begin //special case for null pointer
                next_ba_state = ba_state_idle;
                next_free_descriptor_addr_valid_o = 1'b0;
                addr_descriptor_free_s = addr_read_descriptor_free_s_reg + 1;
                
            end else

            if(ack_descriptor_addr_i) begin
                next_ba_state = ba_state_idle;
                write_descriptor_free_s = 1'b1;
                data_write_descriptor_free_s = data_read_descriptor_free_s & ~data_read_descriptor_free_first_s;
                next_free_descriptor_addr_valid_o = 1'b0;
            end else if (free_valid_i) begin
                next_ba_state = ba_state_free;
                addr_descriptor_free_s = free_addr_i[DESCRIPTOR_MEM_ADDR_WIDTH-1 : PARA_LOOKUP_ADDR_WIDTH];
                next_free_descriptor_addr_valid_o = 1'b0;
            end
            
       end
       
       ba_state_free: begin
            free_ack_o = 1'b1;
            next_ba_state = ba_state_found; //the free memory is our found match
            addr_descriptor_free_s = addr_read_descriptor_free_s_reg;
            write_descriptor_free_s = 1'b1;
            data_write_descriptor_free_s = data_read_descriptor_free_s | (1<< free_addr_i_reg[PARA_LOOKUP_ADDR_WIDTH-1:0]);
       end
       
       
       
    endcase
end



always @(posedge clk_i) begin
    if(rst_i) begin
        ba_state <= ba_state_idle;
        addr_read_descriptor_free_s_reg <= 0;
    end else begin
        ba_state <= next_ba_state;
        addr_read_descriptor_free_s_reg <= addr_descriptor_free_s;
    end
    free_addr_i_reg <= free_addr_i;
    
    
    if (write_descriptor_free_s) begin
        descriptor_mem_free[addr_descriptor_free_s] <= data_write_descriptor_free_s;
        data_read_descriptor_free_s <= data_write_descriptor_free_s;
    end else begin
        data_read_descriptor_free_s <= descriptor_mem_free[addr_descriptor_free_s];
    end
    
    free_descriptor_addr_o <= next_free_descriptor_addr_o;
    free_descriptor_addr_valid_o <= next_free_descriptor_addr_valid_o;
end

wire [PARA_LOOKUP-1:0]            data_read_descriptor_free_first_s;


wire [PARA_LOOKUP-1:0] c;
generate

		assign c = { (~data_read_descriptor_free_s [PARA_LOOKUP-2:0] & c [PARA_LOOKUP-2:0]), 1'b1 };
	    assign data_read_descriptor_free_first_s = data_read_descriptor_free_s & c;
endgenerate



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

endmodule
