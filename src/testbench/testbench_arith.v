`timescale 1ps / 1ps
`default_nettype none

module testbench_tricomp0_sync (output reg completed);
`include "../utils.h"

integer ii;

reg [17:0] in;
wire p;
wire z;
wire n;
wire [2:0] pzn = {p, z, n};

tricomp0_sync comp0(
	.in(in),
	.pos(p), .zero(z), .neg(n)
);

initial begin
	completed = 0;

	for (ii = -9841; ii <= 9841; ii = ii + 1) begin
		in = util_int_to_tryte(ii);
		#10;
		if (ii < 0)
			if (pzn !== 3'b001) $error("[tricomp0_sync] %d", ii);
		if (ii === 0)
			if (pzn !== 3'b010) $error("[tricomp0_sync] %d", ii);
		if (ii > 0)
			if (pzn !== 3'b100) $error("[tricomp0_sync] %d", ii);
	end

	completed = 1;
	$display("[tricomp0_sync] Test completed.");
end

endmodule


module testbench_trisfcomp_sync (output reg completed);
`include "../utils.h"

integer ii;

reg [17:0] in;
wire signed [1:0] sf;

trisfcomp_sync sfcomp(
	.in(in),
	.sf(sf)
);

initial begin
	completed = 0;

	for (ii = -9841; ii <= 9841; ii = ii + 1) begin
		in = util_int_to_tryte(ii);
		#10;
		if (ii < 0)
			if (sf !== 2'b11) $error("[trisfcomp_sync] %d", ii);
		if (ii === 0)
			if (sf !== 2'b00) $error("[trisfcomp_sync] %d", ii);
		if (ii > 0)
			if (sf !== 2'b01) $error("[trisfcomp_sync] %d", ii);
	end


	completed = 1;
	$display("[trisfcomp_sync] Test completed.");
end

endmodule


module testbench_tricomp_sync (output reg completed);
`include "../utils.h"

integer ii;
integer ij;

reg [17:0] lhs;
reg neg_rhs;
reg [17:0] rhs;
wire gt;
wire eq;
wire lt;
wire [2:0] gel = {gt, eq, lt};

tricomp_sync comp(
	.lhs(lhs), .neg_rhs(neg_rhs), .rhs(rhs),
	.gt(gt), .eq(eq), .lt(lt)
);

initial begin
	completed = 0;

	neg_rhs = 1'b0;
	for (ii = -10; ii <= 10; ii = ii + 1)
		for (ij = -9841; ij <= 9841; ij = ij + 1) begin
		lhs = util_int_to_tryte(ii);
		rhs = util_int_to_tryte(ij);
		#10;
		if (ii < ij)
			if (gel !== 3'b001) $error("[tricomp_sync] ~neg %d %d", ii, ij);
		if (ii === ij)
			if (gel !== 3'b010) $error("[tricomp_sync] ~neg %d %d", ii, ij);
		if (ii > ij)
			if (gel !== 3'b100) $error("[tricomp_sync] ~neg %d %d", ii, ij);
		end

	neg_rhs = 1'b1;
	for (ii = -10; ii <= 10; ii = ii + 1)
		for (ij = -9841; ij <= 9841; ij = ij + 1) begin
		lhs = util_int_to_tryte(ii);
		rhs = util_int_to_tryte(ij);
		#10;
		if (ii < -ij)
			if (gel !== 3'b001) $error("[tricomp_sync] neg %d %d", ii, ij);
		if (ii === -ij)
			if (gel !== 3'b010) $error("[tricomp_sync] neg %d %d", ii, ij);
		if (ii > -ij)
			if (gel !== 3'b100) $error("[tricomp_sync] neg %d %d", ii, ij);
		end

	completed = 1;
	$display("[tricomp_sync] Test completed.");
end

endmodule


module testbench_triadd_sync (output reg completed);
`include "../utils.h"
`include "numbers.h"

integer icf;
integer ii;
integer ilhs;
integer ij;
integer irhs;
integer ires;

reg signed [1:0] add_cf_i;
reg signed [1:0] add_cf_mode;
reg [17:0] add_lhs;
reg add_sub;
reg [17:0] add_rhs;
wire [17:0] add_res;
wire signed [1:0] add_cf;
wire signed [1:0] add_sf;
triadd_sync add(
	.cf_i(add_cf_i),
	.cf_mode(add_cf_mode),
	.lhs(add_lhs),
	.sub(add_sub),
	.rhs(add_rhs),

	.res(add_res),
	.cf(add_cf),
	.sf(add_sf)
);

initial begin
	completed = 0;

	for (icf = -1; icf <= 1; icf = icf + 1) begin
		add_cf_i = icf;

		add_cf_mode = 2'b00;
		add_sub = 0;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs + irhs;
				#10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd_sync] %d #0 ~sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b00;
		add_sub = 1;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs - irhs;
				#10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd_sync] %d #0 sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b01;
		add_sub = 0;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs + irhs + icf;
				#10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd_sync] %d #+ ~sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b01;
		add_sub = 1;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs - irhs + icf;
				#10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd_sync] %d #+ sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b11;
		add_sub = 0;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs + irhs + 19683 * icf;
				if (ires >= 29525)
					ires = ires - 59049;
				if (ires <= -29525)
					ires = ires +  59049;
				#10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd_sync] %d #- ~sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b11;
		add_sub = 1;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs - irhs + 19683 * icf;
				if (ires >= 29525)
					ires = ires - 59049;
				if (ires <= -29525)
					ires = ires +  59049;
				#10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd_sync] %d #- sub %d %d", icf, ilhs, irhs);
				end
			end
		end
	end

	completed = 1;
	$display("[triadd_sync] Test completed.");
end

endmodule


module testbench_triadd (output reg completed);
`include "../utils.h"
`include "numbers.h"

integer icf;
integer ii;
integer ilhs;
integer ij;
integer irhs;
integer ires;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg enable;
reg signed [1:0] add_cf_i;
reg signed [1:0] add_cf_mode;
reg [17:0] add_lhs;
reg add_sub;
reg [17:0] add_rhs;
wire ready;
wire [17:0] add_res;
wire signed [1:0] add_cf;
wire signed [1:0] add_sf;
triadd add(
	.clk(clk),
	.rst(rst),

	.e(enable),
	.cf_i(add_cf_i),
	.cf_mode(add_cf_mode),
	.lhs(add_lhs),
	.sub(add_sub),
	.rhs(add_rhs),

	.o(ready),
	.res(add_res),
	.cf(add_cf),
	.sf(add_sf)
);

initial begin
	completed = 0;
	rst = 1;
	#160;
	rst = 0;

	for (icf = -1; icf <= 1; icf = icf + 1) begin
		add_cf_i = icf;

		add_cf_mode = 2'b00;
		add_sub = 0;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				enable = 1;
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs + irhs;
				#10;
				enable = 0;
				while (!ready) #10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd] %d #0 ~sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b00;
		add_sub = 1;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				enable = 1;
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs - irhs;
				#10;
				enable = 0;
				while (!ready) #10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd] %d #0 sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b01;
		add_sub = 0;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				enable = 1;
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs + irhs + icf;
				#10;
				enable = 0;
				while (!ready) #10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd] %d #+ ~sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b01;
		add_sub = 1;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				enable = 1;
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs - irhs + icf;
				#10;
				enable = 0;
				while (!ready) #10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd] %d #+ sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b11;
		add_sub = 0;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				enable = 1;
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs + irhs + 19683 * icf;
				if (ires >= 29525)
					ires = ires - 59049;
				if (ires <= -29525)
					ires = ires +  59049;
				#10;
				enable = 0;
				while (!ready) #10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd] %d #- ~sub %d %d", icf, ilhs, irhs);
				end
			end
		end

		add_cf_mode = 2'b11;
		add_sub = 1;
		for (ii = 0; ii <= 24; ii = ii + 1) begin
			ilhs = util_test_numbers(ii);
			for (ij = 0; ij <= 24; ij = ij + 1) begin
				irhs = util_test_numbers(ij);
				enable = 1;
				add_lhs = util_int_to_tryte(ilhs);
				add_rhs = util_int_to_tryte(irhs);
				ires = ilhs - irhs + 19683 * icf;
				if (ires >= 29525)
					ires = ires - 59049;
				if (ires <= -29525)
					ires = ires +  59049;
				#10;
				enable = 0;
				while (!ready) #10;
				if (
					{add_cf, add_res} !== util_int_to_trits10(ires)
					|| (ires < 0 && add_sf !== 2'b11)
					|| (ires === 0 && add_sf !== 2'b00)
					|| (ires > 0 && add_sf !== 2'b01)
				) begin
					$error("[triadd] %d #- sub %d %d", icf, ilhs, irhs);
				end
			end
		end
	end

	enable = 1;
	add_cf_i = 2'b00;
	add_cf_mode = 2'b00;
	add_sub = 0;
	add_lhs = util_int_to_tryte(1);
	add_rhs = util_int_to_tryte(3);
	ires = 4;
	#10;
	enable = 0;
	while (!ready) #10;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b01)
		$error("[triadd] mem 0");
	#100;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b01)
		$error("[triadd] mem 1");
	add_lhs = util_int_to_tryte(-2);
	#100;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b01)
		$error("[triadd] mem 2");
	enable = 1;
	ires = 1;
	#10;
	enable = 0;
	while (!ready) #10;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b01)
		$error("[triadd] mem 3");
	#100;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b01)
		$error("[triadd] mem 4");
	add_sub = 1;
	#100;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b01)
		$error("[triadd] mem 5");
	enable = 1;
	ires = -5;
	#10;
	enable = 0;
	while (!ready) #10;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b11)
		$error("[triadd] mem 6");
	#100;
	if ({add_cf, add_res} !== util_int_to_trits10(ires) || add_sf !== 2'b11)
		$error("[triadd] mem 7");

	completed = 1;
	$display("[triadd] Test completed.");
end

endmodule


module testbench_triinc_sync (output reg completed);
`include "../utils.h"

integer ii;
integer ires;

reg [17:0] inc_in;
wire [17:0] inc_res;
wire signed [1:0] inc_cf;
wire signed [1:0] inc_sf;
triinc_sync inc(
	.in(inc_in),

	.res(inc_res),
	.cf(inc_cf),
	.sf(inc_sf)
);

initial begin
	completed = 0;

	for (ii = -9841; ii < -1; ii = ii + 1) begin
		inc_in = util_int_to_tryte(ii);
		ires = ii + 1;
		#10;
		if (
			inc_res !== util_int_to_tryte(ires)
			|| inc_cf !== 2'b00
			|| inc_sf !== 2'b11
		) begin
			$error("[triinc_sync] %d", ii);
		end
	end

	ii = -1;
	inc_in = util_int_to_tryte(ii);
	ires = ii + 1;
	#10;
	if (
		inc_res !== util_int_to_tryte(ires)
		|| inc_cf !== 2'b00
		|| inc_sf !== 2'b00
	) begin
		$error("[triinc_sync] %d", ii);
	end

	for (ii = 0; ii < 9841; ii = ii + 1) begin
		inc_in = util_int_to_tryte(ii);
		ires = ii + 1;
		#10;
		if (
			inc_res !== util_int_to_tryte(ires)
			|| inc_cf !== 2'b00
			|| inc_sf !== 2'b01
		) begin
			$error("[triinc_sync] %d", ii);
		end
	end

	ii = 9841;
	inc_in = util_int_to_tryte(ii);
	ires = -9841;
	#10;
	if (
		inc_res !== util_int_to_tryte(ires)
		|| inc_cf !== 2'b01
		|| inc_sf !== 2'b01
	) begin
		$error("[triinc_sync] %d", ii);
	end

	completed = 1;
	$display("[triinc_sync] Test completed.");
end

endmodule


module testbench_tridec_sync (output reg completed);
`include "../utils.h"

integer ii;
integer ires;

reg [17:0] dec_in;
wire [17:0] dec_res;
wire signed [1:0] dec_cf;
wire signed [1:0] dec_sf;
tridec_sync dec(
	.in(dec_in),

	.res(dec_res),
	.cf(dec_cf),
	.sf(dec_sf)
);

initial begin
	completed = 0;

	ii = -9841;
	dec_in = util_int_to_tryte(ii);
	ires = 9841;
	#10;
	if (
		dec_res !== util_int_to_tryte(ires)
		|| dec_cf !== 2'b11
		|| dec_sf !== 2'b11
	) begin
		$error("[tridec_sync] %d", ii);
	end

	for (ii = -9840; ii < 1; ii = ii + 1) begin
		dec_in = util_int_to_tryte(ii);
		ires = ii - 1;
		#10;
		if (
			dec_res !== util_int_to_tryte(ires)
			|| dec_cf !== 2'b00
			|| dec_sf !== 2'b11
		) begin
			$error("[tridec_sync] %d", ii);
		end
	end

	ii = 1;
	dec_in = util_int_to_tryte(ii);
	ires = ii - 1;
	#10;
	if (
		dec_res !== util_int_to_tryte(ires)
		|| dec_cf !== 2'b00
		|| dec_sf !== 2'b00
	) begin
		$error("[tridec_sync] %d", ii);
	end

	for (ii = 2; ii <= 9841; ii = ii + 1) begin
		dec_in = util_int_to_tryte(ii);
		ires = ii - 1;
		#10;
		if (
			dec_res !== util_int_to_tryte(ires)
			|| dec_cf !== 2'b00
			|| dec_sf !== 2'b01
		) begin
			$error("[tridec_sync] %d", ii);
		end
	end

	completed = 1;
	$display("[tridec_sync] Test completed.");
end

endmodule


module testbench_triaddtri_sync (output reg completed);
`include "../utils.h"
`include "numbers.h"

integer ils;
integer ilhsi;
integer ilhs;
integer ims;
integer imhsi;
integer imhs;
integer irs;
integer irhsi;
integer irhs;
integer ires;

reg lsub;
reg [17:0] lhs;
reg msub;
reg [17:0] mhs;
reg rsub;
reg [17:0] rhs;
wire [17:0] res;
wire signed [1:0] cf;
wire signed [1:0] sf;
triaddtri_sync add(
	.lsub(lsub),
	.lhs(lhs),
	.msub(msub),
	.mhs(mhs),
	.rsub(rsub),
	.rhs(rhs),

	.res(res),
	.cf(cf),
	.sf(sf)
);

initial begin
	completed = 0;

	for (ils = -1; ils <= 1; ils = ils + 2)
	for (ims = -1; ims <= 1; ims = ims + 2)
	for (irs = -1; irs <= 1; irs = irs + 2)
	for (ilhsi = 0; ilhsi <= 24; ilhsi = ilhsi + 1)
	for (imhsi = 0; imhsi <= 24; imhsi = imhsi + 1)
	for (irhsi = 0; irhsi <= 24; irhsi = irhsi + 1) begin
		lsub = ils == -1;
		msub = ims == -1;
		rsub = irs == -1;
		ilhs = util_test_numbers(ilhsi);
		imhs = util_test_numbers(imhsi);
		irhs = util_test_numbers(irhsi);
		lhs = util_int_to_tryte(ilhs);
		mhs = util_int_to_tryte(imhs);
		rhs = util_int_to_tryte(irhs);
		ires = ils * ilhs + ims * imhs + irs * irhs;
		#10;
		if (
			{cf, res} !== util_int_to_trits10(ires)
			|| (ires < 0 && sf !== 2'b11)
			|| (ires === 0 && sf !== 2'b00)
			|| (ires > 0 && sf !== 2'b01)
		) begin
			$error("[triaddtri_sync] %d %d %d %d %d %d", ils, ims, irs, ilhs, imhs, irhs);
		end
	end

	completed = 1;
	$display("[triaddtri_sync] Test completed.");
end

endmodule


module testbench_triaddtri (output reg completed);
`include "../utils.h"
`include "numbers.h"

integer ils;
integer ilhsi;
integer ilhs;
integer ims;
integer imhsi;
integer imhs;
integer irs;
integer irhsi;
integer irhs;
integer ires;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg enable;
reg lsub;
reg [17:0] lhs;
reg msub;
reg [17:0] mhs;
reg rsub;
reg [17:0] rhs;
wire ready;
wire [17:0] res;
wire signed [1:0] cf;
wire signed [1:0] sf;
triaddtri add(
	.clk(clk),
	.rst(rst),

	.e(enable),
	.lsub(lsub),
	.lhs(lhs),
	.msub(msub),
	.mhs(mhs),
	.rsub(rsub),
	.rhs(rhs),

	.o(ready),
	.res(res),
	.cf(cf),
	.sf(sf)
);

initial begin
	completed = 0;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;

	for (ils = -1; ils <= 1; ils = ils + 2)
	for (ims = -1; ims <= 1; ims = ims + 2)
	for (irs = -1; irs <= 1; irs = irs + 2)
	for (ilhsi = 0; ilhsi <= 24; ilhsi = ilhsi + 1)
	for (imhsi = 0; imhsi <= 24; imhsi = imhsi + 1)
	for (irhsi = 0; irhsi <= 24; irhsi = irhsi + 1) begin
		lsub = ils == -1;
		msub = ims == -1;
		rsub = irs == -1;
		ilhs = util_test_numbers(ilhsi);
		imhs = util_test_numbers(imhsi);
		irhs = util_test_numbers(irhsi);
		lhs = util_int_to_tryte(ilhs);
		mhs = util_int_to_tryte(imhs);
		rhs = util_int_to_tryte(irhs);
		ires = ils * ilhs + ims * imhs + irs * irhs;
		enable = 1;
		#10;
		enable = 0;
		while (!ready) #10;
		if (
			{cf, res} !== util_int_to_trits10(ires)
			|| (ires < 0 && sf !== 2'b11)
			|| (ires === 0 && sf !== 2'b00)
			|| (ires > 0 && sf !== 2'b01)
		) begin
			$error("[triaddtri] %d %d %d %d %d %d", ils, ims, irs, ilhs, imhs, irhs);
		end
	end

	enable = 1;
	lsub = 1;
	msub = 0;
	rsub = 0;
	lhs = util_int_to_tryte(2);
	mhs = util_int_to_tryte(1);
	rhs = util_int_to_tryte(1);
	ires = 0;
	#10;
	enable = 0;
	while (!ready) #10;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b00) $error("[triaddtri] mem 0");
	#100;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b00) $error("[triaddtri] mem 1");
	mhs = util_int_to_tryte(-2);
	#100;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b00) $error("[triaddtri] mem 2");
	enable = 1;
	ires = -3;
	#10;
	enable = 0;
	while (!ready) #10;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b11) $error("[triaddtri] mem 3");
	#100;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b11) $error("[triaddtri] mem 4");
	lsub = 0;
	#100;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b11) $error("[triaddtri] mem 5");
	enable = 1;
	ires = 1;
	#10;
	enable = 0;
	while (!ready) #10;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b01) $error("[triaddtri] mem 6");
	#100;
	if ({cf, res} !== util_int_to_trits10(ires) || sf !== 2'b01) $error("[triaddtri] mem 7");

	completed = 1;
	$display("[triaddtri] Test completed.");
end

endmodule


module testbench_trimul (output reg completed);
`include "../utils.h"
`include "numbers.h"

integer ilhsi;
integer ilhs;
integer irhsi;
integer irhs;
integer ires;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg enable;
reg [17:0] lhs;
reg [17:0] rhs;
wire [17:0] res;
wire ready;
wire signed [1:0] cf;
wire signed [1:0] sf;
trimul mul(
	.clk(clk),
	.rst(rst),

	.e(enable),
	.lhs(lhs),
	.rhs(rhs),

	.o(ready),
	.res(res),
	.cf(cf),
	.sf(sf)
);

initial begin
	completed = 0;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;

	for (ilhsi = 0; ilhsi <= 24; ilhsi = ilhsi + 1)
		for (irhsi = 0; irhsi <= 24; irhsi = irhsi + 1) begin
			ilhs = util_test_numbers(ilhsi);
			irhs = util_test_numbers(irhsi);
			lhs = util_int_to_tryte(ilhs);
			rhs = util_int_to_tryte(irhs);
			ires = ilhs * irhs;
			enable = 1;
			#10;
			enable = 0;
			while (!ready) #10;
			if (
				res !== util_int_to_tryte(ires) || cf !== 2'b00
				|| (ires < 0 && sf !== 2'b11)
				|| (ires == 0 && sf !== 2'b00)
				|| (ires > 0 && sf !== 2'b01)
			) begin
				$error("[trimul] %d %d", ilhs, irhs);
			end
		end

	enable = 1;
	lhs = util_int_to_tryte(2);
	rhs = util_int_to_tryte(3);
	ires = 6;
	#10;
	enable = 0;
	while (!ready) #10;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b01)
		$error("[trimul] mem 0");
	#100;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b01)
		$error("[trimul] mem 1");
	rhs = util_int_to_tryte(-5);
	#100;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b01)
		$error("[trimul] mem 2");
	enable = 1;
	ires = -10;
	#10;
	enable = 0;
	while (!ready) #10;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b11)
		$error("[trimul] mem 3");
	#100;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b11)
		$error("[trimul] mem 4");
	lhs = util_int_to_tryte(0);
	#100;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b11)
		$error("[trimul] mem 5");
	enable = 1;
	ires = 0;
	#10;
	enable = 0;
	while (!ready) #10;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b00)
		$error("[trimul] mem 6");
	#100;
	if (res !== util_int_to_tryte(ires) || cf !== 2'b00 || sf !== 2'b00)
		$error("[trimul] mem 7");

	completed = 1;
	$display("[trimul] Test completed.");
end

endmodule


module testbench_trishl_sync (output reg completed);
`include "../utils.h"
`include "numbers.h"

integer ilhsi;
integer ilhs;
integer irs;
integer irhs;

reg [17:0] exp_res;

reg [17:0] lhs;
reg neg_rhs;
reg [5:0] rhs;
wire [17:0] res;
wire signed [1:0] cf;
wire signed [1:0] sf;
trishl_sync shl(
	.lhs(lhs),
	.neg_rhs(neg_rhs),
	.rhs(rhs),

	.res(res),
	.cf(cf),
	.sf(sf)
);

initial begin
	completed = 0;

	for (irs = -1; irs <= 1; irs = irs + 2)
	for (ilhsi = 0; ilhsi <= 24; ilhsi = ilhsi + 1)
	for (irhs = -13; irhs <= 13; irhs = irhs + 1) begin
		neg_rhs = irs == -1;
		ilhs = util_test_numbers(ilhsi);
		lhs = util_int_to_tryte(ilhs);
		rhs = util_int_to_tryte(irhs);
		if (neg_rhs) begin
			if (irhs < 0)
				exp_res = lhs << (2 * (-irhs));
			else
				exp_res = lhs >> (2 * irhs);
		end else begin
			if (irhs < 0)
				exp_res = lhs >> (2 * (-irhs));
			else
				exp_res = lhs << (2 * irhs);
		end
		#10;
		// XXX: Not testing sf.
		if (res !== exp_res || cf !== 0) $error("[trishl_sync] %d %d %d", irs, ilhs, irhs);
	end

	completed = 1;
	$display("[trishl_sync] Test completed.");
end

endmodule


module testbench_arith (output wire completed);

wire [10:0] completion;
assign completed = &completion;
testbench_tricomp0_sync p_tricomp0_sync(completion[0]);
testbench_trisfcomp_sync p_trisfcomp_sync(completion[1]);
testbench_tricomp_sync p_tricomp_sync(completion[2]);
testbench_triadd_sync p_triadd_sync(completion[3]);
testbench_triadd p_triadd(completion[4]);
testbench_triinc_sync p_triinc_sync(completion[5]);
testbench_tridec_sync p_tridec_sync(completion[6]);
testbench_triaddtri_sync p_triaddtri_sync(completion[7]);
testbench_triaddtri p_triaddtri(completion[8]);
testbench_trimul p_trimul(completion[9]);
testbench_trishl_sync p_trishl_sync(completion[10]);

initial begin
	#10;
	while (!completed) #10;
	$display("[arith] Test group completed.");
end

endmodule


// vim: tw=100 cc=101
