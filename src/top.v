`timescale 1ps / 1ps
`default_nettype none

module top#(parameter integer P_LOGLEVEL = 0) (
	input wire CLK,
	input wire RST,

	input wire [1:0] SW,
	input wire [3:0] BTN,
	output wire [3:0] LED,
	output wire [26:0] GPIO,

	input wire [31:0] s_axis_tdata,
	input wire s_axis_tlast,
	output wire s_axis_tready,
	input wire s_axis_tvalid,

	output wire [31:0] m_axis_tdata,
	output wire m_axis_tlast,
	input wire m_axis_tready,
	output wire m_axis_tvalid
);

/* wire clk = BTN[2];
 * wire rst;
 * sync rst_sync(clk, 1'b0, ~RST, rst); */

wire clk = CLK;
wire rst = ~RST;

wire [1:0] sw;
sync#(.N(2)) sw_sync(clk, rst, SW, sw);

wire [3:0] btn;
sync#(.N(4)) btn_sync(clk, rst, BTN, btn);

wire [3:0] led;
sync#(.N(4), .DELAY(1)) led_sync(clk, rst, led, LED);

reg [15:0] rst_ctr;
initial rst_ctr = 16'hffff;
always @(posedge clk) begin
	if (btn[0] || rst)
		rst_ctr <= 16'hffff;
	else
		rst_ctr <= rst_ctr >> 1;
end
wire cpu_rst = rst_ctr[0];

reg [31:0] btn2_hist;
wire stepping = sw[0];
reg do_step;
always @(posedge clk) begin
	btn2_hist <= {btn2_hist, btn[2]};
	do_step <= btn2_hist == 32'h7fffffff;
end

wire halted;
wire [17:0] pc;
assign GPIO = {8'h1, pc, 1'b1};
tricpu#(.P_LOGLEVEL(P_LOGLEVEL)) cpu(
	.clk(clk),
	.rst(cpu_rst),

	.noise(btn[3]),

	.halted(halted),

	.stepping(stepping),
	.do_step(do_step),

	.o_pc(pc),

	.s_axis_tdata(s_axis_tdata),
	.s_axis_tlast(s_axis_tlast),
	.s_axis_tready(s_axis_tready),
	.s_axis_tvalid(s_axis_tvalid),

	.m_axis_tdata(m_axis_tdata),
	.m_axis_tlast(m_axis_tlast),
	.m_axis_tready(m_axis_tready),
	.m_axis_tvalid(m_axis_tvalid)
);
assign led = {4{halted}};

endmodule
