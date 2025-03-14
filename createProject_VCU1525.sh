#!/bin/bash
export LC_NUMERIC=en_US.utf8

if [ -z "$XILINXD_LICENSE_FILE" ]
then
    export XILINXD_LICENSE_FILE=2100@YOUR_LICENSE_SERVER
fi
if [ -z "$VIVADO_PATH" ]
then
    export VIVADO_PATH="/tools/Xilinx/Vivado/2024.2"
fi


################################################################
source tools/setup_python.sh

mkdir -p vivado_project_VCU1525/sim_inputs
mkdir vivado_project_VCU1525/sim_outputs

export PROJECT_HOME=$(pwd)

source $PYTHON_VIRTUALENV/bin/activate
python3 tools/pythonPacketGen/packet_generator.py pcap $(pwd)/vivado_project_VCU1525/sim_inputs/input.pcap
python3 tools/ControlPlanePython/config_test.py --sim $(pwd)/vivado_project_U200/sim_inputs/wb_m.txt
deactivate

source $VIVADO_PATH/settings64.sh
$VIVADO_PATH/bin/vivado -nolog -nojournal -source scripts_Ultra+/create-project_VCU1525.tcl
