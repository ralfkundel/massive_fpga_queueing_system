set mig [create_bd_cell -type ip -vlnv xilinx.com:ip:mig_7series:4.2 mig_7series_0]
set_property CONFIG.XML_INPUT_FILE [pwd]/src/ip_xml/nf_sume_ddr3A_bd.prj $mig

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 DDR3_SYS_CLK
connect_bd_intf_net [get_bd_intf_ports DDR3_SYS_CLK] [get_bd_intf_pins mig_7series_0/SYS_CLK]

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 FPGA_SYS_CLK
connect_bd_intf_net [get_bd_intf_ports FPGA_SYS_CLK] [get_bd_intf_pins mig_7series_0/CLK_REF]



create_bd_cell -type ip -vlnv xilinx.com:ip:axi_clock_converter:2.1 axi_clock_converter_0
set_property -dict [list CONFIG.DATA_WIDTH.VALUE_SRC USER CONFIG.ADDR_WIDTH.VALUE_SRC USER] [get_bd_cells axi_clock_converter_0]
set_property -dict [list CONFIG.DATA_WIDTH {256}] [get_bd_cells axi_clock_converter_0]


connect_bd_intf_net [get_bd_intf_pins mig_7series_0/S_AXI] [get_bd_intf_pins axi_clock_converter_0/M_AXI]
connect_bd_net [get_bd_pins mig_7series_0/ui_clk] [get_bd_pins axi_clock_converter_0/m_axi_aclk]

connect_bd_net [get_bd_ports reset_0] [get_bd_pins mig_7series_0/sys_rst]

#Reset the mig axi until it is not initialized
connect_bd_net [get_bd_pins mig_7series_0/init_calib_complete] [get_bd_pins mig_7series_0/aresetn]

#create a reset
connect_bd_net [get_bd_pins proc_sys_reset_0/aux_reset_in] [get_bd_pins mig_7series_0/init_calib_complete]
connect_bd_net [get_bd_ports reset_0] [get_bd_pins proc_sys_reset_0/ext_reset_in]

connect_bd_net [get_bd_pins axi_clock_converter_0/m_axi_aresetn] [get_bd_pins mig_7series_0/init_calib_complete]

connect_bd_net [get_bd_pins proc_sys_reset_0/interconnect_aresetn] [get_bd_pins axi_clock_converter_0/s_axi_aresetn]

connect_bd_net [get_bd_pins axi_clock_converter_0/s_axi_aclk] [get_bd_pins axi_10g_ethernet_0/coreclk_out]


create_bd_intf_port -mode Master -vlnv xilinx.com:interface:ddrx_rtl:1.0 DDR3
connect_bd_intf_net [get_bd_intf_ports DDR3] [get_bd_intf_pins mig_7series_0/DDR3]




regenerate_bd_layout
save_bd_design
