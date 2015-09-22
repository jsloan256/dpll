`timescale 100 ps / 100 ps

module dpll_tb();

reg rst;
reg clk_in;
reg clk_ref;
wire clk_out;
wire clk_out_8x;

	dpll dpll_inst (
		.rst(rst),
		.clk_in(clk_in),
		.clk_ref(clk_ref),
		.clk_out(clk_out),
		.clk_out_8x(clk_out_8x)
	);

	always
//		#9766 clk_in = ~clk_in;
		#9700 clk_in = ~clk_in;

	always
		#19 clk_ref = ~clk_ref;

	initial
	begin
		$display($time, "Starting sim: ");
		rst = 1;
		clk_in = 0;
		clk_ref = 0;

		#5000
		rst = 0;

		#50000000
		$display($time, "End of sim");
		$stop;
	end

endmodule
