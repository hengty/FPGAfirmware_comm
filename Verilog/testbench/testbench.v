`timescale 1ns/100ps

module testbench();
	
	reg inclk = 0;
	always #25 inclk = ~inclk;		//50ns for every tick to make inclk 20MHz
	
	reg        new_bit_enable = 0;
	reg        new_bit;
	reg        start_byte_detected = 0;
	reg        decoding_success = 0;
	wire[31:0] data_to_nios;
	wire       data_to_nios_write;
	reg        data_from_nios_ready;
	reg        data_from_nios_wait;
	wire       data_from_nios_read;
	reg[31:0]  data_from_nios;
	
	wire       transmitter_on;
	wire[31:0] rspns_to_transmit;
	wire       rspns_read;
	wire       tx_machine_on;
	wire[11:0] com_dac;
	
	comm_process comm_process0(.comm_dac_on(tx_machine_on),
								.inclk(inclk), 
								.new_bit_enable(new_bit_enable), 
								.new_bit(new_bit), 
								.start_byte_detected(start_byte_detected),
								.decoding_success(decoding_success), 
								.data_to_nios(data_to_nios), 
								.data_to_nios_write(data_to_nios_write), 
								.data_from_nios_ready(data_from_nios_ready), 
								.data_from_nios(data_from_nios), 
								.data_from_nios_read(data_from_nios_read), 
								.data_from_nios_wait(data_from_nios_wait),
								.transmitter_on(transmitter_on), 
								.rspns_read(rspns_read), 
								.rspns_to_transmit(rspns_to_transmit));
								
	comm_transmitter comm_transmitter0(.inclk(inclk), 
										.transmitter_on(transmitter_on), 
										.rspns(rspns_to_transmit), 
										.rspns_read(rspns_read), 
										.tx_machine_on(tx_machine_on), 
										.com_dac(com_dac)
										);
	
	
	localparam[71:0] comm_chan_reset = 72'b100110010111011110010000001110111000110100001011110111111110000000000000;		//dor_control -- comm_chan_reset
	//(Correct Response: 10011001  01000100  11110100  00100011  11110000  00001111  00000000  11100000  00000000)
	
	localparam[71:0] data_read_req   = 72'b100110011001001111010000101110011101100010000101110111111110000000000000;		//dor_control -- data_read_req
	// (Correct Response: 10011001  01001011  00000100  11101010  11010010  00000110  00000000  11100000  00000000)
	
	localparam[71:0] conn_initd      = 72'b100110010110100100010001111100111110111000000000000000001101000000000000;		//conn_initd
	// (Correct Response: 10011001  01000001  10100100  01100100  11101110  00001000  00000000  11100000  00000000)
	
	localparam[71:0] ack             = 72'b100110010111101001101111001100111110101000000000000000111001000000000000;		//ack with sequence number 0000000000000011
	// (Correct Response: 10011001  01000001  10100100  01100100  11101110  00001000  00000000  11100000  00000000)
	
	localparam[71:0] dom_id_req      = 72'b100110010010000110011101001111111100001010000011110111111110000000000000;		//dom_id_req         
	// (Correct Response: 10011001  01100100  10111100  10000001  10011110  00000000  00000000  00000000  00000000  00000000  00000000  00000000  00000000  00000001  00000010  10000000  00001000)
	
	localparam[103:0] data           = 104'b10011001110110011001001001110111111111011111011101100110000000000000110100000000000000001010000000000001;		//(Data from DOMHub)
	// (Correct Response: 10011001  01000001  10100100  01100100  11101110  00001000  00000000  11100000  00000000)
	
	reg[2:0] state  = 3'b000;
	reg[6:0] current_bit_num = 0;
	reg[4:0] bitclk = 0;
	reg[5:0] crc_n_stop = 0;
	reg[103:0] current_packet;
	reg[6:0] current_packet_num;
	reg      end_of_packet = 0;
	reg[2:0] packet_seq = 3'b000;
	
	integer fileout_nios, fileout_comdac;
	initial 
	begin
		fileout_nios = $fopen("data_to_Nios.txt", "w");
		fileout_comdac = $fopen("com_dac.txt", "w");
	end
	
	always@(posedge inclk)
	begin
	
		//------------------------Simulating Nios Send Buffer--------
		if(data_from_nios_read && !data_from_nios_wait) data_from_nios <= 32'b00000001000000101000000000000000;
		//-----------------------------------------------------------
	
		//------------------------Simulate comm_receiver.v-----------
		bitclk <= bitclk + 1;
		if(new_bit_enable == 1) new_bit_enable <= 0;
		if(end_of_packet  == 1) end_of_packet  <= 0;
		
		if(bitclk == 19) begin
			bitclk <= 0;
			case(state)
			3'b000:begin
					case(packet_seq)
					3'b000:begin
							current_packet <= comm_chan_reset;
							current_packet_num <= 71;
							packet_seq <= packet_seq + 1; end					
					3'b001:begin
							current_packet <= data_read_req;
							packet_seq <= packet_seq + 1; end
					3'b010:begin
							current_packet <= dom_id_req;
							packet_seq <= packet_seq + 1; end
					3'b011:begin
							current_packet <= data;
							current_packet_num <= 103;
							packet_seq <= packet_seq + 1; end
					3'b100:begin
							current_packet <= ack;
							current_packet_num <= 71;
							packet_seq <= packet_seq + 1;
							data_from_nios_ready <= 1; end
					3'b101:begin
							current_packet <= conn_initd;
							current_packet_num <= 71;
							data_from_nios_wait <= 0;
							packet_seq <= packet_seq + 1; end
					3'b110:begin
							current_packet <= data_read_req;
							current_packet_num <= 71;
							packet_seq <= packet_seq + 1; end
					3'b111:$display("Done!");
					endcase
					if(packet_seq == 3'b111) state <= state + 3'b110;
					state <= state + 1; end
			3'b001:begin
					start_byte_detected <= 1;
					state <= state + 1; end
			3'b010: state <= state + 1;
			3'b011: state <= state + 1;
			3'b100:begin
					new_bit         <= current_packet[current_bit_num];
					new_bit_enable  <= 1;
					current_bit_num <= current_bit_num + 1;
					if(current_bit_num == current_packet_num) state  <= state + 1; end
			3'b101:begin
					crc_n_stop <= crc_n_stop + 1;
					if(crc_n_stop == 39) begin
						decoding_success <= 1;
						state <= state + 1; end end
			3'b110:begin
					$display("Finished a packet");
					state <= state + 1; end
			3'b111:if(tx_machine_on == 0) begin
					end_of_packet <= 1;
					start_byte_detected <= 0;
					crc_n_stop <= 0;
					decoding_success <= 0;
					current_bit_num <= 0;
					if(packet_seq == 3'b111) begin
						$fclose(fileout_nios);
						$fclose(fileout_comdac);end
					if(packet_seq != 3'b111) state <= 3'b000; end
			endcase
		end
		//-----------------------------------------------------------
		
		//---Recording data sent from comm_process to nios---------------------
		if(data_to_nios_write)	$fwrite(fileout_nios, "%b\n", data_to_nios[31:0]);
		//---------------------------------------------------------------------
		
		//---Record com_dac when tx_machine_on is high-------------------------
		$fwrite(fileout_comdac, "%b\n", com_dac[11:0]);
		if(end_of_packet) $fwrite(fileout_comdac, "\n");
		//---------------------------------------------------------------------
	
	end
	
endmodule	