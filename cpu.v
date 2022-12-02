module cpu();

// -------------Parameters----------------

parameter MAX_REGS = 11;
parameter MAX_PGM_WORDS = 4096;
parameter MAX_DATA_WORDS = 2048;
parameter MAX_STACK = 512;

// Max values for unsigned int
parameter MAX_UINT8  = 8'hff;
parameter MAX_UINT16 = 16'hffff;
parameter MAX_UINT32 = 32'hffffffff;
parameter MAX_UINT64 = 64'hffffffffffffffff;

// CPU States
parameter STATE_OP_FETCH = 0;
parameter STATE_DECODE = 1;
parameter STATE_DATA_FETCH = 2;
parameter STATE_DIV_PENDING = 3;
parameter STATE_CALL_PENDING = 4;
parameter STATE_HALT = 5;

//  +----------------+--------+--------------------+
//  |   4 bits       |  1 bit |   3 bits           |
//  | operation code | source | instruction class  |
//  +----------------+--------+--------------------+
//  (MSB)                                      (LSB)

// OpCode Classes
parameter OPC_LD    = 8'h00;    // load from immediate
parameter OPC_LDX   = 8'h01;    // load from register
parameter OPC_ST    = 8'h02;    // store immediate
parameter OPC_STX   = 8'h03;    // store value from register
parameter OPC_ALU   = 8'h04;    // 32 bits arithmetic operation
parameter OPC_JMP   = 8'h05;    // jump
parameter OPC_RES   = 8'h06;    // unused, reserved for future use
parameter OPC_ALU64 = 8'h07;    // 64 bits arithmetic operation

// Operation codes (OPC_ALU or OPC_ALU64).
parameter ALU_ADD  = 8'h00;     // addition
parameter ALU_SUB  = 8'h01;     // subtraction
parameter ALU_MUL  = 8'h02;     // multiplication
parameter ALU_DIV  = 8'h03;     // division
parameter ALU_OR   = 8'h04;     // or
parameter ALU_AND  = 8'h05;     // and
parameter ALU_LSH  = 8'h06;     // left shift
parameter ALU_RSH  = 8'h07;     // right shift
parameter ALU_NEG  = 8'h08;     // negation
parameter ALU_MOD  = 8'h09;     // modulus
parameter ALU_XOR  = 8'h0a;     // exclusive or
parameter ALU_MOV  = 8'h0b;     // move
parameter ALU_ARSH = 8'h0c;     // sign extending right shift
parameter ALU_ENDC = 8'h0d;     // endianess conversion

//  +--------+--------+-------------------+
//  | 3 bits | 2 bits |   3 bits          |
//  |  mode  |  size  | instruction class |
//  +--------+--------+-------------------+
//  (MSB)                             (LSB)

// Load/Store Modes
parameter LDST_IMM  = 8'h00;    // immediate value
parameter LDST_ABS  = 8'h01;    // absolute
parameter LDST_IND  = 8'h02;    // indirect
parameter LDST_MEM  = 8'h03;    // load from / store to memory
                   // 8'h04;    // reserved
                   // 8'h05;    // reserved
parameter LDST_XADD = 8'h06;    // exclusive add

// Sizes
parameter LEN_W   = 8'h00;      // word (4 bytes)
parameter LEN_H   = 8'h01;      // half-word (2 bytes)
parameter LEN_B   = 8'h02;      // byte (1 byte)
parameter LEN_DW  = 8'h03;      // double word (8 bytes)

parameter EBPF_SIZE_W    = LEN_W  << 3; // 0x00
parameter EBPF_SIZE_H    = LEN_H  << 3; // 0x08
parameter EBPF_SIZE_B    = LEN_B  << 3; // 0x10
parameter EBPF_SIZE_DW   = LEN_DW << 3; // 0x18

// Operation codes (OPC_JMP)
parameter JMP_JA   = 8'h00;     // jump
parameter JMP_JEQ  = 8'h01;     // jump if equal
parameter JMP_JGT  = 8'h02;     // jump if greater than
parameter JMP_JGE  = 8'h03;     // jump if greater or equal
parameter JMP_JSET = 8'h04;     // jump if `src`& `reg`
parameter JMP_JNE  = 8'h05;     // jump if not equal
parameter JMP_JSGT = 8'h06;     // jump if greater than (signed)
parameter JMP_JSGE = 8'h07;     // jump if greater or equal (signed)
parameter JMP_CALL = 8'h08;     // helper function call
parameter JMP_EXIT = 8'h09;     // return from program
parameter JMP_JLT  = 8'h0a;     // jump if lower than
parameter JMP_JLE  = 8'h0b;     // jump if lower ir equal
parameter JMP_JSLT = 8'h0c;     // jump if lower than (signed)
parameter JMP_JSLE = 8'h0d;     // jump if lower or equal (signed)

// Sources
parameter JMP_K    = 8'h00;     // 32-bit immediate value
parameter JMP_X    = 8'h01;     // `src` register

parameter EBPF_SRC_IMM       = 8'h00;
parameter EBPF_SRC_REG       = 8'h08;

parameter EBPF_MODE_IMM      = 8'h00;
parameter EBPF_MODE_MEM      = 8'h60;

