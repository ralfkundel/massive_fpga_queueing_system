#TODO: optional
#set_property strategy Performance_ExtraTimingOpt [get_runs impl_1]

#contains wishbone spec
set_property  ip_repo_paths  [pwd]/src/ip [current_project]
update_ip_catalog

# constraints

# verilog files
read_verilog [pwd]/src/hdl/NetworkFunction_top.v
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
source scripts_Ultra+/create_synth_infrastructure.tcl
#source scripts_Ultra+/create_memory.tcl
#source scripts_Ultra+/create_crossbar.tcl
#source scripts_Ultra+/create_pci.tcl
regenerate_bd_layout
validate_bd_design
save_bd_design
close_bd_design [get_bd_designs synth_infrastructure]


