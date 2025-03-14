close_project -quiet
set outputDir [pwd]/vivado_project_U200
file mkdir $outputDir
create_project d-nets8-prototype $outputDir -part xcu200-fsgd2104-2-e -force
set_property board_part xilinx.com:au200:part0:1.3 [current_project]


source scripts_Ultra+/ultra+-generic.tcl
#TODO this is dirty for multi target
make_wrapper -files [get_files [pwd]/vivado_project_U200/d-nets8-prototype.srcs/sources_1/bd/synth_infrastructure/synth_infrastructure.bd] -top
add_files -norecurse [pwd]/vivado_project_U200/d-nets8-prototype.srcs/sources_1/bd/synth_infrastructure/hdl/synth_infrastructure_wrapper.v
set_property top synth_infrastructure_wrapper [current_fileset]

source scripts_Ultra+/generic_sim.tcl

#set_property STEPS.SYNTH_DESIGN.ARGS.MAX_URAM_CASCADE_HEIGHT 6 [get_runs synth_infrastructure_NetworkFunctionTop_0_0_synth_1]
