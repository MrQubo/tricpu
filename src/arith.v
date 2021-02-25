`timescale 1ps / 1ps
`default_nettype none

module tricomp0_sync#(parameter N = 9) (
	input wire [2*N-1:0] in,

	output reg pos,
	output reg zero,
	output reg neg
);

integer ii;

reg flag;

always @* begin
	pos = 'hx;
	zero = 'hx;
	neg = 'hx;
	flag = 0;

	for (ii = 2*N-2; ii >= 0; ii = ii - 2) begin
		if (!flag) begin
			case (in[ii+:2])
			2'b00: if (ii == 0) begin
				pos = 0;
				zero = 1;
				neg = 0;
			end
			2'b01: begin
				pos = 1;
				zero = 0;
				neg = 0;
				flag = 1;
			end
			2'b11: begin
				pos = 0;
				zero = 0;
				neg = 1;
				flag = 1;
			end
			default: flag = 1;
			endcase
		end
	end
end

endmodule


module trisfcomp_sync#(parameter N = 9) (
	input wire [2*N-1:0] in,

	output reg signed [1:0] sf
);

wire pos;
wire zero;
wire neg;
tricomp0_sync#(.N(N)) comp0(
	.in(in),
	.pos(pos), .zero(zero), .neg(neg)
);

always @* begin
	sf = 'hx;
	case ({pos, zero, neg})
	3'b100: sf = 2'b01;
	3'b010: sf = 2'b00;
	3'b001: sf = 2'b11;
	endcase
end

endmodule


module tricomp_sync#(parameter N = 9) (
	input wire [2*N-1:0] lhs,
	input wire neg_rhs,
	input wire [2*N-1:0] rhs,

	output reg gt,
	output reg eq,
	output reg lt
);
`include "utils.h"

integer ii;

function signed [1:0] cast_rhs(input [0:0] neg_rhs, input signed [1:0] trit);
	begin
		cast_rhs = util_trit_neg_cond(neg_rhs, trit);
	end
endfunction

reg flag;

always @* begin
	gt = 'hx;
	eq = 'hx;
	lt = 'hx;
	flag = 0;

	for (ii = 2*N-2; ii >= 0; ii = ii - 2) begin
		if (!flag) begin
			case ({lhs[ii+:2], cast_rhs(neg_rhs, rhs[ii+:2])})
			4'b0000: if (ii == 0) begin
				gt = 0;
				eq = 1;
				lt = 0;
			end
			4'b0100: begin
				gt = 1;
				eq = 0;
				lt = 0;
				flag = 1;
			end
			4'b1100: begin
				gt = 0;
				eq = 0;
				lt = 1;
				flag = 1;
			end
			4'b0001: begin
				gt = 0;
				eq = 0;
				lt = 1;
				flag = 1;
			end
			4'b0101: if (ii == 0) begin
				gt = 0;
				eq = 1;
				lt = 0;
			end
			4'b1101: begin
				gt = 0;
				eq = 0;
				lt = 1;
				flag = 1;
			end
			4'b0011: begin
				gt = 1;
				eq = 0;
				lt = 0;
				flag = 1;
			end
			4'b0111: begin
				gt = 1;
				eq = 0;
				lt = 0;
				flag = 1;
			end
			4'b1111: if (ii == 0) begin
				gt = 0;
				eq = 1;
				lt = 0;
			end
			default: flag = 1;
			endcase
		end
	end
end

endmodule


module triadd_sync#(parameter N = 9) (
	input wire signed [1:0] cf_i,
	input wire signed [1:0] cf_mode,
	input wire [2*N-1:0] lhs,
	input wire sub,
	input wire [2*N-1:0] rhs,

	output reg [2*N-1:0] res,
	output reg signed [1:0] cf,
	output reg signed [1:0] sf
);
`include "utils.h"

integer ii;

reg [3:0] extrit;