parameter EBPF_OP_ADD        = ALU_ADD << 4;
parameter EBPF_OP_SUB        = ALU_SUB << 4;
parameter EBPF_OP_MUL        = ALU_MUL << 4;
parameter EBPF_OP_DIV        = ALU_DIV << 4;
parameter EBPF_OP_OR         = ALU_OR << 4;
parameter EBPF_OP_AND        = ALU_AND << 4;
parameter EBPF_OP_LSH        = ALU_LSH << 4;
parameter EBPF_OP_RSH        = ALU_RSH << 4;
parameter EBPF_OP_MOD        = ALU_MOD << 4;
parameter EBPF_OP_XOR        = ALU_XOR << 4;
parameter EBPF_OP_MOV        = ALU_MOV << 4;
parameter EBPF_OP_ARSH       = ALU_ARSH << 4;

parameter EBPF_OP_ADD_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_ADD);
parameter EBPF_OP_ADD_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_ADD);
parameter EBPF_OP_SUB_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_SUB);
parameter EBPF_OP_SUB_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_SUB);
parameter EBPF_OP_MUL_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_MUL);
parameter EBPF_OP_MUL_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_MUL);
parameter EBPF_OP_DIV_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_DIV);
parameter EBPF_OP_DIV_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_DIV);
parameter EBPF_OP_OR_IMM     = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_OR);
parameter EBPF_OP_OR_REG     = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_OR);
parameter EBPF_OP_AND_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_AND);
parameter EBPF_OP_AND_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_AND);
parameter EBPF_OP_LSH_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_LSH);
parameter EBPF_OP_LSH_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_LSH);
parameter EBPF_OP_RSH_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_RSH);
parameter EBPF_OP_RSH_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_RSH);
parameter EBPF_OP_NEG        = (OPC_ALU|8'h80);
parameter EBPF_OP_MOD_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_MOD);
parameter EBPF_OP_MOD_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_MOD);
parameter EBPF_OP_XOR_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_XOR);
parameter EBPF_OP_XOR_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_XOR);
parameter EBPF_OP_MOV_IMM    = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_MOV);
parameter EBPF_OP_MOV_REG    = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_MOV);
parameter EBPF_OP_ARSH_IMM   = (OPC_ALU|EBPF_SRC_IMM|EBPF_OP_ARSH);
parameter EBPF_OP_ARSH_REG   = (OPC_ALU|EBPF_SRC_REG|EBPF_OP_ARSH);
parameter EBPF_OP_LE         = (OPC_ALU|EBPF_SRC_IMM|8'hd0);
parameter EBPF_OP_BE         = (OPC_ALU|EBPF_SRC_REG|8'hd0);

parameter EBPF_OP_ADD64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_ADD);
parameter EBPF_OP_ADD64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_ADD);
parameter EBPF_OP_SUB64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_SUB);
parameter EBPF_OP_SUB64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_SUB);
parameter EBPF_OP_MUL64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_MUL);
parameter EBPF_OP_MUL64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_MUL);
parameter EBPF_OP_DIV64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_DIV);
parameter EBPF_OP_DIV64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_DIV);
parameter EBPF_OP_OR64_IMM   = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_OR);
parameter EBPF_OP_OR64_REG   = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_OR);
parameter EBPF_OP_AND64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_AND);
parameter EBPF_OP_AND64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_AND);
parameter EBPF_OP_LSH64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_LSH);
parameter EBPF_OP_LSH64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_LSH);
parameter EBPF_OP_RSH64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_RSH);
parameter EBPF_OP_RSH64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_RSH);
parameter EBPF_OP_NEG64      = (OPC_ALU64|8'h80);
parameter EBPF_OP_MOD64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_MOD);
parameter EBPF_OP_MOD64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_MOD);
parameter EBPF_OP_XOR64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_XOR);
parameter EBPF_OP_XOR64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_XOR);
parameter EBPF_OP_MOV64_IMM  = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_MOV);
parameter EBPF_OP_MOV64_REG  = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_MOV);
parameter EBPF_OP_ARSH64_IMM = (OPC_ALU64|EBPF_SRC_IMM|EBPF_OP_ARSH);
parameter EBPF_OP_ARSH64_REG = (OPC_ALU64|EBPF_SRC_REG|EBPF_OP_ARSH);

parameter EBPF_OP_LDXW       = (OPC_LDX|EBPF_MODE_MEM|EBPF_SIZE_W);
parameter EBPF_OP_LDXH       = (OPC_LDX|EBPF_MODE_MEM|EBPF_SIZE_H);
parameter EBPF_OP_LDXB       = (OPC_LDX|EBPF_MODE_MEM|EBPF_SIZE_B);
parameter EBPF_OP_LDXDW      = (OPC_LDX|EBPF_MODE_MEM|EBPF_SIZE_DW);
parameter EBPF_OP_STW        = (OPC_ST|EBPF_MODE_MEM|EBPF_SIZE_W);
parameter EBPF_OP_STH        = (OPC_ST|EBPF_MODE_MEM|EBPF_SIZE_H);
parameter EBPF_OP_STB        = (OPC_ST|EBPF_MODE_MEM|EBPF_SIZE_B);
parameter EBPF_OP_STDW       = (OPC_ST|EBPF_MODE_MEM|EBPF_SIZE_DW);
parameter EBPF_OP_STXW       = (OPC_STX|EBPF_MODE_MEM|EBPF_SIZE_W);
parameter EBPF_OP_STXH       = (OPC_STX|EBPF_MODE_MEM|EBPF_SIZE_H);
parameter EBPF_OP_STXB       = (OPC_STX|EBPF_MODE_MEM|EBPF_SIZE_B);
parameter EBPF_OP_STXDW      = (OPC_STX|EBPF_MODE_MEM|EBPF_SIZE_DW);
parameter EBPF_OP_LDDW       = (OPC_LD|EBPF_MODE_IMM|EBPF_SIZE_DW);

