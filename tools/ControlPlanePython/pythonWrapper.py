import struct
import ctypes
import os
import mmap



def toByteArray(myInt):
	myArray = []
	for i in (0,8,16,24):
		myHex = myInt >> i & 0xff
		myArray.append(myHex)
	return myArray


class simpleReadWriteWrapper:
	dev_file = None
	
	def __init__(self, path):
		self.path = path
		self.file = None
		self.mmap = None

	def file_open(self):
		if self.path == None:
			self.path = "/sys/bus/pci/devices/0000:65:00.0/resource0"
		try:
		    self.file = os.open(self.path, os.O_RDWR)
		    self.mmap = mmap.mmap(self.file, 0, access=mmap.ACCESS_WRITE)
		    print("hello pci_api stub")
		except OSError as e:
		    print(f"Failed to open mmap device: {e}")
		    exit(1)

	def file_close(self):
		if self.mmap:
		    self.mmap.close()
		if self.file:
		    os.close(self.file)
	    

	def write(self,address, data):
		#print("write")
		#print(address)
		#print(data)
		if address % 4 != 0:
		    print("address should be modulo 4")	
		data = struct.pack('<I', data)
		self.mmap[address:address + 4] = data
		pass

	def read(self, address):
		#print("read")
		#print(address)
		if address % 4 != 0:
		    print("address should be modulo 4")
		data = self.mmap[address:address + 4]
		value = struct.unpack('<I', data)[0]
		#print(value)
		return value
