f = open('pyserial_binary2.txt', 'r')

crc32_poly = '04C11DB7'
crc32_poly = '1'+'{0:032b}'.format(int(crc32_poly, 16)) #Convert to binary
crc        = crc32_poly
crclength  = len(crc)-1

message_type = {'000':'data               ', 
			   '001':'ack                 ', 
			   '010':'data_end            ', 
			   '011':'control             ',
			   '100':'initiate connection ', 
			   '101':'connection initiated',
			   '110':'DOR control         ',
			   '111':'undefined           '}

DOR_control = {'0001':'not used                   ', 
			   '0010':'not used                   ', 
			   '0011':'dom id request             ', 
			   '0100':'not used                   ', 
			   '0101':'data read request          ',
			   '0110':'data read ack, no data     ', 
			   '0111':'dom reboot                 ',
			   '1000':'message received, more Rx buffer available',
			   '1001':'message received, no more Rx buffer available', 
			   '1010':'message received, but CRC error detected',
			   '1011':'communication channel reset ', 
			   '1100':'dom Rx buffer status request', 
			   '1101':'dom system Reset (softboot) ',
			   '1110':'TCAL                        ',
			   '1111':'idle                        '}
# Gives up on B at line 12090	
message_number = 0
print('#','\t','CRC32','\t','DOM Type','\t','Packet Type','\t','Packet Length','\t','DOR Control Message','\t','Boot State','\t', 'Signal Strength Request','\t','Sequence field', end='\r')
for line in f:
	crc_checked = 0
	message_number = message_number + 1
	input('')
	packet = line.split('  ')
	extracted_bit = (len(packet) > 11)
	if(len(packet) < 10):
		print(message_number, '\tError: Insufficient number of bits', end='\r')
		continue
	bitstream = ''
	for i in range(1,9):
		bitstream = bitstream + packet[i][1:9]
	
	bitstream  = '1'*crclength	+ bitstream

	loops = len(bitstream) - crclength
	for i in range(0,loops):
		current_bits = bitstream[i:i+crclength+1]
		if  current_bits[0]=='1':
			bitstream = '0'*i +'{0:033b}'.format(int(current_bits,2)^int(crc,2)) + bitstream[i+crclength+1:]
	
	crc_checked = 'Checked' if(int(bitstream)==0) else 'Error'

	type_n_length   = packet[2][1:9]+packet[1][1:9]
	dom_type        = 'A' if int(type_n_length[0]) else 'B'
	packet_type     = type_n_length[1:4]
	length          = type_n_length[4:]
		
	sequence_number = packet[4][1:9]+packet[3][1:9]
	signal_strength_req = 'Up' if sequence_number[0:2]=='10' else ('Down' if sequence_number[0:2]=='01' else sequence_number[0:2])
	boot_state    = 'IceBoot' if int(sequence_number[3]) else 'ConfigBoot'
	dor_cntr      = sequence_number[4:8] #What about sequence_number[2] and sequence_number[8:]?
		
	if(packet_type == '110'):
		print(message_number, '\t',crc_checked,'\t',dom_type,'\t',message_type[packet_type],'\t',length, '\t'
			, DOR_control[dor_cntr], '\t', boot_state, '\t', signal_strength_req, '\t'
			,sequence_number[2]+' '+sequence_number[8:], end='\r')
	else:
		print(message_number, '\t',crc_checked,'\t',dom_type,'\t',message_type[packet_type],'\t',length, '\t', sequence_number, end='\r')
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	