parameter EBPF_OP_JEQ        = JMP_JEQ << 4;
parameter EBPF_OP_JGT        = JMP_JGT << 4;
parameter EBPF_OP_JGE        = JMP_JGE << 4;
parameter EBPF_OP_JSET       = JMP_JSET << 4;
parameter EBPF_OP_JNE        = JMP_JNE << 4;
parameter EBPF_OP_JSGT       = JMP_JSGT << 4;
parameter EBPF_OP_JSGE       = JMP_JSGE << 4;
parameter EBPF_OP_JLT        = JMP_JLT << 4;
parameter EBPF_OP_JLE        = JMP_JLE << 4;
parameter EBPF_OP_JSLT       = JMP_JSLT << 4;
parameter EBPF_OP_JSLE       = JMP_JSLE << 4;

parameter EBPF_OP_JA         = (OPC_JMP|8'h00);
parameter EBPF_OP_JEQ_IMM    = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JEQ);
parameter EBPF_OP_JEQ_REG    = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JEQ);
parameter EBPF_OP_JGT_IMM    = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JGT);
parameter EBPF_OP_JGT_REG    = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JGT);
parameter EBPF_OP_JGE_IMM    = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JGE);
parameter EBPF_OP_JGE_REG    = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JGE);
parameter EBPF_OP_JSET_IMM   = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JSET);
parameter EBPF_OP_JSET_REG   = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JSET);
parameter EBPF_OP_JNE_IMM    = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JNE);
parameter EBPF_OP_JNE_REG    = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JNE);
parameter EBPF_OP_JSGT_IMM   = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JSGT);
parameter EBPF_OP_JSGT_REG   = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JSGT);
parameter EBPF_OP_JSGE_IMM   = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JSGE);
parameter EBPF_OP_JSGE_REG   = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JSGE);
parameter EBPF_OP_CALL       = (OPC_JMP|8'h80);
parameter EBPF_OP_EXIT       = (OPC_JMP|8'h90);
parameter EBPF_OP_JLT_IMM    = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JLT);
parameter EBPF_OP_JLT_REG    = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JLT);
parameter EBPF_OP_JLE_IMM    = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JLE);
parameter EBPF_OP_JLE_REG    = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JLE);
parameter EBPF_OP_JSLT_IMM   = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JSLT);
parameter EBPF_OP_JSLT_REG   = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JSLT);
parameter EBPF_OP_JSLE_IMM   = (OPC_JMP|EBPF_SRC_IMM|EBPF_OP_JSLE);
parameter EBPF_OP_JSLE_REG   = (OPC_JMP|EBPF_SRC_REG|EBPF_OP_JSLE);


// -------------Direct CPU Status and Control Signals----------------

input clk;
input reset_n;
input error;
input halt;
input debug;


// --------CSR (MMIO) Registers--------

// Control register for CPU
// bits: 0-reset_n
input [7:0] csr_ctl;
wire reset_n_int = (reset_n | csr_ctl[0]);

// CPU Status register including all status flags
// bits: 0-reset_n, 1-halt, 2-error, 7-debug
output [7:0] csr_status;
assign csr_status[0] = reset_n_int;
assign csr_status[1] = halt;
assign csr_status[2] = error;
assign csr_status[3] = 0;		// reserved
assign csr_status[4] = 0;		// reserved
assign csr_status[5] = 0;		// reserved
assign csr_status[6] = 0; 		// reserved
assign csr_status[7] = debug;

// Create register bank with direct accessors for each register in bank.
reg [63:0] regs [MAX_REGS-1:0];


// Result Register R0
output [63:0] r0 = regs[0];


// Input Registers (r1 - r5 are in sync block)
input [63:0] r1;
input [63:0] r2;
input [63:0] r3;
input [63:0] r4;
input [63:0] r5;


// Output Registers
output [63:0] r6 = regs[6];
output [63:0] r7 = regs[7];
output [63:0] r8 = regs[8];
output [63:0] r9 = regs[9];
output [63:0] r10 = regs[10];


// clock ticks between resest going high and halt going high
output reg [63:0] ticks;


// ------------FSM------------
reg [2:0] state;	// 6 possible state, so 3 bits required
reg [2:0] state_next;
reg cpu_data_ack, cpu_div64_ack;


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
wire [63:0] pgm_adr = ip_next;

reg [63:0] pgm_dat_r;

module memory #(data_size = 64, address_size = 12) pgm(.address(), .data_in(), .data_out(pgm_dat_r), .write_enable(), .clk(clock));


// -------Data Memory (e.g Packet Data)------- (WIP)
// max data memory words is 2048 = 2^11
reg data_stb;
wire data_stb_wire = data_stb;
wire [63:0] data_adr;
reg data_we;
wire data_we_wire = data_we;
wire data_ww;
wire [63:0] data_dat_w;

