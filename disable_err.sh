#!/bin/bash
#author: Kadir Eryigit
# this script is used to prevent unwanted system reboot during FPGA programming
# it disables error handling of the upstream port of the FPGA so the system does not reboot
# call this script with the BDF of the fpga
# lspci | grep Xilinx
# 	65:00.0 Serial controller: Xilinx Corporation Device 9024
# gives you the BDF of the fpga
# if there is no result this script is probably not needed
# example: ./disable_err.sh 65:00.0

dev=$1

if [ -z "$dev" ]; then
    echo "Error: no device specified"
    exit 1
fi

if [ ! -e "/sys/bus/pci/devices/$dev" ]; then
    dev="0000:$dev"
fi

if [ ! -e "/sys/bus/pci/devices/$dev" ]; then
    echo "Error: device $dev not found"
    exit 1
fi

port=$(basename $(dirname $(readlink "/sys/bus/pci/devices/$dev")))  #fetches the upstream port of the fpga

if [ ! -e "/sys/bus/pci/devices/$port" ]; then
    echo "Error: device $port not found"
    exit 1
fi

echo "Disabling fatal error reporting on port $port..."

cmd=$(setpci -s $port COMMAND)

echo "Command:" $cmd

# clear SERR bit in command register
setpci -s $port COMMAND=$(printf "%04x" $((0x$cmd & ~0x0100)))

ctrl=$(setpci -s $port CAP_EXP+8.w)
 
echo "Device control:" $ctrl

# clear fatal error reporting enable bit in device control register
setpci -s $port CAP_EXP+8.w=$(printf "%04x" $((0x$ctrl & ~0x0004)))
