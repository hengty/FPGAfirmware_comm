import serial
import binascii

f = open('pyserial_read.txt', 'w')
ser = serial.Serial('COM4', 2000000, timeout=1)

while(1):
	try:
		a = binascii.hexlify(ser.read(5000))
		print(ser.inWaiting())
		if(a != b''):
			f.write(str(a)[2:-1])
	except KeyboardInterrupt: break
f.close()

print('Converting Hex to Binary...')
f = open('pyserial_read.txt', 'r')
g = open('pyserial_binary.txt','w')
counts = 0
for i in range(1): a=f.read(2) # initial read for a and also for skipping bytes

to_write = ''
while(1):
	if(a==''):break
	counts = counts + 1
	to_write = to_write + '{0:08b}'.format(int(a,16)) + ' '
	if (counts >= 13 and a=='99'):
		counts = 0
		g.write(to_write[0:-1] + '\n')
		to_write = ''
	a=f.read(2)

g.close()	
f.close()	
print('Done')