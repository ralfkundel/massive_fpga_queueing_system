# FPGA (H)QoS Queueing System
This FPGA queueing system builds a basis for any kind of network packet queueing system which cannot be implemented with commodity switching ASICs and their build in schedulers. Consider this project as building blocks to enable your queueing challenges.

For further information:
* 2025: "Massive QoS-aware Packet Queueing and Traffic Shaping at the Access Edge using FPGAs" @ UEEE/IFIP NOMS 2025: [Paper](https://www.kom.tu-darmstadt.de/assets/bd94451c-4309-48da-8bd4-194f47be09bc/KWS___25.pdf)



## Usage
This code may be used as a standalone project. However, it can be used as extension for:
1. [P4SE](https://github.com/opencord/p4se)
2. [P4-UPF](https://github.com/ralfkundel/p4-upf)


## Build the project (Linux)
Prerequisites:
- Vivado 2024.2 + Board-Files installed (e.g. Alveo U200) on your computer
- Valid Xilinx Licenses for the used FPGA board and IP cores
Note: This code works for vivado 2019.1 or newer with minor modifications. For this, only some version numbers of IP-cores must be updated in the TCL scripts by hand.

1. Update the createProject shell script, e.g., createProject_U200.sh, to your license server and vivado installation directory:
```
export XILINXD_LICENSE_FILE=2100@PATH_TO_YOUR_LICENSE_SERVER
export VIVADO_PATH="/tools/Xilinx/Vivado/2024.2"
```

2. run the build script for your target (e.g. U200)
```
./createProject_U200.sh
```
This script will start vivado and setup the entire project. The entire procedure will may take several minutes.
Note: the script creates not only the vivado project. It also creates with python3 a pcap file which is used as simulation input.

You should see a simulation and synthesis environment in vivado. 

## Test the python PCIe driver
1. load the synthesized bitfile on the FPGA, e.g., with Xilinx hw-manager. In case of an error (server crashing), [see](#kernel-panik-as-a-result-of-loading-the-bitfile)
2. **restart** the sever, which is hosting the FPGA
2. find out the PCIe address of your card (after loading the FPGA design AND restarting):
```
lspci -d 10ee:
```
3. start the PythonPCIeDriver with this address (e.g. 0000:08:00.0):
```
cd tools/ControlPlanePython
sudo -E python3 config_test.py -hw /sys/bus/pci/devices/0000:08:00.0/resource0
```

### Kernel Panik as a result of loading the bitfile
It may happen, that the FPGA host server crashes while loading the bitfile. This is caused by the reconfiguration of an active PCIe device.
To avoid this, the following command can be used to prevent this:
```
sudo ./disable_err.sh 65:00.0
```

## Board Support
### Alveo U200
If not installed with Vivado, the board files can be downloaded from the [Xilinx Website](https://www.xilinx.com/bin/public/openDownload?filename=au200_board_files_20200616.zip) and added by hand to the vivado installation (e.g. under: /tools/Xilinx/Vivado/2024.2/data/xhub/boards/XilinxBoardStore/boards/Xilinx/). Note: the UltraScale+ FPGA must be part of the vivado installation before, this board file describes only the board not the FPGA!

### For VCU 1525
the default board drivers of vivado are not sufficient as they do not support the QSFP28 ports. Please install the following files manually to your local vivado installation:
<https://github.com/ralfkundel/XilinxBoardStore/tree/master/boards/Xilinx/vcu1525>
VCU1525 v1.4 is required

### NetFPGA Sume
No special drivers are required besides the Virtex7 support in Vivado.

# Acknowledgement
This work has been supported by Deutsche Telekom through the Dynamic Networks 8 project, by the LOEWE initiative (Hesse, Germany) within the emergenCITY center and the German Federal Ministry of Education and Research (BMBF) within the project “Open6GHub”.