package main

import (
	"bytes"
	"context"
	"encoding/binary"
	"fmt"
	grpcIface "generic_pcie_driver/src/protobuf"
	"log"
	"os"
	"unsafe"

	"github.com/edsrzf/mmap-go"
)

type GenericPciApiServerImpl struct {
	grpcIface.UnimplementedGenericPciApiServer
	pcie_device string
	file        *os.File
	mmap        *mmap.MMap
}

func (me *GenericPciApiServerImpl) openDevice() {
	var err error
	me.file, err = os.OpenFile(me.pcie_device, os.O_RDWR, 0644)
	if err != nil {
		log.Fatalf("failed to open mmap device: %v", err)
	}
	tmp, _ := mmap.Map(me.file, mmap.RDWR, 0)
	me.mmap = &tmp
	fmt.Println("hello pci_api stub")
}

func (me *GenericPciApiServerImpl) Terminate() {
	me.file.Close()
	me.mmap.Unmap()
}

func (me *GenericPciApiServerImpl) Read32(ctx context.Context, add *grpcIface.Address) (*grpcIface.Value32, error) {
	if (add.Address % 4) != 0 {
		fmt.Println("address should be modulo 4")
		return nil, nil
	}
	result := grpcIface.Value32{}
	buf := bytes.NewBuffer((*me.mmap)[add.Address : add.Address+4])
	binary.Read(buf, binary.LittleEndian, &result.Value)
	return &result, nil
}
func (me *GenericPciApiServerImpl) Read64(ctx context.Context, add *grpcIface.Address) (*grpcIface.Value64, error) {
	if (add.Address % 8) != 0 {
		fmt.Println("address should be modulo 8 ")
		return nil, nil
	}
	result := grpcIface.Value64{}
	buf := bytes.NewBuffer((*me.mmap)[add.Address : add.Address+8])
	binary.Read(buf, binary.LittleEndian, &result.Value)
	return &result, nil
}
func (me *GenericPciApiServerImpl) Write32(ctx context.Context, addVal *grpcIface.AddressValue32) (*grpcIface.Response, error) {
	if (addVal.Address % 4) != 0 {
		fmt.Println("address should be modulo 4")
		return nil, nil
	}
	//fmt.Printf("Write on address %d the 4byte value %d \n", addVal.Address, addVal.Value)
	copy((*me.mmap)[addVal.Address:], (*[4]byte)(unsafe.Pointer(&addVal.Value))[:])
	resp := grpcIface.Response{Success: true}
	return &resp, nil
}
func (me *GenericPciApiServerImpl) Write64(ctx context.Context, addVal *grpcIface.AddressValue64) (*grpcIface.Response, error) {
	if (addVal.Address % 8) != 0 {
		fmt.Println("address should be modulo 8 ")
		return nil, nil
	}
	copy((*me.mmap)[addVal.Address:], (*[8]byte)(unsafe.Pointer(&addVal.Value))[:])
	resp := grpcIface.Response{Success: true}
	return &resp, nil
}

func NewGenericPciApiServer(pcie_device string) *GenericPciApiServerImpl {
	s := &GenericPciApiServerImpl{pcie_device: pcie_device}
	s.openDevice()
	return s
}
