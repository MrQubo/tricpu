function [0:0] util_trit_0(input signed [1:0] trit);
	begin
		util_trit_0 = 'hx;
		case (trit)
		2'b00: util_trit_0 = 1;
		2'b01: util_trit_0 = 0;
		2'b11: util_trit_0 = 0;
		endcase
	end
endfunction
function [0:0] util_trit_1(input signed [1:0] trit);
	begin
		util_trit_1 = 'hx;
		case (trit)
		2'b00: util_trit_1 = 0;
		2'b01: util_trit_1 = 1;
		2'b11: util_trit_1 = 0;
		endcase
	end
endfunction
function [0:0] util_trit_m1(input signed [1:0] trit);
	begin
		util_trit_m1 = 'hx;
		case (trit)
		2'b00: util_trit_m1 = 0;
		2'b01: util_trit_m1 = 0;
		2'b11: util_trit_m1 = 1;
		endcase
	end
endfunction

function signed [1:0] util_trit_sign(input signed [1:0] trit);
	begin
		util_trit_sign = 'hx;
		case (trit)
		2'b00: util_trit_sign = 2'b00;
		2'b01: util_trit_sign = 2'b01;
		2'b11: util_trit_sign = 2'b11;
		endcase
	end
endfunction
function signed [1:0] util_trit_usf(
	input signed [1:0] sf,
	input signed [1:0] trit
);
	begin
		util_trit_usf = 'hx;
		case (trit)
		2'b00: util_trit_usf = sf;
		2'b01: util_trit_usf = 2'b01;
		2'b11: util_trit_usf = 2'b11;
		endcase
	end
endfunction

