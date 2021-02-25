`timescale 1ps / 1ps
`default_nettype none

module triram#(parameter BIN_FILENAME = "zzz_bram.bin") (
	input wire clk,
	input wire rst,

	// sregs
	input wire [17:0] pgtn,
	input wire [17:0] psw,
	input wire [17:0] pgtp,

	// invalidate MMU cache, cache must be invalidated on sregs change or
	//	pte modification
	input wire invalidate_cache,

	// enable, must be held only for one cycle
	input wire e,
	// 0-read, 1-write
	input wire write,
	// -1-X, 0-W, 1-R
	input wire signed [1:0] pt,
	// address
	input wire [17:0] addr,
	// data_in, relevant iff write=1
	input wire [17:0] in,
	// only one of o or pagefault will be enentually held
	// output ready, held only for one cycle
	output reg o,
	// page pagefault, held only for one cycle
	output reg pagefault,
	// output (preserved until next read/write)
	output reg [17:0] out
);
`include "utils.h"

localparam signed [1:0] C_PT_X = 2'b11;
localparam signed [1:0] C_PT_W = 2'b00;
localparam signed [1:0] C_PT_R = 2'b01;

integer ii;

localparam [4:0] triXM = 5'h3;
localparam [4:0] triWM = 5'h4;
localparam [4:0] triRM = 5'h5;
localparam [4:0] triXP = 5'h6;
localparam [4:0] triWP = 5'h7;
localparam [4:0] triRP = 5'h8;
wire signed [1:0] xm;
wire signed [1:0] wm;
wire signed [1:0] rm;
wire signed [1:0] xp;
wire signed [1:0] wp;
wire signed [1:0] rp;
assign xm = psw[2*triXM+:2];
assign wm = psw[2*triWM+:2];
assign rm = psw[2*triRM+:2];
assign xp = psw[2*triXP+:2];
assign wp = psw[2*triWP+:2];
assign rp = psw[2*triRP+:2];

function signed [1:0] pt_to_ring(input [17:0] psw, input signed [1:0] pt);
	begin
		pt_to_ring = 'hx;
		case (pt)
		2'b11: pt_to_ring = psw[2*triXM+:2];
		2'b00: pt_to_ring = psw[2*triWM+:2];
		2'b01: pt_to_ring = psw[2*triRM+:2];
		endcase
	end
endfunction
function signed [1:0] pt_to_mode(input [17:0] psw, input signed [1:0] pt);
	begin
		pt_to_mode = 'hx;
		case (pt)
		2'b11: pt_to_mode = psw[2*triXP+:2];
		2'b00: pt_to_mode = psw[2*triWP+:2];
		2'b01: pt_to_mode = psw[2*triRP+:2];
		endcase
	end
endfunction
function [17:0] mode_to_pgt(
	input [17:0] pgtp,
	input [17:0] pgtn,
	input signed [1:0] mode
);
	begin
		mode_to_pgt = 'hxxxxx;
		case (mode)
		2'b01: mode_to_pgt = pgtp;
		2'b11: mode_to_pgt = pgtn;
		endcase
	end
endfunction
function signed [1:0] pte_pt_to_paccess(input [17:0] pte, input signed [1:0] pt);
	begin
		pte_pt_to_paccess = 'hx;
		case (pt)
		2'b11: pte_pt_to_paccess = pte[0+:2];
		2'b00: pte_pt_to_paccess = pte[2+:2];
		2'b01: pte_pt_to_paccess = pte[4+:2];
		endcase
	end
endfunction


localparam integer BRAM_SIZE = 2**17;
reg [17:0] bram[0:BRAM_SIZE-1];
initial begin
	$readmemb(BIN_FILENAME, bram);
end

reg r_pagefault;
reg n_pagefault;
reg s_pagefault;

reg r_rdy;
reg n_rdy;
reg s_rdy;

reg r_pte_pgt;
reg n_pte_pgt;
reg s_pte_pgt;

reg r_write;
reg n_write;
reg s_write;

reg signed [1:0] r_pt;
reg signed [1:0] n_pt;
reg s_pt;

reg [17:0] r_addr;
reg [17:0] n_addr;
reg s_addr;

reg [17:0] r_in;
reg [17:0] n_in;
reg s_in;

reg [17:0] r_bram_out;
reg [17:0] n_bram_in;
reg [23:0] c_bram_addr;
reg s_do_read;
reg s_do_write;

localparam [0:0] C_CACHE_X = 1'b0;
localparam [0:0] C_CACHE_WR = 1'b1;
reg r_cache_valid[0:1];
reg n_cache_valid[0:1];
reg signed [1:0] r_cache_pt[0:1];
reg signed [1:0] n_cache_pt[0:1];
reg [17:0] r_cache_addr[0:1];
reg [17:0] n_cache_addr[0:1];
reg [17:0] r_cache_pte[0:1];
reg [17:0] n_cache_pte[0:1];
reg s_cache[0:1];

reg signed [1:0] c_ring_e;
reg signed [1:0] c_ring_pte;
reg signed [1:0] c_mode;
reg signed [1:0] c_paccess;
reg [17:0] c_pgt;
reg [17:0] c_pte;

reg c_cache_hit;

// stats of physical addresses usage for game.nb
// min: -376
// max: 24998
wire [16:0] s_bram_addr_compressed = {
	/*9'*/c_bram_addr[18:10],
	/*8'*/util_5trits_to_8bits(c_bram_addr[9:0])
};

always @* begin
	o = 'hx;
	pagefault = 'hx;
	out = util_tryte_check(r_bram_out);

	s_pte_pgt = 0;
	n_pte_pgt = 'hx;

	s_rdy = 0;
	n_rdy = 'hx;

	s_pagefault = 0;
	n_pagefault = 'hx;

	s_write = 0;
	n_write = 'hx;

	s_pt = 0;
	n_pt = 'hx;

	s_addr = 0;
	n_addr = 'hxxxxx;

	s_in = 0;
	n_in = 'hxxxxx;

	s_do_read = 0;
	s_do_write = 0;
	n_bram_in = 'hxxxxx;
	c_bram_addr = 'hxxxxxx;

	for (ii = 0; ii <= 1; ii = ii + 1) begin
		s_cache[ii] = 0;
		n_cache_valid[ii] = 'hx;
		n_cache_pt[ii] = 'hx;
		n_cache_addr[ii] = 'hxxxxx;
		n_cache_pte[ii] = 'hxxxxx;
	end

	c_ring_e = 'hx;
	c_ring_pte = 'hx;
	c_mode = 'hx;
	c_paccess = 'hx;
	c_pgt = 'hxxxxx;
	c_pte = 'hxxxxx;

	c_cache_hit = 'hx;


	s_pte_pgt = 1;
	n_pte_pgt = 0;

	s_rdy = 1;
	n_rdy = 0;

	s_pagefault = 1;
	n_pagefault = 0;

	if (e) begin
		c_ring_e = pt_to_ring(psw, pt);
		c_mode = pt_to_mode(psw, pt);
		c_pgt = mode_to_pgt(pgtp, pgtn, c_mode);
		o = 0;
		if (util_trit_0(c_mode)) begin
			// direct access
			s_rdy = 1;
			n_rdy = 1;

			if (!util_trit_0(c_ring_e)) begin
				s_pagefault = 1;
				n_pagefault = 1;
			end else begin
				s_do_write = write;
			end

			s_do_read = 1;
			c_bram_addr = {6'b000000, addr};
			n_bram_in = in;
		end else begin
			c_cache_hit = 0;
			for (ii = 0; ii <= 1; ii = ii + 1) begin
				if (
					pt == r_cache_pt[ii]
					&& r_cache_valid[ii]
					&& r_cache_addr[ii][12+:6] == addr[12+:6]
				) begin
					s_rdy = 1;
					n_rdy = 1;

					s_do_read = 1;
					s_do_write = write;
					c_bram_addr = {
						r_cache_pte[ii][6+:12],
						addr[0+:12]
					};
					n_bram_in = in;

					c_cache_hit = 1;
				end
			end
			if (!c_cache_hit) begin
				s_pte_pgt = 1;
				n_pte_pgt = 1;

				// read pte
				s_do_read = 1;
				c_bram_addr = {c_pgt, addr[12+:6]};

				s_write = 1;
				n_write = write;
				s_pt = 1;
				n_pt = pt;
				s_addr = 1;
				n_addr = addr;
				s_in = 1;
				n_in = in;
			end
		end
	end
	if (r_pte_pgt) begin
		c_ring_pte = pt_to_ring(psw, r_pt);
		c_pte = util_tryte_check(r_bram_out);
		c_paccess = pte_pt_to_paccess(c_pte, r_pt);
		o = 0;
		if (
			util_trit_0(c_paccess)
			|| (util_trit_m1(c_paccess) && !util_trit_0(c_ring_pte))
		) begin
			o = 1;
			pagefault = 1;
		end else begin
			s_rdy = 1;
			n_rdy = 1;

			s_do_read = 1;
			s_do_write = r_write;
			c_bram_addr = {c_pte[6+:12], r_addr[0+:12]};
			n_bram_in = r_in;

			if (r_pt == C_PT_X) begin
				s_cache[C_CACHE_X] = 1;
				n_cache_valid[C_CACHE_X] = 1;
				n_cache_pt[C_CACHE_X] = r_pt;
				n_cache_addr[C_CACHE_X] = r_addr;
				n_cache_pte[C_CACHE_X] = c_pte;
			end else begin
				s_cache[C_CACHE_WR] = 1;
				n_cache_valid[C_CACHE_WR] = 1;
				n_cache_pt[C_CACHE_WR] = r_pt;
				n_cache_addr[C_CACHE_WR] = r_addr;
				n_cache_pte[C_CACHE_WR] = c_pte;
			end
		end
	end
	if (r_rdy) begin
		o = 1;
		pagefault = r_pagefault;
	end

	if (invalidate_cache) begin
		for (ii = 0; ii <= 1; ii = ii + 1) begin
			s_cache[ii] = 1;
			n_cache_valid[ii] = 0;
		end
	end
	if (s_do_write) begin
		for (ii = 0; ii <= 1; ii = ii + 1) begin
			if (c_bram_addr == {
				mode_to_pgt(
					pgtp, pgtn,
					pt_to_mode(psw, r_cache_pt[ii])
				),
				r_cache_addr[ii][12+:6]
			}) begin
				s_cache[ii] = 1;
				n_cache_valid[ii] = 0;
			end
		end
	end

	if (rst)
		s_do_write = 0;
end

always @(posedge clk) begin
	if (s_pagefault) r_pagefault <= n_pagefault;
	if (s_rdy) r_rdy <= n_rdy;
	if (s_pte_pgt) r_pte_pgt <= n_pte_pgt;
	if (s_write) r_write <= n_write;
	if (s_pt) r_pt <= n_pt;
	if (s_addr) r_addr <= n_addr;
	if (s_in) r_in <= n_in;
	if (s_do_read) r_bram_out <= bram[s_bram_addr_compressed];
	if (s_do_write) bram[s_bram_addr_compressed] <= n_bram_in;
	for (ii = 0; ii <= 1; ii = ii + 1) begin
		if (s_cache[ii]) begin
			r_cache_valid[ii] <= n_cache_valid[ii];
			r_cache_pt[ii] <= n_cache_pt[ii];
			r_cache_addr[ii] <= n_cache_addr[ii];
			r_cache_pte[ii] <= n_cache_pte[ii];
		end
	end
	if (rst) begin
		r_pagefault <= 0;
		r_rdy <= 0;
		r_pte_pgt <= 0;
		for (ii = 0; ii <= 1; ii = ii + 1)
			r_cache_valid[ii] <= 0;
	end
end

endmodule
