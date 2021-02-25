`timescale 1ps / 1ps
`default_nettype none


module testbench_top_calls_hypercall_log (output reg completed);
`include "../utils.h"

integer ii;
integer msg[0:32] = "";

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

wire [31:0] m_axis_tdata;
wire m_axis_tlast;
reg m_axis_tready;
wire m_axis_tvalid;
top#(.P_LOGLEVEL(-1)) p_top(
	.CLK(clk), .RST(rst),

	.SW(2'b0),
	.BTN(4'b0),

	.m_axis_tdata(m_axis_tdata),
	.m_axis_tlast(m_axis_tlast),
	.m_axis_tready(m_axis_tready),
	.m_axis_tvalid(m_axis_tvalid)
);

initial begin
	completed = 0;
	m_axis_tready = 1;
	rst = 0;
	#160;
	rst = 1;

	msg[0] = "I";
	msg[1] = "n";
	msg[2] = "i";
	msg[3] = "t";
	msg[4] = "i";
	msg[5] = "a";
	msg[6] = "l";
	msg[7] = "i";
	msg[8] = "z";
	msg[9] = "i";
	msg[10] = "n";
	msg[11] = "g";
	msg[12] = " ";
	msg[13] = "o";
	msg[14] = "p";
	msg[15] = "e";
	msg[16] = "r";
	msg[17] = "a";
	msg[18] = "t";
	msg[19] = "i";
	msg[20] = "n";
	msg[21] = "g";
	msg[22] = " ";
	msg[23] = "s";
	msg[24] = "y";
	msg[25] = "s";
	msg[26] = "t";
	msg[27] = "e";
	msg[28] = "m";
	msg[29] = ".";
	msg[30] = ".";
	msg[31] = ".";
	msg[32] = 0;

	while (!m_axis_tvalid) #10;
	if (m_axis_tlast !== 1 || m_axis_tdata !== {25'h0, 7'b1000001})
		$error("[top_calls_hypercall_log] header");

	#10;
	while (!m_axis_tvalid) #10;
	if (m_axis_tlast !== 1 || m_axis_tdata !== {14'h0, 18'b11})
		$error("[top_calls_hypercall_log] level");

	for (ii = 0; ii <= 32; ii = ii + 1) begin
		#10;
		while (!m_axis_tvalid) #10;
		if (m_axis_tlast !== 1 || m_axis_tdata !== {14'h0, util_int_to_tryte(msg[ii])})
			$error("[top_calls_hypercall_log] msg %d", ii);
	end

	while (!p_top.cpu.p_extcall_ctrl.o_ready) #10;
	if (p_top.cpu.p_extcall_ctrl.o_pagefault !== 0 || p_top.cpu.p_extcall_ctrl.o_exit !== 0)
		$error("[top_calls_hypercall_log] extres %d", ii);

	completed = 1;
	$display("[top_calls_hypercall_log] Test completed.");
end

endmodule


module testbench_top (output wire completed);

wire [0:0] completion;
assign completed = &completion;
testbench_top_calls_hypercall_log p_top_calls_hypercall_log(completion[0]);

initial begin
	#10;
	while (!completed) #10;
	$display("[top] Test group completed.");
end

endmodule


// vim: tw=100 cc=101
