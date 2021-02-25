`timescale 1ps / 1ps
`default_nettype none


module testbench_first_instrs (output reg completed);
`include "../utils.h"

integer ii;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

tricpu#(.P_LOGLEVEL(-1)) cpu(
	.clk(clk), .rst(rst),

	.stepping(1'b0),

	.s_axis_tvalid(1'b0),

	.m_axis_tready(1'b1)
);

initial begin
	completed = 0;
	rst = 1;
	#160;
	rst = 0;

	while (!cpu.ram.e) #10;

	// J 18'b000000000001111111
	if (cpu.ram.write !== 0) $error("[first_instrs] 0.0 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 0.0 pt");
	if (cpu.ram.addr !== 18'h0) $error("[first_instrs] 0.0 addr");
	#10;
	while (!cpu.ram.e) #10;
	if (cpu.ram.write !== 0) $error("[first_instrs] 0.1 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 0.1 pt");
	if (cpu.ram.addr !== 18'h1) $error("[first_instrs] 0.1 addr");
	#10;
	while (!cpu.ram.e) #10;

	// MOV @1 18'b000101110101010011
	if (cpu.ram.write !== 0) $error("[first_instrs] 1.0 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 1.0 pt");
	if (cpu.ram.addr !== 18'b000000000001111111)
		$error("[first_instrs] 1.0 addr");
	#10;
	while (!cpu.ram.e) #10;
	if (cpu.ram.write !== 0) $error("[first_instrs] 1.1 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 1.1 pt");
	if (cpu.ram.addr !== 18'b000000000001111100)
		$error("[first_instrs] 1.1 addr");
	#10;
	while (!cpu.ram.e) #10;
	if (cpu.regs[1] !== 18'b000101110101010011) $error("[first_instrs] 1.1 r1");

	// MOV @2 18'b0000000000000000011
	if (cpu.ram.write !== 0) $error("[first_instrs] 2.0 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 2.0 pt");
	if (cpu.ram.addr !== 18'b000000000001111101)
		$error("[first_instrs] 2.0 addr");
	#10;
	while (!cpu.ram.e) #10;
	if (cpu.regs[1] !== 18'b000101110101010011) $error("[first_instrs] 2.0 r1");
	if (cpu.ram.write !== 0) $error("[first_instrs] 2.1 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 2.1 pt");
	if (cpu.ram.addr !== 18'b000000000001110011)
		$error("[first_instrs] 2.1 addr");
	#10;
	while (!cpu.ram.e) #10;
	if (cpu.regs[1] !== 18'b000101110101010011) $error("[first_instrs] 2.1 r1");
	if (cpu.regs[2] !== 18'b000000000000000011) $error("[first_instrs] 2.1 r2");

	// HVC 1 (hypercall_log)
	if (cpu.ram.write !== 0) $error("[first_instrs] 3.0 write");
	if (cpu.ram.pt !== 2'b11) $error("[first_instrs] 3.0 pt");
	if (cpu.ram.addr !== 18'b000000000001110000)
		$error("[first_instrs] 3.0 addr");
	while (!cpu.p_extcall_ctrl.i_enable) #10;
	if (cpu.p_extcall_ctrl.i_type !== 1'b1 || cpu.p_extcall_ctrl.i_code !== 6'b000001)
		$error("[first_instrs] 3.0 extcall");
	while (!cpu.ram.e) #10;
	// reads first character of string
	if (cpu.ram.write !== 0) $error("[first_instrs] 3.1 write", ii);
	if (cpu.ram.pt !== 2'b01) $error("[first_instrs] 3.1 pt", ii);
	if (cpu.ram.addr !== 18'b000101110101010011) $error("[first_instrs] 3.1 addr", ii);

	completed = 1;
	$display("[first_instrs] Test completed.");
end

endmodule


module testbench_cpu_calls_hypercall_log (output reg completed);
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
tricpu#(.P_LOGLEVEL(-1)) cpu(
	.clk(clk), .rst(rst),

	.stepping(1'b0),

	.s_axis_tvalid(1'b0),

	.m_axis_tdata(m_axis_tdata),
	.m_axis_tlast(m_axis_tlast),
	.m_axis_tready(m_axis_tready),
	.m_axis_tvalid(m_axis_tvalid)
);

initial begin
	completed = 0;
	m_axis_tready = 1;
	rst = 1;
	#160;
	rst = 0;

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
		$error("[cpu_calls_hypercall_log] header");

	#10;
	while (!m_axis_tvalid) #10;
	if (m_axis_tlast !== 1 || m_axis_tdata !== {14'h0, 18'b11})
		$error("[cpu_calls_hypercall_log] level");

	for (ii = 0; ii <= 32; ii = ii + 1) begin
		#10;
		while (!m_axis_tvalid) #10;
		if (m_axis_tlast !== 1 || m_axis_tdata !== {14'h0, util_int_to_tryte(msg[ii])})
			$error("[cpu_calls_hypercall_log] msg %d", ii);
	end

	while (!cpu.p_extcall_ctrl.o_ready) #10;
	if (cpu.p_extcall_ctrl.o_pagefault !== 0 || cpu.p_extcall_ctrl.o_exit !== 0)
		$error("[cpu_calls_hypercall_log] extres %d", ii);

	completed = 1;
	$display("[cpu_calls_hypercall_log] Test completed.");
end

endmodule


module testbench_inf_loop (output reg completed);
`include "../utils.h"

integer ii;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

tricpu#(.BIN_FILENAME("zzz_test_inf_loop.bin")) cpu(
	.clk(clk), .rst(rst),

	.stepping(1'b0),

	.s_axis_tvalid(1'b0),

	.m_axis_tready(1'b1)
);

initial begin
	completed = 0;
	rst = 1;
	#160;
	rst = 0;

	while (!cpu.ram.e) #10;

	for (ii = 0; ii < 27; ii = ii + 1) begin
		// J 18'b000000000000000000
		if (cpu.ram.write !== 0) $error("[inf_loop] %d.0 write", ii);
		if (cpu.ram.pt !== 2'b11) $error("[inf_loop] %d.0 pt", ii);
		if (cpu.ram.addr !== 18'h0) $error("[inf_loop] %d.0 addr", ii);
		#10;
		while (!cpu.ram.e) #10;
		if (cpu.ram.write !== 0) $error("[inf_loop] %d.1 write", ii);
		if (cpu.ram.pt !== 2'b11) $error("[inf_loop] %d.1 pt", ii);
		if (cpu.ram.addr !== 18'h1) $error("[inf_loop] %d.1 addr", ii);
		#10;
		while (!cpu.ram.e) #10;
	end

	completed = 1;
	$display("[inf_loop] Test completed.");

end

endmodule


module testbench_cpu (output wire completed);

wire [2:0] completion;
assign completed = &completion;
testbench_first_instrs p_first_instrs(completion[0]);
testbench_cpu_calls_hypercall_log p_cpu_calls_hypercall_log(completion[1]);
testbench_inf_loop p_inf_loop(completion[2]);

initial begin
	#10;
	while (!completed) #10;
	$display("[cpu] Test group completed.");
end

endmodule


// vim: tw=100 cc=101
