//ty@wisc.edu
//This verilog module to calculate crc32 of comm data between DOM and DOMHub
//Wait for eight bits to be acquired. Then released them into the CRC machine newest bit first.
//Since the calculation starts 8 bits late, extra 8 (junk) bits are needed to be loaded in at the end.
//  In the case of use in the comm_receiver, the extra eight bits are satisfied by the stop byte at the end of the packet.
//  In the case of use in the comm_transmitter, need to load in additional bits manually (simply by toggling the new_bit_enable line).
//reset on the posedge of the input rst
//Last update: Dec 05, 2017

module crc32_calculator(inclk, rst, new_bit_enable, new_bit, current_rmder);
	input inclk;
	input rst;				//This input serves to reset the calculator
	input new_bit_enable;	//Indication of a new bit to be read
	input new_bit;
	output reg[31:0] current_rmder = 32'b11111111111111111111111111111111;
	
	reg[31:0] crc32poly = 32'b00000100110000010001110110110111; //Standard crc32 without the 33th bit
	
	reg[15:0] temp_byte;		//This 16-bit long register temporary holds the incoming new_bit so that the bits can be loaded in msb first
	reg[ 3:0] bit_number;
	reg       start_crc;
	reg[ 1:0] rst_monitor = 2'b00;
	
	always@(posedge inclk)
	begin
		rst_monitor    <= rst_monitor << 1;
		rst_monitor[0] <= rst;
		if(rst_monitor == 2'b01) begin	//Reset at the beginning of a new data packet
			current_rmder <= 32'b11111111111111111111111111111111;
			temp_byte     <= 0;
			bit_number    <= 0;
			start_crc     <= 0; end
		if(new_bit_enable) begin
			temp_byte    <= temp_byte << 1;
			temp_byte[0] <= new_bit;
			bit_number   <= bit_number + 1'b1;
			if(bit_number == 7) begin
				bit_number <= 0;
				start_crc  <= 1; end
			if(start_crc) begin
				current_rmder[0]    <= temp_byte[bit_number+bit_number] ^ (crc32poly[0]    &     current_rmder[31]);
				current_rmder[31:1] <= current_rmder[30:0]              ^ (crc32poly[31:1] & {31{current_rmder[31]}}); end end
	end
	
endmodule