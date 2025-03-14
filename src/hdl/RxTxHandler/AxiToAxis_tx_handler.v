module AxiToAxis_tx_handler #(
	parameter AXI_ADDR_WIDTH = 32,
	parameter DATA_WIDTH = 64, //both, axi and axis
	parameter PACKET_SIZE_WIDTH = 11,
	parameter QUEUE_ID_WIDTH = 32,
    parameter AXI_ID_WIDTH = 2
)(
    input  wire                   clk_i,
    input  wire                   rst_i,
    
    //Scheduler input interface
    input wire valid_packet_i,
    input wire [AXI_ADDR_WIDTH-1:0] addr_packet_scheduler_i,
    input wire [PACKET_SIZE_WIDTH -1 : 0] length_packet_scheduler_i,
    output reg ack_from_tx_handler_o,
    
    //AXI Read Memory Interface
    output wire [AXI_ID_WIDTH-1:0] m_axi_arid_o, // Read address ID (optional)
    output reg  [AXI_ADDR_WIDTH-1:0] m_axi_araddr_o, // Read address (optional)
    output reg  [7:0] m_axi_arlen_o, // Burst length (optional)
    output wire [2:0] m_axi_arsize_o, // Burst size (optional)
    output wire [1:0] m_axi_arburst_o, // Burst type (optional)
    output wire [0:0] m_axi_arlock_o, // Lock type (optional)
    output wire [3:0] m_axi_arcache_o, // Cache type (optional)
    output wire [2:0] m_axi_arprot_o, // Protection type (optional)
    output wire [3:0] m_axi_arqos_o, // Quality of service token (optional)
    output reg  m_axi_arvalid_o, // Read address valid (optional)
    input wire m_axi_arready_i, // Read address ready (optional)
    
    input wire [AXI_ID_WIDTH-1:0] m_axi_rid_i, // Read ID tag (optional)
    input wire [DATA_WIDTH-1:0] m_axi_rdata_i, // Read data (optional)
    input wire [1:0] m_axi_rresp_i, // Read response (optional)
    input wire m_axi_rlast_i, // Read last beat (optional)
    input wire m_axi_rvalid_i, // Read valid (optional)
    output reg  m_axi_rready_o, // Read ready (optional)

    
    //AXIS output interface
    input wire                              m_axis_tready_i,
    output  wire                            m_axis_tvalid_o,
    output  wire [DATA_WIDTH-1:0]           m_axis_tdata_o,
    output  wire [DATA_WIDTH/8-1:0]         m_axis_tkeep_o,
    output  wire                            m_axis_tlast_o,
    
    //mem alloc unit interface
        
    output reg [AXI_ADDR_WIDTH-1:0] free_mem_addr_o,
    output reg free_mem_o,
    input  wire free_mem_ack_i
    
    
    );
   

    /**********************************************************
    **********************************************************/
    
    
    wire                    axis_tready_s;
    reg                     axis_tvalid_s;
    wire [DATA_WIDTH-1:0]   axis_tdata_s;
    wire [DATA_WIDTH/8-1:0] axis_tkeep_s;
    wire                    axis_tlast_s;
    
    axis_fifo #(
        .ADDR_WIDTH((DATA_WIDTH==512)?7:10), //10 = 8 kbyte
        .DATA_WIDTH(DATA_WIDTH),
        .PACKET_SIZE_WIDTH(PACKET_SIZE_WIDTH)
    ) tx_fifo (
        //input stream
        .s_axis_tready_o(axis_tready_s),
        .s_axis_tvalid_i(axis_tvalid_s),
        .s_axis_tdata_i(axis_tdata_s),
        .s_axis_tkeep_i(axis_tkeep_s),
        .s_axis_tlast_i(axis_tlast_s),
        //output stream
        .m_axis_tready_i(m_axis_tready_i),
        .m_axis_tdata_o(m_axis_tdata_o),
        .m_axis_tkeep_o(m_axis_tkeep_o),
        .m_axis_tlast_o(m_axis_tlast_o),
        .m_axis_tvalid_o(m_axis_tvalid_o),
        
        .m_packet_length_o(),  //unused
        
        .clk_i(clk_i),
        .resetn_i(~rst_i)
    
    
    );
  /************************************
    TX Handler
    ************************************/  
    reg [AXI_ADDR_WIDTH-1:0] addr_packet_s;
    reg [PACKET_SIZE_WIDTH -1 : 0] length_packet_s;
    /************************************
    TX Handler ar state machine
    ************************************/
    
    
  //TODO: make AXI fast!!!  
  reg [PACKET_SIZE_WIDTH -1 : 0] packet_length_mem [2**AXI_ID_WIDTH-1:0]; //each entry describes the length of the requested packet - 8
                                                                              //address = axi arid
  reg [2**AXI_ID_WIDTH-1:0] valid_ids;
  reg [AXI_ADDR_WIDTH-1:0] mem_addr_s [2**AXI_ID_WIDTH-1:0];
  
  reg [AXI_ID_WIDTH-1:0] next_axi_id_s;
  
  
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
    
    assign m_axi_arid_o = next_axi_id_s; // Read address ID (optional)
    
    reg [2:0]ar_state, next_ar_state;
    localparam state_ar_idle = 0;
    localparam state_ar_write_address = 1;
    localparam state_ar_wait = 2;
    
    reg save_packet_metadata_s;
    always @(*)begin
        next_ar_state = state_ar_idle;
        save_packet_metadata_s = 1'b0;
        
        m_axi_araddr_o = {AXI_ID_WIDTH{1'bx}};
        m_axi_arlen_o = {8{1'bx}};
        m_axi_arvalid_o = 1'b0;
        
        case(ar_state)
            state_ar_idle: begin
                if(valid_packet_i && valid_ids!= {2**AXI_ID_WIDTH{1'b1}}) begin
                    save_packet_metadata_s = 1'b1;
                    next_ar_state = state_ar_write_address;
                end
            end
            state_ar_write_address: begin
                next_ar_state = state_ar_write_address;
                
                m_axi_araddr_o = addr_packet_s;
                m_axi_arlen_o = (length_packet_s+ (DATA_WIDTH/8 - 1) )/(DATA_WIDTH/8) - 1; 
                m_axi_arvalid_o = 1'b1;
                
                if(m_axi_arready_i) begin
                    next_ar_state = state_ar_wait;
                end
            end
            state_ar_wait: begin
                //next_ar_state = state_ar_wait;
                m_axi_arvalid_o = 1'b0;
                next_ar_state = state_ar_idle;
            end
        endcase
    end
    
    
    integer i;
    always @(posedge clk_i) begin
        if(rst_i) begin
            ar_state <= state_ar_idle;
            valid_ids = 0;
        end else begin
            ar_state <= next_ar_state;
        end
        if(save_packet_metadata_s) begin
            next_axi_id_s <= next_unused_id_s;
            addr_packet_s <= addr_packet_scheduler_i;
            length_packet_s <= length_packet_scheduler_i;
            ack_from_tx_handler_o <= 1'b1;
            mem_addr_s[next_unused_id_s] <= addr_packet_scheduler_i;
            if(free_id_s) begin
                valid_ids <= (valid_ids | (1 << next_unused_id_s)) & ~(1 << m_axi_rid_i);
            end else begin
                valid_ids <= valid_ids | (1 << next_unused_id_s);
            end
            packet_length_mem [next_unused_id_s] <= length_packet_scheduler_i - (DATA_WIDTH/8); //TODO: for future use to address multiple packets in parallel
        end else begin
            ack_from_tx_handler_o <= 1'b0;
            if(free_id_s)
                valid_ids <= valid_ids & ~(1 << m_axi_rid_i); //TODO synthetisierbar machen
        end
    end

    assign m_axi_arsize_o = $clog2((DATA_WIDTH/8)-1); // The maximum number of bytes to transfer in each data transfer
    assign m_axi_arburst_o = 2'b01; // Burst type 
                                // 00 is FIXED
                                // 01 is INCR
                                // 10 is WRAP
    assign m_axi_arlock_o = 0; // Lock type (optional)
    assign m_axi_arcache_o = 4'b0010; // Cache type (optional)
    assign m_axi_arprot_o = 0; // Protection type - AXI provides access permissions signals that can be used to protect against illegal transactions
    assign m_axi_arqos_o = 0; // Quality of service token (optional)
    
      /************************************
      AXI W-Master Logic
      ************************************/  
    



  //  assign m_axi_rready_o = axis_tready_s; // Read ready (optional)
 //   assign axis_tvalid_s = m_axi_rvalid_i;
    assign axis_tdata_s = m_axi_rdata_i;
    reg [DATA_WIDTH/8-1:0]  r_counter_one_hot_s;
    assign axis_tkeep_s = (m_axi_rlast_i)? r_counter_one_hot_s  : {(DATA_WIDTH/8){1'b1}};
    assign axis_tlast_s = m_axi_rlast_i;
    
    reg  [PACKET_SIZE_WIDTH -1 : 0] r_counter_s, next_r_counter_s;
    reg take_counter_init_s;
    
    reg [AXI_ADDR_WIDTH-1:0] next_free_mem_addr_o;
    
    reg free_id_s;
    
    reg [1:0]r_state, next_r_state;
    localparam state_r_idle = 0;
    localparam state_r_receive = 1;
    localparam state_r_free_mem = 2;
  
    
    
    always @(*) begin
        next_r_state = state_r_idle;
        next_r_counter_s = {PACKET_SIZE_WIDTH{1'bx}};
        take_counter_init_s = 1'b0;
        free_mem_o = 1'b0;
        next_free_mem_addr_o = free_mem_addr_o;
        free_id_s = 1'b0;
        
        r_counter_one_hot_s = (r_counter_s==0)? 0 :({(DATA_WIDTH/8){1'b1}} >> ((DATA_WIDTH/8)-r_counter_s));
        
        m_axi_rready_o = axis_tready_s;
        axis_tvalid_s = m_axi_rvalid_i;
        
        case (r_state)
            state_r_idle: begin
                if(m_axi_rvalid_i && axis_tready_s) begin
                    next_r_state = state_r_receive;
                    take_counter_init_s = 1'b1;
                    next_free_mem_addr_o = mem_addr_s[m_axi_rid_i];
                    
                    // if packet is fits in 1 clockcycle
                    if(m_axi_rlast_i) begin
                         next_r_state = state_r_free_mem;
                         free_id_s = 1'b1;
                         r_counter_one_hot_s = ( {(DATA_WIDTH/8){1'b1}} ); //dirty workaround, smaller than 1 word (<64byte for 512bit axi) not possible, should not happen in ethernet
                     end
                    
                end
            end
            state_r_receive: begin
                next_r_counter_s = r_counter_s;
                next_r_state = state_r_receive;
                if(m_axi_rvalid_i && axis_tready_s) begin
                    next_r_counter_s = r_counter_s - (DATA_WIDTH/8);
                    if(m_axi_rlast_i) begin
                         next_r_state = state_r_free_mem;
                         free_mem_o = 1'b1;
                         free_id_s = 1'b1;
                     end
                end
 
            end
            state_r_free_mem: begin
                next_r_state = state_r_free_mem;
                free_mem_o = 1'b1;
                

                m_axi_rready_o = 0;
                axis_tvalid_s = 0;
                
                if(free_mem_ack_i) begin
                    next_r_state = state_r_idle;
                    
                    m_axi_rready_o = axis_tready_s;
                    axis_tvalid_s = m_axi_rvalid_i;
                    if(m_axi_rvalid_i) begin //fasttrack
                        next_r_state = state_r_receive;
                        next_free_mem_addr_o = mem_addr_s[m_axi_rid_i];
                        take_counter_init_s = 1'b1;
                    end
                end
            end
        endcase
    end
    
    always @(posedge clk_i) begin
        if(rst_i) begin
          r_state <= state_r_idle;
        end else begin
            r_state <= next_r_state;
        end
        if(take_counter_init_s) begin
            r_counter_s <= packet_length_mem [m_axi_rid_i];
        end else begin
            r_counter_s <= next_r_counter_s;
        end
        free_mem_addr_o <= next_free_mem_addr_o;
    end
    
    
endmodule