always @* begin
	cf = 0;
	if (util_trit_1(cf_mode))
		cf = cf_i;
	sf = 0;
	for (ii = 0; ii < 2*N; ii = ii + 2) begin
		extrit = util_halfadder(
			lhs[ii+:2],
			util_trit_neg_cond(sub, rhs[ii+:2]),
			cf,
			2'b00
		);
		res[ii+:2] = extrit[1:0];
		cf = extrit[3:2];
		sf = util_trit_usf(sf, res[ii+:2]);
	end
	if (util_trit_m1(cf_mode)) begin
		extrit = util_halfadder(cf, cf_i, 2'b00, 2'b00);
		cf = extrit[1:0];
	end
	sf = util_trit_usf(sf, cf);
end

endmodule


module triadd#(parameter N = 9) (
	input wire clk,
	input wire rst,

	input wire e,
	input wire signed [1:0] cf_i,
	input wire signed [1:0] cf_mode,
	input wire [2*N-1:0] lhs,
	input wire sub,
	input wire [2*N-1:0] rhs,

	output reg o,
	output reg [2*N-1:0] res,
	output reg signed [1:0] cf,
	output reg signed [1:0] sf
);

wire [2*N-1:0] res0;
wire signed [1:0] cf0;
wire signed [1:0] sf0;
triadd_sync#(.N(N)) add(
	.cf_i(cf_i), .cf_mode(cf_mode),
	.lhs(lhs), .sub(sub), .rhs(rhs),
	.res(res0), .cf(cf0), .sf(sf0)
);

always @(posedge clk) begin
	if (rst) begin
		o <= 0;
		res <= 'hxxxxx;
		cf <= 'hx;
		sf <= 'hx;
	end else begin
		o <= 0;
		if (e) begin
			o <= 1;
			res <= res0;
			cf <= cf0;
			sf <= sf0;
		end
	end
end

endmodule


module triinc_sync#(parameter N = 9) (
	input wire [2*N-1:0] in,

	output wire [2*N-1:0] res,
	output wire signed [1:0] cf,
	output wire signed [1:0] sf
);

triadd_sync#(.N(N)) add(
	.cf_i('hx), .cf_mode(2'b00),
	.lhs(in), .sub(1'b0), .rhs(18'b01),
	.res(res), .cf(cf), .sf(sf)
);

endmodule


module tridec_sync#(parameter N = 9) (
	input wire [2*N-1:0] in,

	output wire [2*N-1:0] res,
	output wire signed [1:0] cf,
	output wire signed [1:0] sf
);

triadd_sync#(.N(N)) add(
	.cf_i('hx), .cf_mode(2'b00),
	.lhs(in), .sub(1'b0), .rhs(18'b11),
	.res(res), .cf(cf), .sf(sf)
);

endmodule


