`timescale 1 ns/10 ps

module divider_tb ();

	// input
	reg clk, reset_n;
	reg [63:0] dividend;
	reg [63:0] divisor;
	reg stb;

	// output
	wire [63:0] quotient;
	wire [63:0] remainder;
	wire ack, err;

	divider #(.data_width(64)) DUT(.clk(clk), .reset_n(reset_n), .dividend(dividend), .divisor(divisor), .stb(stb), .quotient(quotient), .remainder(remainder), .ack(ack), .err(err));
	
	always 
	begin
		#1 clk = ~clk;
	end

	initial
	begin
		clk = 0;
		
		// test 1: 13 div 2
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 13;
		divisor = 2;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 2: 8 div 2
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 8;
		divisor = 2;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 3: 42 div 7
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 42;
		divisor = 7;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 4: 23 div 9
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 23;
		divisor = 9;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 5: 88 div 6
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 88;
		divisor = 6;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 6: 255 div 2
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 255;
		divisor = 2;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 7: 255 div 3
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 255;
		divisor = 3;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 8: 255 div 4
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 255;
		divisor = 4;
		stb = 1;
		#4;
		stb = 0;
		#176;


		// Special Case

		// test 1: 4 div 8
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 4;
		divisor = 8;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 2: 3 div 3
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 3;
		divisor = 3;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 3: 3 div 0
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 3;
		divisor = 0;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 4: 0 div 0
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 0;
		divisor = 0;
		stb = 1;
		#4;
		stb = 0;
		#176;

		// test 5: 0 div 2
		reset_n = 0;
		#10;
		reset_n = 1;
		#10;
		dividend = 0;
		divisor = 2;
		stb = 1;
		#4;
		stb = 0;
		#176;
		
		$finish;
	end

endmodule
