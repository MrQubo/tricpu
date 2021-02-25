`timescale 1ps / 1ps
`default_nettype none


module testbench_termcall_beep (output reg completed);

integer ii;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg occ;

wire [31:0] m_axis_tdata;
wire m_axis_tlast;
reg m_axis_tready;
wire m_axis_tvalid;
reg enable;
reg type;
reg [5:0] code;
wire ready;
wire pagefault;
wire exit;
m_extcall_controller ectrl(
	.i_clk(clk),
	.i_rst(rst),

	.o_m_axis_tdata(m_axis_tdata),
	.o_m_axis_tlast(m_axis_tlast),
	.i_m_axis_tready(m_axis_tready),
	.o_m_axis_tvalid(m_axis_tvalid),

	.i_enable(enable),
	.i_type(type),
	.i_code(code),

	.o_ready(ready),
	.o_pagefault(pagefault),
	.o_exit(exit)
);

initial begin
	completed = 0;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;
	#10;

	occ = 0;
	m_axis_tready = 1;
	enable = 1;
	type = 1'b0;
	code = 6'b000011;
	#10;
	enable = 0;
	while (!ready) begin
		if (m_axis_tvalid) begin
			if (occ) $error("[termcall_beep] occ 0");
			if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b11)
				$error("[termcall_beep] m_axis 0");
			occ = 1;
		end
		#10;
	end
	if (m_axis_tvalid) begin
		if (occ) $error("[termcall_beep] occ 0");
		if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b11)
			$error("[termcall_beep] m_axis 0");
		occ = 1;
	end
	if (!occ) $error("[termcall_beep] ~occ 0");
	if (pagefault !== 0 || exit !== 0) $error("[termcall_beep] res 0");
	#10;

	occ = 0;
	m_axis_tready = 0;
	enable = 1;
	type = 1'b0;
	code = 6'b000011;
	#10;
	enable = 0;
	if (ready === 1) $error("[termcall_beep] preocc 1");
	for (ii = 0; ii < 9; ii = ii + 1) begin
		#1;
		if (ready === 1) $error("[termcall_beep] preocc 1");
		#9;
	end
	m_axis_tready = 1;
	#1;
	while (!ready) begin
		if (m_axis_tvalid) begin
			if (occ) $error("[termcall_beep] occ 1");
			if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b11)
				$error("[termcall_beep] m_axis 1");
			occ = 1;
		end
		#10;
	end
	if (m_axis_tvalid) begin
		if (occ) $error("[termcall_beep] occ 1");
		if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b11)
			$error("[termcall_beep] m_axis 1");
		occ = 1;
	end
	if (!occ) $error("[termcall_beep] ~occ 1");
	if (pagefault !== 0 || exit !== 0) $error("[termcall_beep] res 1");
	#9;

	completed = 1;
	$display("[termcall_beep] Test completed.");
end

endmodule


module testbench_termcall_putc (output reg completed);

integer ii;
integer reg_idx;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg [17:0] regs[1:4];

wire [31:0] m_axis_tdata;
wire m_axis_tlast;
reg m_axis_tready;
wire m_axis_tvalid;
reg enable;
reg type;
reg [5:0] code;
wire ready;
wire pagefault;
wire exit;
m_extcall_controller ectrl(
	.i_clk(clk),
	.i_rst(rst),

	.i_r1(regs[1]),
	.i_r2(regs[2]),
	.i_r3(regs[3]),
	.i_r4(regs[4]),

	.o_m_axis_tdata(m_axis_tdata),
	.o_m_axis_tlast(m_axis_tlast),
	.i_m_axis_tready(m_axis_tready),
	.o_m_axis_tvalid(m_axis_tvalid),

	.i_enable(enable),
	.i_type(type),
	.i_code(code),

	.o_ready(ready),
	.o_pagefault(pagefault),
	.o_exit(exit)
);

