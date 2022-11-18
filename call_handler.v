module call_handler(
	input [63:0] func,
	input clk, stb,
	output reg IP4_led, IPv6_led, pkt_err_led
	);

// -------64 Bits Registers-------
reg [63:0] r1;
reg [63:0] r2;
reg [63:0] r3;
reg [63:0] r4;
reg [63:0] r5;
reg [63:0] ret;

// -------Status-------
reg ack = 0;
reg err = 0;

// -------Memory-------
wire [63:0] address = r1; 
wire [63:0] data_r;
wire [63:0] data_w = r2;
reg write_enable;
wire we = write_enable;

module memory #(data_size = 64, address_size = 5) call_handler_mem(.address(address), .data_in(data_w), .data_out(data_r), .write_enable(we), .clk(clk))
reg wait = 0;

// -------Sync Logic-------
always @(posedge clk) begin
	if (stb) begin
		case(func)
			// Extension to set IP4, IPv6 or packet error LED based on R1 bits 0 - 2
			0xff000001: begin
				IP4_led <= r1[0];
				IPv6_led <= r1[1];
				pkt_err_led <= r1[2];
				ack <= 1;
			end

			// Extension to store some values
			0xff000002: begin
				if (~write_enable) begin
					write_enable <= 1;

				end else begin
					if (~wait) begin
						wait <= 1;
					end else begin
						wait <= 0;
						write_enable <= 0;
						ack <= 1;
					end
				end
			end

			// Extension to read values from store
			0xff000003: begin
				if (~wait) begin
					wait <= 1;
				end else begin
					ret <= data_r;
					wait <= 0;
					ack <= 1;
				end
			end
			
			// Else throw an err
			default: begin
				err <= 1;
				ack <= 1;
			end
		endcase
	end else begin
		ack <= 0;
		err <= 0;
	end
end


endmodule
