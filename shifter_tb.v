`timescale 1 ns/10 ps

module shifter_tb ();

    // input
	reg stb, clk;
	reg arith;
	reg left;
	reg [63:0] value;
	reg [63:0] shift;

	// output
	wire [63:0] out;
	wire ack;

	shifter #(.data_width(64)) DUT(.stb(stb), .clk(clk), .arith(arith), .left(left), .value(value), .shift(shift), .out(out), .ack(ack));

	always 
	begin
		#1 clk = ~clk;
	end

	initial
	begin
		clk = 0;
		
		// test 1: 64'h1000 right shift 1
		#10;
		value = 64'h1000;
		shift = 1;
		stb = 1;
		arith = 1;
		left = 0;
		#2;
		stb = 0;
		#188;
		
		// test 2: 64'h1 right shift 1
		#10;
		value = 64'h1;
		shift = 1;
		stb = 1;
		arith = 1;
		left = 0;
		#2;
		stb = 0;
		#188;
		
		// test 3: 64'h8000000000000080 right shift 4
		#10;
		value = 64'h8000000000000080;
		shift = 4;
		stb = 1;
		arith = 1;
		left = 0;
		#2;
		stb = 0;
		#188;
		
		// test 3: 64'h8000000000000080 right shift 60
		#10;
		value = 64'h8000000000000000;
		shift = 60;
		stb = 1;
		arith = 1;
		left = 0;
		#2;
		stb = 0;
		#188;
		
		$finish;

	end

endmodule