initial begin
	completed = 0;

	regs[1] = 18'h110011;
	regs[2] = 18'h010011;
	regs[3] = 18'h110111;
	regs[4] = 18'h010100;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;
	#10;

	reg_idx = 1;
	m_axis_tready = 1;
	enable = 1;
	type = 1'b0;
	code = 6'b000000;
	#10;
	enable = 0;
	while (!ready) begin
		if (m_axis_tvalid) begin
			if (reg_idx > 4) $error("[termcall_putc] occ 0");
			if (m_axis_tlast !== 1 || m_axis_tdata !== {14'h0, regs[reg_idx]})
				$error("[termcall_putc] m_axis 0");
			reg_idx = reg_idx + 1;
		end
		#10;
	end
	if (m_axis_tvalid) begin
		if (reg_idx > 4) $error("[termcall_putc] occ 0");
		if (m_axis_tlast !== 1 || m_axis_tdata !== {14'h0, regs[reg_idx]})
			$error("[termcall_putc] m_axis 0");
		reg_idx = reg_idx + 1;
	end
	if (reg_idx < 5) $error("[termcall_putc] ~occ 0");
	if (pagefault !== 0 || exit !== 0) $error("[termcall_putc] res 0");
	#10;

	completed = 1;
	$display("[termcall_putc] Test completed.");
end

endmodule


module testbench_hypercall_exit (output reg completed);

integer ii;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

reg occ;

wire [31:0] m_axis_tdata;
wire m_axis_tlast;
reg m_axis_tready;
wire m_axis_tvalid;
reg enable;
reg type;
reg [5:0] code;
wire ready;
wire pagefault;
wire exit;
m_extcall_controller ectrl(
	.i_clk(clk),
	.i_rst(rst),

	.o_m_axis_tdata(m_axis_tdata),
	.o_m_axis_tlast(m_axis_tlast),
	.i_m_axis_tready(m_axis_tready),
	.o_m_axis_tvalid(m_axis_tvalid),

	.i_enable(enable),
	.i_type(type),
	.i_code(code),

	.o_ready(ready),
	.o_pagefault(pagefault),
	.o_exit(exit)
);

initial begin
	completed = 0;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;
	#10;

	occ = 0;
	m_axis_tready = 1;
	enable = 1;
	type = 1'b1;
	code = 6'b000000;
	#10;
	enable = 0;
	while (!ready) begin
		if (m_axis_tvalid) begin
			if (occ) $error("[hypercall_exit] occ 0");
			if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b1000000)
				$error("[hypercall_exit] m_axis 0");
			occ = 1;
		end
		#10;
	end
	if (m_axis_tvalid) begin
		if (occ) $error("[hypercall_exit] occ 0");
		if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b1000000)
			$error("[hypercall_exit] m_axis 0");
		occ = 1;
	end
	if (!occ) $error("[hypercall_exit] ~occ 0");
	if (pagefault !== 0 || exit !== 1) $error("[hypercall_exit] res 0");
	#10;

	occ = 0;
	m_axis_tready = 0;
	enable = 1;
	type = 1'b1;
	code = 6'b000000;
	#10;
	enable = 0;
	if (ready === 1) $error("[hypercall_exit] preocc 1");
	for (ii = 0; ii < 9; ii = ii + 1) begin
		#1;
		if (ready === 1) $error("[hypercall_exit] preocc 1");
		#9;
	end
	m_axis_tready = 1;
	#1;
	while (!ready) begin
		if (m_axis_tvalid) begin
			if (occ) $error("[hypercall_exit] occ 1");
			if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b1000000)
				$error("[hypercall_exit] m_axis 1");
			occ = 1;
		end
		#10;
	end
	if (m_axis_tvalid) begin
		if (occ) $error("[hypercall_exit] occ 1");
		if (m_axis_tlast !== 1 || m_axis_tdata !== 32'b1000000)
			$error("[hypercall_exit] m_axis 1");
		occ = 1;
	end
	if (!occ) $error("[hypercall_exit] ~occ 1");
	if (pagefault !== 0 || exit !== 1) $error("[hypercall_exit] res 1");
	#9;

	completed = 1;
	$display("[hypercall_exit] Test completed.");
end

endmodule


module testbench_hypercall_log (output wire completed);
`include "../utils.h"

reg [1:0] completion;
initial completion = 0;
assign completed = &completion;

reg clk;
initial clk = 0;
always #5 if (!completed) clk = ~clk;
reg rst;

wire [31:0] m_axis_tdata;
wire m_axis_tlast;
reg m_axis_tready;
wire m_axis_tvalid;
wire ram_enable;
wire ram_write;
wire signed [1:0] ram_pt;
wire [17:0] ram_addr;
reg ram_ready;
reg ram_pagefault;
reg [17:0] ram_out;
reg enable;
reg type;
reg [5:0] code;
wire ready;
wire pagefault;
wire exit;
m_extcall_controller ectrl(
	.i_clk(clk),
	.i_rst(rst),

	.o_m_axis_tdata(m_axis_tdata),
	.o_m_axis_tlast(m_axis_tlast),
	.i_m_axis_tready(m_axis_tready),
	.o_m_axis_tvalid(m_axis_tvalid),

	.i_r1(18'h0),
	.i_r2(18'h0),

	.o_ram_enable(ram_enable),
	.o_ram_write(ram_write),
	.o_ram_pt(ram_pt),
	.o_ram_addr(ram_addr),
	.i_ram_ready(ram_ready),
	.i_ram_pagefault(ram_pagefault),
	.i_ram_out(ram_out),

	.i_enable(enable),
	.i_type(type),
	.i_code(code),

	.o_ready(ready),
	.o_pagefault(pagefault),
	.o_exit(exit)
);

integer addr_idx;
integer ictr;
integer igap;

initial begin
	completion[0] = 0;

	enable = 0;
	rst = 1;
	#160;
	rst = 0;
	#10;

	for (igap = 0; igap <= 5; igap = igap + 1) begin
		addr_idx = -1;
		m_axis_tready = 1;
		enable = 1;
		type = 1'b1;
		code = 6'b000001;
		#10;
		type = 'hx;
		code = 'hxx;
		enable = 0;
		ictr = 0;
		#1;
		while (!ready) begin
			if (m_axis_tvalid && m_axis_tready) begin
				if (addr_idx === -1) begin
					if (m_axis_tlast !== 1 || m_axis_tdata !== 32'h0) begin
						$error(
							"[hypercall_log] m_axis %d %d",
							igap, addr_idx
						);
					end
				end else if (addr_idx < 10) begin
					if (
						m_axis_tlast !== 1
						|| m_axis_tdata
							!== {14'h0, util_int_to_tryte(2*addr_idx-1)}
					) begin
						$error(
							"[hypercall_log] m_axis %d %d",
							igap, addr_idx
						);
					end
				end else if (addr_idx === 10) begin
					if (m_axis_tlast !== 1 || m_axis_tdata !== 32'h0) begin
						$error(
							"[hypercall_log] m_axis %d %d",
							igap, addr_idx
						);
					end
				end else if (addr_idx > 10) begin
					$error("[hypercall_log] occ %d", igap);
				end
				addr_idx = addr_idx + 1;
				#9;
				if (igap !== 0) begin
					m_axis_tready = 0;
					ictr = 0;
				end
				#1;
			end else begin
				#9;
				ictr = ictr + 1;
				if (ictr === igap)
					m_axis_tready = 1;
				#1;
			end
		end
		if (m_axis_tvalid && m_axis_tready) begin
			if (addr_idx === -1) begin
				if (m_axis_tlast !== 1 || m_axis_tdata !== 32'h0)
					$error("[hypercall_log] m_axis %d %d", igap, addr_idx);
			end else if (addr_idx < 10) begin
				if (
					m_axis_tlast !== 1
					|| m_axis_tdata
						!== {14'h0, util_int_to_tryte(2*addr_idx-1)}
				) begin
					$error("[hypercall_log] m_axis %d %d", igap, addr_idx);
				end
			end else if (addr_idx === 10) begin
				if (m_axis_tlast !== 1 || m_axis_tdata !== 32'h0)
					$error("[hypercall_log] m_axis %d %d", igap, addr_idx);
			end else if (addr_idx > 10) begin
				$error("[hypercall_log] occ %d", igap);
			end
			addr_idx = addr_idx + 1;
		end
		if (addr_idx < 11) $error("[hypercall_log] ~occ %d %d", igap, addr_idx);
		if (pagefault !== 0 || exit !== 0) $error("[hypercall_log] res %d", igap);
		#9;
	end

	completion[0] = 1;
end

integer ictr_mmu;
integer ram_idx;

initial begin
	completion[1] = 0;

	ram_idx = 0;
	ram_ready = 0;
	ram_pagefault = 'hx;
	ram_out = 'hxxxxx;
	ictr_mmu = 0;

	#10;
	#1;
	while (~completion[0]) begin
		if (ram_enable) begin
			if (
				ram_write !== 0 || ram_pt !== 2'b01
				|| ram_addr !== util_int_to_tryte(ram_idx)
			) begin
				$error("[hypercall_log] ram %d", ram_idx);
			end

			#9;
			ram_ready = 0;
			if (ictr_mmu === 7) begin
				#1;
				if (ram_enable !== 0)
					$error("[hypercall_log] ram_enable %d", ram_idx);
				#9;
				ictr_mmu = 0;
			end else begin
				ictr_mmu = ictr_mmu + 1;
			end

			if (ram_idx === 10) begin
				ram_out = util_int_to_tryte(0);
				ram_idx = 0;
			end else begin
				ram_out = util_int_to_tryte(2 * ram_idx - 1);
				ram_idx = ram_idx + 1;
			end
			ram_ready = 1;
			ram_pagefault = 0;
			#1;
			if (!ram_enable) begin
				#9;
				ram_ready = 0;
				ram_pagefault = 'hx;
				#1;
			end
		end else begin
			#10;
		end
	end

	completion[1] = 1;
end

initial begin
	#10;
	while (~completed) #10;
	$display("[hypercall_log] Test completed.");
end

endmodule


module testbench_extcall (output wire completed);

wire [3:0] completion;
assign completed = &completion;
testbench_termcall_beep p_termcall_beep(completion[0]);
testbench_termcall_putc p_termcall_putc(completion[1]);
testbench_hypercall_exit p_hypercall_exit(completion[2]);
testbench_hypercall_log p_hypercall_log(completion[3]);

initial begin
	#10;
	while (!completed) #10;
	$display("[extcall] Test group completed.");
end

endmodule


// vim: tw=100 cc=101
