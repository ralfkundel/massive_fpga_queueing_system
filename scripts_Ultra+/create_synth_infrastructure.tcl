
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0
set_property -dict [list CONFIG.CONST_VAL {0}] [get_bd_cells xlconstant_0]


create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_1
set_property -dict [list CONFIG.CONST_VAL {1}] [get_bd_cells xlconstant_1]


#Add NF
create_bd_cell -type module -reference NetworkFunctionTop NetworkFunctionTop_0
set_property -dict [list CONFIG.AXIS_WIDTH {512} CONFIG.AXI_WIDTH {512}] [get_bd_cells NetworkFunctionTop_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_NF
connect_bd_net [get_bd_pins proc_sys_reset_NF/bus_struct_reset] [get_bd_pins NetworkFunctionTop_0/rst_i]
connect_bd_net [get_bd_pins proc_sys_reset_NF/slowest_sync_clk] [get_bd_pins NetworkFunctionTop_0/clk_i]


#PCIe

create_bd_cell -type ip -vlnv xilinx.com:ip:xdma:4.1 xdma_0
set_property -dict [list CONFIG.functional_mode {AXI_Bridge} CONFIG.mode_selection {Advanced} CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} CONFIG.axi_addr_width {32} CONFIG.axisten_freq {125} CONFIG.en_axi_slave_if {false} CONFIG.en_axi_master_if {true} CONFIG.pf0_device_id {9021} CONFIG.pf0_interrupt_pin {NONE} CONFIG.pf0_msi_enabled {false} CONFIG.xdma_axilite_slave {true} CONFIG.SYS_RST_N_BOARD_INTERFACE {pcie_perstn} CONFIG.PCIE_BOARD_INTERFACE {pci_express_x1} CONFIG.en_gt_selection {true} CONFIG.plltype {QPLL1} CONFIG.pf0_link_status_slot_clock_config {true} CONFIG.pf0_bar0_size {64} CONFIG.pf0_bar0_scale {Megabytes} CONFIG.PF0_DEVICE_ID_mqdma {9021} CONFIG.PF2_DEVICE_ID_mqdma {9021} CONFIG.PF3_DEVICE_ID_mqdma {9021}] [get_bd_cells xdma_0]
set_property -dict [list CONFIG.pf0_base_class_menu {Memory_controller} CONFIG.pf0_class_code_base {05} CONFIG.pf0_sub_class_interface_menu {Other_memory_controller} CONFIG.pf0_class_code_sub {80} CONFIG.pf0_class_code_interface {00} CONFIG.pf0_class_code {058000}] [get_bd_cells xdma_0]
make_bd_intf_pins_external  [get_bd_intf_pins xdma_0/pcie_mgt]
make_bd_pins_external  [get_bd_pins xdma_0/sys_rst_n]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 buf_pcie
set_property -dict [list CONFIG.C_BUF_TYPE {IBUFDSGTE} CONFIG.DIFF_CLK_IN_BOARD_INTERFACE {pcie_refclk}] [get_bd_cells buf_pcie]
make_bd_intf_pins_external  [get_bd_intf_pins buf_pcie/CLK_IN_D]
connect_bd_net [get_bd_pins buf_pcie/IBUF_OUT] [get_bd_pins xdma_0/sys_clk_gt]
connect_bd_net [get_bd_pins buf_pcie/IBUF_DS_ODIV2] [get_bd_pins xdma_0/sys_clk]
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dwidth_converter:2.1 axi_dwidth_converter_0
connect_bd_intf_net [get_bd_intf_pins xdma_0/M_AXI_B] [get_bd_intf_pins axi_dwidth_converter_0/S_AXI]
connect_bd_net [get_bd_pins xdma_0/axi_aclk] [get_bd_pins axi_dwidth_converter_0/s_axi_aclk]
connect_bd_net [get_bd_pins xdma_0/axi_aresetn] [get_bd_pins axi_dwidth_converter_0/s_axi_aresetn]