reg [63:0] data_dat_r;
reg [63:0] data_dat_r2;
reg [63:0] data_dat_r4;
reg [63:0] data_dat_r8;
reg data_ack;

module memory #(data_size = 64, address_size = 11) data_mem(.address(), .data_in(), .data_out(), .write_enable(), .clk(clock));


// -------64 Bit Math Divider-------
wire arsh64_stb, arsh64_arith, arsh64_left;
wire [63:0] arsh64_value;
wire [63:0] arsh64_shift;

reg [63:0] arsh64_out;
reg arsh64_ack;

module shifter #(data_width = 64) arsh64(.stb(arsh64_stb), .clk(clock), .arith(arsh64_arith), .left(arsh64_left), .value(arsh64_value), .shift(arsh64_shift), .out(arsh64_out), .ack(arsh64_ack));


// -------64 Bit Logic and Arithmetic Shifter -------
reg [63:0] div64_dividend;
wire [63:0] div64_dividend_wire = div64_dividend;
reg [63:0] div64_divisor;
wire [63:0] div64_divisor_wire = div64_divisor;
reg div64_stb;
wire div64_stb_wire = div64_stb;

reg [63:0] div64_quotient;
reg [63:0] div64_remainder;
reg div64_ack, div64_err;

module divider #(data_width = 64) div64(.clk(clock), .reset_n(reset_n_int), .dividend(div64_dividend), .divisor(div64_divisor), .stb(div64_stb), .quotient(div64_quotient), .remainder(div64_remainder), .ack(div64_ack), .err(div64_err));

// MSB                                                        LSB
// | Byte 8 | Byte 7  | Byte 5-6       | Byte 1-4               |
// +--------+----+----+----------------+------------------------+
// |opcode  | src| dst|          offset|               immediate|
// +--------+----+----+----------------+------------------------+
// 63     56   52   48               32                        0

// -------Call Handler------- (WIP)
wire [63:0] call_handler_func;
wire call_handler_stb;
wire [63:0] call_handler_r1, 
			call_handler_r2, 
			call_handler_r3, 
			call_handler_r4, 
			call_handler_r5;
reg [63:0] call_handler_ret;
reg call_handler_IP4_led, call_handler_IPv6_led, call_handler_pkt_err_led; 
reg call_handler_ack, call_handler_err;

module call_handler call_handler(.func(), .clk(), .stb(), .IP4_led(), .IPv6_led(), .pkt_err_led());


// -------Sync Logic-------

