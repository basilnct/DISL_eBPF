module memory(address, data_in, data_out, write_enable, clk);

	parameter data_size = 64; 
	parameter address_size = 12;
	parameter memory_depth = 2**address_size;  // do not specify this when using module
	 
	input [address_size-1:0] address;
	input [data_size-1:0] data_in;
	output [data_size-1:0] data_out;
	input write_enable;
	input clk;
	 
	reg [data_size-1:0] mem [0:memory_depth-1];
	assign data_out = mem [address];

	always @(posedge clk) begin
		case (write_enable)
			1: mem [address] = data_in;
		endcase
	end
	
	// testing
	// MSB                                                        LSB
    // | Byte 8 | Byte 7  | Byte 5-6       | Byte 1-4               |
    // +--------+----+----+----------------+------------------------+
    // |opcode  | src| dst|          offset|               immediate|
    // +--------+----+----+----------------+------------------------+
    // 63     56   52   48               32                        0
    
  initial begin
    // jeq-imm.test
    // mov32 r6, 0
    mem [0] = {8'hb4, 8'h08, 16'h0000, 32'h00000000};
    // mov32 r7, 0xa
    mem [1] = {8'hb4, 8'h07, 16'h0000, 32'h0000000a};
    // jeq r7, 0xb, +4 # Not taken
    mem [2] = {8'h15, 8'h07, 16'h0004, 32'h0000000b};
    // mov32 r6, 0
    mem [3] = {8'hb4, 8'h08, 16'h0000, 32'h00000000};
    // mov32 r7, 0xb
    mem [4] = {8'hb4, 8'h07, 16'h0000, 32'h0000000b};
    // jeq r7, 0xb, +1 # Taken
    mem [5] = {8'h15, 8'h77, 16'h0001, 32'h0000000b};
    // mov32 r6, 2 # Skipped
    mem [6] = {8'hb4, 8'h08, 16'h0000, 32'h00000002};
    // exit
    mem [7] = {8'h95, 8'h00, 16'h0000, 32'h00000000}; 
  end
endmodule