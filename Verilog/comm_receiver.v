//Go into decoding state when sees disturbance in COM_ADC. Get out of decoding state if:
//	- first ten bits do not form a start_byte's
//	- number of bits decoded have reached the value specified in the pack header
//Many ways to get out of decoding state, but only one way to get out "successfully" (with decoding_success flag raised)
//ty@wisc.edu
//Last update: Jan 28, 2018

`timescale 1ns / 100ps

module comm_receiver(
							//input       on,
							input       inclk,
							input[13:0] com_adc,
							output reg  new_bit_enable,
							output reg  new_bit,
							output reg  decoding,
							output reg  start_byte_detected,
							output      decoding_success
							);
	
	//------Constants----------------------------------------------------
	localparam      trig_threshold   = 600;             //com_adc threshold
	localparam[9:0] start_byte       = 10'b0111000111;
	localparam[9:0] stop_byte        = 10'b0100110011;
	//-------------------------------------------------------------------
	
	reg[1:0]  decoding_state;	//2'b00:check for a valid state_byte
								//2'b01:read and broadcast contents of packet
								//2'b10:check for a valid stop_byte and crc
	
	reg[13:0] trig_mem1, trig_mem2, trig_mem3, trig_mem4, trig_mem5, trig_mem6, trig_mem7;
	reg[3:0]  current_bit_address;
	reg[15:0] new_bit_number;
	reg[1:0]  current_byte_address;
	reg[12:0] byte_number;
	reg[11:0] packet_length;
	reg[4:0]  decoder_time_counter;
	reg       crc_checked;
	reg       stop_byte_detected;
	reg[13:0] com_adc_max0;
	reg[13:0] com_adc_max1;
	reg[13:0] com_adc_min0;
	reg[13:0] com_adc_min1;
	reg[14:0] slope_threshold;
	reg       slope_threshold_set;
	
	wire[31:0] current_rmder;
	crc32_calculator crc32_calculator0(.inclk(inclk), .rst(start_byte_detected), .new_bit_enable(new_bit_enable), .new_bit(new_bit), .current_rmder(current_rmder));
	
	wire trigger = ((com_adc - trig_mem7) > trig_threshold) && (com_adc > trig_mem7);
	
	wire[14:0] com_adc_max   = (com_adc_max0 + com_adc_max1);
	wire[14:0] com_adc_min   = (com_adc_min0 + com_adc_min1);
	wire[14:0] current_slope = ((com_adc_max-com_adc_min)>>1);			//Divide by 2 to take average
	
	assign decoding_success = (stop_byte_detected && crc_checked);
	
	always@(posedge inclk) begin
		if(new_bit_enable==1) new_bit_enable <= 0;
		
		//if(on) begin
		
			//---Trigger state------------------------------------------------
			if(decoding !== 1) begin
				trig_mem1 <= com_adc;
				trig_mem2 <= trig_mem1;
				trig_mem3 <= trig_mem2;
				trig_mem4 <= trig_mem3;
				trig_mem5 <= trig_mem4;
				trig_mem6 <= trig_mem5;
				trig_mem7 <= trig_mem6;
				if(trigger) begin
					trig_mem1 <= 1'bx;
					trig_mem2 <= 1'bx;
					trig_mem3 <= 1'bx;
					trig_mem4 <= 1'bx;
					trig_mem5 <= 1'bx;
					trig_mem6 <= 1'bx;
					trig_mem7 <= 1'bx;
					decoding             <= 1;
					decoding_state       <= 2'b00;
					start_byte_detected  <= 0;
					stop_byte_detected   <= 0;
					decoder_time_counter <= 0;
					new_bit_number       <= 0;
					current_bit_address  <= 0;
					current_byte_address <= 0;
					byte_number          <= 0;
					crc_checked          <= 0;
					com_adc_max0         <= 14'b00000000000000;
					com_adc_max1         <= 14'b00000000000000;
					com_adc_min0         <= 14'b11111111111111;
					com_adc_min1         <= 14'b11111111111111;
					slope_threshold      <= 0;
					slope_threshold_set  <= 0;	end end
			//---End of Trigger state-----------------------------------------
			
			//---Decoding states---------------------------------------------------------------------------------------------------------------------------------------
			if(decoding) begin
				
				//---new_bit processor-------------------------------------------------------------
				//Find max in the first 8 data points, min in the next 8 data points. Use them to determine current_slope of the bit
				decoder_time_counter <= decoder_time_counter + 1'b1;
				if(decoder_time_counter == 19) decoder_time_counter <= 0;
				if((decoder_time_counter < 8)&&(com_adc_max1 < com_adc)) begin
					if(com_adc_max0 < com_adc) begin
						com_adc_max0 <= com_adc;
						com_adc_max1 <= com_adc_max0; end
					else com_adc_max1 <= com_adc; end
				if((decoder_time_counter >= 8)&&(decoder_time_counter < 15)&&(com_adc_min1 > com_adc)) begin
					if(com_adc_min0 > com_adc) begin
						com_adc_min0 <= com_adc;
						com_adc_min1 <= com_adc_min0; end
					else com_adc_min1 <= com_adc; end
				//Then determine new_bit from current_slope
				case(decoder_time_counter)
				15:begin
					if(!slope_threshold_set) begin
						slope_threshold <= (current_slope >> 1);	// Slope threshold is 1/2 of average of (two max - two min) of the first bit in the packet.
						slope_threshold_set <= 1; end
					new_bit <= (current_slope > slope_threshold)&&(com_adc_max > com_adc_min); end
				19:begin
					decoder_time_counter  <= 0;										//Reset decoder_time_counter after 20 inclk ticks
					com_adc_max0          <= 14'b00000000000000;
					com_adc_max1          <= 14'b00000000000000;
					com_adc_min0          <= 14'b11111111111111;
					com_adc_min1          <= 14'b11111111111111;
					current_bit_address   <= current_bit_address + 1'b1;		//current_bit_address tags new_bit's position in the byte.
					if(current_bit_address == 9) begin
						current_bit_address <= 0;
						current_byte_address <= current_byte_address + 1'b1;
						if(current_byte_address == 2'b11) byte_number <= byte_number + 3'b100; end end
				endcase
				//---------------------------------------------------------------------------------
				
				//---Decoding-Progress State Machine-----------------------------------------------
				case(decoding_state)
				2'b00:begin
						if(decoder_time_counter == 16) decoding <= (new_bit == start_byte[current_bit_address]);	//First 10 bits have to match start_byte. Otherewise decoding off.
						if(decoder_time_counter == 17 && current_bit_address == 9) begin
							start_byte_detected <= 1;
							decoding_state   <= 2'b01; end end
				2'b01:begin
						if(decoder_time_counter == 15) new_bit_enable <= (current_bit_address != 0)&&(current_bit_address != 9);
						if(decoder_time_counter == 16 && new_bit_enable) begin
							new_bit_number <= new_bit_number + 1'b1;
							if(new_bit_number<12) packet_length[new_bit_number] <= new_bit; end
						if(decoder_time_counter == 18 && (current_bit_address == 9) && (byte_number >= ({1'b0,packet_length} + 13'b0000000001000))) decoding_state <= 2'b10; end
				2'b10:begin
						if(decoder_time_counter == 15) new_bit_enable <= (current_bit_address != 0)&&(current_bit_address != 9);
						if(decoder_time_counter == 16) decoding <= (new_bit == stop_byte[current_bit_address]);		//First 10 bits have to match stop_byte. Otherewise decoding off.
						if(decoder_time_counter == 17 && current_bit_address == 9) begin
							crc_checked        <= (current_rmder==0);
							stop_byte_detected <= 1;
							decoding           <= 0; end end
				endcase
				//---End of Decoding-Progress State Machine----------------------------------------
				
			end
			//---End of Decoding state---------------------------------------------------------------------------------------------------------------------------------
			
		//end
	end
endmodule
