
#axi_10g_ethernet_n
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.1 axi_10g_ethernet_0
set_property -dict [list CONFIG.Management_Interface {false} CONFIG.base_kr {BASE-R} CONFIG.DClkRate {156.25} CONFIG.SupportLevel {1} CONFIG.autonegotiation {0} CONFIG.fec {0} CONFIG.Statistics_Gathering {0}] [get_bd_cells axi_10g_ethernet_0]
#TODO reset evtl über mig  machen
make_bd_pins_external  [get_bd_pins axi_10g_ethernet_0/reset]

create_bd_port -dir I singal_detect_0
connect_bd_net [get_bd_ports singal_detect_0] [get_bd_pins axi_10g_ethernet_0/signal_detect]

create_bd_port -dir O txp0
create_bd_port -dir O txn0
create_bd_port -dir I rxp0
create_bd_port -dir I rxn0
connect_bd_net [get_bd_ports txp0] [get_bd_pins axi_10g_ethernet_0/txp]
connect_bd_net [get_bd_ports txn0] [get_bd_pins axi_10g_ethernet_0/txn]
connect_bd_net [get_bd_ports rxp0] [get_bd_pins axi_10g_ethernet_0/rxp]
connect_bd_net [get_bd_ports rxn0] [get_bd_pins axi_10g_ethernet_0/rxn]

create_bd_port -dir O tx_disable_0_o
create_bd_port -dir I tx_fault_0_i
connect_bd_net [get_bd_ports tx_fault_0_i] [get_bd_pins axi_10g_ethernet_0/tx_fault]
connect_bd_net [get_bd_ports tx_disable_0_o] [get_bd_pins axi_10g_ethernet_0/tx_disable]

#axi_10g_ethernet_n
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_10g_ethernet:3.1 axi_10g_ethernet_n
set_property -dict [list CONFIG.Management_Interface {false} CONFIG.base_kr {BASE-R} CONFIG.DClkRate {156.25} CONFIG.autonegotiation {0} CONFIG.fec {0} CONFIG.Statistics_Gathering {0}] [get_bd_cells axi_10g_ethernet_n]
create_bd_port -dir I singal_detect_1
connect_bd_net [get_bd_ports singal_detect_1] [get_bd_pins axi_10g_ethernet_n/signal_detect]
create_bd_port -dir O txp1
create_bd_port -dir O txn1
create_bd_port -dir I rxp1
create_bd_port -dir I rxn1
connect_bd_net [get_bd_ports txp1] [get_bd_pins axi_10g_ethernet_n/txp]
connect_bd_net [get_bd_ports txn1] [get_bd_pins axi_10g_ethernet_n/txn]
connect_bd_net [get_bd_ports rxp1] [get_bd_pins axi_10g_ethernet_n/rxp]
connect_bd_net [get_bd_ports rxn1] [get_bd_pins axi_10g_ethernet_n/rxn]

create_bd_port -dir O tx_disable_1_o
create_bd_port -dir I tx_fault_1_i
connect_bd_net [get_bd_ports tx_fault_1_i] [get_bd_pins axi_10g_ethernet_n/tx_fault]
connect_bd_net [get_bd_ports tx_disable_1_o] [get_bd_pins axi_10g_ethernet_n/tx_disable]

create_bd_port -dir I ref_clk_p
create_bd_port -dir I ref_clk_n
connect_bd_net [get_bd_ports ref_clk_n] [get_bd_pins axi_10g_ethernet_0/refclk_n]
connect_bd_net [get_bd_ports ref_clk_p] [get_bd_pins axi_10g_ethernet_0/refclk_p]

create_bd_port -dir O -type clk clk_156_o
connect_bd_net [get_bd_ports clk_156_o] [get_bd_pins axi_10g_ethernet_0/coreclk_out]

connect_bd_net [get_bd_pins axi_10g_ethernet_0/txusrclk_out] [get_bd_pins axi_10g_ethernet_n/txusrclk]
connect_bd_net [get_bd_pins axi_10g_ethernet_0/txusrclk2_out] [get_bd_pins axi_10g_ethernet_n/txusrclk2]

connect_bd_net [get_bd_pins axi_10g_ethernet_0/dclk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_10g_ethernet_0/coreclk_out] [get_bd_pins axi_10g_ethernet_n/coreclk]
connect_bd_net [get_bd_pins axi_10g_ethernet_n/dclk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]

connect_bd_net [get_bd_pins axi_10g_ethernet_n/areset_coreclk] [get_bd_pins axi_10g_ethernet_0/areset_datapathclk_out]

connect_bd_net [get_bd_pins axi_10g_ethernet_0/qplloutrefclk_out] [get_bd_pins axi_10g_ethernet_n/qplloutrefclk]
connect_bd_net [get_bd_pins axi_10g_ethernet_0/qplloutclk_out] [get_bd_pins axi_10g_ethernet_n/qplloutclk]
connect_bd_net [get_bd_pins axi_10g_ethernet_0/qplllock_out] [get_bd_pins axi_10g_ethernet_n/qplllock]