create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0
connect_bd_intf_net [get_bd_intf_pins axi_dwidth_converter_0/M_AXI] [get_bd_intf_pins axi_clock_converter_0/S_AXI]
connect_bd_net [get_bd_pins axi_clock_converter_0/s_axi_aclk] [get_bd_pins xdma_0/axi_aclk]
connect_bd_net [get_bd_pins axi_clock_converter_0/s_axi_aresetn] [get_bd_pins xdma_0/axi_aresetn]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/clk_i] [get_bd_pins axi_clock_converter_0/m_axi_aclk]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/rstn_o] [get_bd_pins axi_clock_converter_0/m_axi_aresetn]

#axi-wb-bridge
create_bd_cell -type module -reference axi_wb_bridge axi_wb_bridge_0
connect_bd_intf_net [get_bd_intf_pins axi_wb_bridge_0/s_axi0] [get_bd_intf_pins axi_clock_converter_0/M_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_wb_bridge_0/m_wb] [get_bd_intf_pins NetworkFunctionTop_0/s_wb]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/clk_i] [get_bd_pins axi_wb_bridge_0/axi_clk]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/clk_i] [get_bd_pins axi_wb_bridge_0/wb_clk]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/rst_i] [get_bd_pins axi_wb_bridge_0/rst]

##make it hierarchical
create_bd_cell -type hier PCIe
move_bd_cells [get_bd_cells PCIe] [get_bd_cells buf_pcie]
move_bd_cells [get_bd_cells PCIe] [get_bd_cells xdma_0]
move_bd_cells [get_bd_cells PCIe] [get_bd_cells axi_dwidth_converter_0]
move_bd_cells [get_bd_cells PCIe] [get_bd_cells axi_clock_converter_0]
move_bd_cells [get_bd_cells PCIe] [get_bd_cells axi_wb_bridge_0]



#QSFP0
create_bd_cell -type ip -vlnv xilinx.com:ip:cmac_usplus:3.1 cmac_usplus_0
apply_board_connection -board_interface "qsfp0_4x" -ip_intf "cmac_usplus_0/gt_serial_port" -diagram "synth_infrastructure" 
set_property -dict [list CONFIG.USER_INTERFACE {AXIS} CONFIG.GT_DRP_CLK {156.25} CONFIG.TX_FLOW_CONTROL {0} CONFIG.RX_FLOW_CONTROL {0} CONFIG.ENABLE_AXI_INTERFACE {0} CONFIG.INCLUDE_STATISTICS_COUNTERS {0} CONFIG.GT_REF_CLK_FREQ {156.25} CONFIG.DIFFCLK_BOARD_INTERFACE {qsfp0_156mhz}] [get_bd_cells cmac_usplus_0]
make_bd_intf_pins_external  [get_bd_intf_pins cmac_usplus_0/gt_ref_clk]

connect_bd_net [get_bd_pins cmac_usplus_0/gt_ref_clk_out] [get_bd_pins cmac_usplus_0/init_clk]
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins cmac_usplus_0/drp_clk]
connect_bd_net [get_bd_pins cmac_usplus_0/gt_txusrclk2] [get_bd_pins cmac_usplus_0/rx_clk]
connect_bd_net [get_bd_pins xlconstant_1/dout] [get_bd_pins cmac_usplus_0/ctl_tx_enable]
connect_bd_net [get_bd_pins cmac_usplus_0/ctl_rx_enable] [get_bd_pins xlconstant_1/dout]

connect_bd_net [get_bd_pins cmac_usplus_0/usr_rx_reset] [get_bd_pins proc_sys_reset_NF/aux_reset_in]


##create global reset module
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 global_sys_reset
set_property -dict [list CONFIG.RESET_BOARD_INTERFACE {resetn} CONFIG.C_EXT_RESET_HIGH {0}] [get_bd_cells global_sys_reset]
make_bd_pins_external  [get_bd_pins global_sys_reset/ext_reset_in]
connect_bd_net [get_bd_pins cmac_usplus_0/gt_ref_clk_out] [get_bd_pins global_sys_reset/slowest_sync_clk]
connect_bd_net [get_bd_pins proc_sys_reset_NF/ext_reset_in] [get_bd_pins global_sys_reset/peripheral_reset]

