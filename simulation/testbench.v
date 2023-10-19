`timescale 1ns/100ps

module basic_testbench();
	
	reg inclk=0;	//20MHz
	always #25 inclk = ~inclk;
	
	reg comm_dac_on=0;
	always #110000 comm_dac_on = ~comm_dac_on;
	//cross talk test-------------------------------------------------------------
	reg comm_trig_test = 0;
	reg[1:0] comm_dac_on_mon = 0;
	reg[11:0] comm_dac_on_counter = 0;
	always@(posedge inclk)
		begin
		comm_dac_on_mon[1] <= comm_dac_on_mon[0];
		comm_dac_on_mon[0] <= comm_dac_on;
		if(comm_dac_on_mon==2'b01) comm_dac_on_counter <= comm_dac_on_counter + 1'b1;
		if(comm_dac_on_counter==12'b111111111111) comm_trig_test <= 1;
		if(comm_trig_test==1)
			begin
			comm_trig_test <= 0;
			comm_dac_on_counter <= 0;
			end
		end
	//assign EXT_UEXT1_9 = COM_DAC_D[11];
	//----------------------------------------------------------------------------
	
	
	
	// reg[13:0] com_adc;
	// wire[11:0] com_dac;
	
	// wire comm_dac_on, new_bit_enable, new_bit, decoding, start_byte_detected, decoding_success, data_to_nios_write, data_from_nios_ready, data_from_nios_read, data_from_nios_wait, transmitter_on, rspns_read;
	// wire[31:0] data_to_nios, data_from_nios, rspns;
	// reg[1:0] decoding_success_mon;
	
	
	// integer file, fileout, g, h, ticks=0, n=0;
	// localparam numofdata = 32769;

	// comm_receiver com_receiver0(//.on(!comm_dac_on), 
								// .inclk(inclk), 
								// .com_adc(com_adc), 
								// .new_bit_enable(new_bit_enable), 
								// .new_bit(new_bit),
								// .decoding(decoding), 
								// .start_byte_detected(start_byte_detected), 
								// .decoding_success(decoding_success)
								// );
	
	// comm_process comm_process0(.comm_dac_on(comm_dac_on),
								// .inclk(inclk), 
								// .new_bit_enable(new_bit_enable), 
								// .new_bit(new_bit),
								// .start_byte_detected(start_byte_detected), 
								// .decoding_success(decoding_success), 
								// .data_to_nios(data_to_nios), 
								// .data_to_nios_write(data_to_nios_write),
								// .data_from_nios_ready(data_from_nios_ready),
								// .data_from_nios(data_from_nios),
								// .data_from_nios_read(data_from_nios_read),
								// .data_from_nios_wait(data_from_nios_wait),
								// .transmitter_on(transmitter_on), 
								// .rspns_read(rspns_read), 
								// .rspns_to_transmit(rspns));
		
	// comm_transmitter comm_transmitter0(.inclk(inclk), 
										// .transmitter_on(transmitter_on), 
										// .rspns(rspns),
										// .rspns_read(rspns_read), 
										// .tx_machine_on(comm_dac_on), 
										// .com_dac);
	
	// //my_uart my_uart0(.inclk(inclk), .new_bit_clk(new_bit_clk), .new_bit(new_bit), .decoding(decoding), .start_byte_detected(start_byte_detected), .tx(tx));
	// initial begin
		// file = $fopen("data_packet.csv", "r");
		// fileout = $fopen("newbits.txt", "w");
		// g       = $fopen("rspns.txt", "w");
		// h       = $fopen("to_nios.txt", "w"); end
		
	// always@(posedge inclk)
	// begin
		// ticks <= ticks + 1;
		// $fscanf(file,"%b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, \n", com_adc[0], com_adc[1], com_adc[2], com_adc[3], com_adc[4], com_adc[5], com_adc[6], com_adc[7], com_adc[8], com_adc[9], com_adc[10], com_adc[11], com_adc[12], com_adc[13]);
		// // $fwrite(fileout, "%b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, %b, \n", com_dac[0], com_dac[1], com_dac[2], com_dac[3], com_dac[4], com_dac[5], com_dac[6], com_dac[7], com_dac[8], com_dac[9], com_dac[10], com_dac[11]);
		
		// decoding_success_mon <= decoding_success_mon << 1;
		// decoding_success_mon[0] <= decoding_success;
		// if(decoding_success_mon == 2'b01) $fwrite(fileout, "\n");
		
		// if(new_bit_enable) begin
			// $fwrite(fileout, "%b", new_bit);
			// n <= n + 1;
			// if(n==7) begin
				// $fwrite(fileout, " ");
				// n<=0; end end
		
		// if(rspns_read) $fwrite(g, "%b \n", rspns);
		
		// if(data_to_nios_write) $fwrite(h, "%b \n", data_to_nios);
		
		// if(ticks == numofdata+1) begin
			// $fclose(fileout);
			// $fclose(g);
			// $fclose(h); end
			
	// end
			
endmodule