module triaddtri_sync#(parameter N = 9) (
	input wire lsub,
	input wire [2*N-1:0] lhs,
	input wire msub,
	input wire [2*N-1:0] mhs,
	input wire rsub,
	input wire [2*N-1:0] rhs,

	output reg [2*N-1:0] res,
	output reg signed [1:0] cf,
	output reg signed [1:0] sf
);
`include "utils.h"

integer ii;

reg [3:0] extrit;

always @* begin
	cf = 0;
	sf = 0;
	for (ii = 0; ii < 2*N; ii = ii + 2) begin
		extrit = util_halfadder(
			util_trit_neg_cond(lsub, lhs[ii+:2]),
			util_trit_neg_cond(msub, mhs[ii+:2]),
			util_trit_neg_cond(rsub, rhs[ii+:2]),
			cf
		);
		res[ii+:2] = extrit[1:0];
		cf = extrit[3:2];
		sf = util_trit_usf(sf, res[ii+:2]);
	end
	sf = util_trit_usf(sf, cf);
end

endmodule


module triaddtri#(parameter N = 9) (
	input wire clk,
	input wire rst,

	input wire e,
	input wire lsub,
	input wire [2*N-1:0] lhs,
	input wire msub,
	input wire [2*N-1:0] mhs,
	input wire rsub,
	input wire [2*N-1:0] rhs,

	output reg o,
	output reg [2*N-1:0] res,
	output reg signed [1:0] cf,
	output reg signed [1:0] sf
);

wire [2*N-1:0] res0;
wire signed [1:0] cf0;
wire signed [1:0] sf0;
triaddtri_sync#(.N(N)) addtri(
	.lsub(lsub), .lhs(lhs), .msub(msub), .mhs(mhs), .rsub(rsub), .rhs(rhs),
	.res(res0), .cf(cf0), .sf(sf0)
);

always @(posedge clk) begin
	if (rst) begin
		o <= 0;
		res <= 'hxxxxx;
		cf <= 'hx;
		sf <= 'hx;
	end else begin
		o <= 0;
		if (e) begin
			o <= 1;
			res <= res0;
			cf <= cf0;
			sf <= sf0;
		end
	end
end

endmodule


module trimul (
	input wire clk,
	input wire rst,

	input wire e,
	input wire [17:0] lhs,
	input wire [17:0] rhs,

	output wire o,
	output wire [17:0] res,
	output wire signed [1:0] cf,
	output reg signed [1:0] sf
);

function [0:0] opsub(input signed [1:0] trit);
	begin
		opsub = 'hx;
		case (trit)
		2'b00: opsub = 'hx;
		2'b01: opsub = 1'b0;
		2'b11: opsub = 1'b1;
		endcase
	end
endfunction

function [17:0] ophs(input signed [1:0] trit, input [17:0] hs);
	begin
		ophs = 'hxxxxx;
		case (trit)
		2'b00: ophs = 0;
		2'b01: ophs = hs;
		2'b11: ophs = hs;
		endcase
	end
endfunction

function [0:0] f_acc_enable(
	input [0:0] lhs_ready,
	input [0:0] mhs_ready,
	input [0:0] rhs_ready
);
	begin
		f_acc_enable = 'hx;
		// Addition always takes the same amount of cycles.
		case ({lhs_ready, mhs_ready, rhs_ready})
		3'b000: f_acc_enable = 0;
		3'b111: f_acc_enable = 1;
		endcase
	end
endfunction

wire [17:0] temp_lhs;
wire temp_lhs_ready;
wire [17:0] temp_mhs;
wire temp_mhs_ready;
wire [17:0] temp_rhs;
wire temp_rhs_ready;

assign cf = 0;
wire acc_enable = f_acc_enable(temp_lhs_ready, temp_mhs_ready, temp_rhs_ready);

wire signed [1:0] lsf;
wire signed [1:0] rsf;
trisfcomp_sync trisfcomp_l(lhs, lsf);
trisfcomp_sync trisfcomp_r(rhs, rsf);

triaddtri l_add(
	.clk(clk), .rst(rst),
	.e(e),
	.lsub(opsub(rhs[0+:2])), .lhs(ophs(rhs[0+:2], lhs << 0)),
	.msub(opsub(rhs[2+:2])), .mhs(ophs(rhs[2+:2], lhs << 2)),
	.rsub(opsub(rhs[4+:2])), .rhs(ophs(rhs[4+:2], lhs << 4)),
	.o(temp_lhs_ready),
	.res(temp_lhs)
);
triaddtri m_add(
	.clk(clk), .rst(rst),
	.e(e),
	.lsub(opsub(rhs[6+:2])), .lhs(ophs(rhs[6+:2], lhs << 6)),
	.msub(opsub(rhs[8+:2])), .mhs(ophs(rhs[8+:2], lhs << 8)),
	.rsub(opsub(rhs[10+:2])), .rhs(ophs(rhs[10+:2], lhs << 10)),
	.o(temp_mhs_ready),
	.res(temp_mhs)
);
triaddtri r_add(
	.clk(clk), .rst(rst),
	.e(e),
	.lsub(opsub(rhs[12+:2])), .lhs(ophs(rhs[12+:2], lhs << 12)),
	.msub(opsub(rhs[14+:2])), .mhs(ophs(rhs[14+:2], lhs << 14)),
	.rsub(opsub(rhs[16+:2])), .rhs(ophs(rhs[16+:2], lhs << 16)),
	.o(temp_rhs_ready),
	.res(temp_rhs)
);
triaddtri acc_add(
	.clk(clk), .rst(rst),
	.e(acc_enable),
	.lsub(1'b0), .lhs(temp_lhs),
	.msub(1'b0), .mhs(temp_mhs),
	.rsub(1'b0), .rhs(temp_rhs),
	.o(o),
	.res(res)
);

function signed [1:0] bit_and(input signed [1:0] lhs, input signed [1:0] rhs);
	begin
		bit_and = 'hx;
		case ({lhs, rhs})
		4'b0000: bit_and = 2'b00;
		4'b0100: bit_and = 2'b00;
		4'b1100: bit_and = 2'b00;
		4'b0001: bit_and = 2'b00;
		4'b0101: bit_and = 2'b01;
		4'b1101: bit_and = 2'b11;
		4'b0011: bit_and = 2'b00;
		4'b0111: bit_and = 2'b11;
		4'b1111: bit_and = 2'b01;
		endcase
	end
endfunction

always @(posedge clk) begin
	if (e) begin
		sf <= bit_and(lsf, rsf);
	end
end

endmodule


// http://homepage.divms.uiowa.edu/~jones/ternary/multiply.shtml
/* balanced int rem, quo; [> the remainder and quotient, return values <]
 * void div( balanced int dividend, balanced int divisor ) {
 *     balanced int one = 1; [> determines whether to negate bits of quotient <]
 *     if (divisor < 0) { [> take absolute value of divisor <]
 *         divisor = -divisor;
 *         one = -one;
 *     }
 *     quo = dividend;
 *     rem = 0;
 *     for (i = 0; i < trits_per_word; i++) {
 *         [> first shift rem-quo double register 1 trit left <]
 *         (rem,quo) = (rem,quo) <<3 1;
 *
 *         [> second, compute one trit of quotient <]
 *         if (rem > 0) {
 *             balanced int low = rem - divisor;
 *             if ( (-low < rem)
 *             ||   ((-low == rem) && (quo > 0)) ) {
 *                 quo = quo + one;
 *                 rem = low;
 *             }
 *         } else if (rem < 0) {
 *             balanced int high = rem + divisor;
 *             if ( (-high > rem)
 *             ||   ((-high == rem) && (quo < 0)) ) {
 *                 quo = quo - one;
 *                 rem = high;
 *             }
 *         }
 *     }
 * } */
module tridiv (
	input wire clk,
	input wire rst,

	input wire e,
	input wire [17:0] lhs,
	input wire [17:0] rhs,

	output reg o,
	output reg divby0,
	output reg [17:0] quo_o,
	output reg signed [1:0] quo_cf_o,
	output reg signed [1:0] quo_sf_o,
	output reg [17:0] rem_o,
	output reg signed [1:0] rem_cf_o,
	output reg signed [1:0] rem_sf_o
);
`include "utils.h"

