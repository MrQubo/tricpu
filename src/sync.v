`timescale 1ps / 1ps
`default_nettype none

module sync#(
	parameter N = 1,
	parameter DELAY = 2,
	parameter INITIAL = {N{1'b0}}
) (
	input wire clk,
	input wire rst,
	input wire [N-1:0] in,
	output wire [N-1:0] out
);

integer ii;

reg [N-1:0] inter[0:DELAY-1];
assign out = inter[DELAY-1];

initial begin
	for (ii = 0; ii < DELAY; ii = ii + 1) begin
		inter[ii] = INITIAL;
	end
end

always @(posedge clk) begin
	if (rst) begin
		for (ii = 0; ii < DELAY; ii = ii + 1) begin
			inter[ii] = INITIAL;
		end
	end else begin
		inter[0] <= in;
		for (ii = 1; ii < DELAY; ii = ii + 1) begin
			inter[ii] <= inter[ii-1];
		end
	end
end

endmodule
