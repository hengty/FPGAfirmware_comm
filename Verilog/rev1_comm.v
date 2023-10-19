//Communication firmware for Rev.1 board - DOMHub
//ty@wisc.edu
//Last update: Jan 02, 2018

module rev1_comm
  (
	input OSC_TCXO_20M_FPGA,
	input[13:0] COM_ADC_D,		// 2.5V, pin T22, R22, P22, R21, T19, T18, T17, P19, P18, R17, P17, R16, P16, R15
	
	output[11:0] COM_DAC_D,    // 2.5V, pin C16, A18, B18, C18, B20, F19, C20, B21, E20, D21, D22, E22
	output COM_DAC_CLK,        // 2.5V, pin F22
	
	output COM_ADC_CLK,			// 2.5V, pin F7, E7 (Differential)
	output EXT_UEXT1_3,			// Indicator LED
	output EXT_UEXT1_10			// UART Tx pin G20
	);
	
	wire clk_20MHz;
	altclkctrl altclkctrl0(.inclk(OSC_TCXO_20M_FPGA), .outclk(clk_20MHz));
	
	assign COM_ADC_CLK = clk_20MHz;
	assign COM_DAC_CLK = clk_20MHz;
	
	//---Indictor LED driver-----------------------------
	reg[24:0] LED_clk  = 0;
	assign EXT_UEXT1_3 = LED_clk[24];
	always@(posedge clk_20MHz) LED_clk <= LED_clk + 1'b1;
	//---------------------------------------------------
	
	wire       comm_trsmter_on;
	wire       rspns_read;
	wire       comm_dac_on;
	wire[31:0] data_to_nios;
	wire       data_to_nios_write;
	wire       data_from_nios_read;
	wire       data_from_nios_wait;
	wire       data_from_nios_ready;
	wire[31:0] data_from_nios;
	wire[ 4:0] comm_receiver_O;
	wire[31:0] rspns_to_transmit;
	
	comm_receiver comm_receiver0(//.on(!comm_dac_on),
											.inclk(clk_20MHz),
											.com_adc(COM_ADC_D), 
											.new_bit_enable(comm_receiver_O[0]), 
											.new_bit(comm_receiver_O[1]), 
											.decoding(comm_receiver_O[2]), 
											.start_byte_detected(comm_receiver_O[3]), 
											.decoding_success(comm_receiver_O[4]));
	
	comm_process comm_process0(.comm_dac_on(comm_dac_on),
										.inclk(clk_20MHz),
										.new_bit_enable(comm_receiver_O[0]), 
										.new_bit(comm_receiver_O[1]),
										.start_byte_detected(comm_receiver_O[3]), 
										.decoding_success(comm_receiver_O[4]), 
										.data_to_nios(data_to_nios),
										.data_to_nios_write(data_to_nios_write),
										.data_from_nios_ready(data_from_nios_ready),
										.data_from_nios(data_from_nios),
										.data_from_nios_read(data_from_nios_read),
										.data_from_nios_wait(data_from_nios_wait),
										.transmitter_on(comm_trsmter_on),
										.rspns_read(rspns_read),
										.rspns_to_transmit(rspns_to_transmit));
	
	comm_transmitter comm_transmitter0(.inclk(clk_20MHz),
													.transmitter_on(comm_trsmter_on),
													.rspns(rspns_to_transmit),
													.rspns_read(rspns_read),
													.tx_machine_on(comm_dac_on),
													.com_dac(COM_DAC_D));
	
	nios u0 (
        .clk_clk                 (clk_20MHz),					//             clk.clk
        .nios_data_ready_export  (data_from_nios_ready),		// nios_data_ready.export
        .niosinbuff_writedata    (data_to_nios),				//      niosinbuff.writedata
        .niosinbuff_write        (data_to_nios_write),		//                .write
        .niosoutbuff_readdata    (data_from_nios),				//     niosoutbuff.readdata
        .niosoutbuff_read        (data_from_nios_read),		//                .read
        .niosoutbuff_waitrequest (data_from_nios_wait),		//                .waitrequest
        .reset_reset_n           (1)								//           reset.reset_n
    );

	my_uart my_uart0(.inclk(clk_20MHz),
							.new_bit_enable(comm_receiver_O[0]), 
							.new_bit(comm_receiver_O[1]), 
							.decoding(comm_receiver_O[2]), 
							.start_byte_detected(comm_receiver_O[3]),
							.tx(EXT_UEXT1_10));
	 
endmodule
