close_project -quiet
set outputDir [pwd]/vivado_project_VCU1525
file mkdir $outputDir
create_project d-nets8-prototype $outputDir -part xcvu9p-fsgd2104-2L-e -force
set_property board_part xilinx.com:vcu1525:part0:1.4 [current_project]

source scripts_Ultra+/ultra+-generic.tcl
#TODO this is dirty for multi target
make_wrapper -files [get_files [pwd]/vivado_project_VCU1525/d-nets8-prototype.srcs/sources_1/bd/synth_infrastructure/synth_infrastructure.bd] -top
add_files -norecurse [pwd]/vivado_project_VCU1525/d-nets8-prototype.srcs/sources_1/bd/synth_infrastructure/hdl/synth_infrastructure_wrapper.v
set_property top synth_infrastructure_wrapper [current_fileset]
source scripts_Ultra+/generic_sim.tcl

#set_property STEPS.SYNTH_DESIGN.ARGS.MAX_URAM_CASCADE_HEIGHT 6 [get_runs synth_infrastructure_NetworkFunctionTop_0_0_synth_1]
