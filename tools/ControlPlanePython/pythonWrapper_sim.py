import struct
import ctypes


class simpleReadWriteWrapper_sim:	
	dev_file = None

	def __init__(self, path):
		self.path = path

	def file_open(self):
		self.dev_file = open(self.path, "w");

	def file_close(self):
		self.dev_file.close();

	def write(self,address, data):
		print("write: " + str(data) + " address: "+ str(address))
		self.dev_file.write(format(address, 'x'))
		self.dev_file.write(" ")
		self.dev_file.write(format(data, 'x'))
		self.dev_file.write("\n")

	def read(self, address):
		return 0
