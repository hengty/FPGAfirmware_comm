
message_type = {'000':'data     ', 
			   '001':'ack       ', 
			   '010':'data_end  ', 
			   '011':'control   ',
			   '100':'init conn ', 
			   '101':'conn initd',
			   '110':'DOR contr ',
			   '111':'undefined '}

DOR_control = {'0001':'not used                  ', 
			   '0010':'not used                  ', 
			   '0011':'dom id request            ', 
			   '0100':'not used                  ', 
			   '0101':'data read request         ',
			   '0110':'data read ack, no data    ', 
			   '0111':'dom reboot                ',
			   '1000':'msg recvd, more Rx buf    ',
			   '1001':'msg recvd, no more Rx buf ', 
			   '1010':'msg recvd, but CRC err    ',
			   '1011':'comm chan reset           ', 
			   '1100':'dom Rx buf status req     ', 
			   '1101':'dom sys reset (softboot)  ',
			   '1110':'TCAL                      ',
			   '1111':'idle                      ',
			   '0000':'Error                     '}
			   
crc32_poly = '04C11DB7'
crc32_poly = '1'+'{0:032b}'.format(int(crc32_poly, 16)) #Convert to binary
crc        = crc32_poly
crclength  = len(crc)-1

f = open('pyserial_binary.txt', 'r')

message_number = 0
print('\n'
	 ,'Timestamp(ms)\t'
	 ,'Msg #\t'
	 ,'CRC32\t\t'
	 ,'DOM\t'
	 ,'Packet Type\t'
	 ,'Data len\t'
	 ,'Sequence field\t\t'
	 ,'Boot State\t\t'
	 ,'Vol Req\t'
	 ,'DOR Control Message')
goto = 0
frame = '-'*100
for line in f:
	
	while(goto==0):
		skips = input('')
		goto = 1 if(skips=='') else int(skips)
	goto=goto-1
	
	crc_checked = 0
	message_number = message_number + 1
	packet = line.split(' ')
	if(len(packet) < 13):
		print('00000000000','\t', message_number, '\t','Error: Insufficient number of bits                                                   ', end='\r')
		continue
	message_time = int(packet[3]+packet[2]+packet[1]+packet[0],2)/20000.
	message_time = "{:10.5f}".format(message_time)
	bitstream = ''
	for i in range(4,len(packet)-1): bitstream = bitstream + packet[i]
	
	bitstream  = '1'*crclength	+ bitstream
	loops = len(bitstream) - crclength
	for i in range(0,loops):
		current_bits = bitstream[i:i+crclength+1]
		if  current_bits[0]=='1':
			bitstream = '0'*i +'{0:033b}'.format(int(current_bits,2)^int(crc,2)) + bitstream[i+crclength+1:]
	
	crc_checked = 'Checked' if(int(bitstream)==0) else 'Error  '

	type_n_length   = packet[5]+packet[4]
	dom_type        = 'A' if int(type_n_length[0]) else 'B'
	packet_type     = type_n_length[1:4]
	length          = str(int(type_n_length[4:],2))
	sequence_number = packet[7]+packet[6]
	signal_strength_req = 'Up ' if sequence_number[0:2]=='10' else ('Down ' if sequence_number[0:2]=='01 ' else sequence_number[0:2])
	boot_state    = 'IceBoot ' if int(sequence_number[3]) else 'ConfigBoot '
	dor_cntr      = sequence_number[4:8] #What about sequence_number[2] and sequence_number[8:]?
	
	if(packet_type == '110'):
		print(message_time, '\t', message_number, '\t',crc_checked,'\t',dom_type,'\t',message_type[packet_type],'\t',length, '\t\t'
			,sequence_number, '\t', boot_state, '\t', signal_strength_req, '\t\t'
			,DOR_control[dor_cntr], end='\r')
	else:
		print(message_time, '\t', message_number, '\t',crc_checked,'\t',dom_type,'\t',message_type[packet_type],'\t',length, '\t\t'
				, sequence_number+70*' ', end='\r')
			
	#if(packet_type != '110' or crc_checked=='Error'): input('')
	if(crc_checked!='Checked' or (dor_cntr != '0101' and dor_cntr != '0110' and dor_cntr != '1011' and dor_cntr != '1111')):
		print(message_time, '\t', message_number, '\t',crc_checked,'\t',dom_type,'\t',message_type[packet_type],'\t',length, '\t\t'
				, sequence_number)
	
	if(packet_type == '010' or packet_type =='000'):
		data_packets    = packet[8:-5]
		data_str        = ''
		for item in data_packets: 
			data_str = data_str + chr(int(item,2))
		print('\n\n',frame,'\n',data_str,'\n',frame,'\n\n')
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	