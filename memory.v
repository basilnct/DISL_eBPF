module Memory(address, data_in, data_out, write_enable, clk);

	parameter data_size = 64;
	parameter address_size = 5;
	 
	parameter memory_depth = 2**address_size;  // do not specify this when using module
	 
	input [63:0] address;
	input [data_size-1:0] data_in;
	output [data_size-1:0] data_out;
	input write_enable;
	input clk;
	 
reg [data_size-1:0] mem [0:memory_depth-1];
assign data_out = mem [address[address_size+1:2]];

always @(posedge clk) begin
	case (write)
		1: mem[address[address_size+1:2]] = data_in;
	endcase
end

endmodule