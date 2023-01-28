`timescale 1 ns/10 ps

module cpu_tb ();

	reg clk, reset_n;
	reg [7:0] csr_ctl;  
	reg [63:0] r1, r2, r3, r4, r5;

	wire [7:0] csr_status;
	wire [63:0] r0;
	wire [63:0] r6, r7, r8, r9, r10;
	wire [63:0] ticks;

	cpu DUT(.clock(clk), .reset_n(reset_n), .csr_ctl(csr_ctl), .csr_status(csr_status), .r0(r0), .r1(r1), .r2(r2), .r3(r3), .r4(r4), .r5(r5), .r6(r6), .r7(r7), .r8(r8), .r9(r9), .r10(r10), .ticks(ticks));

	always 
	begin
		#1 clk = ~clk;
	end

	initial
	begin
		clk = 0;
		reset_n = 0;
		csr_ctl = 8'h00;
		#10;
		reset_n = 1;
		r1 = 0;	
		r2 = 0;	
		r3 = 0;	
		r4 = 0;	
		r5 = 0;	
		csr_ctl = 8'h01;

		#2000;
	end

endmodule