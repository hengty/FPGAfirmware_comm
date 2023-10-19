# Calculate CRC-32 -- software style

crc32_poly = '04C11DB7'
crc32_poly = '1'+'{0:032b}'.format(int(crc32_poly, 16)) #Convert to binary
crc        = crc32_poly
crclength  = len(crc)-1

# bitstream = '00000000000001111111101110100001 00011011100111010000101111001001' #data_read_request to DOM A(1)
# bitstream = '0000000000000111111110111010000100011011100111010000101111001001'
# bitstream = '0000000000000111111110111010000100000000000000000000000000000000'

# bitstream = '00000000000001110000000001100000'+'00000000000000000000000000000000' #data_req_ack_no_data, DOM A(1)
# bitstream =   '00000000000001100000000001100000'+'00000000000000000000000000000000' #data_req_ack_no_data, DOM B(0)  

bitstream = '00000000000001110000000011110000'+'00000000000000000000000000000000' #idle A
#bitstream = '00000000000001100000000011110000'+'00000000000000000000000000000000' #idle B

print(bitstream[0:8]+' '+bitstream[8:16]+' '+bitstream[16:24]+' '+bitstream[24:32])
bitstream_temp=''
for i in range(int(len(bitstream)/8)):
	bitstream_temp = bitstream_temp + bitstream[i*8:(i+1)*8][::-1]			#To flip each byte. Why? Because that's how it was implemented in the DOMHub
bitstream = bitstream_temp
print(bitstream[0:8]+' '+bitstream[8:16]+' '+bitstream[16:24]+' '+bitstream[24:32])

bitstream  = '1'*crclength	+ bitstream
print(bitstream)

loops = len(bitstream) - crclength
for i in range(0,loops):
	current_bits = bitstream[i:i+crclength+1]
	if  current_bits[0]=='1':
		bitstream = '0'*i +'{0:033b}'.format(int(current_bits,2)^int(crc,2)) + bitstream[i+crclength+1:]
	print(bitstream)#[i:i+crclength][::-1])
	
bitstream = bitstream[-32:]
bitstream_temp=''
for i in range(int(len(bitstream)/8)):
	bitstream_temp = bitstream_temp + bitstream[i*8:(i+1)*8][::-1]			#To flip each byte. Why? Because that's how it was implemented in the DOMHub
bitstream = bitstream_temp

print('\n'+bitstream[0:8]+' '+bitstream[8:16]+' '+bitstream[16:24]+' '+bitstream[24:32])
print(  '00011011 10011101 00001011 11001001  (From labhub)')

# print(hex(int(bitstream,2)))