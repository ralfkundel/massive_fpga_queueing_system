close_project -quiet
set outputDir [pwd]/vivado_project_SUME
file mkdir $outputDir
create_project netfpga-queueing $outputDir -part XC7VX690T-FFG1761-3 -force
#TODO: optional
#set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]


set_property  ip_repo_paths  [pwd]/src/ip [current_project]
update_ip_catalog

# constraints
read_xdc [pwd]/src/hdl/constrs/cstrs_SUME.xdc
set_property target_constrs_file [pwd]/src/hdl/constrs/cstrs_SUME.xdc [current_fileset -constrset]


# verilog files
read_verilog [pwd]/src/hdl/Synth_TopModule_SUME.v
read_verilog [pwd]/src/hdl/NetworkFunction_top.v
read_verilog [pwd]/src/hdl/blink_driver.v
read_verilog [pwd]/src/hdl/led_driver.v
read_verilog [pwd]/src/hdl/pcs_pma_conf.v
read_verilog [pwd]/src/hdl/dualport_bram.v
read_verilog [pwd]/src/hdl/dualport_ram_bw.v
read_verilog [pwd]/src/hdl/virt_dualport_ram_bw.v
read_verilog [pwd]/src/hdl/axi_wb_bridge.v
read_verilog [pwd]/src/hdl/simple_queue.v
read_verilog [pwd]/src/hdl/queueIdCutter.v
read_verilog [pwd]/src/hdl/wb_interconnect.v


read_verilog [pwd]/src/hdl/axis_fifo/axis_fifo.v
read_verilog [pwd]/src/hdl/RxTxHandler/AxisToAxi_rx_handler.v
read_verilog [pwd]/src/hdl/RxTxHandler/AxiToAxis_tx_handler.v
read_verilog [pwd]/src/hdl/RxTxHandler/simple_mem_alloc_unit.v
read_verilog [pwd]/src/hdl/RxTxHandler/job_arbiter.v
read_verilog [pwd]/src/hdl/RxTxHandler/NoScheduler.v
read_verilog [pwd]/src/hdl/RxTxHandler/SimpleScheduler.v
read_verilog [pwd]/src/hdl/RxTxHandler/rate_limiter.v
read_verilog [pwd]/src/hdl/RxTxHandler/HierarchicalScheduler.v
read_verilog [pwd]/src/hdl/RxTxHandler/packet_counter.v

read_verilog [pwd]/src/hdl/queue_memory/queue_memory.v
read_verilog [pwd]/src/hdl/queue_memory/descriptor_mem_manager.v
read_verilog [pwd]/src/hdl/queue_memory/queue_length_mem.v


read_verilog [pwd]/src/sim/dcbram/dc_bram_rw.v

#Create MIG and clock conversion
create_bd_design "synth_infrastructure"
source scripts_SUME/create_synth_infrastructure.tcl
source scripts_SUME/create_memory.tcl
source scripts_SUME/create_crossbar.tcl
source scripts_SUME/create_pci.tcl
validate_bd_design
save_bd_design
close_bd_design [get_bd_designs synth_infrastructure]

set_property top TopLevelModule [current_fileset]

# create testbench(es)


create_fileset -simset sim_rxtx
add_files -fileset sim_rxtx [pwd]/src/sim/pcap_utils/PcapRxAxiStream.sv
add_files -fileset sim_rxtx [pwd]/src/sim/pcap_utils/PcapTxAxiStream.sv
add_files -fileset sim_rxtx [pwd]/src/sim/benches/pcap_axi_rxtx_tb.v
add_files -fileset sim_rxtx [pwd]/src/sim/dcbram/dc_bram_rw.v
set_property top rxtx_tb [get_filesets sim_rxtx]
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_rxtx]
add_files -fileset sim_rxtx -norecurse [pwd]/src/sim/pcap_rxtx_tb_behav.wcfg
set_property xsim.view [pwd]/src/sim/pcap_rxtx_tb_behav.wcfg [get_filesets sim_rxtx]

create_fileset -simset sim_network_function_rxtx
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/pcap_utils/PcapRxAxiStream.sv
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/pcap_utils/PcapTxAxiStream.sv
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/benches/pcap_system_tb.v
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/dcbram/dc_bram_rw.v
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/wishbone/wb_master_sim.v
set_property -name {xsim.simulate.runtime} -value {4000ns} -objects [get_filesets sim_network_function_rxtx]
source scripts_SUME/create_sim.tcl
set_property top pcap_system_tb [get_filesets sim_network_function_rxtx]
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_network_function_rxtx]
add_files -fileset sim_network_function_rxtx -norecurse [pwd]/src/sim/pcap_system_tb_behav.wcfg
set_property xsim.view [pwd]/src/sim/pcap_system_tb_behav.wcfg [get_filesets sim_network_function_rxtx]

# default sim fileset
current_fileset -simset [ get_filesets sim_network_function_rxtx ]
#delete automatic generated sim_1 fileset
delete_fileset sim_1


set_msg_config -id {Timing 38-282} -new_severity {ERROR}

