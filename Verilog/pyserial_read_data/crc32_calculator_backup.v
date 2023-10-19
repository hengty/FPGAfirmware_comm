//ty@wisc.edu
//This verilog module to calculate crc32 of com data between DOM and DOMHub

module crc32(new_bit, data_in, data_out);
	input new_bit; //1MHz clock, posedge is start of new bit
	input data_in;
	output[31:0] data_out;
	//output data_out_ready;
	
	reg[31:0] crc32poly = 32'b00000100110000010001110110110111; //Standard crc32 without the 33th bit
	reg[31:0] rmder = 32'b11111111111111111111111111111111;
	assign data_out = rmder;
	
	always@(posedge new_bit)
	begin
		rmder[0]    <=     data_in^(crc32poly[0]   &rmder[31]);
		rmder[31:1] <= rmder[30:0]^(crc32poly[31:1]&{31{rmder[31]}});
		
	end
	
endmodule