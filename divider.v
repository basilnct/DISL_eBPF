module divider(clk, reset_n, dividend, divisor, stb, quotient, remainder, ack, err);

	parameter data_width = 64;
	
	input clk, reset_n;
	input [data_width-1:0] dividend;
	input [data_width-1:0] divisor;
	input stb;
	
	reg [2*data_width-1:0] qr;
	reg [data_width:0] counter;
	reg [data_width-1:0] divisor_r;
	wire [data_width:0] diff = qr[2*data_width-1:data_width-1] - divisor_r;
	
	output [data_width-1:0] quotient;
	output [data_width-1:0] remainder;
	output ack;
	output reg err;
	
	assign quotient = qr[data_width-1:0];
	assign remainder = qr[data_width*2-1:data_width];
	assign ack = (counter == 0);
	
	always @(posedge clk) begin
		if (~reset_n) begin
			counter <= ~0;
			qr <= 0;
			err <= 0;
		end 
		else begin
		    if (stb) begin
			    if (divisor == 0) begin
                    counter <= 0;
                    qr <= 0;
                    err <= 1;
                end 
                else begin
                    counter <= data_width;
                    qr <= dividend;
                    divisor_r <= divisor;
                    err <= 0;
                end
            end else if (~(counter == 0)) begin
                if (diff[data_width]) begin
                    qr <= {qr[2*data_width-2:0], 1'b0};
                end 
                else begin
                    qr <= {diff[data_width-1:0], qr[data_width-2:0], 1'b1};
                end
                counter <= counter - 1;
            end
        end
	end
endmodule