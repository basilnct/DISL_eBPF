module cpu();

parameter MAX_REGS = 11;
parameter MAX_PGM_WORDS = 4096;
parameter MAX_DATA_WORDS = 2048;

// CPU States
parameter STATE_OP_FETCH = 0;
parameter STATE_DECODE = 1;
parameter STATE_DATA_FETCH = 2;
parameter STATE_DIV_PENDING = 3;
parameter STATE_CALL_PENDING = 4;
parameter STATE_HALT = 5;

// -------------clk rst----------------

input sys_clk;
input sys_rst;


// --------CSR (MMIO) Registers--------

// CPU Status register including all status flags
// bits: 0-rst_n, 1-halt, 2-error, 7-debug
output reg [7:0] r_status;

// Result Register R0
output reg [63:0] r0;

// Input Registers
input reg [63:0] r1;
input reg [63:0] r2;
input reg [63:0] r3;
input reg [63:0] r4;
input reg [63:0] r5;

// Output Registers
output reg [63:0] r6;
output reg [63:0] r7;
output reg [63:0] r8;
output reg [63:0] r9;
output reg [63:0] r10;

// clock ticks between resest going high and halt going high
output reg [63:0] ticks;

// Control register for CPU
// bits: 0-rst_n
input reg [7:0] r_ctl;

// Create register bank with direct accessors for each register in bank.


// ----------Call Handler--------------
call_handler call_handler(.func(), .clk(), .stb(), .IP4_led(), .IPv6_led(), .pkt_err_led.());


reg reset_n_int;
reg [2:0] state;	// 6 possible state, so 3 bits required
reg [2:0] state_next;
reg data_ack, div64_ack;



// Represents an ebpf instruction.
// See https://www.kernel.org/doc/Documentation/networking/filter.txt
// for more information.

// Layout of an ebpf instruction. VM internally works with
// little-endian byte-order.

// MSB                                                        LSB
// +------------------------+----------------+----+----+--------+
// |immediate               |offset          |src |dst |opcode  |
// +------------------------+----------------+----+----+--------+
// 63                     32               16   12    8        0

        

reg [63:0] instruction;
reg [7:0] opcode;
reg [2:0] opclass;
reg [3:0] dst;
reg [3:0] src;
reg [15:0] offset;
reg signed [15:0] offset_s;
reg [31:0] immediate;
reg signed [31:0] immediate_s;
reg [7:0] keep_op;
reg [3:0] keep_dst;

reg [63:0] src_reg;
reg signed [63:0] src_reg_s;
reg [31:0] src_reg_32;
reg signed [31:0] src_reg_32_s;

reg [63:0] dst_reg;
reg signed [63:0] dst_reg_s;
reg [31:0] dst_reg_32;
reg signed [31:0] dst_reg_32_s;

reg [31:0] ip;
reg [31:0] ip_next;

// --------Program Memory--------
// max program memory words is 4096 = 2^12
module memory #(data_size = 64, address_size = 12) pgm(.address(), .data_in(), .data_out(), .write_enable(), .clk(clk));

// -------Data Memory (e.g Packet Data)-------
// max program memory words is 2048 = 2^11
module memory #(data_size = 64, address_size = 11) data_mem(.address(), .data_in(), .data_out(), .write_enable(), .clk(clk));

// -------64 Bit Math Divider-------
module

// -------64 Bit Logic and Arithmetic Shifter-------
module

// MSB                                                        LSB
// | Byte 8 | Byte 7  | Byte 5-6       | Byte 1-4               |
// +--------+----+----+----------------+------------------------+
// |opcode  | src| dst|          offset|               immediate|
// +--------+----+----+----------------+------------------------+
// 63     56   52   48               32                        0






// state machine example

module state_machine(clk, rst, read, data_out);

reg [3:0] state, next_state;
parameter S0=4'b0001, S1=4'b0010, S2=4'b0100, S3=4'b1000;
always @(posedge clk)
	begin 
		case(state)
		S0: begin
			if (rst)						next_state<=S3;
			else if (read)					next_state<=S1;
			else 							next_state<=S0; end
		S1: begin data_out<=ram_data[P];	next_state<=S2; end
		S2: begin p<=p+1;					next_state<=S0; end
		S3: begin p<=0;						next_state<=S0; end
		default: next_state<=S0
		endcase
	end
always @(posedge clk) state<=next_state;
endmodule
		