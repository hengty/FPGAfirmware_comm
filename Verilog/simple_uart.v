//ty@wisc.edu
//A simple UART module to pass data to my laptop. 2 Mbaud
//Last update: Sep 11, 2017

`timescale 1ns / 100ps

module my_uart(inclk, new_bit_enable, new_bit, decoding, start_byte_detected, tx);
	input inclk;
	input new_bit_enable;											//Indicates a new bit is ready to be read out
	input new_bit;
	input decoding;
	input start_byte_detected;									//for reset
	output reg tx = 1;
	
	reg[1 :0]  decoding_monitor   = 2'b00;
	reg[1 :0]  start_byte_det_mon = 2'b00;
	reg[31:0]  data_buffer;
	reg[4 :0]  next_write_address = 0;
	reg[4 :0]  next_read_address  = 0;
	reg[31:0]  local_time         = 0;							//Goes up to 3.579 minutes
	reg[31:0]  timestamp          = 0;
	reg[3 :0]  two_MHz_counter    = 0;
	reg[5 :0]  timestamp_sent     = 0;
	reg[3 :0]  tx_counter         = 9;
	reg[8 :0]  byte_to_send       = 0;
	reg        byte_ready         = 0;
	
	wire[7:0] buffer_level;
	assign    buffer_level = (next_write_address - next_read_address );
	
	always@(posedge inclk)
	begin
		local_time      <= local_time + 1'b1;
		
		//---timestamp whenever decoding goes up---------------------
		decoding_monitor    <= decoding_monitor << 1;
		decoding_monitor[0] <= decoding;
		if(decoding_monitor == 2'b01) timestamp <= local_time;
		//-----------------------------------------------------------
		
		//---send timestamp when the start byte is detected----------
		start_byte_det_mon    <= start_byte_det_mon << 1;
		start_byte_det_mon[0] <= start_byte_detected;
		if(start_byte_det_mon == 2'b01) begin
			next_write_address <= 0;
			next_read_address  <= 0;
			timestamp_sent <= 0; end
		//-----------------------------------------------------------
		
		//---ring buffer for storing newly decoded new_bit-----------
		if(new_bit_enable) begin
			data_buffer[next_write_address] <= new_bit;
			if(next_write_address==31) next_write_address <= 0;
			else next_write_address	<= next_write_address + 1'b1; end
		//-----------------------------------------------------------
		
		//---Send bytes to tx machine---------------------------------------------------
		if((tx_counter==9) && (byte_ready==0)) begin	//tx_counter==9 means the tx machine is ready to send a new byte
			if(timestamp_sent != 32) begin
				byte_to_send[8:1] <= timestamp[timestamp_sent +:8];
				byte_ready        <= 1;
				timestamp_sent    <= timestamp_sent + 4'b1000;
			end
			else if(buffer_level >= 8) begin
				byte_to_send[8:1] <= data_buffer[next_read_address +:8];
				byte_ready        <= 1;
				next_read_address <= next_read_address + 4'b1000;
			end
		end
		//-----------------------------------------------------------------------------
		
		//---2 Mbaud UART tx machine--------------------------------
		two_MHz_counter <= two_MHz_counter + 1'b1;
		if(two_MHz_counter==9) begin
			two_MHz_counter <= 0;				
			if(tx_counter < 9) begin					//tx machine. Triggers whenever byte_ready is on -- 9 total bits sent per trigger
				tx_counter <= tx_counter + 1'b1;
				tx         <= byte_to_send[tx_counter]; end		//Send bit, unless when tx_counter is zero. In that case uart start-bit is sent (zero)
			if(tx_counter ==9) begin		//tx_counter stops counting when reaches 9. This block gets triggered when a new byte is ready to be sent.
				tx <= 1;
				if(byte_ready) begin
					tx_counter <= 0;
					byte_ready <= 0; end end end		//byte_ready is turned off after the tx machine senses it
		//----------------------------------------------------------
	end
	
endmodule