function [17:0] util_tryte_check(input [17:0] tryte);
	integer ii;
	reg valid;
	begin
		valid = 1;
		for (ii = 17; ii > 0; ii = ii - 2) begin
			if (tryte[ii-:2] == 2'b10)
				valid = 0;
		end
		if (valid)
			util_tryte_check = tryte;
		else
			util_tryte_check = 'hxxxxx;
	end
endfunction

function signed [1:0] util_trit_neg(input signed [1:0] trit);
	begin
		util_trit_neg = 'hx;
		case (trit)
		2'b00: util_trit_neg = 2'b00;
		2'b01: util_trit_neg = 2'b11;
		2'b11: util_trit_neg = 2'b01;
		endcase
	end
endfunction

function signed [1:0] util_trit_neg_cond(
	input [0:0] neg,
	input signed [1:0] trit
);
	begin
		util_trit_neg_cond = 'hx;
		case (trit)
		2'b00: util_trit_neg_cond = 2'b00;
		2'b01: util_trit_neg_cond = neg ? 2'b11 : 2'b01;
		2'b11: util_trit_neg_cond = neg ? 2'b01 : 2'b11;
		endcase
	end
endfunction

function [3:0] util_halfadder(
	input signed [1:0] t0,
	input signed [1:0] t1,
	input signed [1:0] t2,
	input signed [1:0] t3
);
	begin
		util_halfadder = 'hx;
		case ({t0, t1, t2, t3})
		8'b11111111: util_halfadder = 4'b1111;
		8'b11111100: util_halfadder = 4'b1100;
		8'b11111101: util_halfadder = 4'b1101;
		8'b11110011: util_halfadder = 4'b1100;
		8'b11110000: util_halfadder = 4'b1101;
		8'b11110001: util_halfadder = 4'b0011;
		8'b11110111: util_halfadder = 4'b1101;
		8'b11110100: util_halfadder = 4'b0011;
		8'b11110101: util_halfadder = 4'b0000;
		8'b11001111: util_halfadder = 4'b1100;
		8'b11001100: util_halfadder = 4'b1101;
		8'b11001101: util_halfadder = 4'b0011;
		8'b11000011: util_halfadder = 4'b1101;
		8'b11000000: util_halfadder = 4'b0011;
		8'b11000001: util_halfadder = 4'b0000;
		8'b11000111: util_halfadder = 4'b0011;
		8'b11000100: util_halfadder = 4'b0000;
		8'b11000101: util_halfadder = 4'b0001;
		8'b11011111: util_halfadder = 4'b1101;
		8'b11011100: util_halfadder = 4'b0011;
		8'b11011101: util_halfadder = 4'b0000;
		8'b11010011: util_halfadder = 4'b0011;
		8'b11010000: util_halfadder = 4'b0000;
		8'b11010001: util_halfadder = 4'b0001;
		8'b11010111: util_halfadder = 4'b0000;
		8'b11010100: util_halfadder = 4'b0001;
		8'b11010101: util_halfadder = 4'b0111;
		8'b00111111: util_halfadder = 4'b1100;
		8'b00111100: util_halfadder = 4'b1101;
		8'b00111101: util_halfadder = 4'b0011;
		8'b00110011: util_halfadder = 4'b1101;
		8'b00110000: util_halfadder = 4'b0011;
		8'b00110001: util_halfadder = 4'b0000;
		8'b00110111: util_halfadder = 4'b0011;
		8'b00110100: util_halfadder = 4'b0000;
		8'b00110101: util_halfadder = 4'b0001;
		8'b00001111: util_halfadder = 4'b1101;
		8'b00001100: util_halfadder = 4'b0011;
		8'b00001101: util_halfadder = 4'b0000;
		8'b00000011: util_halfadder = 4'b0011;
		8'b00000000: util_halfadder = 4'b0000;
		8'b00000001: util_halfadder = 4'b0001;
		8'b00000111: util_halfadder = 4'b0000;
		8'b00000100: util_halfadder = 4'b0001;
		8'b00000101: util_halfadder = 4'b0111;
		8'b00011111: util_halfadder = 4'b0011;
		8'b00011100: util_halfadder = 4'b0000;
		8'b00011101: util_halfadder = 4'b0001;
		8'b00010011: util_halfadder = 4'b0000;
		8'b00010000: util_halfadder = 4'b0001;
		8'b00010001: util_halfadder = 4'b0111;
		8'b00010111: util_halfadder = 4'b0001;
		8'b00010100: util_halfadder = 4'b0111;
		8'b00010101: util_halfadder = 4'b0100;
		8'b01111111: util_halfadder = 4'b1101;
		8'b01111100: util_halfadder = 4'b0011;
		8'b01111101: util_halfadder = 4'b0000;
		8'b01110011: util_halfadder = 4'b0011;
		8'b01110000: util_halfadder = 4'b0000;
		8'b01110001: util_halfadder = 4'b0001;
		8'b01110111: util_halfadder = 4'b0000;
		8'b01110100: util_halfadder = 4'b0001;
		8'b01110101: util_halfadder = 4'b0111;
		8'b01001111: util_halfadder = 4'b0011;
		8'b01001100: util_halfadder = 4'b0000;
		8'b01001101: util_halfadder = 4'b0001;
		8'b01000011: util_halfadder = 4'b0000;
		8'b01000000: util_halfadder = 4'b0001;
		8'b01000001: util_halfadder = 4'b0111;
		8'b01000111: util_halfadder = 4'b0001;
		8'b01000100: util_halfadder = 4'b0111;
		8'b01000101: util_halfadder = 4'b0100;
		8'b01011111: util_halfadder = 4'b0000;
		8'b01011100: util_halfadder = 4'b0001;
		8'b01011101: util_halfadder = 4'b0111;
		8'b01010011: util_halfadder = 4'b0001;
		8'b01010000: util_halfadder = 4'b0111;
		8'b01010001: util_halfadder = 4'b0100;
		8'b01010111: util_halfadder = 4'b0111;
		8'b01010100: util_halfadder = 4'b0100;
		8'b01010101: util_halfadder = 4'b0101;
		endcase
	end
endfunction


function signed [4:0] util_3trits_to_5bits(input [5:0] trits);
	integer ii;
	begin
		util_3trits_to_5bits = 0;
		for (ii = 5; ii > 0; ii = ii - 2) begin
			util_3trits_to_5bits =
				$signed(trits[ii-:2]) + 3*util_3trits_to_5bits;
		end
	end
endfunction

function signed [7:0] util_5trits_to_8bits(input [9:0] trits);
	integer ii;
	begin
		util_5trits_to_8bits = 0;
		for (ii = 9; ii > 0; ii = ii - 2) begin
			util_5trits_to_8bits =
				$signed(trits[ii-:2]) + 3*util_5trits_to_8bits;
		end
	end
endfunction

function [17:0] util_int_to_tryte(input integer n);
	integer ii;
	begin
		util_int_to_tryte = 'hxxxxx;
		for (ii = 0; ii < 18; ii = ii + 2) begin
			case (n % 3)
			0: begin
				util_int_to_tryte[ii+:2] = 2'b00;
			end
			-2: begin
				util_int_to_tryte[ii+:2] = 2'b01;
				n = n - 1;
			end
			1: begin
				util_int_to_tryte[ii+:2] = 2'b01;
				n = n - 1;
			end
			-1: begin
				util_int_to_tryte[ii+:2] = 2'b11;
				n = n + 1;
			end
			2: begin
				util_int_to_tryte[ii+:2] = 2'b11;
				n = n + 1;
			end
			endcase
			n = n / 3;
		end
	end
endfunction
function [19:0] util_int_to_trits10(input integer n);
	integer ii;
	begin
		util_int_to_trits10 = 'hxxxxx;
		for (ii = 0; ii < 20; ii = ii + 2) begin
			case (n % 3)
			0: begin
				util_int_to_trits10[ii+:2] = 2'b00;
			end
			-2: begin
				util_int_to_trits10[ii+:2] = 2'b01;
				n = n - 1;
			end
			1: begin
				util_int_to_trits10[ii+:2] = 2'b01;
				n = n - 1;
			end
			-1: begin
				util_int_to_trits10[ii+:2] = 2'b11;
				n = n + 1;
			end
			2: begin
				util_int_to_trits10[ii+:2] = 2'b11;
				n = n + 1;
			end
			endcase
			n = n / 3;
		end
	end
endfunction