connect_bd_net [get_bd_pins axi_10g_ethernet_0/gttxreset_out] [get_bd_pins axi_10g_ethernet_n/gttxreset]
connect_bd_net [get_bd_pins axi_10g_ethernet_n/gtrxreset] [get_bd_pins axi_10g_ethernet_0/gtrxreset_out]

connect_bd_net [get_bd_pins axi_10g_ethernet_0/txuserrdy_out] [get_bd_pins axi_10g_ethernet_n/txuserrdy]

connect_bd_net [get_bd_pins axi_10g_ethernet_0/reset_counter_done_out] [get_bd_pins axi_10g_ethernet_n/reset_counter_done]

#create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 sim_speedup
#set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells sim_speedup]

#config vectors
create_bd_port -dir I -from 79 -to 0 tx_config
connect_bd_net [get_bd_ports tx_config] [get_bd_pins axi_10g_ethernet_0/mac_tx_configuration_vector]
connect_bd_net [get_bd_ports tx_config] [get_bd_pins axi_10g_ethernet_n/mac_tx_configuration_vector]
create_bd_port -dir I -from 79 -to 0 rx_config
connect_bd_net [get_bd_ports rx_config] [get_bd_pins axi_10g_ethernet_0/mac_rx_configuration_vector]
connect_bd_net [get_bd_ports rx_config] [get_bd_pins axi_10g_ethernet_n/mac_rx_configuration_vector]
create_bd_port -dir I -from 535 -to 0 pcs_pma_config
connect_bd_net [get_bd_ports pcs_pma_config] [get_bd_pins axi_10g_ethernet_n/pcs_pma_configuration_vector]
connect_bd_net [get_bd_ports pcs_pma_config] [get_bd_pins axi_10g_ethernet_0/pcs_pma_configuration_vector]

#axis reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
#aktivate aux
set_property -dict [list CONFIG.C_AUX_RESET_HIGH.VALUE_SRC USER] [get_bd_cells proc_sys_reset_0]
set_property -dict [list CONFIG.C_AUX_RESET_HIGH {0}] [get_bd_cells proc_sys_reset_0]
set_property -dict [list CONFIG.C_AUX_RST_WIDTH {2}] [get_bd_cells proc_sys_reset_0]
#connect reset
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_10g_ethernet_n/rx_axis_aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_10g_ethernet_n/tx_axis_aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_10g_ethernet_0/rx_axis_aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_10g_ethernet_0/tx_axis_aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins proc_sys_reset_0/bus_struct_reset] [get_bd_pins axi_10g_ethernet_n/areset]

create_bd_port -dir O rst_o
connect_bd_net [get_bd_ports rst_o] [get_bd_pins proc_sys_reset_0/peripheral_reset]

#unknown constant tx_ifg_delay
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_WIDTH {8} CONFIG.CONST_VAL {8}] [get_bd_cells xlconstant_0]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins axi_10g_ethernet_0/tx_ifg_delay]
connect_bd_net [get_bd_pins axi_10g_ethernet_n/tx_ifg_delay] [get_bd_pins xlconstant_0/dout]


#Instanciate Network Function
create_bd_cell -type module -reference NetworkFunctionTop NetworkFunctionTop_0
set_property -dict [list CONFIG.AXI_ID_WIDTH {1} CONFIG.NUMBER_QUEUES {160000} CONFIG.NUMBER_BUCKETS {32768}] [get_bd_cells NetworkFunctionTop_0]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/clk_i] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
#TODO how to reset better
connect_bd_net [get_bd_pins NetworkFunctionTop_0/rst_i] [get_bd_pins proc_sys_reset_0/peripheral_reset]
connect_bd_intf_net [get_bd_intf_pins NetworkFunctionTop_0/s_axis0] [get_bd_intf_pins axi_10g_ethernet_n/m_axis_rx]
connect_bd_intf_net [get_bd_intf_pins NetworkFunctionTop_0/m_axis1] [get_bd_intf_pins axi_10g_ethernet_0/s_axis_tx]

#demo fifo
#create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:1.1 axis_data_fifo_0
#set_property -dict [list CONFIG.TUSER_WIDTH.VALUE_SRC USER] [get_bd_cells axis_data_fifo_0]
#set_property -dict [list CONFIG.TUSER_WIDTH {0}] [get_bd_cells axis_data_fifo_0]
#set_property -dict [list CONFIG.FIFO_MODE {2}] [get_bd_cells axis_data_fifo_0]
#connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axis_data_fifo_0/s_axis_aresetn]
#connect_bd_net [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
#connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
#connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins axi_10g_ethernet_0/m_axis_rx]
#connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axi_10g_ethernet_n/s_axis_tx]



regenerate_bd_layout
save_bd_design
#close_bd_design [get_bd_designs synth_infrastructure]
