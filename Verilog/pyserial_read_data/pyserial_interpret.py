import serial

f = open('pyserial_read4.txt', 'r')
g = open('pyserial_binary44.txt','w')
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
				g.write(' 1'+('{0:08b}'.format(int('5c',16)))+'1 ')
				len=len+10
			else:break
		if(a=='x'):
			b=f.read(2)
			if(b=='e3'):
				g.write('\t'+str(len)+'\n'+'1'+('{0:08b}'.format(int(b,16)))+'0 ')
				len=10
			else:
				g.write(' 1'+('{0:08b}'.format(int(b,16)))+'1 ')
				len = len + 10
		else:
			g.write(' 1'+('{0:08b}'.format(ord(a)))+'1 ')
			len = len + 10
	else:
			g.write(' 1'+('{0:08b}'.format(ord(a)))+'1 ')
			len = len + 10

g.close()