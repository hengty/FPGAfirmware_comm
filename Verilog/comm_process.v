//Take decoded packets from comm_receiver, bit by bit in real time. Look at packet, prepare appropriate reponse packet. If the packet is not of type DOR control, write the packet header and any following data to niosInbuff upon successful decoding.
//Monitor buffer from Nios. If not empty, read it in, send a data packet on the next opportunity.
//Most of the time, the packet will be DOR Control: data read request. The default response to that packet will be DOR Control: data read request acknowledge, no data.
//ty@wisc.edu
//Last update: Jan 04, 2018

`timescale 1ns / 100ps

module comm_process(
					input            comm_dac_on,
					input            inclk,
					input            new_bit_enable,
					input            new_bit,
					input            start_byte_detected,
					input            decoding_success,
					output reg[31:0] data_to_nios,
					output reg       data_to_nios_write,
					input            data_from_nios_ready,
					input     [31:0] data_from_nios,
					output           data_from_nios_read,
					input            data_from_nios_wait,
					output           transmitter_on,
					input            rspns_read,	//(has been "red")
					output reg[31:0] rspns_to_transmit
					);
					
	//---Parameters and Constants---------------------------------------------------------------------
	
	//Packet type
	localparam[2:0] data        = 3'b000;
	localparam[2:0] ack         = 3'b001;
	localparam[2:0] data_end    = 3'b010;
	localparam[2:0] control     = 3'b011;
	localparam[2:0] init_conn   = 3'b100;
	localparam[2:0] conn_intd   = 3'b101;
	localparam[2:0] dor_control = 3'b110;
	//localparam[2:0] (not_used)  = 3'b111;
	
	//DOR Control message Types
	//localparam[3:0] (not_used)           = 3'b0001;
	//localparam[3:0] not_used             = 3'b0010;
	localparam[3:0] dom_id_req           = 4'b0011;
	//localparam[3:0] (not_used)           = 3'b0100;
	localparam[3:0] data_read_req        = 4'b0101;
	localparam[3:0] data_req_ack_no_data = 4'b0110;
	localparam[3:0] dom_reboot           = 4'b0111;
	localparam[3:0] more_rx_buff         = 4'b1000;
	localparam[3:0] no_more_rx_buff      = 4'b1001;
	localparam[3:0] crc_error            = 4'b1010;
	localparam[3:0] comm_chan_reset      = 4'b1011;
	localparam[3:0] dom_rx_buf_stat_req  = 4'b1100;
	localparam[3:0] dom_softboot         = 4'b1101;
	localparam[3:0] tcal                 = 4'b1110;
	localparam[3:0] idle                 = 4'b1111;
	
	//---End of parameters and Constants--------------------------------------------------------------
	
	reg my_dom_type = 0;		//0 is type B. 1 is type A.
	
	//map of packet header
	reg[31:0] packet_header;
	wire[11: 0] packet_len    = packet_header[11: 0];
	wire[ 2: 0] packet_type   = packet_header[14:12];
	//wire        packet_chan   = packet_header[15];		//0 is for DOM B. 1 is for DOM A.
	//wire[15: 0] packet_seqn   = packet_header[31:16];
	wire[ 3: 0] pkt_dorcntrl  = packet_header[27:24];
	//wire        pkt_boot_stat = packet_header[28];
	//wire[ 1: 0] pkt_sgnl_req  = packet_header[31:30];
	wire data_packet = (packet_type == data_end) || (packet_type == data);
	
	//for reading in new_bit
	reg       processing;
	reg[ 1:0] start_byte_det_mon;
	reg[15:0] new_bit_num;
	
	//for nios data control
	reg [255:0] databuffer;
	reg   [7:0] num_bits_buffd;
	wire  [2:0] num_words_buffd = num_bits_buffd[7:5];
	wire  [4:0] num_bytes_buffd = {num_words_buffd,2'b0};	//num_words_buffd*4
	reg   [2:0] num_words_sent;
	reg         data_from_nios_acqd;
	assign data_from_nios_read = (data_from_nios_acqd !== 1);

	//response headers
	reg        boot_state = 0;		//0 is Configboot
	reg [ 1:0] signal_req = 2'b00;  //(2'b10 : "Up")
	reg [31:0] rspns_header;
	wire[11:0] rspns_data_len  = rspns_header[11:0];
	wire       pkt_is_dorcntrl = (packet_type == dor_control);
	wire[31:0] msg_recv_header = {signal_req, 1'b0, boot_state, more_rx_buff, 8'b00000000, my_dom_type, dor_control, 12'b000000000000};
	wire[31:0] dom_id_header   = {16'b0000000100000010, my_dom_type, data, 12'b000000001000};	//data length: 8 bytes
	wire[31:0] idle_header     = {signal_req, 1'b0, boot_state, idle, 8'b00000000, my_dom_type, dor_control, 12'b000000000000};
	wire[31:0] no_data_header  = {signal_req, 1'b0, boot_state, data_req_ack_no_data, 8'b00000000, my_dom_type, dor_control, 12'b000000000000};
	
	//comm_transmitter control
	reg       rspns_header_ready;
	reg       responding;
	reg[11:0] num_words_trsmttd;
	assign transmitter_on = responding; //Turns on comm_transmitter when responding
	
	always@(posedge inclk)
	begin
	
		//reading from nios buffer
		if(data_from_nios_read && (data_from_nios_wait === 0)) data_from_nios_acqd <= 1;
		
		//writing to nios buffer
		if(data_to_nios_write) begin
			data_to_nios       <= databuffer[32*num_words_sent +:32];
			num_words_sent     <= num_words_sent + 1'b1;
			data_to_nios_write <= (num_words_sent < num_words_buffd); end
	
		//processing state machine
		if(processing !== 1) begin
			start_byte_det_mon    <= start_byte_det_mon << 1;
			start_byte_det_mon[0] <= start_byte_detected;
			if(start_byte_det_mon == 2'b01) begin
				processing        <= 1;
				new_bit_num       <= 0;
				num_words_trsmttd <= 0;
				responding        <= 0;
			end
		end
		if(processing) begin
			if(new_bit_enable && (comm_dac_on !== 1)) begin
				new_bit_num <= new_bit_num + 1'b1;
				if(new_bit_num < 32) packet_header[new_bit_num] <= new_bit;		//Record the first 32 bits to packet_header[31:0]
				if(new_bit_num == 15) processing <= (my_dom_type == new_bit);	//Go back to Idle if the packet is not intended for this DOM
				if(new_bit_num == 31) begin
					if(packet_len == 12'b0) num_bits_buffd <= 0;
					if(!pkt_is_dorcntrl) rspns_header <= msg_recv_header;
					if( pkt_is_dorcntrl)
						case(pkt_dorcntrl)
						dom_id_req     :rspns_header <= dom_id_header;
						data_read_req  :if(data_from_nios_acqd && data_from_nios_ready) begin
											rspns_header        <= {data_from_nios[31:16], my_dom_type, data_from_nios[14:0]};
											data_from_nios_acqd <= 0; end
										else rspns_header <= no_data_header;
						comm_chan_reset:rspns_header <= idle_header;
						idle           :rspns_header <= idle_header; endcase
					rspns_header_ready <= 1; end
				if(new_bit_num >= 32 && data_packet && num_bytes_buffd < packet_len) begin			//If processing a data packet, write to data buffer
					databuffer[num_bits_buffd] <= new_bit;							//Start writing at bit 33th
					           num_bits_buffd  <= num_bits_buffd + 1'b1; end end	//Stop when number of bytes written equals or exceeds packet_header[11: 0]
			if(decoding_success && rspns_header_ready) begin
			    rspns_to_transmit  <= rspns_header;
				rspns_header_ready <= 0;
				responding         <= 1;
				if(!pkt_is_dorcntrl) begin
					data_to_nios       <= packet_header;
					num_words_sent     <= 0;
					data_to_nios_write <= 1; end end
			if(responding && rspns_read) begin					//Handle "read" signal from comm_transmitter
				if(num_words_trsmttd >= rspns_data_len) begin
					responding <= 0;			//Turn off transmitter
					processing <= 0; end		//Stop processing, go back to Idle
				if(num_words_trsmttd < rspns_data_len) begin
					if(rspns_header == dom_id_header) rspns_to_transmit <= 32'b0;
					else begin
						data_from_nios_acqd <= 0;
						rspns_to_transmit   <= data_from_nios; end
					num_words_trsmttd <= num_words_trsmttd + 3'b100; end end
			//---------------------------------------------------------------------------	
		end
	end
	
endmodule