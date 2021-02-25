`timescale 1ps / 1ps
`default_nettype none


module testbench_ram_direct_read (output reg completed);
`include "../utils.h"

integer ipt;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg [17:0] psw;
reg enable;
reg signed [1:0] pt;
reg [17:0] addr;
wire ready;
wire pagefault;
wire [17:0] out;
triram ram(
	.clk(clk),
	.rst(rst),

	.psw(psw),

	.e(enable),
	.write(1'b0),
	.pt(pt),
	.addr(addr),

	.o(ready),
	.pagefault(pagefault),
	.out(out)
);

initial begin
	completed = 0;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;
	#10;

	for (ipt = -1; ipt <= 1; ipt = ipt + 1) begin
		pt = ipt;

		psw = 18'h0;
		enable = 1;
		addr = 18'h0;
		#10;
		enable = 0;
		if (ready !== 1) $error("[ram_direct_read] %d 0 ready", ipt);
		if (pagefault !== 0) $error("[ram_direct_read] %d 0 pagefault", ipt);
		if (out !== 18'b111111000000000000) $error("[ram_direct_read] %d 0 out", ipt);

		psw = 18'h0;
		psw[2*(4+ipt)+:2] = 2'b01;
		enable = 1;
		addr = util_int_to_tryte(1916);
		#10;
		enable = 0;
		if (ready !== 1) $error("[ram_direct_read] %d 1 ready", ipt);
		if (pagefault !== 1) $error("[ram_direct_read] %d 1 pagefault", ipt);

		#10;

		psw = 18'h0;
		enable = 1;
		addr = util_int_to_tryte(1916);
		#10;
		enable = 0;
		if (ready !== 1) $error("[ram_direct_read] %d 2 ready", ipt);
		if (pagefault !== 0) $error("[ram_direct_read] %d 2 pagefault", ipt);
		if (out !== 18'b111111000011000000) $error("[ram_direct_read] %d 2 out", ipt);

		#10;

		psw = 18'h0;
		psw[2*(4+ipt)+:2] = 2'b11;
		enable = 1;
		addr = util_int_to_tryte(697);
		#10;
		enable = 0;
		if (ready !== 1) $error("[ram_direct_read] %d 3 ready", ipt);
		if (pagefault !== 1) $error("[ram_direct_read] %d 3 pagefault", ipt);

		psw = 18'h0;
		enable = 1;
		addr = util_int_to_tryte(697);
		#10;
		enable = 0;
		if (ready !== 1) $error("[ram_direct_read] %d 4 ready", ipt);
		if (pagefault !== 0) $error("[ram_direct_read] %d 4 pagefault", ipt);
		if (out !== 18'b111111001101000100) $error("[ram_direct_read] %d 4 out", ipt);
	end

	completed = 1;
	$display("[ram_direct_read] Test completed.");
end

endmodule


module testbench_ram (output wire completed);

wire [0:0] completion;
assign completed = &completion;
testbench_ram_direct_read p_ram_direct_read(completion[0]);

initial begin
	#10;
	while (!completed) #10;
	$display("[ram] Test group completed.");
end

endmodule


// vim: tw=100 cc=101
