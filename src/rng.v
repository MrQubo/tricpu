`timescale 1ps / 1ps
`default_nettype none

module trirng (
        input wire clk,
        input wire rst,

        input wire noise,

        output reg [17:0] num
);

function [17:0] trifix (input [17:0] in);
        integer ii;
        begin
                trifix = 0;
                for (ii = 0; ii < 18; ii = ii + 2) begin
                        case (in[ii+:2])
                        2'b00: trifix[ii+:2] = 2'b00;
                        2'b01: trifix[ii+:2] = 2'b01;
                        2'b11: trifix[ii+:2] = 2'b11;
                        2'b10: begin
                                if (ii == 0)
                                        trifix[ii+:2] = 0;
                                else
                                        trifix[ii+:2] = trifix[ii-2+:2];
                        end
                        endcase
                end
        end
endfunction

wire [31:0] num_32;
rng_tkacik p_rng(
	.clk(clk), .rst(rst),
	.i_noise(noise),
	.o_num(num_32)
);

always @(posedge clk) begin
	num <= trifix(num_32[17:0]);
end

endmodule


// See https://doi.org/10.1007/3-540-36400-5_32
module rng_tkacik (
	input wire clk,
	input wire rst,

	input wire i_noise,

	output reg [31:0] o_num
);

reg [42:0] r_LFSR;
reg [42:0] n_LFSR;

reg [36:0] r_CASR;
reg [36:0] n_CASR;

reg [31:0] n_num;

always @* begin
	n_LFSR[42] = r_LFSR[41];
	n_LFSR[41] = r_LFSR[40] ^ r_LFSR[42];
	n_LFSR[40] = r_LFSR[39];
	n_LFSR[39] = r_LFSR[38];
	n_LFSR[38] = r_LFSR[37];
	n_LFSR[37] = r_LFSR[36];
	n_LFSR[36] = r_LFSR[35];
	n_LFSR[35] = r_LFSR[34];
	n_LFSR[34] = r_LFSR[33];
	n_LFSR[33] = r_LFSR[32];
	n_LFSR[32] = r_LFSR[31];
	n_LFSR[31] = r_LFSR[30];
	n_LFSR[30] = r_LFSR[29];
	n_LFSR[29] = r_LFSR[28];
	n_LFSR[28] = r_LFSR[27];
	n_LFSR[27] = r_LFSR[26];
	n_LFSR[26] = r_LFSR[25];
	n_LFSR[25] = r_LFSR[24];
	n_LFSR[24] = r_LFSR[23];
	n_LFSR[23] = r_LFSR[22];
	n_LFSR[22] = r_LFSR[21];
	n_LFSR[21] = r_LFSR[20];
	n_LFSR[20] = r_LFSR[19] ^ r_LFSR[42];
	n_LFSR[19] = r_LFSR[18];
	n_LFSR[18] = r_LFSR[17];
	n_LFSR[17] = r_LFSR[16];
	n_LFSR[16] = r_LFSR[15];
	n_LFSR[15] = r_LFSR[14];
	n_LFSR[14] = r_LFSR[13];
	n_LFSR[13] = r_LFSR[12];
	n_LFSR[12] = r_LFSR[11];
	n_LFSR[11] = r_LFSR[10];
	n_LFSR[10] = r_LFSR[9];
	n_LFSR[9] = r_LFSR[8];
	n_LFSR[8] = r_LFSR[7];
	n_LFSR[7] = r_LFSR[6];
	n_LFSR[6] = r_LFSR[5];
	n_LFSR[5] = r_LFSR[4];
	n_LFSR[4] = r_LFSR[3];
	n_LFSR[3] = r_LFSR[2];
	n_LFSR[2] = r_LFSR[1];
	n_LFSR[1] = r_LFSR[0] ^ r_LFSR[42];
	n_LFSR[0] = r_LFSR[42] ^ i_noise;

	n_CASR[36] = r_CASR[35] ^ r_CASR[0];
	n_CASR[35] = r_CASR[34] ^ r_CASR[36];
	n_CASR[34] = r_CASR[33] ^ r_CASR[35];
	n_CASR[33] = r_CASR[32] ^ r_CASR[34];
	n_CASR[32] = r_CASR[31] ^ r_CASR[33];
	n_CASR[31] = r_CASR[30] ^ r_CASR[32];
	n_CASR[30] = r_CASR[29] ^ r_CASR[31];
	n_CASR[29] = r_CASR[28] ^ r_CASR[30];
	n_CASR[28] = r_CASR[27] ^ r_CASR[29];
	n_CASR[27] = r_CASR[26] ^ r_CASR[27] ^ r_CASR[28];
	n_CASR[26] = r_CASR[25] ^ r_CASR[27];
	n_CASR[25] = r_CASR[24] ^ r_CASR[26];
	n_CASR[24] = r_CASR[23] ^ r_CASR[25];
	n_CASR[23] = r_CASR[22] ^ r_CASR[24];
	n_CASR[22] = r_CASR[21] ^ r_CASR[23];
	n_CASR[21] = r_CASR[20] ^ r_CASR[22];
	n_CASR[20] = r_CASR[19] ^ r_CASR[21];
	n_CASR[19] = r_CASR[18] ^ r_CASR[20];
	n_CASR[18] = r_CASR[17] ^ r_CASR[19];
	n_CASR[17] = r_CASR[16] ^ r_CASR[18];
	n_CASR[16] = r_CASR[15] ^ r_CASR[17];
	n_CASR[15] = r_CASR[14] ^ r_CASR[16];
	n_CASR[14] = r_CASR[13] ^ r_CASR[15];
	n_CASR[13] = r_CASR[12] ^ r_CASR[14];
	n_CASR[12] = r_CASR[11] ^ r_CASR[13];
	n_CASR[11] = r_CASR[10] ^ r_CASR[12];
	n_CASR[10] = r_CASR[9] ^ r_CASR[11];
	n_CASR[9] = r_CASR[8] ^ r_CASR[10];
	n_CASR[8] = r_CASR[7] ^ r_CASR[9];
	n_CASR[7] = r_CASR[6] ^ r_CASR[8];
	n_CASR[6] = r_CASR[5] ^ r_CASR[7];
	n_CASR[5] = r_CASR[4] ^ r_CASR[6];
	n_CASR[4] = r_CASR[3] ^ r_CASR[5];
	n_CASR[3] = r_CASR[2] ^ r_CASR[4];
	n_CASR[2] = r_CASR[1] ^ r_CASR[3];
	n_CASR[1] = r_CASR[0] ^ r_CASR[2];
	n_CASR[0] = r_CASR[36] ^ r_CASR[1];

	n_num = n_LFSR[31:0] ^ n_CASR[31:0];
end

always @(posedge clk) begin
	r_LFSR <= n_LFSR;
	r_CASR <= n_CASR;
	o_num <= n_num;
	if (rst) begin
		r_LFSR <= 1;
		r_CASR <= 1;
		o_num <= 32'd1337;
	end
end

endmodule
