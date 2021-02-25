`timescale 1ps / 1ps
`default_nettype none

module testbench_util_trit_m1 (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_trit_m1(2'b11) !== 1'b1) $error("[util_trit_m1] #-");
	if (util_trit_m1(2'b00) !== 1'b0) $error("[util_trit_m1] #0");
	if (util_trit_m1(2'b01) !== 1'b0) $error("[util_trit_m1] #+");

	completed = 1;
	$display("[util_trit_m1] Test completed.");
end

endmodule


module testbench_util_trit_0 (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_trit_0(2'b11) !== 1'b0) $error("[util_trit_0] #-");
	if (util_trit_0(2'b00) !== 1'b1) $error("[util_trit_0] #0");
	if (util_trit_0(2'b01) !== 1'b0) $error("[util_trit_0] #+");

	completed = 1;
	$display("[util_trit_0] Test completed.");
end

endmodule


module testbench_util_trit_1 (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_trit_1(2'b11) !== 1'b0) $error("[util_trit_1] #-");
	if (util_trit_1(2'b00) !== 1'b0) $error("[util_trit_1] #0");
	if (util_trit_1(2'b01) !== 1'b1) $error("[util_trit_1] #+");

	completed = 1;
	$display("[util_trit_1] Test completed.");
end

endmodule


module testbench_util_tryte_check (output reg completed);
`include "../utils.h"

integer ii;

reg [17:0] tryte;

initial begin
	completed = 0;

	for (ii = -9841; ii <= 9841; ii = ii + 1) begin
		tryte = util_int_to_tryte(tryte);
		if (util_tryte_check(tryte) !== tryte)
			$error("[util_tryte_check] %d", ii);
	end

	completed = 1;
	$display("[util_tryte_check] Test completed.");
end

endmodule


module testbench_util_trit_neg (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_trit_neg(2'b11) !== 2'b01)
		$error("[util_trit_neg] #-");
	if (util_trit_neg(2'b00) !== 2'b00)
		$error("[util_trit_neg] #0");
	if (util_trit_neg(2'b01) !== 2'b11)
		$error("[util_trit_neg] #+");

	completed = 1;
	$display("[util_trit_neg] Test completed.");
end

endmodule


module testbench_util_trit_neg_cond (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_trit_neg_cond(1'b0, 2'b11) !== 2'b11)
		$error("[util_trit_neg_cond] 0 #-");
	if (util_trit_neg_cond(1'b0, 2'b00) !== 2'b00)
		$error("[util_trit_neg_cond] 0 #0");
	if (util_trit_neg_cond(1'b0, 2'b01) !== 2'b01)
		$error("[util_trit_neg_cond] 0 #+");
	if (util_trit_neg_cond(1'b1, 2'b11) !== 2'b01)
		$error("[util_trit_neg_cond] 1 #-");
	if (util_trit_neg_cond(1'b1, 2'b00) !== 2'b00)
		$error("[util_trit_neg_cond] 1 #0");
	if (util_trit_neg_cond(1'b1, 2'b01) !== 2'b11)
		$error("[util_trit_neg_cond] 1 #+");

	completed = 1;
	$display("[util_trit_neg_cond] Test completed.");
end

endmodule


module testbench_util_halfadder (output reg completed);
`include "../utils.h"

function [1:0] trunc2(input integer n);
	begin trunc2 = n[1:0]; end
endfunction
function [3:0] trunc4(input integer n);
	begin trunc4 = n[3:0]; end
endfunction

integer ii0;
integer ii1;
integer ii2;
integer ii3;
reg signed [1:0] t0;
reg signed [1:0] t1;
reg signed [1:0] t2;
reg signed [1:0] t3;
reg [3:0] tres;

initial begin
	completed = 0;

	for (ii0 = -1; ii0 <= 1; ii0 = ii0 + 1)
		for (ii1 = -1; ii1 <= 1; ii1 = ii1 + 1)
			for (ii2 = -1; ii2 <= 1; ii2 = ii2 + 1)
				for (ii3 = -1; ii3 <= 1; ii3 = ii3 + 1) begin
					t0 = trunc2(util_int_to_tryte(ii0));
					t1 = trunc2(util_int_to_tryte(ii1));
					t2 = trunc2(util_int_to_tryte(ii2));
					t3 = trunc2(util_int_to_tryte(ii3));
					tres = trunc4(util_int_to_tryte(ii0 + ii1 + ii2 + ii3));
					if (util_halfadder(t0, t1, t2, t3) !== tres) begin
						$error(
							"[util_halfadder] %d %d %d %d",
							ii0, ii1, ii2, ii3
						);
					end
				end

	completed = 1;
	$display("[util_halfadder] Test completed.");
end

endmodule


module testbench_util_5trits_to_8bits (output reg completed);
`include "../utils.h"

function [9:0] trunc10(input integer n);
	begin trunc10 = n[5:0]; end
endfunction

integer ii;

initial begin
	completed = 0;

	for (ii = -13; ii <= 13; ii = ii + 1) begin
		if (ii !== util_5trits_to_8bits(trunc10(util_int_to_tryte(ii))))
			$error("[util_5trits_to_8bits] %d", ii);
	end

	completed = 1;
	$display("[util_5trits_to_8bits] Test completed.");
end

endmodule


module testbench_util_int_to_tryte (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_int_to_tryte(-29524) !== 18'b111111111111111111) $error("[util_int_to_tryte] -29524");
	if (util_int_to_tryte(-29523) !== 18'b111111111111111100) $error("[util_int_to_tryte] -29523");
	if (util_int_to_tryte(-9841)  !== 18'b111111111111111111) $error("[util_int_to_tryte] -9841");
	if (util_int_to_tryte(-9840)  !== 18'b111111111111111100) $error("[util_int_to_tryte] -9840");
	if (util_int_to_tryte(-10)    !== 18'b000000000000110011) $error("[util_int_to_tryte] -10");
	if (util_int_to_tryte(-9)     !== 18'b000000000000110000) $error("[util_int_to_tryte] -9");
	if (util_int_to_tryte(-8)     !== 18'b000000000000110001) $error("[util_int_to_tryte] -8");
	if (util_int_to_tryte(-7)     !== 18'b000000000000110111) $error("[util_int_to_tryte] -7");
	if (util_int_to_tryte(-6)     !== 18'b000000000000110100) $error("[util_int_to_tryte] -6");
	if (util_int_to_tryte(-5)     !== 18'b000000000000110101) $error("[util_int_to_tryte] -5");
	if (util_int_to_tryte(-4)     !== 18'b000000000000001111) $error("[util_int_to_tryte] -4");
	if (util_int_to_tryte(-3)     !== 18'b000000000000001100) $error("[util_int_to_tryte] -3");
	if (util_int_to_tryte(-2)     !== 18'b000000000000001101) $error("[util_int_to_tryte] -2");
	if (util_int_to_tryte(-1)     !== 18'b000000000000000011) $error("[util_int_to_tryte] -1");
	if (util_int_to_tryte(0)      !== 18'b000000000000000000) $error("[util_int_to_tryte] 0");
	if (util_int_to_tryte(1)      !== 18'b000000000000000001) $error("[util_int_to_tryte] 1");
	if (util_int_to_tryte(2)      !== 18'b000000000000000111) $error("[util_int_to_tryte] 2");
	if (util_int_to_tryte(3)      !== 18'b000000000000000100) $error("[util_int_to_tryte] 3");
	if (util_int_to_tryte(4)      !== 18'b000000000000000101) $error("[util_int_to_tryte] 4");
	if (util_int_to_tryte(5)      !== 18'b000000000000011111) $error("[util_int_to_tryte] 5");
	if (util_int_to_tryte(6)      !== 18'b000000000000011100) $error("[util_int_to_tryte] 6");
	if (util_int_to_tryte(7)      !== 18'b000000000000011101) $error("[util_int_to_tryte] 7");
	if (util_int_to_tryte(8)      !== 18'b000000000000010011) $error("[util_int_to_tryte] 8");
	if (util_int_to_tryte(9)      !== 18'b000000000000010000) $error("[util_int_to_tryte] 9");
	if (util_int_to_tryte(10)     !== 18'b000000000000010001) $error("[util_int_to_tryte] 10");
	if (util_int_to_tryte(9840)   !== 18'b010101010101010100) $error("[util_int_to_tryte] 9840");
	if (util_int_to_tryte(9841)   !== 18'b010101010101010101) $error("[util_int_to_tryte] 9841");
	if (util_int_to_tryte(29523)  !== 18'b010101010101010100) $error("[util_int_to_tryte] 29523");
	if (util_int_to_tryte(29524)  !== 18'b010101010101010101) $error("[util_int_to_tryte] 29524");
	if (util_int_to_tryte(29526)  !== 18'b111111111111111100) $error("[util_int_to_tryte] 29526");

	completed = 1;
	$display("[util_int_to_tryte] Test completed.");
end

endmodule


module testbench_util_int_to_trits10 (output reg completed);
`include "../utils.h"

initial begin
	completed = 0;

	if (util_int_to_trits10(-29524) !== 20'b11111111111111111111) $error("[util_int_to_trits10] -29524");
	if (util_int_to_trits10(-29523) !== 20'b11111111111111111100) $error("[util_int_to_trits10] -29523");
	if (util_int_to_trits10(-9841)  !== 20'b00111111111111111111) $error("[util_int_to_trits10] -9841");
	if (util_int_to_trits10(-9840)  !== 20'b00111111111111111100) $error("[util_int_to_trits10] -9840");
	if (util_int_to_trits10(-10)    !== 20'b00000000000000110011) $error("[util_int_to_trits10] -10");
	if (util_int_to_trits10(-9)     !== 20'b00000000000000110000) $error("[util_int_to_trits10] -9");
	if (util_int_to_trits10(-8)     !== 20'b00000000000000110001) $error("[util_int_to_trits10] -8");
	if (util_int_to_trits10(-7)     !== 20'b00000000000000110111) $error("[util_int_to_trits10] -7");
	if (util_int_to_trits10(-6)     !== 20'b00000000000000110100) $error("[util_int_to_trits10] -6");
	if (util_int_to_trits10(-5)     !== 20'b00000000000000110101) $error("[util_int_to_trits10] -5");
	if (util_int_to_trits10(-4)     !== 20'b00000000000000001111) $error("[util_int_to_trits10] -4");
	if (util_int_to_trits10(-3)     !== 20'b00000000000000001100) $error("[util_int_to_trits10] -3");
	if (util_int_to_trits10(-2)     !== 20'b00000000000000001101) $error("[util_int_to_trits10] -2");
	if (util_int_to_trits10(-1)     !== 20'b00000000000000000011) $error("[util_int_to_trits10] -1");
	if (util_int_to_trits10(0)      !== 20'b00000000000000000000) $error("[util_int_to_trits10] 0");
	if (util_int_to_trits10(1)      !== 20'b00000000000000000001) $error("[util_int_to_trits10] 1");
	if (util_int_to_trits10(2)      !== 20'b00000000000000000111) $error("[util_int_to_trits10] 2");
	if (util_int_to_trits10(3)      !== 20'b00000000000000000100) $error("[util_int_to_trits10] 3");
	if (util_int_to_trits10(4)      !== 20'b00000000000000000101) $error("[util_int_to_trits10] 4");
	if (util_int_to_trits10(5)      !== 20'b00000000000000011111) $error("[util_int_to_trits10] 5");
	if (util_int_to_trits10(6)      !== 20'b00000000000000011100) $error("[util_int_to_trits10] 6");
	if (util_int_to_trits10(7)      !== 20'b00000000000000011101) $error("[util_int_to_trits10] 7");
	if (util_int_to_trits10(8)      !== 20'b00000000000000010011) $error("[util_int_to_trits10] 8");
	if (util_int_to_trits10(9)      !== 20'b00000000000000010000) $error("[util_int_to_trits10] 9");
	if (util_int_to_trits10(10)     !== 20'b00000000000000010001) $error("[util_int_to_trits10] 10");
	if (util_int_to_trits10(9840)   !== 20'b00010101010101010100) $error("[util_int_to_trits10] 9840");
	if (util_int_to_trits10(9841)   !== 20'b00010101010101010101) $error("[util_int_to_trits10] 9841");
	if (util_int_to_trits10(29523)  !== 20'b01010101010101010100) $error("[util_int_to_trits10] 29523");
	if (util_int_to_trits10(29524)  !== 20'b01010101010101010101) $error("[util_int_to_trits10] 29524");
	if (util_int_to_trits10(29526)  !== 20'b11111111111111111100) $error("[util_int_to_trits10] 29526");

	completed = 1;
	$display("[util_int_to_trits10] Test completed.");
end

endmodule


module testbench_utils (output wire completed);

wire [8:0] completion;
assign completed = &completion;
testbench_util_trit_m1 p_util_trit_m1(completion[0]);
testbench_util_trit_0 p_util_trit_0(completion[1]);
testbench_util_trit_1 p_util_trit_1(completion[2]);
testbench_util_tryte_check p_util_tryte_check(completion[3]);
testbench_util_trit_neg p_util_trit_neg(completion[4]);
testbench_util_trit_neg_cond p_util_trit_neg_cond(completion[5]);
testbench_util_halfadder p_util_halfadder(completion[6]);
testbench_util_5trits_to_8bits p_util_5trits_to_8bits(completion[7]);
testbench_util_int_to_tryte p_util_int_to_tryte(completion[8]);
testbench_util_int_to_trits10 p_util_int_to_trits10(completion[8]);

initial begin
	#10;
	while (!completed) #10;
	$display("[utils] Test group completed.");
end

endmodule


// vim: tw=100 cc=101
