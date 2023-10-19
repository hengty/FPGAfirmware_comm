#Python simulation of how CRC-32 is calculated in hardware registers.
#To verify a packet of data with its crc32 checksum, load all of them in and the final remainder should be zero.
#To generate the crc32 checksum for a packet of data, load the data in followed by 32 zeros. The remainder is the crc32 checksum.

#Data: 1000000001 1000001111 1111110111 1101000011
#CRC:  1000110111 1100111011 1000010111 1110010011
crc_poly='100000100110000010001110110110111'[::-1]


# data = '00000000000001111111101110100001 00011011100111010000101111001001' #Data1 + CRC
# data = '00000000000001110000000001100000 01001011010101110010000011010010' #Data2 + CRC
data = '00000000000001111111101110100001 00000000000000000000000000000000' #Data1 + 32 zeros -- to generate the CRC
data_temp=''
for i in range(int(len(data)/8)):
	data_temp = data_temp + data[i*8:(i+1)*8][::-1]
data = data_temp

reg = ['1']*32

for bit in data:
	temp=reg[31]
	for i in range(1,32):
		reg[32-i] = str(int((bool(int(temp))*bool(int(crc_poly[32-i])))^bool(int(reg[(32-i)-1]))))	
	reg[0] = str(int((bool(int(temp))*bool(int(crc_poly[0])))^bool(int(bit)))) #As a new bit comes in, xor it with the LSB of the crc32 polynomial, then store to the LSB of reg
	
	reg_str=''		
	for j in range(32):
		reg_str=reg_str+reg[31-j]				#This block is for cosmetic -- make Python string to look like hardware register by reflecting it.
	print(int(reg_str,2))
	
print('Output: ', reg_str[0:8][::-1]+' '+reg_str[8:16][::-1]+' '+reg_str[16:24][::-1]+' '+reg_str[24:32][::-1])
print('CRC32 : ','00011011 10011101 00001011 11001001  (From labhub)')