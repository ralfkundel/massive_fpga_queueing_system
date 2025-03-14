module AxisToAxi_rx_handler #(
	parameter AXI_ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 64, //both, axi and axis
	parameter PACKET_SIZE_WIDTH = 11,
	parameter QUEUE_ID_WIDTH = 32,
    parameter AXI_ID_WIDTH = 2
)(
    input  wire                   clk_i,
    input  wire                   reset_i,
    
    //memory alloc interface
    input wire [AXI_ADDR_WIDTH-1:0] next_addr_i,
    input wire      next_addr_valid_i,
    output wire [PACKET_SIZE_WIDTH-1:0]  packet_length_o,
    output reg addr_ack_o,
    
    //AXI Memory Interface
    output reg  [AXI_ID_WIDTH-1:0] axi_awid_o, // Write address ID
     output reg [AXI_ADDR_WIDTH-1:0] axi_awaddr_o, // Write address
     output reg  [7:0] axi_awlen_o, // Burst length
     output wire [2:0] axi_awsize_o, // Burst size
     output wire [1:0] axi_awburst_o, // Burst type
     output wire [0:0] axi_awlock_o, // Lock type //TODO
     output wire [3:0] axi_awcache_o, // Cache type
     output wire [2:0] axi_awprot_o, // Protection type
     //output wire [3:0] <s_awregion>, // Write address slave region //TODO
     output wire [3:0] axi_awqos_o, // Transaction Quality of Service token
     //output wire [<left_bound>:0] <s_awuser>, // Write address user sideband //TODO
     output reg axi_awvalid_o, // Write address valid
     input wire axi_awready_i, // Write address ready
     
     output reg  [AXI_ID_WIDTH-1:0] axi_wid_o, // Write ID tag
     output reg  [DATA_WIDTH-1:0] axi_wdata_o, // Write data
     output wire [DATA_WIDTH/8-1:0] axi_wstrb_o, // Write strobes
     output reg  axi_wlast_o, // Write last beat
     //output wire [<left_bound>:0] <s_wuser>, // Write data user sideband //TODO
     output reg axi_wvalid_o, // Write valid
     input wire axi_wready_i, // Write ready
     
     input wire [AXI_ID_WIDTH-1:0] axi_bid_i, // Response ID
     input wire [1:0] axi_bresp_i, // Write response
     //input wire [<left_bound>:0] <s_buser>, // Write response user sideband //TODO
     input wire axi_bvalid_i, // Write response valid
     output reg axi_bready_o, // Write response ready


    
    //AXIS input fifo interface
    output reg                    s_axis_tready_o,
    input  wire                   s_axis_tvalid_i,
    input  wire [DATA_WIDTH-1:0]  s_axis_tdata_i,
    input  wire [DATA_WIDTH/8-1:0]  s_axis_tkeep_i,
    input  wire                   s_axis_tlast_i,
    input wire [PACKET_SIZE_WIDTH-1:0]  s_axis_packet_length_i,
    input wire [QUEUE_ID_WIDTH-1:0] s_axis_queue_id_i,
    
    //TODO eqm (enqueue manager) interface
    output reg eqm_valid_o,
    output reg [PACKET_SIZE_WIDTH-1:0] eqm_packet_length_o,
    output reg [QUEUE_ID_WIDTH-1:0] eqm_queue_id_o,
    output reg [AXI_ADDR_WIDTH-1:0] eqm_addr_o,
    input wire eqm_ready_i
);



assign axi_awsize_o = $clog2((DATA_WIDTH/8)-1);

