#!/usr/bin/env python

from kamene.all import *   #kamene is scapy for python3


class QueueID(Packet):
    name = "QueueID "
    fields_desc = [
        IntField("id", 0)
    ]


def generatePacketList(num):

    payload = 'Testpaket'
    for x in range(0,1469):
        payload += "b"


    packetlist = []
    #smallp = QueueID(id=15)/Ether()/"asdf"
    #packetlist.append(smallp)
    #packetlist.append(smallp/"asdf")
    #for x in range(0,300):
    #    packetlist.append(smallp/"asdfasdfasdfasdfasdfasdfasdfasdfasdfasdfasaabbccbbbbcccc") #exactly 68 byte excluding qid
    #    packetlist.append(smallp/"asdfasdfasdfasdfasdfasdfasdfasdfasdfasdf") #exactly 58 byte including qid header


    smallp = QueueID(id=8)/Ether()/IP()/TCP()/"asdf"
    #packetlist.append(smallp)
    #p = QueueID(id=15)/Ether()/IP()/UDP()/"Mein Name ist ralf und ich bin ein kleines Paket das einfach nur messen soll wie lange es braucht"
    #packetlist.append(p)


    for x in range (0,num): #TODO increase
        packetlist.append(smallp/"asdfaaaaaaaaaaaaaaaaaa") #exactly 80 byte excluding qid

        p = QueueID(id=8)/Ether()/IP()/TCP()/payload
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid
        packetlist.append(p) #should be 1532 byte excluding qid


        for i in range(0,0):
            payload = 'Testpaket'
            for y in range (0,(1+(x%100))): #MTU = 1000 + x //x%1000
                payload += 'a'
            p = QueueID(id=8)/Ether()/IP()/TCP()/payload
            packetlist.append(p)
    return packetlist


def generatePcapFile(path):
    packetlist = generatePacketList(100)
    wrpcap(path, packetlist)

def sendPackets(interface):
    print("not yet implemented")
    #todo

#TODO: start (one of them):
	# python pcap_example.py pcap /path/to/output
	# sudo python pcap_example.py enp0s31f6
if __name__ == "__main__":
    if(sys.argv[1] == "pcap"):
        generatePcapFile(sys.argv[2])
    else:
        sendPackets(sys.argv[1])