##create mac0 clock domain reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 cmac0_rxtx_clk_rst
connect_bd_net [get_bd_pins cmac_usplus_0/gt_txusrclk2] [get_bd_pins cmac0_rxtx_clk_rst/slowest_sync_clk]
connect_bd_net [get_bd_pins cmac0_rxtx_clk_rst/ext_reset_in] [get_bd_pins global_sys_reset/peripheral_reset]
connect_bd_net [get_bd_pins cmac_usplus_0/usr_rx_reset] [get_bd_pins cmac0_rxtx_clk_rst/aux_reset_in]

##mac0 Rx register slice
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_0
connect_bd_intf_net [get_bd_intf_pins axis_register_slice_0/S_AXIS] [get_bd_intf_pins cmac_usplus_0/axis_rx]
connect_bd_net [get_bd_pins axis_register_slice_0/aclk] [get_bd_pins cmac_usplus_0/gt_txusrclk2]
connect_bd_net [get_bd_pins axis_register_slice_0/aresetn] [get_bd_pins cmac0_rxtx_clk_rst/interconnect_aresetn]

##mac0 RX clock converter
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter:1.1 axis_clock_converter_0
connect_bd_net [get_bd_pins axis_clock_converter_0/s_axis_aclk] [get_bd_pins cmac_usplus_0/gt_txusrclk2]
connect_bd_net [get_bd_pins axis_clock_converter_0/s_axis_aresetn] [get_bd_pins cmac0_rxtx_clk_rst/interconnect_aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_register_slice_0/M_AXIS] [get_bd_intf_pins axis_clock_converter_0/S_AXIS]
connect_bd_net [get_bd_pins axis_clock_converter_0/m_axis_aclk] [get_bd_pins NetworkFunctionTop_0/clk_i]
connect_bd_net [get_bd_pins axis_clock_converter_0/m_axis_aresetn] [get_bd_pins NetworkFunctionTop_0/rstn_o]
connect_bd_intf_net [get_bd_intf_pins axis_clock_converter_0/M_AXIS] [get_bd_intf_pins NetworkFunctionTop_0/s_axis0]


##mac0 TX fifo, clock converter
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_data_fifo:2.0 axis_data_fifo_0
set_property -dict [list CONFIG.FIFO_DEPTH {64} CONFIG.FIFO_MODE {2} CONFIG.IS_ACLK_ASYNC {1}] [get_bd_cells axis_data_fifo_0]
connect_bd_net [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins NetworkFunctionTop_0/clk_i]
connect_bd_net [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins NetworkFunctionTop_0/rstn_o]
connect_bd_net [get_bd_pins axis_data_fifo_0/m_axis_aclk] [get_bd_pins cmac_usplus_0/gt_txusrclk2]
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/S_AXIS] [get_bd_intf_pins NetworkFunctionTop_0/m_axis1]

##mac0 TX slice
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice:1.1 axis_register_slice_1
connect_bd_net [get_bd_pins axis_register_slice_1/aclk] [get_bd_pins cmac_usplus_0/gt_txusrclk2]
connect_bd_net [get_bd_pins cmac0_rxtx_clk_rst/interconnect_aresetn] [get_bd_pins axis_register_slice_1/aresetn]
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/M_AXIS] [get_bd_intf_pins axis_register_slice_1/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_register_slice_1/M_AXIS] [get_bd_intf_pins cmac_usplus_0/axis_tx]


