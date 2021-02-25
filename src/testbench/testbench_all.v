`timescale 1ps / 1ps
`default_nettype none

module testbench_all (output wire completed);

wire [5:0] completion;
assign completed = &completion;
testbench_arith p_arith(completion[0]);
testbench_cpu p_cpu(completion[1]);
testbench_extcall p_extcall(completion[2]);
testbench_ram p_ram(completion[3]);
testbench_top p_top(completion[4]);
testbench_utils p_utils(completion[5]);

initial begin
	#10;
	while (!completed) #10;
	$info("[all] Test group completed.");
end

endmodule
