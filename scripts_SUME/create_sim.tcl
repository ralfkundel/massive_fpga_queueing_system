create_bd_design -srcset sim_network_function_rxtx "sim_infrastructure"


create_bd_port -dir I -type clk clk_i
set_property CONFIG.FREQ_HZ 156250000 [get_bd_ports clk_i]

create_bd_cell -type module -reference NetworkFunctionTop NetworkFunctionTop_0
connect_bd_net [get_bd_ports clk_i] [get_bd_pins NetworkFunctionTop_0/clk_i]
make_bd_intf_pins_external  [get_bd_intf_pins NetworkFunctionTop_0/m_axis1]
set_property name m_axis1 [get_bd_intf_ports m_axis1_0]
make_bd_intf_pins_external  [get_bd_intf_pins NetworkFunctionTop_0/s_axis0]
set_property name s_axis0 [get_bd_intf_ports s_axis0_0]


#create reset core
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_port -dir I -type rst ext_rst
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_ports ext_rst]
connect_bd_net [get_bd_ports ext_rst] [get_bd_pins proc_sys_reset_0/ext_reset_in]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins NetworkFunctionTop_0/rst_i]
connect_bd_net [get_bd_ports clk_i] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

create_bd_port -dir O -type rst rst_o
connect_bd_net [get_bd_ports rst_o] [get_bd_pins proc_sys_reset_0/peripheral_reset]


# create sim crossbar
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.XBAR_DATA_WIDTH.VALUE_SRC USER] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.XBAR_DATA_WIDTH {256}] [get_bd_cells axi_interconnect_0]
#connect resets
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
#connect clocks
connect_bd_net [get_bd_ports clk_i] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_ports clk_i] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_ports clk_i] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_ports clk_i] [get_bd_pins axi_interconnect_0/S01_ACLK]
# connect network function
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins NetworkFunctionTop_0/m0_axi_rx_handler]
connect_bd_intf_net [get_bd_intf_pins NetworkFunctionTop_0/m1_axi_tx_handler] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI]
# create bram
create_bd_cell -type module -reference dc_bram_rw dc_bram_rw_0
set_property -dict [list CONFIG.FREQ_HZ {156250000}] [get_bd_intf_pins dc_bram_rw_0/AXI]
set_property -dict [list CONFIG.AXI_DATA_WIDTH {256}  CONFIG.FREQ_HZ {156250000} CONFIG.ADDR_WIDTH {32}] [get_bd_cells dc_bram_rw_0]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins dc_bram_rw_0/AXI]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins dc_bram_rw_0/rst_i]
connect_bd_net [get_bd_ports clk_i] [get_bd_pins dc_bram_rw_0/clk_i]


#assign whole address space
assign_bd_address [get_bd_addr_segs {M00_AXI_0/Reg }]
set_property offset 0x00000000 [get_bd_addr_segs {NetworkFunctionTop_0/m0_axi_rx_handler/SEG_dc_bram_rw_0_reg0}]
set_property range 4G [get_bd_addr_segs {NetworkFunctionTop_0/m0_axi_rx_handler/SEG_dc_bram_rw_0_reg0}]
set_property offset 0x00000000 [get_bd_addr_segs {NetworkFunctionTop_0/m1_axi_tx_handler/SEG_dc_bram_rw_0_reg0}]
set_property range 4G [get_bd_addr_segs {NetworkFunctionTop_0/m1_axi_tx_handler/SEG_dc_bram_rw_0_reg0}]


make_bd_intf_pins_external  [get_bd_intf_pins NetworkFunctionTop_0/s_wb]
set_property name s_wb [get_bd_intf_ports s_wb_0]

regenerate_bd_layout
save_bd_design
close_bd_design [get_bd_designs sim_infrastructure]