integer ii;

localparam ST = 9;

reg [17:0] div;
wire div_zero;
wire div_neg;
tricomp0_sync div_comp0(
	.in(div),
	.zero(div_zero), .neg(div_neg)
);

reg [17:0] quo;
wire quo_pos;
wire quo_zero;
wire quo_neg;
tricomp0_sync quo_comp0(
	.in(quo),
	.pos(quo_pos), .zero(quo_zero), .neg(quo_neg)
);

reg [17:0] rem;
wire rem_pos;
wire rem_neg;
tricomp0_sync rem_comp0(
	.in(rem),
	.pos(rem_pos), .neg(rem_neg)
);

reg [17:0] add_lhs;
reg add_sub;
reg [17:0] add_rhs;
wire [17:0] add_res;
triadd_sync add(
	.lhs(add_lhs), .sub(add_sub), .rhs(add_rhs),
	.res(add_res)
);

reg [17:0] comp_lhs;
reg comp_neg_rhs;
reg [17:0] comp_rhs;
wire comp_gt;
wire comp_eq;
wire comp_lt;
tricomp_sync comp(
	.lhs(comp_lhs), .neg_rhs(comp_neg_rhs), .rhs(comp_rhs),
	.gt(comp_gt), .eq(comp_eq), .lt(comp_lt)
);

