// This module defines a simple implementation of the Digital Phase Lock Loop
// (DPLL) described in Texas Instruments's SDLA005B application node

module dpll (rst, clk_in, clk_ref, clk_out, clk_out_8x);

input wire rst;
input wire clk_in;
input wire clk_ref;
output wire clk_out;
output wire clk_out_8x;

reg [7:0] k_count_up, k_count_down, n_count;
reg borrow, carry, id_out;
wire decrement, increment, down_upn;

parameter S_LOW_CYCLE = 3'b000,
			S_HIGH_CYCLE = 3'b001,
			S_LOW_CYCLE2 = 3'b010,
			S_HIGH_CYCLE2 = 3'b011,
			S_LOW_CYCLE3 = 3'b100,
			S_HIGH_CYCLE3 = 3'b101;

reg [2:0] state, next;

	// Phase Detector
	assign down_upn = clk_in ^ clk_out;

	// K Counter
	always @(posedge clk_ref or posedge rst)
	begin
		if (rst) begin
			k_count_down <= 8'h00;
			k_count_up <= 8'h00;
		end else begin
			if (down_upn) k_count_down <= k_count_down - 1;
			else k_count_up <= k_count_up + 1;
		end
	end

	always @(k_count_down)
	begin
		if (k_count_down == 8'h00) borrow = 1;
		else borrow = 0;
	end

	always @(k_count_up)
	begin
		if (k_count_up == 8'hFF) carry = 1;
		else carry = 0;
	end

	edgedet edge_inst1 (
		.rst(rst),
		.clk(clk_ref),
		.sig(borrow),
		.rising_or_falling(),
		.rising(decrement),
		.falling()
	);

	edgedet edge_inst2 (
		.rst(rst),
		.clk(clk_ref),
		.sig(carry),
		.rising_or_falling(),
		.rising(increment),
		.falling()
	);

	// I/D
	always @(posedge clk_ref or posedge rst)
		if (rst) state <= S_LOW_CYCLE;
		else state <= next;

	always @(state or increment or decrement) begin
		next = 'bx;
		case (state)
			S_LOW_CYCLE : if (decrement) next = S_LOW_CYCLE;
							else if (increment) next = S_HIGH_CYCLE2;
							else next = S_HIGH_CYCLE;
			S_HIGH_CYCLE : if (increment) next = S_HIGH_CYCLE;
							else if (decrement) next = S_LOW_CYCLE2;
							else next = S_LOW_CYCLE;
			S_HIGH_CYCLE2 : if (decrement) next = S_HIGH_CYCLE3;
							else next = S_HIGH_CYCLE;
			S_LOW_CYCLE2 : if (increment) next = S_LOW_CYCLE3;
							else next = S_LOW_CYCLE;
			S_HIGH_CYCLE3 : next = S_LOW_CYCLE2;
			S_LOW_CYCLE3 : next = S_HIGH_CYCLE2;
		endcase
	end

	always @(posedge clk_ref or posedge rst)
		if (rst) begin
			id_out <= 0;
		end
		else begin
			id_out <= 0;
		case (next)
			S_HIGH_CYCLE: id_out <= 1;
			S_HIGH_CYCLE2: id_out <= 1;
			S_HIGH_CYCLE3: id_out <= 1;
		endcase
	end

	// /N Counter
	always @(posedge clk_ref or posedge rst)
	begin
		if (rst) begin
			n_count <= 8'h00;
		end else begin
			if (id_out) n_count <= n_count + 1;
		end
	end

	assign clk_out = n_count[7];
	assign clk_out_8x = n_count[3];

endmodule
