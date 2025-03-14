
# create testbench(es)


create_fileset -simset sim_rxtx
add_files -fileset sim_rxtx [pwd]/src/sim/pcap_utils/PcapRxAxiStream.sv
add_files -fileset sim_rxtx [pwd]/src/sim/pcap_utils/PcapTxAxiStream.sv
add_files -fileset sim_rxtx [pwd]/src/sim/benches/pcap_axi_rxtx_tb_100G.v
add_files -fileset sim_rxtx [pwd]/src/sim/dcbram/dc_bram_rw.v
set_property top rxtx_tb [get_filesets sim_rxtx]
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_rxtx]
add_files -fileset sim_rxtx -norecurse [pwd]/src/sim/pcap_rxtx_tb_behav.wcfg
set_property xsim.view [pwd]/src/sim/pcap_rxtx_tb_behav.wcfg [get_filesets sim_rxtx]

create_fileset -simset sim_network_function_rxtx
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/pcap_utils/PcapRxAxiStream.sv
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/pcap_utils/PcapTxAxiStream.sv
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/benches/pcap_system_tb_100G.v
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/dcbram/dc_bram_rw.v
add_files -fileset sim_network_function_rxtx [pwd]/src/sim/wishbone/wb_master_sim.v
set_property -name {xsim.simulate.runtime} -value {4000ns} -objects [get_filesets sim_network_function_rxtx]
source scripts_Ultra+/create_sim.tcl
set_property top pcap_system_tb [get_filesets sim_network_function_rxtx]
set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_network_function_rxtx]
add_files -fileset sim_network_function_rxtx -norecurse [pwd]/src/sim/pcap_system_tb_behav_100G.wcfg
set_property xsim.view [pwd]/src/sim/pcap_system_tb_behav.wcfg [get_filesets sim_network_function_rxtx]

# default sim fileset
current_fileset -simset [ get_filesets sim_network_function_rxtx ]
#delete automatic generated sim_1 fileset
delete_fileset sim_1
