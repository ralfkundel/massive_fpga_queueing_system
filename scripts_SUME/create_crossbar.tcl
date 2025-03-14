create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_0]

#connect clocks - currently one clock domain
connect_bd_net [get_bd_pins axi_interconnect_0/ACLK] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins axi_10g_ethernet_0/coreclk_out]

#connect resets
connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_interconnect_0/S01_ARESETN] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]

# connect NIC
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_clock_converter_0/S_AXI]

# connect NF
connect_bd_intf_net [get_bd_intf_pins NetworkFunctionTop_0/m0_axi_rx_handler] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins NetworkFunctionTop_0/m1_axi_tx_handler] -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI]

#assign whole address space
assign_bd_address [get_bd_addr_segs {mig_7series_0/memmap/memaddr }]


regenerate_bd_layout
save_bd_design
