//ty@wisc.edu
//Read data packet from COM_ADC[13:0], decode the bits, verify CRC, relay message received
//reg decoding_failed goes high during negedge of reg decoding if the module failed to decode a packet - either due to stop-byte nondetection or crc failure.
//Last update: Aug 24, 2017

`timescale 1ns / 100ps

module comm_receiver(inclk, com_adc, new_bit_clk, new_bit, decoding, start_byte_detected, decoding_failed);
	input       inclk;
	input[13:0] com_adc;
	output reg  new_bit_clk;
	output reg  new_bit;
	output reg  decoding = 0;
	output reg  start_byte_detected;
	output reg  decoding_failed;
	
	//------Constants---------------------------------------------------
	localparam trig_threshold         = 9216; //com_adc threshold
	localparam slope_threshold_weak   = 1100; //From data: falling slope is ~1000 in 7 inclk. This number decides whether the bit is a 1 or 0
	localparam slope_threshold_strong = 20000;
	reg[9:0]   start_byte             = 10'b0111000111;
	reg[9:0]   stop_byte              = 10'b0100110011;
	//------------------------------------------------------------------
	
	reg[14:0] slope_threshold;
	reg[9:0]  current_byte;
	reg[15:0] com_adc_start, com_adc_stop;
	reg[2:0]  trig_finder;
	reg[15:0] number_bits_decoded;
	reg[3:0]  current_bit_number;
	reg[4:0]  decoder_time_counter;
	reg       crc_checked;
	reg       stop_byte_detected;
	
	wire[31:0] current_rmder;
	crc32_calculator crc32_calculator0(.new_bit_clk(new_bit_clk), .on(start_byte_detected), .bit_in(new_bit), .current_rmder(current_rmder));
	
	always@(posedge inclk)
		begin
	
		//---Trigger state-----------------------------------------------
		if(!decoding)
			begin
			trig_finder    <= trig_finder << 1;
			trig_finder[0] <= (com_adc >= trig_threshold);
			
			if(trig_finder == 3'b011)
				begin
				decoding             <= 1;	//If positive edge trigger is detected, decoder is turned on.
				start_byte_detected  <= 0;
				stop_byte_detected   <= 0;
				decoder_time_counter <= 0;
				new_bit_clk          <= 0;
				current_bit_number   <= 0;
				number_bits_decoded  <= 0;
				trig_finder          <= 3'bxxx;
				current_byte         <= 10'b0000000000;
				decoding_failed      <= 0;
				crc_checked          <= 0;
				if(com_adc < 12000) slope_threshold <= slope_threshold_weak;
				else slope_threshold                <= slope_threshold_strong;
				end
			end
		//---------------------------------------------------------------
		
		//---Decoding state----------------------------------------------
		else 
			begin
			decoder_time_counter <= decoder_time_counter + 1;
			case(decoder_time_counter)
			1 :com_adc_start <= com_adc;
			2 :com_adc_start <= com_adc_start+com_adc;
			8 :com_adc_stop  <= com_adc;
			9 :com_adc_stop  <= com_adc_stop+com_adc;
			10:begin
				new_bit <= ((com_adc_start - com_adc_stop) > slope_threshold)&&(com_adc_start > com_adc_stop);
				current_bit_number  <=  current_bit_number + 1;	//current_bit_number gets incremented as new bit is decoded, tagging its position in the byte.
				number_bits_decoded <= number_bits_decoded + 1;
				end
			19:begin
				decoder_time_counter <= 0; //Reset decoder_time_counter after 20 inclk ticks
				new_bit_clk          <= 0;
				if(current_bit_number==10) current_bit_number  <= 0;
				end
			endcase
			
			//---Check start_byte substate-----------------------------
			if(!start_byte_detected)
				case(decoder_time_counter)
				11:decoding <= (new_bit == start_byte[current_bit_number-1]);	//First 10 bits have to match the reg start_byte. Otherewise decoding off.
				12:if(current_bit_number == 10) start_byte_detected <= 1;
				endcase
			
			//---New_bit substate-----------------------------------------
			if(start_byte_detected)
				case(decoder_time_counter)
				11:begin
					new_bit_clk <= (current_bit_number != 1)&&(current_bit_number != 10) ;	//Only flag data bit as "new_bit"
					current_byte[current_bit_number-1] <= new_bit;
					end
				12:if(current_bit_number == 10) stop_byte_detected  <= (current_byte==stop_byte);
				13:begin
					decoding_failed <=  (stop_byte_detected ^  crc_checked);
					decoding        <= !(stop_byte_detected || crc_checked);
					end
				14:if(current_bit_number == 9) crc_checked <= (current_rmder==0); //crc_checked is placed here so that it turns on at the same cycle as stop_byte_detected
				endcase
			//------------------------------------------------------------
			
			end
		
		end
	
endmodule
