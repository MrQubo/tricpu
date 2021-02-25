`timescale 1ps / 1ps
`default_nettype none

// TODO: This protocol could be minified. We can send two bits (one trit) of
//	each register with header and two registers at once in one dword.

module m_extcall_controller#(parameter integer P_LOGLEVEL = 0) (
	input wire i_clk,
	input wire i_rst,

	input wire [31:0] i_s_axis_tdata,
	input wire i_s_axis_tlast,
	output reg o_s_axis_tready,
	input wire i_s_axis_tvalid,

	output reg [31:0] o_m_axis_tdata,
	output reg o_m_axis_tlast,
	input wire i_m_axis_tready,
	output reg o_m_axis_tvalid,

	input wire [17:0] i_r1,
	input wire [17:0] i_r2,
	input wire [17:0] i_r3,
	input wire [17:0] i_r4,

	output reg o_write_r1_enable,
	output reg [17:0] o_write_r1_val,

	output reg o_ram_enable,
	output reg o_ram_write,
	output reg signed [1:0] o_ram_pt,
	output reg [17:0] o_ram_addr,
	output reg [17:0] o_ram_in,
	input wire i_ram_ready,
	input wire i_ram_pagefault,
	input wire [17:0] i_ram_out,

	input wire i_enable,
	input wire i_type,
	input wire [5:0] i_code,

	output reg o_ready,
	output reg o_pagefault,
	output reg signed [1:0] o_pagefault_pt,
	output reg [17:0] o_pagefault_addr,
	output reg o_exit
);
`include "utils.h"

localparam [17:0] C_MINLOGLEVEL_TRYTE = util_int_to_tryte(P_LOGLEVEL);

localparam signed [1:0] C_PT_X = 2'b11;
localparam signed [1:0] C_PT_W = 2'b00;
localparam signed [1:0] C_PT_R = 2'b01;

localparam [6:0] C_DECODE_T_BEAP     = 7'b0000011;
localparam [6:0] C_DECODE_T_PUTC     = 7'b0000000;
localparam [6:0] C_DECODE_T_GETC     = 7'b0000001;
localparam [6:0] C_DECODE_H_EXIT     = 7'b1000000;
localparam [6:0] C_DECODE_H_LOG      = 7'b1000001;
localparam [6:0] C_DECODE_H_OPEN_NB  = 7'b1000111;
localparam [6:0] C_DECODE_H_READ     = 7'b1000100;
localparam [6:0] C_DECODE_H_OPEN_TXT = 7'b1000101;


reg [17:0] o_comp_lhs;
reg [17:0] o_comp_rhs;
wire i_comp_gt;
wire i_comp_eq;
wire i_comp_lt;
tricomp_sync p_comp(
	.lhs(o_comp_lhs), .neg_rhs(1'b0), .rhs(o_comp_rhs),
	.gt(i_comp_gt), .eq(i_comp_eq), .lt(i_comp_lt)
);

reg [17:0] o_comp0_in;
wire i_comp0_zero;
tricomp0_sync p_comp0(
	.in(o_comp0_in),
	.zero(i_comp0_zero)
);

reg [17:0] o_inc_in;
wire [17:0] i_inc_res;
triinc_sync p_inc(
	.in(o_inc_in),
	.res(i_inc_res)
);


reg r_type;
reg n_type;
reg s_type;

reg [5:0] r_code;
reg [5:0] n_code;
reg s_code;

reg [17:0] c_str_addr;
reg [17:0] r_str_addr;
reg [17:0] n_str_addr;
reg s_str_addr;

reg [17:0] c_log_arg_level;

reg c_task_write_header;
reg r_task_write_header;
reg n_task_write_header;
reg s_task_write_header;

reg c_task_write_r1;
reg r_task_write_r1;
reg n_task_write_r1;
reg s_task_write_r1;

reg c_task_write_r2;
reg r_task_write_r2;
reg n_task_write_r2;
reg s_task_write_r2;

reg c_task_write_r3;
reg r_task_write_r3;
reg n_task_write_r3;
reg s_task_write_r3;

reg c_task_write_r4;
reg r_task_write_r4;
reg n_task_write_r4;
reg s_task_write_r4;

reg c_task_write_str;
reg r_task_write_str;
reg n_task_write_str;
reg s_task_write_str;

reg c_task_read_r1;
reg r_task_read_r1;
reg n_task_read_r1;
reg s_task_read_r1;

reg c_task_read_str;
reg r_task_read_str;
reg n_task_read_str;
reg s_task_read_str;

reg c_task_exit;
reg r_task_exit;
reg n_task_exit;
reg s_task_exit;

reg c_ram_in_progress;
reg r_ram_in_progress;
reg n_ram_in_progress;
reg s_ram_in_progress;

reg c_ram_pagefaulted;
reg r_ram_pagefaulted;
reg n_ram_pagefaulted;
reg s_ram_pagefaulted;

reg signed [1:0] c_pagefault_pt;
reg signed [1:0] r_pagefault_pt;
reg signed [1:0] n_pagefault_pt;
reg s_pagefault_pt;

reg [17:0] c_pagefault_addr;
reg [17:0] r_pagefault_addr;
reg [17:0] n_pagefault_addr;
reg s_pagefault_addr;

reg c_do_axi_write;
reg [31:0] c_do_axi_write_data;

reg c_do_ram_read;
reg [17:0] c_do_ram_read_addr;

reg c_do_ram_write;
reg [17:0] c_do_ram_write_addr;
reg [17:0] c_do_ram_write_data;

reg c_decode_write_header;
reg c_decode_write_r1;
reg c_decode_write_r2;
reg c_decode_write_r3;
reg c_decode_write_r4;
reg c_decode_write_str;
reg c_decode_read_r1;
reg c_decode_read_str;
reg c_decode_exit;


wire clk = i_clk;
wire rst = i_rst;
wire c_has_tasks_left_exc_exit = |{
	c_task_write_header,
	c_task_write_r1,
	c_task_write_r2,
	c_task_write_r3,
	c_task_write_r4,
	c_task_write_str,
	c_task_read_r1,
	c_task_read_str
};
wire c_in_progress = |{
	r_task_write_header,
	r_task_write_r1,
	r_task_write_r2,
	r_task_write_r3,
	r_task_write_r4,
	r_task_write_str,
	r_task_read_r1,
	r_task_read_str
};

always @* begin
	o_s_axis_tready = 'hx;

	o_m_axis_tdata = 'hxxxxxxxx;
	o_m_axis_tlast = 'hx;
	o_m_axis_tvalid = 0;

	o_write_r1_enable = 0;
	o_write_r1_val = 'hxxxxx;

	o_ram_enable = 0;
	o_ram_write = 'hx;
	o_ram_pt = 'hx;
	o_ram_addr = 'hxxxxx;
	o_ram_in = 'hxxxxx;

	o_ready = 'hx;
	o_pagefault = 'hx;
	o_pagefault_pt = 'hx;
	o_pagefault_addr = 'hxxxxx;
	o_exit = 'hx;

	o_comp_lhs = 'hxxxxx;
	o_comp_rhs = 'hxxxxx;

	o_comp0_in = 'hxxxxx;

	o_inc_in = 'hxxxxx;

	s_type = 0;
	n_type = 'hx;

	s_code = 0;
	n_code = 'hxx;

	c_str_addr = r_str_addr;
	s_str_addr = 0;
	n_str_addr = 'hx;

	c_log_arg_level = 'hxxxxx;

	c_task_write_header = r_task_write_header;
	s_task_write_header = 0;
	n_task_write_header = 'hx;

	c_task_write_r1 = r_task_write_r1;
	s_task_write_r1 = 0;
	n_task_write_r1 = 'hx;

	c_task_write_r2 = r_task_write_r2;
	s_task_write_r2 = 0;
	n_task_write_r2 = 'hx;

	c_task_write_r3 = r_task_write_r3;
	s_task_write_r3 = 0;
	n_task_write_r3 = 'hx;

	c_task_write_r4 = r_task_write_r4;
	s_task_write_r4 = 0;
	n_task_write_r4 = 'hx;

	c_task_write_str = r_task_write_str;
	s_task_write_str = 0;
	n_task_write_str = 'hx;

	c_task_read_r1 = r_task_read_r1;
	s_task_read_r1 = 0;
	n_task_read_r1 = 'hx;

	c_task_read_str = r_task_read_str;
	s_task_read_str = 0;
	n_task_read_str = 'hx;

	c_task_exit = r_task_exit;
	s_task_exit = 0;
	n_task_exit = 'hx;

	c_ram_in_progress = r_ram_in_progress;
	s_ram_in_progress = 0;
	n_ram_in_progress = 'hx;

	c_ram_pagefaulted = r_ram_pagefaulted;
	s_ram_pagefaulted = 0;
	n_ram_pagefaulted = 'hx;

	c_pagefault_pt = r_pagefault_pt;
	s_pagefault_pt = 0;
	n_pagefault_pt = 'hx;

	c_pagefault_addr = r_pagefault_addr;
	s_pagefault_addr = 0;
	n_pagefault_addr = 'hx;

	c_do_axi_write = 0;
	c_do_axi_write_data = 'hxxxxxxxx;

	c_do_ram_read = 0;
	c_do_ram_read_addr = 'hxxxxx;

	c_do_ram_write = 0;
	c_do_ram_write_addr = 'hxxxxx;
	c_do_ram_write_data = 'hxxxxx;

	c_decode_write_header = 'hx;
	c_decode_write_r1 = 'hx;
	c_decode_write_r2 = 'hx;
	c_decode_write_r3 = 'hx;
	c_decode_write_r4 = 'hx;
	c_decode_write_str = 'hx;
	c_decode_read_r1 = 'hx;
	c_decode_read_str = 'hx;
	c_decode_exit = 'hx;


	//******************* DECODE *******************//
	if (i_enable) begin
/*                 s_task_write_header = 1;
 *                 n_task_write_header = c_decode_write_header;
 *                 c_task_write_header = n_task_write_header;
 *
 *                 s_task_write_r1 = 1;
 *                 n_task_write_r1 = c_decode_write_r1;
 *                 c_task_write_r1 = n_task_write_r1;
 *
 *                 s_task_write_r2 = 1;
 *                 n_task_write_r2 = c_decode_write_r2;
 *                 c_task_write_r2 = n_task_write_r2;
 *
 *                 s_task_write_r3 = 1;
 *                 n_task_write_r3 = c_decode_write_r3;
 *                 c_task_write_r3 = n_task_write_r3;
 *
 *                 s_task_write_r4 = 1;
 *                 n_task_write_r4 = c_decode_write_r4;
 *                 c_task_write_r4 = n_task_write_r4;
 *
 *                 s_task_write_str = 1;
 *                 n_task_write_str = c_decode_write_str;
 *                 c_task_write_str = n_task_write_str;
 *
 *                 s_task_read_r1 = 1;
 *                 n_task_read_r1 = c_decode_read_r1;
 *                 c_task_read_r1 = n_task_read_r1;
 *
 *                 s_task_read_str = 1;
 *                 n_task_read_str = c_decode_read_str;
 *                 c_task_read_str = n_task_read_str;
 *
 *                 s_task_exit = 1;
 *                 n_task_exit = c_decode_exit;
 *                 c_task_exit = n_task_exit; */

		c_decode_write_header = 0;
		c_decode_write_r1 = 0;
		c_decode_write_r2 = 0;
		c_decode_write_r3 = 0;
		c_decode_write_r4 = 0;
		c_decode_write_str = 0;
		c_decode_read_r1 = 0;
		c_decode_read_str = 0;
		c_decode_exit = 0;

		case ({i_type, i_code})
		C_DECODE_T_BEAP: begin
			c_decode_write_header = 1;
		end
		C_DECODE_T_PUTC: begin
			c_decode_write_header = 1;
			c_decode_write_r1 = 1;
			c_decode_write_r2 = 1;
			c_decode_write_r3 = 1;
			c_decode_write_r4 = 1;
		end
		C_DECODE_T_GETC: begin
			c_decode_write_header = 1;
			c_decode_write_r1 = 1;
			c_decode_write_r2 = 1;
			c_decode_read_r1 = 1;
		end
		C_DECODE_H_EXIT: begin
			c_decode_write_header = 1;
			c_decode_exit = 1;
		end
		C_DECODE_H_LOG: begin
			c_decode_write_header = 1;
			c_decode_write_r2 = 1;

			o_comp_lhs = i_r2;
			o_comp_rhs = C_MINLOGLEVEL_TRYTE;
			if (i_comp_gt || i_comp_eq)
				c_decode_write_str = 1;
		end
		C_DECODE_H_OPEN_NB: begin
			c_decode_write_header = 1;
			c_decode_write_str = 1;
			c_decode_read_r1 = 1;
		end
		C_DECODE_H_OPEN_TXT: begin
			c_decode_write_header = 1;
			c_decode_write_str = 1;
			c_decode_read_r1 = 1;
		end
		C_DECODE_H_READ: begin
			c_decode_write_header = 1;
			c_decode_write_r2 = 1;
			c_decode_write_r3 = 1;
			c_decode_read_r1 = 1;
			c_decode_read_str = 1;
		end
		endcase

		s_task_write_header = 1;
		n_task_write_header = c_decode_write_header;
		c_task_write_header = n_task_write_header;

		s_task_write_r1 = 1;
		n_task_write_r1 = c_decode_write_r1;
		c_task_write_r1 = n_task_write_r1;

		s_task_write_r2 = 1;
		n_task_write_r2 = c_decode_write_r2;
		c_task_write_r2 = n_task_write_r2;

		s_task_write_r3 = 1;
		n_task_write_r3 = c_decode_write_r3;
		c_task_write_r3 = n_task_write_r3;

		s_task_write_r4 = 1;
		n_task_write_r4 = c_decode_write_r4;
		c_task_write_r4 = n_task_write_r4;

		s_task_write_str = 1;
		n_task_write_str = c_decode_write_str;
		c_task_write_str = n_task_write_str;

		s_task_read_r1 = 1;
		n_task_read_r1 = c_decode_read_r1;
		c_task_read_r1 = n_task_read_r1;

		s_task_read_str = 1;
		n_task_read_str = c_decode_read_str;
		c_task_read_str = n_task_read_str;

		s_task_exit = 1;
		n_task_exit = c_decode_exit;
		c_task_exit = n_task_exit;
	end


	//******************* WRITE *******************//
	if (i_enable && c_decode_write_header && i_m_axis_tready) begin
		s_task_write_header = 1;
		n_task_write_header = 0;
		c_task_write_header = n_task_write_header;

		c_do_axi_write = 1;
		c_do_axi_write_data = {25'h0, i_type, i_code};
	end else begin
		s_type = 1;
		n_type = i_type;
		s_code = 1;
		n_code = i_code;
	end

	if (i_enable && c_task_write_str) begin
		c_do_ram_read = 1;
		c_do_ram_read_addr = i_r1;

		o_inc_in = i_r1;
		s_str_addr = 1;
		n_str_addr = i_inc_res;
		c_str_addr = n_str_addr;
	end

	if (r_task_write_header) begin
		c_do_axi_write = 1;
		c_do_axi_write_data = {25'h0, r_type, r_code};

		if (i_m_axis_tready) begin
			s_task_write_header = 1;
			n_task_write_header = 0;
			c_task_write_header = n_task_write_header;
		end
	end else if (r_task_write_r1) begin
		c_do_axi_write = 1;
		c_do_axi_write_data = {14'h0, i_r1};

		if (i_m_axis_tready) begin
			s_task_write_r1 = 1;
			n_task_write_r1 = 0;
			c_task_write_r1 = n_task_write_r1;
		end
	end else if (r_task_write_r2) begin
		c_do_axi_write = 1;
		c_do_axi_write_data = {14'h0, i_r2};

		if (i_m_axis_tready) begin
			s_task_write_r2 = 1;
			n_task_write_r2 = 0;
			c_task_write_r2 = n_task_write_r2;
		end
	end else if (r_task_write_r3) begin
		c_do_axi_write = 1;
		c_do_axi_write_data = {14'h0, i_r3};

		if (i_m_axis_tready) begin
			s_task_write_r3 = 1;
			n_task_write_r3 = 0;
			c_task_write_r3 = n_task_write_r3;
		end
	end else if (r_task_write_r4) begin
		c_do_axi_write = 1;
		c_do_axi_write_data = {14'h0, i_r4};

		if (i_m_axis_tready) begin
			s_task_write_r4 = 1;
			n_task_write_r4 = 0;
			c_task_write_r4 = n_task_write_r4;
		end
	end else if (r_task_write_str) begin
		// First ram read was initiated with i_enable.
		c_do_axi_write = (!r_ram_in_progress || i_ram_ready);
		if (c_ram_pagefaulted)
			c_do_axi_write_data = 32'h0;
		else
			c_do_axi_write_data = {14'h0, i_ram_out};
		if (c_do_axi_write && i_m_axis_tready) begin
			if (c_ram_pagefaulted) begin
				s_task_write_str = 1;
				n_task_write_str = 0;
				c_task_write_str = n_task_write_str;
			end else begin
				o_comp0_in = i_ram_out;
				if (i_comp0_zero) begin
					s_task_write_str = 1;
					n_task_write_str = 0;
					c_task_write_str = n_task_write_str;
				end else begin
					c_do_ram_read = 1;
					c_do_ram_read_addr = r_str_addr;

					o_inc_in = r_str_addr;
					s_str_addr = 1;
					n_str_addr = i_inc_res;
					c_str_addr = n_str_addr;
				end
			end
		end
	end

	if (c_do_axi_write) begin
		o_m_axis_tdata = c_do_axi_write_data;
		o_m_axis_tlast = 1;
		o_m_axis_tvalid = 1;
	end


	//******************* READ *******************//
	if (i_enable && c_decode_read_str) begin
		s_str_addr = 1;
		n_str_addr = i_r1;
		c_str_addr = n_str_addr;
	end

	if (r_task_read_r1) begin
		o_s_axis_tready = 1;

		if (o_s_axis_tready && i_s_axis_tvalid) begin
			s_task_read_r1 = 1;
			n_task_read_r1 = 0;
			c_task_read_r1 = n_task_read_r1;

			o_write_r1_enable = 1;
			o_write_r1_val = util_tryte_check(i_s_axis_tdata[17:0]);
		end
	end else if (r_task_read_str) begin
		o_s_axis_tready = c_ram_pagefaulted || (r_ram_in_progress && i_ram_ready) || !r_ram_in_progress;

		if (o_s_axis_tready && i_s_axis_tvalid) begin
			if (i_s_axis_tdata[31]) begin
				s_task_read_str = 1;
				n_task_read_str = 0;
				c_task_read_str = n_task_read_str;
			end else if (!c_ram_pagefaulted) begin
				c_do_ram_write = 1;
				c_do_ram_write_addr = r_str_addr;
				c_do_ram_write_data
					= util_tryte_check(i_s_axis_tdata[17:0]);

				o_inc_in = r_str_addr;
				s_str_addr = 1;
				n_str_addr = i_inc_res;
				c_str_addr = n_str_addr;
			end

		end
	end


	//******************* RAM *******************//
	if (i_enable) begin
		s_ram_pagefaulted = 1;
		n_ram_pagefaulted = 0;
		c_ram_pagefaulted = n_ram_pagefaulted;
	end

	if (c_do_ram_read) begin
		o_ram_enable = 1;
		o_ram_write = 0;
		o_ram_pt = C_PT_R;
		o_ram_addr = c_do_ram_read_addr;
	end

	if (c_do_ram_write) begin
		o_ram_enable = 1;
		o_ram_write = 1;
		o_ram_pt = C_PT_W;
		o_ram_addr = c_do_ram_write_addr;
		o_ram_in = c_do_ram_write_data;
	end

	if (o_ram_enable) begin
		s_ram_in_progress = 1;
		n_ram_in_progress = 1;
		c_ram_in_progress = n_ram_in_progress;

		if (!c_ram_pagefaulted) begin
			s_pagefault_pt = 1;
			n_pagefault_pt = o_ram_pt;
			c_pagefault_pt = n_pagefault_pt;

			s_pagefault_addr = 1;
			n_pagefault_addr = o_ram_addr;
			c_pagefault_addr = n_pagefault_addr;
		end
	end

	if (r_ram_in_progress && i_ram_ready) begin
		s_ram_in_progress = 1;
		n_ram_in_progress = 0;
		c_ram_in_progress = n_ram_in_progress;

		if (i_ram_pagefault) begin
			s_ram_pagefaulted = 1;
			n_ram_pagefaulted = 1;
			c_ram_pagefaulted = n_ram_pagefaulted;
		end
	end


	//******************* READY *******************//
	if (i_enable) begin
		o_ready = 0;

		if (!c_has_tasks_left_exc_exit) begin
			o_ready = 1;
			o_pagefault = 0;
			o_exit = c_decode_exit;

			s_task_exit = 1;
			n_task_exit = 0;
			c_task_exit = n_task_exit;
		end
	end
	if (c_in_progress && !i_enable) begin
		o_ready = 0;

		if (!c_has_tasks_left_exc_exit) begin
			o_ready = 1;
			o_pagefault = c_ram_pagefaulted;
			o_pagefault_pt = c_pagefault_pt;
			o_pagefault_addr = c_pagefault_addr;
			o_exit = r_task_exit;

			s_task_exit = 1;
			n_task_exit = 0;
			c_task_exit = n_task_exit;
		end
	end


/*         /[>****************** RESET ******************<]/
 *         if (rst) begin
 *                 s_task_write_header = 1;
 *                 n_task_write_header = 0;
 *
 *                 s_task_write_r1 = 1;
 *                 n_task_write_r1 = 0;
 *
 *                 s_task_write_r2 = 1;
 *                 n_task_write_r2 = 0;
 *
 *                 s_task_write_r3 = 1;
 *                 n_task_write_r3 = 0;
 *
 *                 s_task_write_r4 = 1;
 *                 n_task_write_r4 = 0;
 *
 *                 s_task_write_str = 1;
 *                 n_task_write_str = 0;
 *
 *                 s_task_read_r1 = 1;
 *                 n_task_read_r1 = 0;
 *
 *                 s_task_read_str = 1;
 *                 n_task_read_str = 0;
 *
 *                 s_task_exit = 1;
 *                 n_task_exit = 0;
 *         end */
end

always @(posedge clk) begin
	if (s_type) r_type <= n_type;
	if (s_code) r_code <= n_code;
	if (s_str_addr) r_str_addr <= n_str_addr;
	if (s_task_write_header) r_task_write_header <= n_task_write_header;
	if (s_task_write_r1) r_task_write_r1 <= n_task_write_r1;
	if (s_task_write_r2) r_task_write_r2 <= n_task_write_r2;
	if (s_task_write_r3) r_task_write_r3 <= n_task_write_r3;
	if (s_task_write_r4) r_task_write_r4 <= n_task_write_r4;
	if (s_task_write_str) r_task_write_str <= n_task_write_str;
	if (s_task_read_r1) r_task_read_r1 <= n_task_read_r1;
	if (s_task_read_str) r_task_read_str <= n_task_read_str;
	if (s_task_exit) r_task_exit <= n_task_exit;
	if (s_ram_in_progress) r_ram_in_progress <= n_ram_in_progress;
	if (s_ram_pagefaulted) r_ram_pagefaulted <= n_ram_pagefaulted;
	if (s_pagefault_pt) r_pagefault_pt <= n_pagefault_pt;
	if (s_pagefault_addr) r_pagefault_addr <= n_pagefault_addr;
	if (rst) begin
		r_task_write_header <= 0;
		r_task_write_r1 <= 0;
		r_task_write_r2 <= 0;
		r_task_write_r3 <= 0;
		r_task_write_r4 <= 0;
		r_task_write_str <= 0;
		r_task_read_r1 <= 0;
		r_task_read_str <= 0;
		r_task_exit <= 0;
	end
end

endmodule
