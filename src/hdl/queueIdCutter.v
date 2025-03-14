module queueIdCutter #(
    parameter AXIS_DATA_WIDTH = 64,
    parameter QUEUE_ID_WIDTH = 32,
    parameter PACKET_SIZE_WIDTH = 11
)(

    //AXIS input interface
    output reg                    s_axis_tready_o,
    input  wire                   s_axis_tvalid_i,
    input  wire [AXIS_DATA_WIDTH-1:0]  s_axis_tdata_i,
    input  wire [AXIS_DATA_WIDTH/8-1:0]  s_axis_tkeep_i,
    input  wire                   s_axis_tlast_i,
    input wire [PACKET_SIZE_WIDTH-1:0]  s_axis_packet_length_i,
    
    input wire                    m_axis_tready_i,
    output  reg                   m_axis_tvalid_o,
    output  wire [AXIS_DATA_WIDTH-1:0]  m_axis_tdata_o,
    output  reg [AXIS_DATA_WIDTH/8-1:0]  m_axis_tkeep_o,
    output  reg                   m_axis_tlast_o,
    output reg [PACKET_SIZE_WIDTH-1:0]  m_axis_packet_length_o,
    output reg [QUEUE_ID_WIDTH-1:0] m_queue_id_o,
    
    input wire clk_i,
    input wire rst_i
    
    );
    
    wire [QUEUE_ID_WIDTH-1:0] data_part_one_s = s_axis_tdata_i[QUEUE_ID_WIDTH-1:0];                         //contains the queue id in the first clock cycle
    wire [AXIS_DATA_WIDTH-QUEUE_ID_WIDTH-1:0] data_part_two_s = s_axis_tdata_i[AXIS_DATA_WIDTH-1:QUEUE_ID_WIDTH];
 
 
    wire [QUEUE_ID_WIDTH-1:0] data_part_one_inv_s;
    reg  [AXIS_DATA_WIDTH-QUEUE_ID_WIDTH-1:0] data_part_two_reg_s;
 
    wire [AXIS_DATA_WIDTH-1:0]      data_both_s = {data_part_one_s, data_part_two_reg_s};
    assign m_axis_tdata_o = data_both_s;
    
    wire[QUEUE_ID_WIDTH/8-1:0] data_part_one_keep_s = s_axis_tkeep_i [QUEUE_ID_WIDTH/8-1:0];
    wire [(AXIS_DATA_WIDTH-QUEUE_ID_WIDTH)/8-1:0] data_part_two_keep_s = s_axis_tkeep_i[AXIS_DATA_WIDTH/8-1:QUEUE_ID_WIDTH/8];
    reg [(AXIS_DATA_WIDTH-QUEUE_ID_WIDTH)/8-1:0] data_part_two_keep_reg_s; //[AXIS_DATA_WIDTH/8-1:QUEUE_ID_WIDTH/8];

    genvar i;
    generate        //Convert the queue id: big to little endian
        for(i = 0; i < QUEUE_ID_WIDTH; i=i+8) begin
            assign data_part_one_inv_s[i+7:i] = data_part_one_s[QUEUE_ID_WIDTH-1-i:QUEUE_ID_WIDTH-1-(i+7)];
        end
    endgenerate

    
    reg [2:0] state, next_state;
    localparam state_idle = 0;
    localparam state_receive = 1;
    localparam state_send_last = 2;
    
    reg store_id_s, store_part_two_s;
    
    always @(*) begin
        next_state = state_idle;
        store_id_s = 1'b0;
        store_part_two_s = 1'b0;
        m_axis_tvalid_o = 1'b0;
        m_axis_tkeep_o = {data_part_one_keep_s, data_part_two_keep_reg_s};
        m_axis_tlast_o = 1'b0;
        
        
        if(s_axis_tlast_i && data_part_two_keep_s == {((AXIS_DATA_WIDTH-QUEUE_ID_WIDTH)/8){1'b0}}) begin
            m_axis_tlast_o = 1'b1;
        end
        
         s_axis_tready_o = m_axis_tready_i;
        
        case (state)
            state_idle:begin
                s_axis_tready_o = 1'b1;
                if(s_axis_tvalid_i) begin
                    next_state = state_receive;
                    store_id_s = 1'b1;
                    store_part_two_s = 1'b1;
                    
                    if(s_axis_tlast_i) begin
                        if(data_part_two_keep_s == {((AXIS_DATA_WIDTH-QUEUE_ID_WIDTH)/8){1'b0}}) begin
                            next_state = state_idle;
                            //TODO kann jetzt schon das nächste paket kommen?
                        end else begin
                            next_state = state_send_last;
                        end                  
                    end            
                end
            end
            
            state_receive: begin
                next_state = state_receive;
                m_axis_tvalid_o = 1'b1; 
                if(m_axis_tready_i) begin
                    store_part_two_s = 1'b1;
                    //...
                    if(s_axis_tlast_i) begin
                        if(data_part_two_keep_s == {((AXIS_DATA_WIDTH-QUEUE_ID_WIDTH)/8){1'b0}}) begin
                            next_state = state_idle;
                        end else begin
                            next_state = state_send_last;
                        end
                        
                    end
                end
            end
                   
            state_send_last: begin
                m_axis_tvalid_o = 1'b1;
                m_axis_tlast_o = 1'b1;
                m_axis_tkeep_o = data_part_two_keep_reg_s;
                next_state = state_send_last;
                
                if(m_axis_tready_i) begin
                    if(s_axis_tvalid_i) begin
                        next_state = state_receive;
                        store_id_s = 1'b1;
                        store_part_two_s = 1'b1;
                        
                        
                        if(s_axis_tlast_i) begin
                            if(data_part_two_keep_s == {((AXIS_DATA_WIDTH-QUEUE_ID_WIDTH)/8){1'b0}}) begin
                                next_state = state_idle;
                            end else begin
                                next_state = state_send_last;
                            end                  
                        end  
                        
                        
                        
                    end else begin
                        next_state = state_idle;
                    end
                    
                    
                end
            end
        endcase
    end
    
    always @(posedge clk_i) begin
        state <= next_state;
        if(store_id_s) begin
            m_queue_id_o  <= data_part_one_inv_s;
            m_axis_packet_length_o <= s_axis_packet_length_i - (QUEUE_ID_WIDTH/8);
        end
        if (store_part_two_s) begin
            data_part_two_reg_s <= data_part_two_s;
            data_part_two_keep_reg_s <= s_axis_tkeep_i[AXIS_DATA_WIDTH/8-1:QUEUE_ID_WIDTH/8];
        end
    end
        
    
endmodule
