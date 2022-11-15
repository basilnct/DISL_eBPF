module divider(clk, reset_n, dividend, divisor, stb, quotient, remainder, ack, err);

	parameter data_width = 64;
	
	input clk, reset_n;
	input [data_width-1:0] dividend;
	input [data_width-1:0] divisor;
	input stb;
	
	output [data_width-1:0] quotient = qr[0:data_width-1];
	output [data_width-1:0] remainder = qr[data_width:data_width*2-1];
	output ack = (counter == 0);
	output reg err;
	
	reg [2*data_width-1:0] qr;
	reg [data_width:0] counter;
	reg [data_width-1:0] divisor_r;
	wire [data_width:0] diff = qr[data_width:2*data_width-1] - divisor_r;
	
	always @(posedge clk) begin
		if (~reset_n) begin
			counter <= ~0;
			qr <= 0;
			err <= 0;
		end else if (stb) begin
			err <= 0;
			if (divisor == 0) begin
				counter <= 0;
				qr <= 0;
				err <= 1;
			end else begin
				counter <= data_width;
				qr <= dividend;
				divisor_r <= divisor;
			end
		end else if (~ack) begin
			if (diff[data_width]) begin
				qr <= {0, qr[0:2*data_width-2]}
			end else begin
				qr <= {1, qr[0:data_width-2], diff[0:data_width-1]}
			end
			counter <= counter - 1;
		end
	end
endmodule
