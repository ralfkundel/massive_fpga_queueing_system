from pythonWrapper import simpleReadWriteWrapper 
from pythonWrapper_sim import simpleReadWriteWrapper_sim
from time import *
import ctypes
import argparse


QD_ADDRESS = 0
SCHED_ADDRESS = 1
COUNTER_ADDRESS = 2

CLOCK_DIVIDER = 1248
CLOCK_FREQUENZY = 156250000
CLOCK_FREQUENZY = 300000000


QUEUE_DEPTH_LENGTH = 27
MAX_QUEUE_DEPTH = 2**QUEUE_DEPTH_LENGTH - 1


w = None

def hex2(n):
	return hex (n & 0xffffffff)


print(hex2(MAX_QUEUE_DEPTH))
def setMaxQueueDepth(qos_class, value):
	#print("setMaxQueueDepth")
	address = (QD_ADDRESS << 24) + (qos_class*4) #memory access is byte alligned
	if(value > MAX_QUEUE_DEPTH):
		value = MAX_QUEUE_DEPTH
	w.write(address, value)
	res = w.read(address)
	if(res != value):
		print(hex2(res))
	return res

def setMaxRateLimit(queue_id, rate): #rate in bit/s
	#print("setMaxRateLimit")
	rate_limiter_id = 1
	address = (SCHED_ADDRESS << 24) + (rate_limiter_id << 21)+ (queue_id*4) #memory access is byte allignedess
	value = (rate / 8)* CLOCK_DIVIDER / CLOCK_FREQUENZY#TODO
	value = int(value)
	w.write(address, value)
	res = w.read(address)
	if(res != value):
		print(hex2(res))
		print(hex2(value))
	return res


def setMaxBucketSize(value):
	rate_limiter_id = 1
	address = (SCHED_ADDRESS << 24) + (rate_limiter_id << 21)+ (0x1ffff*4) #memory access is byte allignedess
	w.write(address, value)
	return

def readCounter(counter_id):
	address = (COUNTER_ADDRESS << 24) + (counter_id*4) #memory access is byte allignedess
	res = w.read(address)
	return res


def main():
	print("I'm in the python main now")
	setMaxQueueDepth(0, 5000)  ##read: 0:128, 1: 256, 2:512, ...
	setMaxRateLimit(0, 84*1000*1000)
	setMaxRateLimit(1, 2*1000*1000)
	setMaxRateLimit(8, 200*1000*1000)
	
	
	c = readCounter(1)
	print(c)


	setMaxBucketSize(100000)


parser = argparse.ArgumentParser(description='NetFPGA queueing PCIe kernel module demo')
parser.add_argument('--sim', help='indicates sim outputs', type=str, action="store")
parser.add_argument('--hw', help='path to sys bus PCIe device, e.g. /sys/bus/pci/devices/0000:65:00.0/resource0', type=str, action="store")
args = parser.parse_args()

if __name__ == "__main__":
	if args.sim is not None:
		w = simpleReadWriteWrapper_sim(args.sim);
	elif args.hw is not None:
		w = simpleReadWriteWrapper(args.hw);
	else:
		pass
	w.file_open()
	main()
	w.file_close()
