//Take bits to be sent from comm_process.v. Add Start byte, paddings, CRC, and stop byte to the packet. Transmit it via the COMM_DAC.
//ty@wisc.edu
//Last update: Dec 05, 2017

`timescale 1ns / 100ps

module comm_transmitter(inclk, transmitter_on, rspns, rspns_read, tx_machine_on, com_dac);
	input inclk;
	input transmitter_on;    //transmitter_on means there's still content to be read from rspns
	input wire[31:0] rspns;
	output reg rspns_read = 0;
	output reg tx_machine_on = 0;
	output reg[11:0] com_dac = 12'b011111111111;
	
	//---Constants---------------------------------------------------------------
	reg[9:0] start_byte = 10'b0111000111;
	reg[9:0] stop_byte  = 10'b0100110011;
	// reg[99:0] data_req_ack_no_data = 100'b0100110011111001011110100011111101111001100111110110000011011000000001101100000110000000010111000111;
	// reg[99:0] idle                 = 100'b0100110011111000100111011011111011101011100011100110000111111000000001101100000110000000010111000111;
	//--------------------------------------------------------------------------
	
	reg[4:0]  one_MHz_counter;			//for the 1 Mbaud tx_machine
	reg[3:0]  tx_counter;				//tells tx machine where to read in byte_to_send
	reg[9:0]  byte_to_send;				//tx machine only reads from this register
	reg[32:0] line_to_send;             //This register copies to byte_to_send, 8 bits at a time
	reg[2:0]  byte_counter;				//This tells which part to copy from line_to_send to byte_to_send
	reg       crc_rst = 0;
	reg[1:0]  transmitter_mon = 0;
	reg[2:0]  next_state;				//Tells state machine where to go after transmitter_on turns off
	reg[2:0]  state = 3'b000;
	reg[5:0]  crc_load_cnter;
	reg[6:0]  crc_enbl_cnter;           //Keeps track of how many bits loaded into crc32_calculator
	reg       crc_bit_enable = 0;
	reg       crc_bit;
	reg       crc_block = 1;
	
	wire refresh_byte;
	assign refresh_byte = (tx_counter == 9) && (one_MHz_counter == 11);
	
	wire[31:0] current_rmder;
	crc32_calculator crc32_calculator1(.inclk(inclk), .rst(crc_rst), .new_bit_enable(crc_bit_enable), .new_bit(crc_bit), .current_rmder(current_rmder));
	
	always@(posedge inclk)
	begin
	
		//-----------------------For loading reponse bits into CRC calculator----------------------------------------------------------------------------------------
		if(rspns_read) begin
			rspns_read     <= 0;								//rspns_read is turned on for only 1 clk cycle at a time
			crc_block      <= 0; end
		if(!crc_block) begin									//crc_block is turned off for only 1 clk cycle at a time
			crc_block      <= 1;								
			crc_bit_enable <= 1;								//Turn on the circuit to load line_to_send to crc32_calculator
			crc_load_cnter <= 1;
			crc_bit        <= line_to_send[0];					//The first bit going into crc32_calculator has to be set here because crc_bit_enable is turned on here
			if(transmitter_on) crc_enbl_cnter <= 31;
			else               crc_enbl_cnter <= 71; end		//If last rspns, add additional 32 0's and 8 (junk) bits to crc32_calculator
		if(crc_bit_enable) begin
			crc_enbl_cnter <= crc_enbl_cnter - 1'b1;
			crc_bit        <= line_to_send[crc_load_cnter];
			if(crc_enbl_cnter ==  0) crc_bit_enable <= 0;		//Turn off the circuit to load bits into crc32_calculator once crc_enbl_cnter has been exhausted
			if(crc_load_cnter != 32) crc_load_cnter <= crc_load_cnter + 1'b1; end
		//-----------------------------------------------------------------------------------------------------------------------------------------------------------
		
		case(state)
		
		//--------------------------Idle---------------------------------------
		3'b000:begin
				transmitter_mon    <= transmitter_mon << 1;
				transmitter_mon[0] <= transmitter_on;		//Monitor the transmitter_on line, which is controlled by comm_process.v
				if(transmitter_mon == 2'b01) begin          //(note: can use this line to add delay to response)
					byte_to_send    <= start_byte;			//Load the first byte (10-bit start_byte) of the packet to tx_machine
					tx_counter      <= 0;
					one_MHz_counter <= 0;
					tx_machine_on   <= 1;					//Turn on tx machine
					crc_rst         <= 1;					//Reset crc calculator
					byte_counter    <= 4;
					crc_load_cnter  <= 0;
					line_to_send[32]<= 0;
					next_state      <= 3'b100;				//After transmitter_on turns off, first go to CRC32
					state           <= 3'b011; end end
					
		//--------------------------Comm Process Read--------------------------
		3'b001:begin
				line_to_send[31:0] <= rspns;
				rspns_read         <= 1;
				byte_counter       <= 0;
				state <= state + 1'b1; end
				
		//--------------------------Refresh------------------------------------
		3'b010:begin
				byte_to_send <= {1'b1, line_to_send[8*byte_counter+:8], 1'b1};	//(indexed part-select)
				byte_counter <= byte_counter + 1'b1;
				state <= state + 1'b1; end
				
		//--------------------------Wait to Refresh----------------------------
		3'b011:if(refresh_byte) begin
					if(byte_counter == 4) begin
						if( transmitter_on) state <= 3'b001;					//Go to Comm Process Read
						if(!transmitter_on) state <= next_state; end			//Go to state specified by next_state
					else                    state <= 3'b010; end				//Go to Refresh
				
		//--------------------------CRC32--------------------------------------
		3'b100:begin
				line_to_send[31:24] <= current_rmder[ 7: 0];					//For some reason the output from my crc32 calculator has to be paste this way...
				line_to_send[23:16] <= current_rmder[15: 8];
				line_to_send[15: 8] <= current_rmder[23:16];
				line_to_send[ 7: 0] <= current_rmder[31:24];
				byte_counter        <= 0;
				next_state          <= 3'b101;
				state               <= 3'b010; end
				
		//--------------------------Stop Byte----------------------------------
		3'b101:begin
				byte_to_send <= stop_byte;
				byte_counter <= 4;
				next_state   <= 3'b110;
				state <= 3'b011; end
				
		//--------------------------Turn off tx_machine------------------------
		3'b110:if(one_MHz_counter == 19) begin
				tx_machine_on <= 0;												//Turn off tx_machine. No need to reset com_dac since the last bit of stop_byte is always a zero.
				crc_rst       <= 0;
				state         <= 3'b000; end											//Go to Idle after all is done
		
		endcase
		
		//--------------------------------1 Mbaud tx machine----------------------------------------//
		//---Will loop over and send byte_to_send bit-by-bit, as long as tx_machine_on is on		//
		if(tx_machine_on) begin																		//
			one_MHz_counter <= one_MHz_counter + 1'b1;   //count to 19, then reset to 0, every 1 us //
			case(one_MHz_counter)																	//
			0 :com_dac <= {byte_to_send[tx_counter], 11'b11111111111};								//
			10:if(byte_to_send[tx_counter]) com_dac <= 12'b000000000000;							//
			19:begin																				//
				one_MHz_counter <= 0;																//
				tx_counter <= tx_counter + 1'b1;													//
				if(tx_counter == 9) tx_counter <= 0; end											//
			endcase end																				//
		//------------------------------------------------------------------------------------------//
			
	end
	
endmodule
