module data_memory(stb, adr, we, ww, dat_w, clk, dat_r, data_ack);

	parameter data_size = 64;
	parameter address_size = 11;
	 
	parameter memory_depth = 2**address_size;  // do not specify this when using module

	// inputs
	input stb;
	input [address_size-1:0] adr;
	input we;
	input [3:0] ww;
	input [data_size-1:0] dat_w;
	input clk;

	// outputs
	output [63:0] dat_r;
	output data_ack;
	

	//
	reg [data_size-1:0] mem [0:memory_depth-1];
	assign data_r = mem [adr];

	always @(posedge clk) begin
		case (we)
			1: mem [adr] = dat_w;
		endcase
	end


endmodule