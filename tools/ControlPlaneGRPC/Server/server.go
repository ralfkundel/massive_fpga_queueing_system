package main
//inspired by: https://github.com/grpc/grpc-go/blob/master/examples/route_guide/server/server.go

import (
	"flag"
	"fmt"
	"net"
	"log"
	"time"
	"os"
	"os/signal"
	"syscall"
	"google.golang.org/grpc"
	iface "generic_pcie_driver/src/protobuf"
)

var (
	serverAddr         = flag.String("addr", "localhost:10000", "The server address in the format of host:port")
	pcie_device = flag.String("dev", "/sys/bus/pci/devices/0000:65:00.0/resource0", "The sys/bus/pcie device of the FPGA")
)


func main() {
	fmt.Println("main")
	flag.Parse()

	lis, err := net.Listen("tcp", *serverAddr)
	if err != nil {
	log.Fatalf("failed to listen: %v", err)
	}
	grpcServer := grpc.NewServer()

	apiServer := NewGenericPciApiServer(*pcie_device)
	SetupCloseHandler(apiServer)
	iface.RegisterGenericPciApiServer(grpcServer, apiServer)
	grpcServer.Serve(lis)

}

func SetupCloseHandler(server *GenericPciApiServerImpl){
	c := make(chan os.Signal)
	signal.Notify(c, os.Interrupt, syscall.SIGTERM)
	go func() {
		<-c
		fmt.Println("\r- Ctrl+C pressed in Terminal")
		server.Terminate()

		time.Sleep(1 * time.Second)
		os.Exit(0)
	}()
}