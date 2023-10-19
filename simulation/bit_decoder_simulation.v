//ty@wisc.edu
//Start-frame detector

`timescale 1ns / 100ps

module bit_decoder(inclk, com_adc, new_bit, decoded_bit, decoding_out, start, stop);
	output[13:0] start, stop;
	reg[13:0] com_adc_start, com_adc_stop;
	assign start = com_adc_start;
	assign stop = com_adc_stop;
	
	input inclk;
	input[13:0] com_adc;
	output new_bit;
	output decoded_bit;
	output decoding_out;
	reg decoding = 0;
	assign decoding_out = decoding;
	reg new_bit_clk;
	assign new_bit = new_bit_clk;
	reg bit_received;
	assign decoded_bit = bit_received;
	
	localparam trig_threshold = 9216; //com_adc threshold
	localparam slope_threshold = 700; //From data: falling slope is ~1000 in 7 inclk. This number decides whether the bit is a 1 or 0
	reg[9:0] start_byte = 10'b0111000111;
	reg[9:0] stop_byte = 10'b0100110011;
	reg[9:0] current_byte;
	reg[2:0] trig_finder;
	reg[3:0] current_bit_number;
	reg[4:0] decoder_time_counter;
	reg start_byte_detected;
	wire stop_byte_detected;
	assign stop_byte_detected = (current_byte==stop_byte);
	
	always@(posedge inclk)
	begin
		if(~decoding)
			begin
			trig_finder[2] <= trig_finder[1];
			trig_finder[1] <= trig_finder[0];
			trig_finder[0] <= (com_adc >= trig_threshold);
			if(trig_finder == 3'b011)
				begin
				decoding <= 1;	//If positive edge trigger is detected, decoder is turned on.
				start_byte_detected <= 0;
				decoder_time_counter <= 0;
				new_bit_clk <=0;
				current_bit_number <=0;
				trig_finder <= 3'bxxx;
				current_byte <= 10'b0000000000;
				end
			end
		else //The decoding machine
			begin
			decoder_time_counter <= decoder_time_counter + 1;
			if(decoder_time_counter == 1) com_adc_start <= com_adc;
			if(decoder_time_counter == 8) com_adc_stop <= com_adc;
			if(decoder_time_counter == 9)
				begin
				bit_received <= ((com_adc_start - com_adc_stop) > slope_threshold)&&(com_adc_start > com_adc_stop);
				current_bit_number <= current_bit_number + 1;
				end
			if(decoder_time_counter == 10)
				begin
				new_bit_clk <= 1;
				if(~start_byte_detected) //Start-byte test
					begin
					decoding <= (bit_received == start_byte[current_bit_number-1]);
					if(current_bit_number == 10) start_byte_detected <= 1;
					end
				current_byte[current_bit_number-1] = bit_received;
				end
			if(decoder_time_counter == 11) decoding <= ~stop_byte_detected; //Stop-byte test
			if(decoder_time_counter == 19)
				begin
				new_bit_clk <= 0;
				if(current_bit_number==10) current_bit_number <= 0;
				decoder_time_counter <= 0; //Reset decoder_time_counter after 20 inclk ticks
				end
			end
	end
endmodule