#DDR4
create_bd_cell -type ip -vlnv xilinx.com:ip:ddr4:2.2 ddr4_0
set_property -dict [list CONFIG.C0_CLOCK_BOARD_INTERFACE {default_300mhz_clk0} CONFIG.C0_DDR4_BOARD_INTERFACE {ddr4_sdram_c0} CONFIG.C0.DDR4_TimePeriod {833} CONFIG.C0.DDR4_InputClockPeriod {3332} CONFIG.C0.DDR4_CLKOUT0_DIVIDE {5} CONFIG.C0.DDR4_MemoryType {RDIMMs} CONFIG.C0.DDR4_MemoryPart {MTA18ASF2G72PZ-2G3} CONFIG.C0.DDR4_DataWidth {72} CONFIG.C0.DDR4_DataMask {NONE} CONFIG.C0.DDR4_Ecc {true} CONFIG.C0.DDR4_CasLatency {17} CONFIG.C0.DDR4_CasWriteLatency {12} CONFIG.C0.DDR4_AxiDataWidth {512} CONFIG.C0.DDR4_AxiAddressWidth {34} CONFIG.ADDN_UI_CLKOUT1_FREQ_HZ {None} CONFIG.C0.CKE_WIDTH {1} CONFIG.C0.CS_WIDTH {1} CONFIG.C0.ODT_WIDTH {1}] [get_bd_cells ddr4_0]
make_bd_intf_pins_external  [get_bd_intf_pins ddr4_0/C0_SYS_CLK]
set_property -dict [list CONFIG.FREQ_HZ {300000000}] [get_bd_intf_ports C0_SYS_CLK_0]
make_bd_intf_pins_external  [get_bd_intf_pins ddr4_0/C0_DDR4]
connect_bd_net [get_bd_pins ddr4_0/c0_init_calib_complete] [get_bd_pins ddr4_0/c0_ddr4_aresetn]
connect_bd_net [get_bd_pins ddr4_0/sys_rst] [get_bd_pins global_sys_reset/peripheral_reset]
##disable ctrl interface
connect_bd_net [get_bd_pins xlconstant_0/dout] [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_arvalid]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_bready] [get_bd_pins xlconstant_0/dout]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_rready] [get_bd_pins xlconstant_0/dout]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_wvalid] [get_bd_pins xlconstant_0/dout]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_s_axi_ctrl_awvalid] [get_bd_pins xlconstant_0/dout]


#logic core clock generator
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins NetworkFunctionTop_0/clk_i]
set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} CONFIG.USE_LOCKED {false} CONFIG.USE_RESET {false} CONFIG.MMCM_CLKOUT0_DIVIDE_F {6.000} CONFIG.CLKOUT1_JITTER {102.086}] [get_bd_cells clk_wiz_0]

#Memory Crossbar
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
set_property -dict [list CONFIG.M00_HAS_REGSLICE {4} CONFIG.S00_HAS_DATA_FIFO {2} CONFIG.S01_HAS_DATA_FIFO {2}] [get_bd_cells axi_interconnect_0]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins ddr4_0/C0_DDR4_S_AXI]
connect_bd_net [get_bd_pins axi_interconnect_0/M00_ACLK] [get_bd_pins ddr4_0/c0_ddr4_ui_clk]
connect_bd_net [get_bd_pins ddr4_0/c0_ddr4_ui_clk] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins ddr4_0/c0_init_calib_complete] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins ddr4_0/c0_init_calib_complete] [get_bd_pins axi_interconnect_0/ARESETN]

##connect NF to crossbar
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins NetworkFunctionTop_0/m0_axi_rx_handler]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S01_AXI] [get_bd_intf_pins NetworkFunctionTop_0/m1_axi_tx_handler]
connect_bd_net [get_bd_pins axi_interconnect_0/S00_ACLK] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins axi_interconnect_0/S01_ACLK] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/rstn_o] [get_bd_pins axi_interconnect_0/S01_ARESETN]
connect_bd_net [get_bd_pins NetworkFunctionTop_0/rstn_o] [get_bd_pins axi_interconnect_0/S00_ARESETN]


assign_bd_address

regenerate_bd_layout
save_bd_design
#close_bd_design [get_bd_designs synth_infrastructure]
