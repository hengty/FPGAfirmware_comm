# c = ''
# word = ''

# for i in range(4):
	# print('char ', i)
	# c = input()
	# if(c==''):
		# word = '00000000' + word
	# else:
		# word = '{0:08b}'.format(ord(c)) + word

# print(word)
# print(int(word,2))

import codecs
line = input("String to convert to decimal: ")
line = codecs.decode(line, 'unicode_escape')
print(line, len(line), line[0], line[1])
word = ''
num_bits = 0
i=0
while(num_bits < len(line)):
	for i in range(4):
		n = num_bits + i
		if(n < len(line)):
			word = '{0:08b}'.format(ord(line[n])) + word
		else:
			word = '00000000' + word
	print(word, ':', int(word, 2))
	word = ''
	num_bits = num_bits + 4
	
	