assign axi_awburst_o = 2'b01; //incremental
assign axi_awlock_o = 0;
assign axi_awcache_o = 4'b0010;
assign axi_awprot_o = 0;
assign axi_awqos_o = 0;
assign axi_wstrb_o= {DATA_WIDTH/8{1'b1}};


assign packet_length_o = s_axis_packet_length_i; //for memory alloc

wire  [7:0] axi_burst_len_s = ((s_axis_packet_length_i  + (DATA_WIDTH/8 - 1) ) / (DATA_WIDTH/8) ) - 1; //4 means 5 bus cycles, start counting with 0

reg [AXI_ADDR_WIDTH-1:0] eqm_addr_reg_s;

reg [AXI_ID_WIDTH-1:0] next_wid_o;

//
reg [QUEUE_ID_WIDTH-1:0]eqm_queue_id_o_reg [2**AXI_ID_WIDTH-1:0];
reg [PACKET_SIZE_WIDTH-1:0] eqm_packet_length_o_reg [2**AXI_ID_WIDTH-1:0];
reg [AXI_ADDR_WIDTH-1:0] eqm_addr_o_reg [2**AXI_ID_WIDTH-1:0];

// axi ID optimizations
reg [2**AXI_ID_WIDTH-1:0] valid_ids;
wire[AXI_ID_WIDTH-1:0] next_unused_id_s = one_hot_converter(~valid_ids);

function integer one_hot_converter; //converts one hot to unsigned decimal
    input one_hot_vector; 
    reg [2**AXI_ID_WIDTH-1:0] one_hot_vector;
    integer i; 
    for (i= (2**AXI_ID_WIDTH - 1); i>=0; i=i-1) begin
        if (one_hot_vector[i]) begin
            one_hot_converter = i;
        end
    end
endfunction 

//////////////////////////////////////
//   Address Write State machine    //
//////////////////////////////////////

localparam aw_state_idle = 2'b00;
localparam aw_state_address_write = 2'b01;
localparam aw_state_finished = 2'b10;
reg [1:0] aw_state, next_aw_state;
reg write_addr_s;
reg set_addr_s;

reg lock_id_s;

reg ready_to_write_s; //this signal indicates to w-state-machine that it can start sending with the current id

always @(*) begin
    next_aw_state = aw_state_idle;
    write_addr_s = 1'b0;
    set_addr_s = 1'b0;
    lock_id_s = 1'b0;
        
    ready_to_write_s= 1'b0;
    
    case (aw_state)
    
        aw_state_idle: begin
            if(s_axis_tvalid_i && next_addr_valid_i && (valid_ids != {(2**AXI_ID_WIDTH) {1'b1}}) && eqm_ready_i) begin  //TODO: replace eqm_ready_i by ~eqm_almost_full_i
                set_addr_s = 1'b1;
                lock_id_s = 1'b1;
                if(axi_awready_i) begin
                    next_aw_state = aw_state_finished;
                    write_addr_s = 1'b1;
                end else begin
                    next_aw_state = aw_state_address_write;
                    write_addr_s = 1'b1;
                end
            end
        end
        
        aw_state_address_write: begin
            next_aw_state = aw_state_address_write;
            write_addr_s = 1'b1;
            ready_to_write_s= 1'b1;
            if(axi_awready_i) begin
                next_aw_state = aw_state_finished;
                write_addr_s = 1'b0;
            end
        end
        
        aw_state_finished: begin
            next_aw_state = aw_state_finished;
            ready_to_write_s= 1'b1;
            if(axi_wlast_o && axi_wready_i && axi_wvalid_o) begin
                next_aw_state = aw_state_idle;
            end
        
        end
    
    endcase
end

always @(posedge clk_i) begin
    if (reset_i) begin
        aw_state <= aw_state_idle;
        axi_awvalid_o <= 1'b0;
    end else begin
        aw_state <= next_aw_state;
        if (write_addr_s) begin
            axi_awlen_o <= axi_burst_len_s;
            axi_awvalid_o <= 1'b1;
        end else begin
            axi_awvalid_o <= 1'b0;
        end
    end
    if (set_addr_s) begin
        axi_awaddr_o <= next_addr_i;
        eqm_addr_o_reg[next_unused_id_s] <= next_addr_i;
        eqm_addr_reg_s <= next_addr_i;
        addr_ack_o <=  1'b1;
        axi_awid_o <= next_unused_id_s;
        next_wid_o <= next_unused_id_s;
    end else begin
         addr_ack_o <=  1'b0;
    end
end

//////////////////////////////////////
//      Write State machine         //
//////////////////////////////////////

localparam w_state_idle = 3'b001;
localparam w_state_send = 3'b010;
localparam w_state_last = 3'b011;
reg [2:0] w_state, next_w_state;

reg set_next_data_s;
reg next_axi_wvalid_s;
reg next_axi_wlast_s;

//reg next_eqm_valid_o;
reg prepare_eqm_data_s;


always @(*) begin
    next_w_state = w_state_idle;
    set_next_data_s = 1'b0;
    next_axi_wvalid_s = 1'b0;
    s_axis_tready_o  = 1'b0;
    next_axi_wlast_s = 1'b0;
    
    //next_eqm_valid_o = 1'b0;
    prepare_eqm_data_s = 1'b0;
   
    
    case (w_state)
        w_state_idle: begin
            if(s_axis_tvalid_i && next_addr_valid_i && ready_to_write_s) begin
                next_w_state = w_state_send;
                prepare_eqm_data_s = 1'b1;
                s_axis_tready_o = 1'b1;
                set_next_data_s = 1'b1;
                next_axi_wvalid_s = 1'b1;
                if (s_axis_tlast_i) begin //iff packet fits in one clock cycle, e.g. 64 byte
                    next_w_state = w_state_last;
                    next_axi_wlast_s = 1'b1; 
                end
            end
        end

        w_state_send: begin
            next_axi_wvalid_s = 1'b1;
            next_w_state = w_state_send;
            if (axi_wready_i) begin
                s_axis_tready_o = 1'b1;
                set_next_data_s = 1'b1;
                if (s_axis_tlast_i) begin
                    next_w_state = w_state_last;
                    next_axi_wlast_s = 1'b1; 
                end
            end
            
        end
        w_state_last: begin
            next_w_state = w_state_last;
            next_axi_wvalid_s = 1'b1;
            next_axi_wlast_s = 1'b1;
            if (axi_wready_i) begin
                next_axi_wvalid_s = 1'b0;
                next_axi_wlast_s = 1'b0;
                next_w_state = w_state_idle;
            end
        end
        
    endcase
end

always @(posedge clk_i) begin
    if (reset_i) begin
        w_state <= w_state_idle;
    end else begin
        w_state <= next_w_state;
        
        if(prepare_eqm_data_s) begin
            eqm_queue_id_o_reg[next_wid_o] <= s_axis_queue_id_i;
            eqm_packet_length_o_reg[next_wid_o] <= s_axis_packet_length_i;
        end
    end
    axi_wvalid_o <= next_axi_wvalid_s;
    
    if(set_next_data_s) begin
        axi_wdata_o <= s_axis_tdata_i;
        axi_wid_o <= next_wid_o;
    end 
    axi_wlast_o <= next_axi_wlast_s;
    
end


always @(posedge clk_i) begin
    if (reset_i) begin
        valid_ids <= 0;
    end else begin
        if(axi_bvalid_i && axi_bready_o) begin
            if(lock_id_s == 1'b1) begin
                valid_ids <= ( valid_ids | (1 << next_unused_id_s) ) & ~(1 << axi_bid_i); //Take axi id and free id at same time
            end else begin
                valid_ids <= (valid_ids) & ~(1 << axi_bid_i); // free axi id as axi_b channel notified successful write
            end
        end else if (lock_id_s == 1'b1) begin
            valid_ids <= (valid_ids | (1 << next_unused_id_s) ); //take next_unused_is_s as axi_aw id
        end
    end
    
end

reg eqm_state, next_eqm_state;
localparam eqm_state_idle = 1'b0;
localparam eqm_state_wait = 1'b1;
reg set_eqm_data_s;
always @(*) begin
    next_eqm_state = eqm_state_idle;
    set_eqm_data_s = 1'b0;
    eqm_valid_o = 1'b0;
    axi_bready_o = 1'b0;
    
    case(eqm_state)
    
    eqm_state_idle: begin
        axi_bready_o = 1'b1;
        if (axi_bvalid_i) begin
            next_eqm_state = eqm_state_wait;
            set_eqm_data_s = 1'b1;
        end
    end
    
    eqm_state_wait: begin
        next_eqm_state = eqm_state_wait;
        eqm_valid_o = 1'b1;
        if(eqm_ready_i) begin
            next_eqm_state = eqm_state_idle;
        end else begin

        end
    end
    
    endcase
end


always @(posedge clk_i) begin
    if (reset_i) begin
        eqm_state <= eqm_state_idle;
        
    end else begin
        eqm_state <= next_eqm_state;
    end
    
    if(set_eqm_data_s) begin
        eqm_queue_id_o <= eqm_queue_id_o_reg[axi_bid_i];
        eqm_packet_length_o <= eqm_packet_length_o_reg[axi_bid_i];
        eqm_addr_o <= eqm_addr_o_reg[axi_bid_i];
    end
end



    
endmodule