reg next_quo_sf;
reg next_rem_sf;
reg signed [1:0] next_quo_trit;
reg [17:0] next_quo;
reg [17:0] next_rem;
reg [ST-2:0] state_reg;
wire [ST-1:0] state = {state_reg, e};

reg [17:0] quo_acc;
reg quo_sf;
reg [17:0] rem_acc;
reg rem_sf;
reg [17:0] rhs_acc;

always @* begin
	divby0 = 'hx;
	o = 'hx;
	quo_o = 'hxxxxx;
	quo_cf_o = 'hx;
	quo_sf_o = 'hx;
	rem_o = 'hxxxxx;
	rem_cf_o = 'hx;
	rem_sf_o = 'hx;

	add_lhs = 'hxxxxx;
	add_sub = 'hx;
	add_rhs = 'hxxxxx;

	comp_lhs = 'hxxxxx;
	comp_neg_rhs = 'hx;
	comp_rhs = 'hxxxxx;

	quo = 'hxxxxx;
	rem = 'hxxxxx;
	next_quo_trit = 'hx;
	next_quo = 'hxxxxx;
	next_rem = 'hxxxxx;

	if (|state) begin
		if (state[0]) begin
			div = rhs;
			quo = {lhs[15:0], 2'b00};
			rem = {16'h0, lhs[17-:2]};
		end else begin
			div = rhs_acc;
			quo = {quo_acc[15:0], 2'b00};
			rem = {rem_acc[15:0], quo_acc[17-:2]};
		end

		o = state[ST-1];
		if (o)
			divby0 = 0;

		next_quo_trit = 2'b00;
		next_rem = rem;
		if (rem_pos) begin
			add_lhs = rem;
			add_sub = !div_neg;
			add_rhs = div;
			comp_lhs = add_res;
			comp_neg_rhs = 1;
			comp_rhs = rem;
			if (comp_gt || (comp_eq && quo_pos)) begin
				next_quo_trit = div_neg ? 2'b11 : 2'b01;
				next_rem = add_res;
			end
		end else if (rem_neg) begin
			add_lhs = rem;
			add_sub = div_neg;
			add_rhs = div;
			comp_lhs = add_res;
			comp_neg_rhs = 1;
			comp_rhs = rem;
			if (comp_lt || (comp_eq && quo_neg)) begin
				next_quo_trit = div_neg ? 2'b01 : 2'b11;
				next_rem = add_res;
			end
		end
		next_quo = {quo[17:2], next_quo_trit};

		if (state[0] || quo_sf == 0)
			next_quo_sf = util_trit_sign(next_quo[0+:2]);
		if (state[0] || rem_sf == 0)
			next_rem_sf = util_trit_sign(next_rem[0+:2]);

		if (o) begin
			quo_o = next_quo;
			quo_cf_o = 0;
			quo_sf_o = next_quo_sf;
			rem_o = next_rem;
			rem_cf_o = 0;
			rem_sf_o = next_rem_sf;
		end

		if (div_zero) begin
			o = 1;
			divby0 = 1;
			quo_o = 'hxxxxx;
			quo_cf_o = 'hx;
			quo_sf_o = 'hx;
			rem_o = 'hxxxxx;
			rem_cf_o = 'hx;
			rem_sf_o = 'hx;
		end
	end
end

always @(posedge clk) begin
	if (rst || (|state && o && divby0)) begin
		state_reg <= 0;
	end else begin
		state_reg <= state[ST-2:0];
		if (state[0]) begin
			rhs_acc <= rhs;
		end
	end
	quo_acc <= next_quo;
	quo_sf <= next_quo_sf;
	rem_acc <= next_rem;
	rem_sf <= next_rem_sf;
end

endmodule


module trishl_sync (
	input wire [17:0] lhs,
	input wire neg_rhs,
	input wire [5:0] rhs,

	output reg [17:0] res,
	output reg signed [1:0] cf,
	output wire signed [1:0] sf
);
`include "utils.h"

function signed [1:0] cast_rhs(input [0:0] neg_rhs, input signed [1:0] trit);
	begin
		cast_rhs = util_trit_neg_cond(neg_rhs, trit);
	end
endfunction

trisfcomp_sync sfcomp(res, sf);

reg [3*18-1:0] tmp[0:3];

always @* begin
	cf = 0;
	tmp[1] = 'hxxxxxxxxxxxxxxxx;
	tmp[2] = 'hxxxxxxxxxxxxxxxx;
	tmp[3] = 'hxxxxxxxxxxxxxxxx;

	tmp[0] = {18'h0, lhs, 18'h0};

	case (cast_rhs(neg_rhs, rhs[1-:2]))
	2'b00: tmp[1] = tmp[0];
	2'b01: tmp[1] = {tmp[0][3*18-1-2:0], 2'h0};
	2'b11: tmp[1] = {2'h0, tmp[0][3*18-1:2]};
	endcase

	case (cast_rhs(neg_rhs, rhs[3-:2]))
	2'b00: tmp[2] = tmp[1];
	2'b01: tmp[2] = {tmp[1][3*18-1-6:0], 6'h0};
	2'b11: tmp[2] = {6'h0, tmp[1][3*18-1:6]};
	endcase

	case (cast_rhs(neg_rhs, rhs[5-:2]))
	2'b00: tmp[3] = tmp[2];
	2'b01: tmp[3] = {tmp[2][3*18-1-18:0], 18'h0};
	2'b11: tmp[3] = {18'h0, tmp[2][3*18-1:18]};
	endcase

	res = tmp[3][35:18];
end

endmodule


module tribit_sync#(parameter N = 9) (
	input wire [1:0] op,
	input wire [2*N-1:0] lhs,
	input wire [2*N-1:0] rhs,

	output reg [2*N-1:0] res,
	output reg signed [1:0] cf,
	output reg signed [1:0] sf
);
`include "utils.h"

localparam [1:0] OP_AND = 2'b01;
localparam [1:0] OP_XOR = 2'b10;

integer ii;

function signed [1:0] doop(
	input [1:0] op,
	input signed [1:0] lhs,
	input signed [1:0] rhs
);
	begin
		doop = 'hx;
		case (op)
		OP_AND:
			case ({lhs, rhs})
			4'b0000: doop = 2'b00;
			4'b0100: doop = 2'b00;
			4'b1100: doop = 2'b00;
			4'b0001: doop = 2'b00;
			4'b0101: doop = 2'b01;
			4'b1101: doop = 2'b11;
			4'b0011: doop = 2'b00;
			4'b0111: doop = 2'b11;
			4'b1111: doop = 2'b01;
			endcase
		OP_XOR:
			case ({lhs, rhs})
			4'b0000: doop = 2'b00;
			4'b0100: doop = 2'b01;
			4'b1100: doop = 2'b11;
			4'b0001: doop = 2'b01;
			4'b0101: doop = 2'b11;
			4'b1101: doop = 2'b00;
			4'b0011: doop = 2'b11;
			4'b0111: doop = 2'b00;
			4'b1111: doop = 2'b01;
			endcase
		endcase
	end
endfunction

always @* begin
	cf = 0;
	sf = 0;

	for (ii = 0; ii < 2*N; ii = ii + 2) begin
		res[ii+:2] = doop(op, lhs[ii+:2], rhs[ii+:2]);
		sf = util_trit_usf(sf, res[ii+:2]);
	end
end

endmodule
