import serial

f = open('pyserial_read.txt', 'r')
g = open('pyserial_hex.txt','w')
len = 0
while(1):
	a=f.read(1)
	if a=='':
		print('End of File')
		break
	if(a=='\\'):
		while(1):
			a = f.read(1)
			if(a=='\\'):
				g.write('0x{:02x}'.format(int('5c',16))[2:])
				len=len+10
			else:break
		if(a=='x'):
			b=f.read(2)
			if(b=='e3'):
				g.write('\t'+str(len)+'\n'+'0x{:02x}'.format((int(b,16))))
				len=10
			else:
				g.write('0x{:02x}'.format(int(b,16))[2:])
				len = len + 10
		else:
			g.write('0x{:02x}'.format(ord(a))[2:])
			len = len + 10
	else:
			g.write('0x{:02x}'.format(ord(a))[2:])
			len = len + 10

#For display in LSB			
# while(1):
	# a=f.read(1)
	# if a=='':
		# print('End of File')
		# break
	# if(a=='\\'):
		# while(1):
			# a = f.read(1)
			# if(a=='\\'):
				# g.write('0x{:02x}'.format(int('{0:08b}'.format(int('5c',16))[::-1],2))[2:])
				# len=len+10
			# else:break
		# if(a=='x'):
			# b=f.read(2)
			# if(b=='e3'):
				# g.write('\t'+str(len)+'\n'+'0x{:02x}'.format(int('{0:08b}'.format(int(b,16))[::-1],2)))
				# len=10
			# else:
				# g.write('0x{:02x}'.format(int('{0:08b}'.format(int(b,16))[::-1],2))[2:])
				# len = len + 10
		# else:
			# g.write('0x{:02x}'.format(int('{0:08b}'.format(ord(a))[::-1],2))[2:])
			# len = len + 10
	# else:
			# g.write('0x{:02x}'.format(int('{0:08b}'.format(ord(a))[::-1],2))[2:])
			# len = len + 10

g.close()