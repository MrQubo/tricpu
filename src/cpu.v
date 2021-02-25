`timescale 1ps / 1ps
`default_nettype none

module tricpu#(
	parameter integer P_LOGLEVEL = 0,
	parameter BIN_FILENAME = "zzz_bram.bin"
) (
	input wire clk,
	input wire rst,

	input wire noise,
	output wire halted,

	input wire stepping,
	input wire do_step,

	output wire [17:0] o_pc,

	input wire [31:0] s_axis_tdata,
	input wire s_axis_tlast,
	output wire s_axis_tready,
	input wire s_axis_tvalid,

	output wire [31:0] m_axis_tdata,
	output wire m_axis_tlast,
	input wire m_axis_tready,
	output wire m_axis_tvalid
);
`include "utils.h"

integer ii;

localparam signed [3:0] idxSCRN = -4'sh4;
localparam signed [3:0] idxSCRZ = -4'sh3;
localparam signed [3:0] idxSCRP = -4'sh2;
localparam signed [3:0] idxPGTN = -4'sh1;
localparam signed [3:0] idxPSW = 4'sh0;
localparam signed [3:0] idxPGTP = 4'sh1;
localparam signed [3:0] idxEPC = 4'sh2;
localparam signed [3:0] idxEPSW = 4'sh3;
localparam signed [3:0] idxEDATA = 4'sh4;
localparam [4:0] triSF = 5'h0;
localparam [4:0] triCF = 5'h1;
localparam [4:0] triTL = 5'h2;
localparam [4:0] triXM = 5'h3;
localparam [4:0] triWM = 5'h4;
localparam [4:0] triRM = 5'h5;
localparam [4:0] triXP = 5'h6;
localparam [4:0] triWP = 5'h7;
localparam [4:0] triRP = 5'h8;
localparam signed [1:0] ptX = 2'b11;
localparam signed [1:0] ptW = 2'b00;
localparam signed [1:0] ptR = 2'b01;
localparam signed [1:0] tlSINGLE = 2'b00;
localparam signed [1:0] tlDOUBLE = 2'b01;
localparam signed [1:0] tlTRIPLE = 2'b11;

// EXCEPTION CODES
function [3:0] exc_pagefault(input signed [1:0] pt);
	begin
		exc_pagefault = 'hx;
		case (pt)
		ptX: exc_pagefault = 4'b1111;
		ptW: exc_pagefault = 4'b1100;
		ptR: exc_pagefault = 4'b1101;
		endcase
	end
endfunction
localparam [3:0] exc_doublefault = 4'b0011;
localparam [3:0] exc_syscall = 4'b0001;
localparam [3:0] exc_priverr = 4'b0111;
localparam [3:0] exc_illegal = 4'b0100;
localparam [3:0] exc_divby0 = 4'b0101;

// REGISTERS
reg [17:0] pc;
reg [17:0] regs[-4:4];
reg [17:0] sregs[-4:4];
wire [17:0] scrn = sregs[idxSCRN];
wire [17:0] scrz = sregs[idxSCRZ];
wire [17:0] scrp = sregs[idxSCRP];
wire [17:0] pgtn = sregs[idxPGTN];
wire [17:0] psw = sregs[idxPSW];
wire [17:0] pgtp = sregs[idxPGTP];
wire [17:0] epc = sregs[idxEPC];
wire [17:0] epsw = sregs[idxEPSW];
wire [17:0] edata = sregs[idxEDATA];
wire signed [1:0] sf = psw[2*triSF+:2];
wire signed [1:0] cf = psw[2*triCF+:2];
wire signed [1:0] tl = psw[2*triTL+:2];
wire signed [1:0] xm = psw[2*triXM+:2];
wire signed [1:0] wm = psw[2*triWM+:2];
wire signed [1:0] rm = psw[2*triRM+:2];
wire signed [1:0] xp = psw[2*triXP+:2];
wire signed [1:0] wp = psw[2*triWP+:2];
wire signed [1:0] rp = psw[2*triRP+:2];


// REGISTER UTILS
function signed [3:0] trits2reg_idx(input [3:0] trits);
	begin
		trits2reg_idx = 'hx;
		case (trits)
		4'b1111: trits2reg_idx = -4'sh4;
		4'b1100: trits2reg_idx = -4'sh3;
		4'b1101: trits2reg_idx = -4'sh2;
		4'b0011: trits2reg_idx = -4'sh1;
		4'b0000: trits2reg_idx = 4'sh0;
		4'b0001: trits2reg_idx = 4'sh1;
		4'b0111: trits2reg_idx = 4'sh2;
		4'b0100: trits2reg_idx = 4'sh3;
		4'b0101: trits2reg_idx = 4'sh4;
		endcase
	end
endfunction
function [17:0] trits2reg(input [3:0] trits);
	begin
		trits2reg = 'hxxxxx;
		case (trits)
		4'b1111: trits2reg = regs[-4];
		4'b1100: trits2reg = regs[-3];
		4'b1101: trits2reg = regs[-2];
		4'b0011: trits2reg = regs[-1];
		4'b0000: trits2reg = 0;
		4'b0001: trits2reg = regs[1];
		4'b0111: trits2reg = regs[2];
		4'b0100: trits2reg = regs[3];
		4'b0101: trits2reg = regs[4];
		endcase
	end
endfunction
function signed [3:0] trits2sreg_idx(input [3:0] trits);
	begin
		trits2sreg_idx = trits2reg_idx(trits);
	end
endfunction
function [17:0] trits2sreg(input [3:0] trits);
	begin
		trits2sreg = 'hxxxxx;
		case (trits)
		4'b1111: trits2sreg = sregs[-4];
		4'b1100: trits2sreg = sregs[-3];
		4'b1101: trits2sreg = sregs[-2];
		4'b0011: trits2sreg = sregs[-1];
		4'b0000: trits2sreg = sregs[0];
		4'b0001: trits2sreg = sregs[1];
		4'b0111: trits2sreg = sregs[2];
		4'b0100: trits2sreg = sregs[3];
		4'b0101: trits2sreg = sregs[4];
		endcase
	end
endfunction

function [4:0] trits2psw_idx(input [3:0] trits);
	begin
		trits2psw_idx = 'hxx;
		case (trits)
		4'b1111: trits2psw_idx = triSF;
		4'b1100: trits2psw_idx = triCF;
		4'b1101: trits2psw_idx = triTL;
		4'b0011: trits2psw_idx = triXM;
		4'b0000: trits2psw_idx = triWM;
		4'b0001: trits2psw_idx = triRM;
		4'b0111: trits2psw_idx = triXP;
		4'b0100: trits2psw_idx = triWP;
		4'b0101: trits2psw_idx = triRP;
		endcase
	end
endfunction
function signed [1:0] trits2psw(input [17:0] psw, input [3:0] trits);
	begin
		trits2psw = 'hx;
		case (trits)
		4'b1111: trits2psw = psw[2*triSF+:2];
		4'b1100: trits2psw = psw[2*triCF+:2];
		4'b1101: trits2psw = psw[2*triTL+:2];
		4'b0011: trits2psw = psw[2*triXM+:2];
		4'b0000: trits2psw = psw[2*triWM+:2];
		4'b0001: trits2psw = psw[2*triRM+:2];
		4'b0111: trits2psw = psw[2*triXP+:2];
		4'b0100: trits2psw = psw[2*triWP+:2];
		4'b0101: trits2psw = psw[2*triRP+:2];
		endcase
	end
endfunction
function [0:0] trits2psw_setf_priv(input [3:0] trits);
	begin
		trits2psw_setf_priv = 'hx;
		case (trits)
		4'b1111: trits2psw_setf_priv = 0;
		4'b1100: trits2psw_setf_priv = 0;
		4'b1101: trits2psw_setf_priv = 1;
		4'b0011: trits2psw_setf_priv = 1;
		4'b0000: trits2psw_setf_priv = 1;
		4'b0001: trits2psw_setf_priv = 1;
		4'b0111: trits2psw_setf_priv = 1;
		4'b0100: trits2psw_setf_priv = 1;
		4'b0101: trits2psw_setf_priv = 1;
		endcase
	end
endfunction

function [0:0] eval_cond(input [17:0] psw, input [3:0] arg);
	reg signed [1:0] sf;
	reg signed [1:0] cf;
	begin
		sf = psw[2*triSF+:2];
		cf = psw[2*triCF+:2];

		eval_cond = 'hx;
		case (arg)
		4'b1111: eval_cond = !util_trit_m1(sf);
		4'b1100: eval_cond = !util_trit_0(sf);
		4'b1101: eval_cond = !util_trit_1(sf);
		4'b0011: eval_cond = util_trit_0(cf);
		4'b0000: eval_cond = 1;
		4'b0001: eval_cond = !util_trit_0(cf);
		4'b0111: eval_cond = util_trit_m1(sf);
		4'b0100: eval_cond = util_trit_0(sf);
		4'b0101: eval_cond = util_trit_1(sf);
		endcase
	end
endfunction


// MODULES
localparam [0:0] EXTCALL_TYPE_TERMCALL = 1'b0;
localparam [0:0] EXTCALL_TYPE_HYPERCALL = 1'b1;
wire extcall_write_r1_enable;
wire [17:0] extcall_write_r1_val;
wire extcall_ram_enable;
wire extcall_ram_write;
wire signed [1:0] extcall_ram_pt;
wire [17:0] extcall_ram_addr;
wire [17:0] extcall_ram_in;
reg extcall_enable;
reg extcall_type;
reg [5:0] extcall_code;
wire extcall_ready;
wire extcall_pagefault;
wire signed [1:0] extcall_pagefault_pt;
wire [17:0] extcall_pagefault_addr;
wire extcall_exit;
m_extcall_controller#(.P_LOGLEVEL(P_LOGLEVEL)) p_extcall_ctrl(
	.i_clk(clk),
	.i_rst(rst),

	.i_s_axis_tdata(s_axis_tdata),
	.i_s_axis_tlast(s_axis_tlast),
	.o_s_axis_tready(s_axis_tready),
	.i_s_axis_tvalid(s_axis_tvalid),

	.o_m_axis_tdata(m_axis_tdata),
	.o_m_axis_tlast(m_axis_tlast),
	.i_m_axis_tready(m_axis_tready),
	.o_m_axis_tvalid(m_axis_tvalid),

	.i_r1(regs[1]),
	.i_r2(regs[2]),
	.i_r3(regs[3]),
	.i_r4(regs[4]),

	.o_write_r1_enable(extcall_write_r1_enable),
	.o_write_r1_val(extcall_write_r1_val),

	.o_ram_enable(extcall_ram_enable),
	.o_ram_write(extcall_ram_write),
	.o_ram_pt(extcall_ram_pt),
	.o_ram_addr(extcall_ram_addr),
	.o_ram_in(extcall_ram_in),
	.i_ram_ready(ram_ready),
	.i_ram_pagefault(ram_pagefault),
	.i_ram_out(ram_out),

	.i_enable(extcall_enable),
	.i_type(extcall_type),
	.i_code(extcall_code),

	.o_ready(extcall_ready),
	.o_pagefault(extcall_pagefault),
	.o_pagefault_pt(extcall_pagefault_pt),
	.o_pagefault_addr(extcall_pagefault_addr),
	.o_exit(extcall_exit)
);

reg ram_invalidate_cache;
reg ram_enable;
reg ram_write;
reg signed [1:0] ram_pt;
reg [17:0] ram_addr;
reg [17:0] ram_in;
wire ram_ready;
wire ram_pagefault;
wire [17:0] ram_out;
triram#(.BIN_FILENAME(BIN_FILENAME)) ram(
	.clk(clk), .rst(rst),
	.pgtn(pgtn), .psw(psw), .pgtp(pgtp),
	.invalidate_cache(ram_invalidate_cache),
	.e(ram_enable), .write(ram_write),
	.pt(ram_pt),
	.addr(ram_addr), .in(ram_in),
	.o(ram_ready), .pagefault(ram_pagefault),
	.out(ram_out)
);

wire [17:0] rng_num;
trirng rng(
	.clk(clk), .rst(rst),
	.noise(noise),
	.num(rng_num)
);

reg add_enable;
reg signed [1:0] add_cf_mode;
reg [17:0] add_lhs;
reg add_sub;
reg [17:0] add_rhs;
wire add_ready;
wire [17:0] add_res;
wire signed [1:0] add_cf;
wire signed [1:0] add_sf;
triadd add(
	.clk(clk), .rst(rst),
	.e(add_enable),
	.cf_i(cf), .cf_mode(add_cf_mode),
	.lhs(add_lhs), .sub(add_sub), .rhs(add_rhs),
	.o(add_ready),
	.res(add_res),
	.cf(add_cf), .sf(add_sf)
);

reg mul_enable;
reg [17:0] mul_lhs;
reg [17:0] mul_rhs;
wire mul_ready;
wire [17:0] mul_res;
wire signed [1:0] mul_cf;
wire signed [1:0] mul_sf;
trimul mul(
	.clk(clk), .rst(rst),
	.e(mul_enable),
	.lhs(mul_lhs), .rhs(mul_rhs),
	.o(mul_ready),
	.res(mul_res),
	.cf(mul_cf), .sf(mul_sf)
);

reg div_enable;
reg [17:0] div_lhs;
reg [17:0] div_rhs;
wire div_ready;
wire div_divby0;
wire [17:0] div_quo;
wire signed [1:0] div_quo_cf;
wire signed [1:0] div_quo_sf;
wire [17:0] div_rem;
wire signed [1:0] div_rem_cf;
wire signed [1:0] div_rem_sf;
tridiv div(
	.clk(clk), .rst(rst),
	.e(div_enable),
	.lhs(div_lhs), .rhs(div_rhs),
	.o(div_ready), .divby0(div_divby0),
	.quo_o(div_quo), .quo_cf_o(div_quo_cf), .quo_sf_o(div_quo_sf),
	.rem_o(div_rem), .rem_cf_o(div_rem_cf), .rem_sf_o(div_rem_sf)
);

reg [17:0] shl_lhs;
reg shl_neg_rhs;
reg [5:0] shl_rhs;
wire [17:0] shl_res;
wire signed [1:0] shl_cf;
wire signed [1:0] shl_sf;
trishl_sync shl(
	.lhs(shl_lhs), .neg_rhs(shl_neg_rhs), .rhs(shl_rhs),
	.res(shl_res),
	.cf(shl_cf), .sf(shl_sf)
);

localparam [1:0] BIT_OP_AND = 2'b01;
localparam [1:0] BIT_OP_XOR = 2'b10;
reg [1:0] bit_op;
reg [17:0] bit_lhs;
reg [17:0] bit_rhs;
wire [17:0] bit_res;
wire signed [1:0] bit_cf;
wire signed [1:0] bit_sf;
tribit_sync bit(
	.op(bit_op),
	.lhs(bit_lhs), .rhs(bit_rhs),
	.res(bit_res),
	.cf(bit_cf), .sf(bit_sf)
);

wire [17:0] pc_inc;
triinc_sync p_pc_inc(
	.in(pc),
	.res(pc_inc)
);

wire [17:0] reg_arg3_inc;
triinc_sync p_arg3_inc(
	.in(trits2reg(arg3)),
	.res(reg_arg3_inc)
);

wire [17:0] reg_arg3_dec;
tridec_sync p_arg3_dec(
	.in(trits2reg(arg3)),
	.res(reg_arg3_dec)
);

// INSTRUCTIONS
localparam [17:0] OP_IMM        = 18'b111111xxxxxxxxxxxx;
localparam [17:0] OP_IMM_AND    = 18'bxxxxxx1111xxxxxxxx;
localparam [17:0] OP_IMM_ADD    = 18'bxxxxxx1100xxxxxxxx;
localparam [17:0] OP_IMM_XOR    = 18'bxxxxxx1101xxxxxxxx;
localparam [17:0] OP_IMM_LOAD   = 18'bxxxxxx0011xxxxxxxx;
localparam [17:0] OP_IMM_JMP    = 18'bxxxxxx0000xxxxxxxx;
localparam [17:0] OP_IMM_STORE  = 18'bxxxxxx0001xxxxxxxx;
localparam [17:0] OP_IMM_QUO    = 18'bxxxxxx0111xxxxxxxx;
localparam [17:0] OP_IMM_MUL    = 18'bxxxxxx0100xxxxxxxx;
localparam [17:0] OP_IMM_REM    = 18'bxxxxxx0101xxxxxxxx;
localparam [17:0] OP_AND        = 18'b111100xxxxxxxxxxxx;
localparam [17:0] OP_XOR        = 18'b111101xxxxxxxxxxxx;
localparam [17:0] OP_QUO        = 18'b110011xxxxxxxxxxxx;
localparam [17:0] OP_MUL        = 18'b110000xxxxxxxxxxxx;
localparam [17:0] OP_REM        = 18'b110001xxxxxxxxxxxx;
localparam [17:0] OP_SHL_R      = 18'b110111xxxxxxxxxxxx;
localparam [17:0] OP_SHR        = 18'b110100xxxxxxxxxxxx;
localparam [17:0] OP_ILLEGAL_0  = 18'b110101xxxxxxxxxxxx;
localparam [17:0] OP_LOAD       = 18'b0011xxxxxxxxxxxxxx;
localparam [17:0] OP_JMP        = 18'b000011xxxxxxxxxxxx;
localparam [17:0] OP_ILLEGAL_1  = 18'b00000011xxxxxxxxxx;
localparam [17:0] OP_GETF       = 18'b0000000011xxxxxxxx;
localparam [17:0] OP_ILLEGAL_2  = 18'b00000000001111xxxx;
localparam [17:0] OP_ERET       = 18'b000000000011000000;
localparam [17:0] OP_ILLEGAL_30 = 18'b000000000011000011;
localparam [17:0] OP_ILLEGAL_31 = 18'b000000000011000001;
localparam [17:0] OP_ILLEGAL_32 = 18'b0000000000110011xx;
localparam [17:0] OP_ILLEGAL_33 = 18'b0000000000110001xx;
localparam [17:0] OP_RNG        = 18'b00000000001101xxxx;
localparam [17:0] OP_ILLEGAL_4  = 18'b000000000000xxxxxx;
localparam [17:0] OP_SETF       = 18'b000000000001xxxxxx;
localparam [17:0] OP_TERMCALL   = 18'b000000000111xxxxxx;
localparam [17:0] OP_SYSCALL    = 18'b000000000100xxxxxx;
localparam [17:0] OP_HYPERCALL  = 18'b000000000101xxxxxx;
localparam [17:0] OP_S2R        = 18'b0000000111xxxxxxxx;
localparam [17:0] OP_NEG        = 18'b0000000100xxxxxxxx;
localparam [17:0] OP_R2S        = 18'b0000000101xxxxxxxx;
localparam [17:0] OP_ILLEGAL_5  = 18'b000001xxxxxxxxxxxx;
localparam [17:0] OP_STORE      = 18'b0001xxxxxxxxxxxxxx;
localparam [17:0] OP_SUB        = 18'b0111xxxxxxxxxxxxxx;
localparam [17:0] OP_SHL_I      = 18'b0100xxxxxxxxxxxxxx;
localparam [17:0] OP_ADD        = 18'b0101xxxxxxxxxxxxxx;


// STATE
localparam [3:0] STATE_INIT = 4'h0;
localparam [3:0] STATE_LOAD_INSTR = 4'h1;
localparam [3:0] STATE_DECODE = 4'h2;
localparam [3:0] STATE_IMM = 4'h3;
localparam [3:0] STATE_LOAD = 4'h4;
localparam [3:0] STATE_STORE = 4'h5;
localparam [3:0] STATE_WAIT_STORE = 4'h6;
localparam [3:0] STATE_WRITE = 4'h7;
localparam [3:0] STATE_EXTCALL = 4'h8;
localparam [3:0] STATE_HALTED = 4'hf;
reg [3:0] state;
reg [3:0] next_state;
initial state = STATE_INIT;

localparam [2:0] WRS_ADD = 3'h0;
localparam [2:0] WRS_MUL = 3'h1;
localparam [2:0] WRS_QUO = 3'h2;
localparam [2:0] WRS_REM = 3'h3;
localparam [2:0] WRS_SHL = 3'h4;
localparam [2:0] WRS_BIT = 3'h5;
localparam [2:0] WRS_RAM = 3'h6;
reg [2:0] wrs;
reg [2:0] next_wrs;

reg signed [1:0] mem_dir;
reg signed [1:0] next_mem_dir;


// REGS
reg [17:0] next_pc;
reg [17:0] next_instr;
reg [17:0] next_instr_pc;
reg write_cfsf_enable;
reg signed [1:0] write_cfsf_cf;
reg signed [1:0] write_cfsf_sf;
reg write_reg_enable;
reg [3:0] write_reg_idx;  // 2 trits
reg [17:0] write_reg_val;
reg write_sreg_enable;
reg [3:0] write_sreg_idx;  // 2 trits
reg [17:0] write_sreg_val;
reg write_psw_f_enable;
reg [3:0] write_psw_f_idx;  // 2 trits
reg signed [1:0] write_psw_f_val;  // 1 trit
reg switch_to_exc;
reg signed [1:0] switch_to_exc_tl;
reg [17:0] switch_to_exc_epc;
reg [17:0] switch_to_exc_epsw;
reg [17:0] switch_to_exc_edata;
reg ret_from_exc;

reg [17:0] imm;
reg jmp;
reg [17:0] jmp_addr;
reg [17:0] jmp_ret;
reg exc;
reg [3:0] exc_code;
reg [17:0] exc_data;
reg [17:0] exc_pc;
reg wrt;

wire [3:0] arg1 = next_instr[0+:4];
wire [3:0] arg2 = next_instr[4+:4];
wire [3:0] arg3 = next_instr[8+:4];
wire signed [1:0] sarg = next_instr[12+:2];
wire [5:0] arg_shl_i = next_instr[8+:6];
wire signed [1:0] arg_setf = next_instr[4+:2];
wire [5:0] arg_extcall_code = next_instr[0+:6];

reg [17:0] instr;
reg [17:0] instr_pc;

reg [17:0] c_dummy_reg_m4;
reg [17:0] c_dummy_reg_m3;
reg [17:0] c_dummy_reg_m2;
reg [17:0] c_dummy_reg_m1;
reg [17:0] c_dummy_reg_0;
reg [17:0] c_dummy_reg_1;
reg [17:0] c_dummy_reg_2;
reg [17:0] c_dummy_reg_3;
reg [17:0] c_dummy_reg_4;

reg [17:0] c_dummy_sreg_m4;
reg [17:0] c_dummy_sreg_m3;
reg [17:0] c_dummy_sreg_m2;
reg [17:0] c_dummy_sreg_m1;
reg [17:0] c_dummy_sreg_0;
reg [17:0] c_dummy_sreg_1;
reg [17:0] c_dummy_sreg_2;
reg [17:0] c_dummy_sreg_3;
reg [17:0] c_dummy_sreg_4;


// LOGIC
assign halted = state == STATE_HALTED;

always @* begin
	c_dummy_reg_m4 = regs[-4];
	c_dummy_reg_m3 = regs[-3];
	c_dummy_reg_m2 = regs[-2];
	c_dummy_reg_m1 = regs[-1];
	c_dummy_reg_0 = regs[0];
	c_dummy_reg_1 = regs[1];
	c_dummy_reg_2 = regs[2];
	c_dummy_reg_3 = regs[3];
	c_dummy_reg_4 = regs[4];
	c_dummy_sreg_m4 = sregs[-4];
	c_dummy_sreg_m3 = sregs[-3];
	c_dummy_sreg_m2 = sregs[-2];
	c_dummy_sreg_m1 = sregs[-1];
	c_dummy_sreg_0 = sregs[0];
	c_dummy_sreg_1 = sregs[1];
	c_dummy_sreg_2 = sregs[2];
	c_dummy_sreg_3 = sregs[3];
	c_dummy_sreg_4 = sregs[4];

	extcall_enable = 0;
	extcall_type = 'hx;
	extcall_code = 'hxx;

	ram_invalidate_cache = 0;
	ram_enable = 0;
	ram_write = 'hx;
	ram_pt = 'hx;
	ram_addr = 'hxxxxx;
	ram_in = 'hxxxxx;

	add_enable = 0;
	add_cf_mode = 'hx;
	add_lhs = 'hxxxxx;
	add_sub = 'hx;
	add_rhs = 'hxxxxx;

	mul_enable = 0;
	mul_lhs = 'hxxxxx;
	mul_rhs = 'hxxxxx;

	div_enable = 0;
	div_lhs = 'hxxxxx;
	div_rhs = 'hxxxxx;

	shl_neg_rhs = 'hx;
	shl_lhs = 'hxxxxx;
	shl_rhs = 'hxxxxx;

	bit_op = 'hx;
	bit_lhs = 'hxxxxx;
	bit_rhs = 'hxxxxx;

	next_state = state;
	next_wrs = 'hx;
	next_mem_dir = 'hx;
	next_pc = pc;
	next_instr = instr;
	next_instr_pc = instr_pc;
	write_cfsf_enable = 0;
	write_cfsf_cf = 'hx;
	write_cfsf_sf = 'hx;
	write_reg_enable = 0;
	write_reg_idx = 'hxx;
	write_reg_val = 'hxxxxx;
	write_sreg_enable = 0;
	write_sreg_idx = 'hxx;
	write_sreg_val = 'hxxxxx;
	write_psw_f_enable = 0;
	write_psw_f_idx = 'hxx;
	write_psw_f_val = 'hx;
	switch_to_exc = 0;
	switch_to_exc_tl = 'hx;;
	switch_to_exc_epc = 'hxxxxx;
	switch_to_exc_epsw = 'hxxxxx;
	switch_to_exc_edata = 'hxxxxx;
	ret_from_exc = 0;

	imm = 'hxxxxx;
	jmp = 0;
	jmp_addr = 'hxxxxx;
	jmp_ret = 'hxxxxx;
	exc = 0;
	exc_code = 'hx;
	exc_data = 'hxxxxx;
	exc_pc = 'hxxxxx;
	wrt = 0;

	case (state)
	STATE_INIT: begin
		next_state = STATE_LOAD_INSTR;
	end
	STATE_LOAD_INSTR: begin
		// pc points to current instruction
		// XXX: There's not much to do here, try skipping state
		//	STATE_LOAD_INSTR with a flag (like jmp or exc).
		if (!stepping || do_step) begin
			ram_enable = 1;
			ram_write = 0;
			ram_pt = ptX;
			ram_addr = pc;
			next_state = STATE_DECODE;
		end

		/* if (ram_ready && ram_pagefault) begin
		 *         exc = 1;
		 *         exc_code = exc_pagefault(ptX);
		 *         exc_data = ram_addr;
		 * end */
	end
	STATE_DECODE: begin
		// pc points to the instruction
		if (ram_ready && ram_pagefault) begin
			exc = 1;
			exc_code = exc_pagefault(ptX);
			exc_data = instr_pc;
		end
		if (ram_ready && !ram_pagefault) begin
			// next_pc is incremented
			next_pc = pc_inc;
			next_instr = ram_out;
			casex (next_instr)
			OP_IMM: begin
				// next_pc points to immediate
				ram_enable = 1;
				ram_write = 0;
				ram_pt = ptX;
				ram_addr = next_pc;
				next_state = STATE_IMM;

				/* if (ram_ready && ram_pagefault) begin
				 *         exc = 1;
				 *         exc_code = exc_pagefault(ptX);
				 *         exc_data = ram_addr;
				 * end */
			end
			OP_AND: begin
				bit_op = BIT_OP_AND;
				bit_lhs = trits2reg(arg2);
				bit_rhs = trits2reg(arg3);
				next_wrs = WRS_BIT;
				wrt = 1;
			end
			OP_XOR: begin
				bit_op = BIT_OP_XOR;
				bit_lhs = trits2reg(arg2);
				bit_rhs = trits2reg(arg3);
				next_wrs = WRS_BIT;
				wrt = 1;
			end
			OP_QUO: begin
				div_enable = 1;
				div_lhs = trits2reg(arg2);
				div_rhs = trits2reg(arg3);
				next_wrs = WRS_QUO;
				wrt = 1;
			end
			OP_MUL: begin
				mul_enable = 1;
				mul_lhs = trits2reg(arg2);
				mul_rhs = trits2reg(arg3);
				next_wrs = WRS_MUL;
				wrt = 1;
			end
			OP_REM: begin
				div_enable = 1;
				div_lhs = trits2reg(arg2);
				div_rhs = trits2reg(arg3);
				next_wrs = WRS_REM;
				wrt = 1;
			end
			OP_SHL_R: begin
				shl_lhs = trits2reg(arg2);
				shl_neg_rhs = 0;
				shl_rhs = trits2reg(arg3);
				next_wrs = WRS_SHL;
				wrt = 1;
			end
			OP_SHR: begin
				shl_lhs = trits2reg(arg2);
				shl_neg_rhs = 1;
				shl_rhs = trits2reg(arg3);
				next_wrs = WRS_SHL;
				wrt = 1;
			end
			OP_ILLEGAL_0: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_LOAD: begin
				add_enable = 1;
				add_cf_mode = 0;
				add_lhs = trits2reg(arg2);
				add_sub = 0;
				add_rhs = trits2reg(arg3);

				next_mem_dir = sarg;
				next_state = STATE_LOAD;
			end
			OP_JMP: begin
				if (eval_cond(psw, arg3)) begin
					jmp = 1;
					jmp_addr = trits2reg(arg2);
					jmp_ret = next_pc;
				end else begin
					next_state = STATE_LOAD_INSTR;
				end
			end
			OP_ILLEGAL_1: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_GETF: begin
				write_reg_enable = 1;
				write_reg_idx = arg1;
				write_reg_val = trits2psw(psw, arg2);
				next_state = STATE_LOAD_INSTR;
			end
			OP_ILLEGAL_2: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_ERET: begin
				if (!util_trit_0(xm)) begin
					exc = 1;
					exc_code = exc_priverr;
					exc_data = next_instr;
				end else begin
					ret_from_exc = 1;
				end
			end
			OP_ILLEGAL_30: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_ILLEGAL_31: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_ILLEGAL_32: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_ILLEGAL_33: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_RNG: begin
				write_reg_enable = 1;
				write_reg_idx = arg1;
				write_reg_val = rng_num;
				next_state = STATE_LOAD_INSTR;
			end
			OP_ILLEGAL_4: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_SETF: begin
				if (trits2psw_setf_priv(arg1)
					&& !util_trit_0(xm)
				) begin
					exc = 1;
					exc_code = exc_priverr;
					exc_data = next_instr;
				end else begin
					write_psw_f_enable = 1;
					write_psw_f_idx = arg1;
					write_psw_f_val = arg_setf;
					// XXX: When removing state
					//	STATE_LOAD_INSTR we will need to
					//	wait one cycle here, because psw
					//	is used by mmu (we can use
					//	STATE_WRITE).
					next_state = STATE_LOAD_INSTR;
				end
			end
			OP_TERMCALL: begin
				if (!util_trit_m1(xm)) begin
					exc = 1;
					exc_code = exc_priverr;
					exc_data = next_instr;
				end else begin
					extcall_enable = 1;
					extcall_type = EXTCALL_TYPE_TERMCALL;
					extcall_code = arg_extcall_code;
					next_state = STATE_EXTCALL;
				end
			end
			OP_SYSCALL: begin
				exc = 1;
				exc_code = exc_syscall;
				exc_data = next_instr;
			end
			OP_HYPERCALL: begin
				if (!util_trit_0(xm)) begin
					exc = 1;
					exc_code = exc_priverr;
					exc_data = next_instr;
				end else begin
					extcall_enable = 1;
					extcall_type = EXTCALL_TYPE_HYPERCALL;
					extcall_code = arg_extcall_code;
					next_state = STATE_EXTCALL;
				end
			end
			OP_S2R: begin
				write_reg_enable = 1;
				write_reg_idx = arg1;
				write_reg_val = trits2sreg(arg2);
				next_state = STATE_LOAD_INSTR;
			end
			OP_NEG: begin
				bit_op = BIT_OP_AND;
				bit_lhs = trits2reg(arg2);
				bit_rhs = 18'h3ffff;  // #---------
				next_wrs = WRS_BIT;
				wrt = 1;
			end
			OP_R2S: begin
				write_sreg_enable = 1;
				write_sreg_idx = arg1;
				write_sreg_val = trits2reg(arg2);
				next_state = STATE_LOAD_INSTR;
			end
			OP_ILLEGAL_5: begin
				exc = 1;
				exc_code = exc_illegal;
				exc_data = next_instr;
			end
			OP_STORE: begin
				add_enable = 1;
				add_cf_mode = 0;
				add_lhs = trits2reg(arg2);
				add_sub = 0;
				add_rhs = trits2reg(arg3);

				next_mem_dir = sarg;
				next_state = STATE_STORE;
			end
			OP_SUB: begin
				add_enable = 1;
				add_cf_mode = sarg;
				add_lhs = trits2reg(arg2);
				add_sub = 1;
				add_rhs = trits2reg(arg3);
				next_wrs = WRS_ADD;
				wrt = 1;
			end
			OP_SHL_I: begin
				shl_lhs = trits2reg(arg2);
				shl_neg_rhs = 0;
				shl_rhs = arg_shl_i;
				next_wrs = WRS_SHL;
				wrt = 1;
			end
			OP_ADD: begin
				add_enable = 1;
				add_cf_mode = sarg;
				add_lhs = trits2reg(arg2);
				add_sub = 0;
				add_rhs = trits2reg(arg3);
				next_wrs = WRS_ADD;
				wrt = 1;
			end
			endcase
		end
	end
	STATE_IMM: begin
		// pc points to the immediate
		if (ram_ready && ram_pagefault) begin
			exc = 1;
			exc_code = exc_pagefault(ptX);
			exc_data = pc;
		end
		if (ram_ready && !ram_pagefault) begin
			// next_pc points to the next instruction
			next_pc = pc_inc;
			imm = ram_out;
			casex (instr)
			OP_IMM_AND: begin
				bit_op = BIT_OP_AND;
				bit_lhs = trits2reg(arg2);
				bit_rhs = imm;
				next_wrs = WRS_BIT;
				wrt = 1;
			end
			OP_IMM_ADD: begin
				add_enable = 1;
				add_cf_mode = 0;
				add_lhs = trits2reg(arg2);
				add_sub = 0;
				add_rhs = imm;
				next_wrs = WRS_ADD;
				wrt = 1;
			end
			OP_IMM_XOR: begin
				bit_op = BIT_OP_XOR;
				bit_lhs = trits2reg(arg2);
				bit_rhs = imm;
				next_wrs = WRS_BIT;
				wrt = 1;
			end
			OP_IMM_LOAD: begin
				add_enable = 1;
				add_cf_mode = 0;
				add_lhs = trits2reg(arg2);
				add_sub = 0;
				add_rhs = imm;

				next_mem_dir = 2'b00;
				next_state = STATE_LOAD;
			end
			OP_IMM_JMP: begin
				if (eval_cond(psw, arg2)) begin
					jmp = 1;
					jmp_addr = imm;
					jmp_ret = next_pc;
				end else begin
					next_state = STATE_LOAD_INSTR;
				end
			end
			OP_IMM_STORE: begin
				add_enable = 1;
				add_cf_mode = 0;
				add_lhs = trits2reg(arg2);
				add_sub = 0;
				add_rhs = imm;

				next_mem_dir = 2'b00;
				next_state = STATE_STORE;
			end
			OP_IMM_QUO: begin
				div_enable = 1;
				div_lhs = trits2reg(arg2);
				div_rhs = imm;
				next_wrs = WRS_QUO;
				wrt = 1;
			end
			OP_IMM_MUL: begin
				mul_enable = 1;
				mul_lhs = trits2reg(arg2);
				mul_rhs = imm;
				next_wrs = WRS_MUL;
				wrt = 1;
			end
			OP_IMM_REM: begin
				div_enable = 1;
				div_lhs = trits2reg(arg2);
				div_rhs = imm;
				next_wrs = WRS_REM;
				wrt = 1;
			end
			endcase
		end
	end
	STATE_LOAD: begin
		next_mem_dir = mem_dir;

		if (add_ready) begin
			next_mem_dir = 'hx;

			ram_enable = 1;
			ram_write = 0;
			ram_pt = ptR;
			ram_addr = add_res;
			next_wrs = WRS_RAM;
			wrt = 1;

			case (mem_dir)
			2'b01: begin
				write_reg_enable = 1;
				write_reg_idx = arg3;
				write_reg_val = reg_arg3_inc;
			end
			2'b11: begin
				write_reg_enable = 1;
				write_reg_idx = arg3;
				write_reg_val = reg_arg3_dec;
			end
			endcase

			/* if (ram_ready && ram_pagefault) begin
			 *         exc = 1;
			 *         exc_code = exc_pagefault(ptR);
			 *         exc_data = add_res;
			 *         next_wrs = 'hx;
			 * end */
		end
	end
	STATE_STORE: begin
		next_mem_dir = mem_dir;

		if (add_ready) begin
			next_mem_dir = 'hx;

			ram_enable = 1;
			ram_write = 1;
			ram_pt = ptW;
			ram_addr = add_res;
			ram_in = trits2reg(arg1);
			next_state = STATE_WAIT_STORE;

			case (mem_dir)
			2'b01: begin
				write_reg_enable = 1;
				write_reg_idx = arg3;
				write_reg_val = reg_arg3_inc;
			end
			2'b11: begin
				write_reg_enable = 1;
				write_reg_idx = arg3;
				write_reg_val = reg_arg3_dec;
			end
			endcase

			/* if (ram_ready && ram_pagefault) begin
			 *         exc = 1;
			 *         exc_code = exc_pagefault(ptW);
			 *         exc_data = add_res;
			 * end */
		end
	end
	STATE_WAIT_STORE: begin
		if (ram_ready) begin
			if (ram_pagefault) begin
				exc = 1;
				exc_code = exc_pagefault(ptW);
				exc_data = add_res;
			end else begin
				next_state = STATE_LOAD_INSTR;
			end
		end
	end
	STATE_WRITE: begin
		next_wrs = wrs;

		casex (wrs)
		WRS_ADD: begin
			if (add_ready) begin
				write_reg_enable = 1;
				write_reg_idx = arg1;
				write_reg_val = add_res;
				write_cfsf_enable = 1;
				write_cfsf_cf = add_cf;
				write_cfsf_sf = add_sf;
				next_state = STATE_LOAD_INSTR;
				next_wrs = 'hx;
			end
		end
		WRS_MUL: begin
			if (mul_ready) begin
				write_reg_enable = 1;
				write_reg_idx = arg1;
				write_reg_val = mul_res;
				write_cfsf_enable = 1;
				write_cfsf_cf = mul_cf;
				write_cfsf_sf = mul_sf;
				next_state = STATE_LOAD_INSTR;
				next_wrs = 'hx;
			end
		end
		WRS_QUO: begin
			if (div_ready) begin
				if (div_divby0) begin
					exc = 1;
					exc_code = exc_divby0;
					exc_data = 'hxxxxx;  // TODO: should be div lhs
				end else begin
					write_reg_enable = 1;
					write_reg_idx = arg1;
					write_reg_val = div_quo;
					write_cfsf_enable = 1;
					write_cfsf_cf = div_quo_cf;
					write_cfsf_sf = div_quo_sf;
					next_state = STATE_LOAD_INSTR;
				end
				next_wrs = 'hx;
			end
		end
		WRS_REM: begin
			if (div_ready) begin
				if (div_divby0) begin
					exc = 1;
					exc_code = exc_divby0;
					exc_data = 'hxxxxx;  // TODO: should be div lhs
				end else begin
					write_reg_enable = 1;
					write_reg_idx = arg1;
					write_reg_val = div_rem;
					write_cfsf_enable = 1;
					write_cfsf_cf = div_rem_cf;
					write_cfsf_sf = div_rem_sf;
					next_state = STATE_LOAD_INSTR;
				end
				next_wrs = 'hx;
			end
		end
		WRS_RAM: begin
			if (ram_ready) begin
				if (ram_pagefault) begin
					exc = 1;
					exc_code = exc_pagefault(ptR);
					exc_data = add_res;
					next_wrs = 'hx;
				end else begin
					write_reg_enable = 1;
					write_reg_idx = arg1;
					write_reg_val = ram_out;
					next_state = STATE_LOAD_INSTR;
					next_wrs = 'hx;
				end
			end
		end
		endcase
	end
	endcase

	if (extcall_enable || state == STATE_EXTCALL) begin
		if (extcall_ready) begin
			if (extcall_exit) begin
				next_state = STATE_HALTED;
			end else if (extcall_pagefault) begin
				exc = 1;
				exc_code = exc_pagefault(extcall_pagefault_pt);
				exc_data = extcall_pagefault_addr;
			end else begin
				next_state = STATE_LOAD_INSTR;
			end
		end
		ram_enable = extcall_ram_enable;
		ram_write = extcall_ram_write;
		ram_pt = extcall_ram_pt;
		ram_addr = extcall_ram_addr;
		ram_in = extcall_ram_in;
	end

	if (jmp) begin
		next_pc = jmp_addr;
		write_reg_enable = 1;
		write_reg_idx = arg1;
		write_reg_val = jmp_ret;
		next_state = STATE_LOAD_INSTR;
	end

	if (exc) begin
		switch_to_exc = 1;
		switch_to_exc_epc = instr_pc;
		switch_to_exc_epsw = psw;
		case (tl)
		tlSINGLE: begin
			switch_to_exc_edata = exc_data;
			switch_to_exc_tl = tlDOUBLE;
		end
		tlDOUBLE: begin
			switch_to_exc_edata = exc_code;
			exc_code = exc_doublefault;
			switch_to_exc_tl = tlTRIPLE;
		end
		tlTRIPLE: begin
			next_state = STATE_HALTED;
		end
		endcase
		next_pc = {12'h0, exc_code, 2'b00};
		next_state = STATE_LOAD_INSTR;
	end

	if (ret_from_exc) begin
		next_pc = epc;
		next_state = STATE_LOAD_INSTR;
	end

	if (wrt) begin
		case (next_wrs)
		WRS_SHL: begin
			// shl is synchronous
			write_reg_enable = 1;
			write_reg_idx = arg1;
			write_reg_val = shl_res;
			write_cfsf_enable = 1;
			write_cfsf_cf = shl_cf;
			write_cfsf_sf = shl_sf;
			next_state = STATE_LOAD_INSTR;
			next_wrs = 'hx;
		end
		WRS_BIT: begin
			// bit is synchronous
			write_reg_enable = 1;
			write_reg_idx = arg1;
			write_reg_val = bit_res;
			write_cfsf_enable = 1;
			write_cfsf_cf = bit_cf;
			write_cfsf_sf = bit_sf;
			next_state = STATE_LOAD_INSTR;
			next_wrs = 'hx;
		end
		default: begin
			next_state = STATE_WRITE;
		end
		endcase
	end

	if (next_state == STATE_LOAD_INSTR)
		next_instr_pc = next_pc;

	if (
		write_sreg_enable || write_psw_f_enable || switch_to_exc
		|| ret_from_exc
	) begin
		ram_invalidate_cache = 1;
	end
end

reg signed [3:0] write_reg_idx_2bin;
reg signed [3:0] write_sreg_idx_2bin;
reg [17:0] switch_to_exc_tl_ext;
reg [17:0] switch_to_exc_tl_psw;
always @(posedge clk) begin
	if (rst) begin
		state <= STATE_INIT;
		pc <= 18'h0;  // #0
		instr_pc <= 18'h0;  // #0
		for (ii = -4; ii <= 4; ii = ii + 1) begin
			regs[ii] <= 0;
			sregs[ii] <= 0;
		end
	end else begin
		state <= next_state;
		wrs <= next_wrs;
		mem_dir <= next_mem_dir;
		pc <= next_pc;
		instr <= next_instr;
		instr_pc <= next_instr_pc;
		if (write_cfsf_enable) begin
			sregs[idxPSW][2*triCF+:2] <= write_cfsf_cf;
			sregs[idxPSW][2*triSF+:2] <= write_cfsf_sf;
		end
		if (write_psw_f_enable) begin
			sregs[idxPSW][
				2*trits2psw_idx(write_psw_f_idx) +:2
			] <= write_psw_f_val;
		end
		if (switch_to_exc) begin
			switch_to_exc_tl_ext = {16'h0, switch_to_exc_tl};
			switch_to_exc_tl_psw = switch_to_exc_tl_ext << (2*triTL);
			sregs[idxPSW] <= switch_to_exc_tl_psw;
			sregs[idxEPC] <= switch_to_exc_epc;
			sregs[idxEPSW] <= switch_to_exc_epsw;
			sregs[idxEDATA] <= switch_to_exc_edata;
		end
		if (ret_from_exc) begin
			sregs[idxPSW] <= epsw;
		end
		if (extcall_write_r1_enable) begin
			regs[1] <= extcall_write_r1_val;
		end
		if (write_reg_enable) begin
			write_reg_idx_2bin = trits2reg_idx(write_reg_idx);
			regs[write_reg_idx_2bin] <= write_reg_val;
		end
		if (write_sreg_enable) begin
			write_sreg_idx_2bin = trits2sreg_idx(write_sreg_idx);
			sregs[write_sreg_idx_2bin] <= write_sreg_val;
		end
	end
end


/* // DEBUG
 * wire [31:0] instr_ext = instr;
 * wire [31:0] ram_addr = util_trits2bits6(ram_addr[11:0]);
 * always @* begin
 *         casex (sw[6:0])
 *         7'b00000xx: led = regs[-4][sw[1:0]*8+7-:8];
 *         7'b00001xx: led = regs[-3][sw[1:0]*8+7-:8];
 *         7'b00010xx: led = regs[-2][sw[1:0]*8+7-:8];
 *         7'b00011xx: led = regs[-1][sw[1:0]*8+7-:8];
 *         7'b00100xx: led = regs[1][sw[1:0]*8+7-:8];
 *         7'b00101xx: led = regs[2][sw[1:0]*8+7-:8];
 *         7'b00110xx: led = regs[3][sw[1:0]*8+7-:8];
 *         7'b00111xx: led = regs[4][sw[1:0]*8+7-:8];
 *         7'b01000xx: led = pc[sw[1:0]*8+7-:8];
 *         7'b01001xx: led = state;
s         7'b01010xx: led = instr[sw[1:0]*8+7-:8];
 *         7'b01011xx: led = ram_addr[sw[1:0]*8+7-:8];
 *         7'b01100xx: led = ram_addr[sw[1:0]*8+7-:8];
 *         7'b01101x0: led = ram_enable;
 *         7'b01101x1: led = ram_write;
 *         default: led = sw;
 *         endcase
 * end */
assign o_pc = pc;

endmodule