always @(posedge clock or posedge reset_n) begin
	if (~reset_n_int) begin
		ticks <= 0;
		error <= 0;
		halt  <= 0;

		ip_next <= 0;
		ip <= 0;
		instruction <= pgm_dat_r;
		state <= STATE_OP_FETCH;
		state_next <= STATE_OP_FETCH;

		keep_op <= 0;
		keep_dst <= 0;

		regs[0] <= 0;

		// r1 - r5 are used as input arguments and thus are not cleared
        // but set from CSR
		regs[1] <= r1;
		regs[2] <= r1;
		regs[3] <= r3;
		regs[4] <= r4;
		regs[5] <= r5;

		regs[6] <= 0;
		regs[7] <= 0;
		regs[8] <= 0;
		regs[9] <= 0;
	end 

	// If halt signal high, stop CPU
	else if (halt) begin
		state_next <= STATE_HALT;
	end 

	// Check invalid source register
	else if (src >= MAX_REGS) begin
		error <= 1;
		halt <= 1;
	end 

	// Check invalid destination register
	else if (src >= MAX_REGS) begin
		error <= 1;
		halt <= 1;
	end 

	// Check for incomplete LDDW instruction
	else if ((keep_op & instruction[56:64]) != 0) begin
		error <= 1;
		halt <= 1;
	end 

	// Process opcodes
	else begin
		ticks <= ticks + 1;

		regs[1] <= r1;
		regs[2] <= r2;
		regs[3] <= r3;
		regs[4] <= r4;
		regs[5] <= r5;

		case(state)

			// STATE_OP_FETCH
			STATE_OP_FETCH: begin
				ip_next <= ip_next + 1;
				ip <= ip_next;
				instruction <= pgm_dat_r;
				state_next <= STATE_DECODE;
			end // STATE_OP_FETCH

			// STATE_DECODE
			STATE_DECODE: begin
				keep_op <= 0;

				case(opclass)

					// OPC_LD
					OPC_LD: begin
						case(opcode)

							// EBPF_OP_LDDW
							EBPF_OP_LDDW: begin
								if (keep_op == 0) begin
									regs[dst] <= immediate;
                            		keep_op <= opcode;
                            		keep_dst <= dst;
								end
								else begin
									regs[dst][32:64] <= immediate;
								end
								ip_next <= ip_next + 1;
                        		ip <= ip_next;
                        		instruction <= pgm_dat_r;
							end // EBPF_OP_LDDW

							// default
							default: begin
								error <= 1;
								halt <= 1;
							end // default
						endcase // opcode
					end


					// OPC_LDX
					OPC_LDX: begin
						if (~cpu_data_ack) begin
							data_adr <= regs[src] + offset;
							state_next <= STATE_DATA_FETCH;
						end
						else begin

							case (opcode)

								// EBPF_OP_LDXB
								EBPF_OP_LDXB: begin
									regs[dst] <= data_dat_r;
								end // EBPF_OP_LDXB

								// EBPF_OP_LDXH
								EBPF_OP_LDXH: begin
									regs[dst] <= data_dat_r2;
								end // EBPF_OP_LDXH

								// EBPF_OP_LDXW
								EBPF_OP_LDXW: begin
									regs[dst] <= data_dat_r4;
								end // EBPF_OP_LDXW

								// EBPF_OP_LDXDW
								EBPF_OP_LDXDW: begin
									regs[dst] <= data_dat_r8;
								end // EBPF_OP_LDXDW

								// default
								default: begin
									error <= 1;
									halt <= 1;
								end // default
							endcase // opcode
							ip_next <= ip_next + 1;
							ip <= ip_next;
							instruction <= pgm_dat_r;
						end
					end // OPC_LDX


					// OPC_ST
					OPC_ST: begin
						if (~cpu_data_ack) begin
							data_adr <= regs[dst] + offset;
							data_we <= 1;

							case (opcode)

								// EBPF_OP_STB
								EBPF_OP_STB: begin
									data_ww <= 1;
									data_dat_w <= immediate[7:0];
								end // EBPF_OP_STB

								// EBPF_OP_STH
								EBPF_OP_STH: begin
									data_ww <= 2;
									data_dat_w <= immediate[15:0];
								end // EBPF_OP_STH

								// EBPF_OP_STW
								EBPF_OP_STW: begin
									data_ww <= 4;
									data_dat_w <= immediate[31:0];
								end // EBPF_OP_STW

								// EBPF_OP_STDW
								EBPF_OP_STDW: begin
									data_ww <= 8;
									data_dat_w <= immediate;
								end // EBPF_OP_STDW

								// default
								default: begin
									error <= 1;
									halt <= 1;
								end // default
							endcase // opcode
							state_next <= STATE_DATA_FETCH;
						end
						else begin
							ip_next <= ip_next + 1;
                            ip <= ip_next;
                            instruction <= pgm_dat_r;
						end
					end // OPC_ST


					// OPC_STX
					OPC_STX: begin
						if (~cpu_data_ack) begin
							data_adr <= regs[dst] + offset;
							data_we <= 1;

							case (opcode)

								// EBPF_OP_STXB
								EBPF_OP_STXB: begin
									data_ww <= 1;
									data_dat_w <= regs[src][7:0];
								end // EBPF_OP_STXB

								// EBPF_OP_STXH
								EBPF_OP_STXH: begin
									data_ww <= 2;
									data_dat_w <= regs[src][15:0];
								end // EBPF_OP_STXH

								// EBPF_OP_STXW
								EBPF_OP_STXW: begin
									data_ww <= 4;
									data_dat_w <= regs[src][31:0];
								end // EBPF_OP_STXW

								// EBPF_OP_STXDW
								EBPF_OP_STXDW: begin
									data_ww <= 8;
									data_dat_w <= regs[src];
								end // EBPF_OP_STXDW

								// default
								default: begin
									error <= 1;
									halt <= 1;
								end // default
							endcase // opcode
							next_state <= STATE_DATA_FETCH;
						end
						else begin
							ip_next <= ip_next + 1;
							ip <= ip_next;
							instruction <= pgm_dat_r;
						end
					end // OPC_STX


					// OPC_ALU
					OPC_ALU: begin
						cpu_div64_ack <= 0;

						case (opcode)

							// OP_DIV_IMM
							OP_DIV_IMM: begin
								if (~cpu_div64_ack) begin
									div64_dividend <= (regs[dst] & 32'hffffffff);
									div64_divisor <= (immediate & 32'hffffffff);
									state_next <= STATE_DIV_PENDING;
									div64_stb <= 1;
								end
								else begin
									regs[dst] <= div64_quotient;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
								end
							end // OP_DIV_IMM
						
							// EBPF_OP_DIV_REG
							EBPF_OP_DIV_REG: begin
								if (~div64_ack) begin
									div64_dividend <= (regs[dst] & 32'hffffffff);
									div64_divisor <= (regs[src] & 32'hffffffff);
									state_next <= STATE_DIV_PENDING;
									div64_stb <= 1;
								end
								else begin
									regs[dst] <= div64_quotient;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
								end
							end // EBPF_OP_DIV_REG

							// EBPF_OP_MOD_IMM
							EBPF_OP_MOD_IMM: begin
								if (~div64_ack) begin
									div64_dividend <= (regs[dst] & 32'hffffffff);
									div64_divisor <= (immediate & 32'hffffffff);
									state_next <= STATE_DIV_PENDING;
									div64_stb <= 1;
								end
								else begin
									regs[dst] <= div64_remainder;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
								end
							end // EBPF_OP_MOD_IMM

							// EBPF_OP_MOD_REG
							EBPF_OP_MOD_REG: begin
								if (~div64_ack) begin
									div64_dividend <= (regs[dst] & 32'hffffffff);
									div64_divisor <= (regs[src] & 32'hffffffff);
									state_next <= STATE_DIV_PENDING;
									div64_stb <= 1;
								end
								else begin
									regs[dst] <= div64_remainder;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_MOD_REG

							// EBPF_OP_ARSH_IMM
							EBPF_OP_ARSH_IMM: begin
								if (~arsh64_ack) begin
									arsh64_value <= { regs[dst][31:0], {32{regs[dst][31]}}};
									arsh64_shift <= immediate;
									arsh64_arith <= 1;
									arsh64_left <= 0;
									arsh64_stb <= 1;
								end
								else begin
									regs[dst] <= (arsh64_out  & 32'hffffffff);
									arsh64_stb <= 0;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_ARSH_IMM

							// EBPF_OP_ARSH_REG
							EBPF_OP_ARSH_REG: begin
								if (~arsh64_ack) begin
									arsh64_value <= { regs[dst][31:0], {32{regs[dst][31]}}};
									arsh64_shift <= (regs[src] & 32'hffffffff);
									arsh64_arith <= 1;
									arsh64_left <= 0;
									arsh64_stb <= 1;
								end
								else begin
									regs[dst] <= (arsh64_out  & 32'hffffffff);
									arsh64_stb <= 0;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_ARSH_REG

							// EBPF_OP_LSH_IMM
							EBPF_OP_LSH_IMM: begin
								if (~arsh64_ack) begin
									arsh64_value <= (regs[dst] & 32'hffffffff);
									arsh64_shift <= immediate;
									arsh64_arith <= 0;
									arsh64_left <= 1;
									arsh64_stb <= 1;
								end
								else begin
									regs[dst] <= (arsh64_out  & 32'hffffffff);
									arsh64_stb <= 0;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_LSH_IMM

							// EBPF_OP_LSH_REG
							EBPF_OP_LSH_REG: begin
								if (~arsh64_ack) begin
									arsh64_value <= (regs[dst] & 32'hffffffff);
									arsh64_shift <= (regs[src] & 32'hffffffff);
									arsh64_arith <= 0;
									arsh64_left <= 1;
									arsh64_stb <= 1;
								end
								else begin
									regs[dst] <= (arsh64_out  & 32'hffffffff);
									arsh64_stb <= 0;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_LSH_REG

							// EBPF_OP_RSH_IMM
							EBPF_OP_RSH_IMM: begin
								if (~arsh64_ack) begin
									arsh64_value <= (regs[dst] & 32'hffffffff);
									arsh64_shift <= immediate;
									arsh64_arith <= 0;
									arsh64_left <= 0;
									arsh64_stb <= 1;
								end
								else begin
									regs[dst] <= (arsh64_out  & 32'hffffffff);
									arsh64_stb <= 0;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_RSH_IMM

							// EBPF_OP_RSH_REG
							EBPF_OP_RSH_REG: begin
								if (~arsh64_ack) begin
									arsh64_value <= (regs[dst] & 32'hffffffff);
									arsh64_shift <= (regs[src] & 32'hffffffff);
									arsh64_arith <= 0;
									arsh64_left <= 0;
									arsh64_stb <= 1;
								end
								else begin
									regs[dst] <= (arsh64_out  & 32'hffffffff);
									arsh64_stb <= 0;
									ip_next <= ip_next + 1;
									ip <= ip_next;
									instruction <= pgm_dat_r;
							end // EBPF_OP_RSH_REG

							// default
							default: begin

								case (opcode)

									// EBPF_OP_ADD_IMM
									EBPF_OP_ADD_IMM: begin
										regs[dst] <= ((regs[dst] + immediate) & 32'hffffffff);
									end // EBPF_OP_ADD_IMM

									// EBPF_OP_ADD_REG
									EBPF_OP_ADD_REG: begin
										regs[dst] <= ((regs[dst] + regs[src]) & 32'hffffffff);
									end // EBPF_OP_ADD_REG

									// EBPF_OP_SUB_IMM
									EBPF_OP_SUB_IMM: begin
										regs[dst] <= ((regs[dst] + immediate) & 32'hffffffff);
									end // EBPF_OP_SUB_IMM

									// EBPF_OP_SUB_REG
									EBPF_OP_SUB_REG: begin
										regs[dst] <= ((regs[dst] - regs[src]) & 32'hffffffff);
									end // EBPF_OP_SUB_REG

									// EBPF_OP_MUL_IMM
									EBPF_OP_MUL_IMM: begin
										regs[dst] <= ((regs[dst] * immediate) & 32'hffffffff);
									end // EBPF_OP_MUL_IMM

									// EBPF_OP_MUL_REG
									EBPF_OP_MUL_REG: begin
										regs[dst] <= ((regs[dst] * regs[src]) & 32'hffffffff);
									end // EBPF_OP_MUL_REG

									// EBPF_OP_OR_IMM
									EBPF_OP_OR_IMM: begin
										regs[dst] <= ((regs[dst] | immediate) & 32'hffffffff);
									end // EBPF_OP_OR_IMM

									// EBPF_OP_OR_REG
									EBPF_OP_OR_REG: begin
										regs[dst] <= ((regs[dst] | regs[src]) & 32'hffffffff);
									end // EBPF_OP_OR_REG

									// EBPF_OP_AND_IMM
									EBPF_OP_AND_IMM: begin
										regs[dst] <= ((regs[dst] & immediate) & 32'hffffffff);
									end // EBPF_OP_AND_IMM

									// EBPF_OP_AND_REG
									EBPF_OP_AND_REG: begin
										regs[dst] <= ((regs[dst] & regs[src]) & 32'hffffffff);
									end // EBPF_OP_AND_REG

									// EBPF_OP_NEG
									EBPF_OP_NEG: begin
										regs[dst] <= ((-regs[dst]) & 32'hffffffff);
									end // EBPF_OP_NEG

									// EBPF_OP_XOR_IMM
									EBPF_OP_XOR_IMM: begin
										regs[dst] <= ((regs[dst] ^ immediate) & 32'hffffffff);
									end // EBPF_OP_XOR_IMM

									// EBPF_OP_XOR_REG
									EBPF_OP_XOR_REG: begin
										regs[dst] <= ((regs[dst] ^ regs[src]) & 32'hffffffff);
									end // EBPF_OP_XOR_REG

									// EBPF_OP_MOV_IMM
									EBPF_OP_MOV_IMM: begin
										regs[dst] <= immediate;
									end // EBPF_OP_MOV_IMM

									// EBPF_OP_MOV_REG
									EBPF_OP_MOV_REG: begin
										regs[dst] <= regs[src];
									end // EBPF_OP_MOV_REG

									// EBPF_OP_LE
									EBPF_OP_LE: begin

										case (immediate)

											// 16 bits EBPF_OP_LE
											16: begin
												regs[dst] <= {regs[dst][7:0], regs[dst][15:8]};
											end // 16 bits EBPF_OP_LE

											// 32 bits EBPF_OP_LE
											32: begin
												regs[dst] <= {regs[dst][7:0], regs[dst][15:8], regs[dst][23:16], regs[dst][31:24]};
											end // 32 bits EBPF_OP_LE

											// 64 bits EBPF_OP_LE
											64: begin
												regs[dst] <= {regs[dst][7:0], regs[dst][15:8], regs[dst][23:16], regs[dst][31:24], regs[dst][39:32], regs[dst][47:40], regs[dst][55:48], regs[dst][63:56]};
											end // 64 bits EBPF_OP_LE

											// default
											default: begin
												error <= 1;
												halt <= 1;
											end // default
											
										endcase			
									end // EBPF_OP_LE

									// EBPF_OP_BE
									EBPF_OP_BE: begin

										case (immediate)

											// 16 bits EBPF_OP_BE
											16: begin
												regs[dst] <= {regs[dst][15:8], regs[dst][7:0]};
											end // 16 bits EBPF_OP_BE

											// 32 bits EBPF_OP_BE
											32: begin
												regs[dst] <= {regs[dst][31:24], regs[dst][23:16], regs[dst][15:8], regs[dst][7:0]};
											end // 32 bits EBPF_OP_BE

											// 64 bits EBPF_OP_BE
											64: begin
												regs[dst] <= {regs[dst][63:56], regs[dst][55:48], regs[dst][47:40], regs[dst][39:32], regs[dst][31:24], regs[dst][23:16], regs[dst][15:8], regs[dst][7:0]};
											end // 64 bits EBPF_OP_BE

											// default
											default: begin
												error <= 1;
												halt <= 1;
											end // default
											
										endcase // immediate
									end // EBPF_OP_BE

									// default
									default: begin
										error <= 1;
										halt <= 1;
									end // default
								endcase // opcode
								ip_next <= ip_next + 1;
								ip <= ip_next;
								instruction <= pgm_dat_r;
							end // default
						endcase // opcode
					end // OPC_ALU


					// OPC_JMP
					OPC_JMP: begin
						case (opcode)

							// EBPF_OP_CALL
							EBPF_OP_CALL: begin
							end // EBPF_OP_CALL

							// default
							default: begin
								state_next <= STATE_OP_FETCH;
								case (opcode)

									// EBPF_OP_JA
									EBPF_OP_JA: begin
										ip_next <= (ip_next + offset_s);
									end // EBPF_OP_JA

									// EBPF_OP_JEQ_IMM
									EBPF_OP_JEQ_IMM: begin
										if (regs[dst] == immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JEQ_IMM

									// EBPF_OP_JEQ_REG
									EBPF_OP_JEQ_REG: begin
										if (regs[dst] == regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JEQ_REG

									// EBPF_OP_JGT_IMM
									EBPF_OP_JGT_IMM: begin
										if (regs[dst] > immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JGT_IMM

									// EBPF_OP_JGT_REG
									EBPF_OP_JGT_REG: begin
										if (regs[dst] > regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JGT_REG

									// EBPF_OP_JGE_IMM
									EBPF_OP_JGE_IMM: begin
										if (regs[dst] >= immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JGE_IMM

									// EBPF_OP_JGE_REG
									EBPF_OP_JGE_REG: begin
										if (regs[dst] >= regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JGE_REG

									// EBPF_OP_JSET_IMM
									EBPF_OP_JSET_IMM: begin
										if (regs[dst] & immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSET_IMM

									// EBPF_OP_JSET_REG
									EBPF_OP_JSET_REG: begin
										if (regs[dst] & regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSET_REG

									// EBPF_OP_JNE_IMM
									EBPF_OP_JNE_IMM: begin
										if (regs[dst] != immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JNE_IMM

									// EBPF_OP_JNE_REG
									EBPF_OP_JNE_REG: begin
										if (regs[dst] != regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JNE_REG

									// EBPF_OP_JSGT_IMM
									EBPF_OP_JSGT_IMM: begin
										if (dst_reg_32_s > immediate_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSGT_IMM

									// EBPF_OP_JSGT_REG
									EBPF_OP_JSGT_REG: begin
										if (dst_reg_32_s > src_reg_32_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSGT_REG

									// EBPF_OP_JSGE_IMM
									EBPF_OP_JSGE_IMM: begin
										if (dst_reg_32_s >= immediate_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSGE_IMM

									// EBPF_OP_JSGE_REG
									EBPF_OP_JSGE_REG: begin
										if (dst_reg_32_s >= src_reg_32_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSGE_REG

									// EBPF_OP_EXIT
									EBPF_OP_EXIT: begin
										halt <= 1;
									end // EBPF_OP_EXIT

									// EBPF_OP_JLT_IMM
									EBPF_OP_JLT_IMM: begin
										if (regs[dst] <= immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JLT_IMM

									// EBPF_OP_JLT_REG
									EBPF_OP_JLT_REG: begin
										if (regs[dst] <= regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JLT_REG

									// EBPF_OP_JLE_IMM
									EBPF_OP_JLE_IMM: begin
										if (regs[dst] < immediate) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JLE_IMM

									// EBPF_OP_JLE_REG
									EBPF_OP_JLE_REG: begin
										if (regs[dst] < regs[src]) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JLE_REG

									// EBPF_OP_JSLT_IMM
									EBPF_OP_JSLT_IMM: begin
										if (dst_reg_32_s < immediate_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSLT_IMM

									// EBPF_OP_JSLT_REG
									EBPF_OP_JSLT_REG: begin
										if (dst_reg_32_s < src_reg_32_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSLT_REG

									// EBPF_OP_JSLE_IMM
									EBPF_OP_JSLE_IMM: begin
										if (dst_reg_32_s <= immediate_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSLE_IMM

									// EBPF_OP_JSLE_REG
									EBPF_OP_JSLE_REG: begin
										if (dst_reg_32_s <= src_reg_32_s) begin
											ip_next <= (ip_next + offset_s);
										end
									end // EBPF_OP_JSLE_REG

									// default
									default: begin
										error <= 1;
										halt <= 1;
									end // default
								endcase // opcode
							end // default
						endcase // opcode
					end // OPC_JMP


					// OPC_RES
					OPC_RES: begin
						error <= 1;
						halt <= 1;
					end // OPC_RES


					// OPC_ALU64
					OPC_ALU64: begin
						cpu_div64_ack <= 0;
						case (opcode)
						
							EBPF_OP_DIV64_IMM
							EBPF_OP_DIV64_REG
							EBPF_OP_MOD64_IMM
							EBPF_OP_MOD64_REG
							EBPF_OP_ARSH64_IMM
							EBPF_OP_ARSH64_REG
							EBPF_OP_LSH64_IMM
							EBPF_OP_LSH64_REG
							EBPF_OP_RSH64_IMM
							EBPF_OP_RSH64_REG

							// default
							default: begin
								case (opcode)
									EBPF_OP_ADD64_IMM
									EBPF_OP_ADD64_REG
									EBPF_OP_SUB64_IMM
									EBPF_OP_SUB64_REG
									EBPF_OP_MUL64_IMM
									EBPF_OP_MUL64_REG
									EBPF_OP_OR64_IMM
									EBPF_OP_OR64_REG
									EBPF_OP_AND64_IMM
									EBPF_OP_AND64_REG
									EBPF_OP_NEG64
									EBPF_OP_XOR64_IMM
									EBPF_OP_XOR64_REG
									EBPF_OP_MOV64_IMM
									EBPF_OP_MOV64_REG
									default
									
								endcase // opcode
							end // default	
						endcase // opcode
					end // OPC_ALU64

				endcase // opclass
				cpu_data_ack <= 0;

			end // STATE_DECODE


			// STATE_DATA_FETCH
			// Fetch from data memory
			STATE_DATA_FETCH: begin
				if (data_ack) begin
					data_stb <= 0;
					data_we <= 0;
					state_next <= STATE_DECODE;
					cpu_data_ack <= 1;
				end
				else begin
					data_stb <= 1;
				end
			end // STATE_DATA_FETCH


			// STATE_DIV_PENDING
			// Exec math divide
			STATE_DIV_PENDING: begin
				if (div64_stb) begin
					div64_stb <= 0;
				end
				else begin
					if (div64_ack) begin
						if (div64_err) begin
							if ((opcode & 8'hf0) != EBPF_OP_MOD) begin
								regs[dst] <= 8'h00;
							end
							error <= 1;
							halt <= 1;
						end
						else begin
							state_next <= STATE_DECODE;
							cpu_div64_ack <= 1;
						end
					end
				end
			end // STATE_DIV_PENDING


			// STATE_CALL_PENDING
			STATE_CALL_PENDING: begin
				if (call_handler_ack) begin
                    call_handler_stb <= 0;
                    if (call_handler_err) begin
                        error <= 1;
                        halt <= 1;
                    end
                    else begin
                    	regs[0] <= call_handler_ret;
                    	state_next <= STATE_DECODE;
                    	ip_next <= ip_next + 1;
                    	ip <= ip_next;
                    	instruction <= pgm_dat_r;
                    end
                end
			end // STATE_CALL_PENDING
		endcase // state
	end
end // always block

// update state for next cycle
always @(posedge clk) state<=next_state;

endmodule