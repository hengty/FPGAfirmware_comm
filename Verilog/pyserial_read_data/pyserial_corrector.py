f = open('pyserial_binary_corrected2.txt', 'r')
g = open('pyserial_binary_corrected3.txt', 'w')
for i in range(92418): g.write(f.readline()) #row number up to before the short one's

a = f.readline()[0:-1] + ' '

for line in f:
	g.write(a+line[0:53]+'\n')
	a = line[54:-1] + ' '

f.close()
g.close()