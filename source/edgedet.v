module edgedet (rst, clk, sig, rising_or_falling, rising, falling);

input wire rst;
input wire clk;
input wire sig;
output wire rising_or_falling;
output wire rising;
output wire falling;

reg sig_q, sig_q_q;

	always @(posedge clk or posedge rst)
	begin
		if (rst) begin
			sig_q <= 0;
			sig_q_q <= 0;
		end else begin
			sig_q <= sig;
			sig_q_q <= sig_q;
		end
	end

	assign rising = ~sig_q_q & sig_q;
	assign falling = sig_q_q & ~sig_q;
	assign rising_or_falling = rising | falling;

endmodule
