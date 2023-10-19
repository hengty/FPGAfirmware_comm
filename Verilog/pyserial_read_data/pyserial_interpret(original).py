import serial

f = open('pyserial_read.txt', 'r')
g = open('pyserial_binary.txt','w')
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
				g.write(' '+('{0:08b}'.format(int('5c',16)))[::-1]+' ')
				len=len+10
			else:break
		if(a=='x'):
			b=f.read(2)
			if(b=='99'):
				g.write(' '+('{0:08b}'.format(int(b,16)))[::-1]+'\t'+str(len)+'\n')
				len=10
			else:
				g.write(' '+('{0:08b}'.format(int(b,16)))[::-1]+' ')
				len = len + 10
		else:
			g.write(' '+('{0:08b}'.format(ord(a)))[::-1]+' ')
			len = len + 10
	else:
			g.write(' '+('{0:08b}'.format(ord(a)))[::-1]+' ')
			len = len + 10

g.close()