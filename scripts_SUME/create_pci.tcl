create_bd_cell -type ip -vlnv xilinx.com:ip:axi_pcie3:3.0 axi_pcie3_0
set_property -dict [list CONFIG.mode_selection {Advanced} CONFIG.pcie_blk_locn {X0Y1} CONFIG.axisten_freq {62.5} CONFIG.en_axi_slave_if {false} CONFIG.dedicate_perst {true} CONFIG.pf0_bar0_size {1} CONFIG.pf0_bar0_scale {Megabytes} CONFIG.pf0_interrupt_pin {NONE} CONFIG.pf0_msi_enabled {false}] [get_bd_cells axi_pcie3_0]

create_bd_port -dir I pcie_sys_rst_i
connect_bd_net [get_bd_ports pcie_sys_rst_i] [get_bd_pins axi_pcie3_0/sys_rst_n]


create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2	 util_ds_buf_0
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE}] [get_bd_cells util_ds_buf_0]
connect_bd_net [get_bd_pins axi_pcie3_0/refclk] [get_bd_pins util_ds_buf_0/IBUF_OUT]
make_bd_intf_pins_external  [get_bd_intf_pins util_ds_buf_0/CLK_IN_D]
set_property name pcie_clk_i [get_bd_intf_ports CLK_IN_D_0]

make_bd_intf_pins_external  [get_bd_intf_pins axi_pcie3_0/pcie_7x_mgt]



create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0
connect_bd_intf_net [get_bd_intf_pins axi_pcie3_0/M_AXI] [get_bd_intf_pins axi_dwidth_converter_0/S_AXI]
set_property -dict [list CONFIG.MI_DATA_WIDTH.VALUE_SRC USER CONFIG.ADDR_WIDTH.VALUE_SRC USER CONFIG.SI_DATA_WIDTH.VALUE_SRC USER CONFIG.SI_ID_WIDTH.VALUE_SRC USER CONFIG.READ_WRITE_MODE.VALUE_SRC USER CONFIG.PROTOCOL.VALUE_SRC USER] [get_bd_cells axi_dwidth_converter_0]
set_property -dict [list CONFIG.SI_DATA_WIDTH {64} CONFIG.SI_ID_WIDTH {3} CONFIG.MAX_SPLIT_BEATS {16} CONFIG.MI_DATA_WIDTH {32}] [get_bd_cells axi_dwidth_converter_0]
connect_bd_net [get_bd_pins axi_dwidth_converter_0/s_axi_aclk] [get_bd_pins axi_pcie3_0/axi_aclk]
connect_bd_net [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn] [get_bd_pins axi_pcie3_0/axi_aresetn]


create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_1
set_property -dict [list CONFIG.ACLK_ASYNC.VALUE_SRC USER] [get_bd_cells axi_clock_converter_1]
connect_bd_net [get_bd_pins axi_clock_converter_1/s_axi_aclk] [get_bd_pins axi_pcie3_0/axi_aclk]
connect_bd_net [get_bd_pins axi_clock_converter_1/s_axi_aresetn] [get_bd_pins axi_pcie3_0/axi_aresetn]
connect_bd_net [get_bd_pins axi_clock_converter_1/m_axi_aresetn] [get_bd_pins proc_sys_reset_0/interconnect_aresetn]
connect_bd_net [get_bd_pins axi_clock_converter_1/m_axi_aclk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]


create_bd_cell -type module -reference axi_wb_bridge axi_wb_bridge_0
update_module_reference synth_infrastructure_axi_wb_bridge_0_0
connect_bd_intf_net [get_bd_intf_pins NetworkFunctionTop_0/s_wb] [get_bd_intf_pins axi_wb_bridge_0/m_wb]
connect_bd_intf_net [get_bd_intf_pins axi_clock_converter_1/M_AXI] [get_bd_intf_pins axi_wb_bridge_0/s_axi0]
connect_bd_net [get_bd_pins axi_wb_bridge_0/axi_clk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_wb_bridge_0/wb_clk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]
connect_bd_net [get_bd_pins axi_wb_bridge_0/rst] [get_bd_pins proc_sys_reset_0/peripheral_reset]
connect_bd_intf_net [get_bd_intf_pins axi_dwidth_converter_0/M_AXI] [get_bd_intf_pins axi_clock_converter_1/S_AXI]

group_bd_cells PCIe_WB_bridge [get_bd_cells util_ds_buf_0] [get_bd_cells axi_dwidth_converter_0] [get_bd_cells axi_clock_converter_1] [get_bd_cells axi_pcie3_0] [get_bd_cells axi_wb_bridge_0]
