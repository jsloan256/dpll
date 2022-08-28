`timescale 1ns / 1ps

module dpll
(
   input clk,              //! Master clock
   input reset,            //! System reset (active high)
   input clk_fin,          //! PLL clock input
   output reg clk_fout,    //! PLL output clock
   output reg clk8x_fout   //! PLL output 8x clock
);

   reg fout = 0;
   reg k_count_enable = 0;
   reg [7:0] k_count;
   reg k_count_down = 1;      // 1 to count down, 0 to count up
   reg k_count_borrow = 0;
   reg k_count_carry = 0;
   reg id_increment = 0;
   reg id_decrement = 0;
   reg id_increment_done = 0;
   reg id_decrement_done = 0;
   reg id_out = 0;
   reg [6:0] n_count;

   // Phase detector (simple XOR)
   always@(*) begin
      k_count_enable = clk_fin ^ fout;
   end

   always@(posedge clk) begin
      if (reset == 1'b1) begin
         k_count <= 0;
      end
      else if (k_count_enable == 1) begin
         if (k_count_down == 0) begin
            k_count <= k_count + 1;

            if (k_count == 16'hFF) begin
               k_count_carry <= 1;
            end
            else begin
               k_count_carry <= 0;
            end
         end
         else begin
            k_count <= k_count - 1;

            if (k_count == 16'h00) begin
               k_count_borrow <= 1;
            end
            else begin
               k_count_borrow <= 0;
            end
         end
      end
      else begin
         k_count_carry <= 0;
         k_count_borrow <= 0;
      end
   end

   always@(posedge clk) begin
      if (reset == 1'b1) begin
         id_increment <= 0;
      end
      else if ((id_increment == 0) && (k_count_carry == 1)) begin
         id_increment <= 1;
      end
      else if (id_increment_done == 1) begin
         id_increment <= 0;
      end
   end

   always@(posedge clk) begin
      if (reset == 1'b1) begin
         id_decrement <= 0;
      end
      else if ((id_decrement == 0) && (k_count_borrow == 1)) begin
         id_decrement <= 1;
      end
      else if (id_decrement_done == 1) begin
         id_decrement <= 0;
      end
   end

   always@(posedge clk) begin
      if (reset == 1'b1) begin
         id_out <= 0;
         id_increment_done <= 0;
         id_decrement_done <= 0;
      end
      else if (id_out == 0) begin
         if (id_decrement == 1) begin
            id_out <= 0;
            id_decrement_done <= 1;
         end
         else begin
            id_out <= 1;
            id_decrement_done <= 0;
         end
      end
      else if (id_out == 1) begin
         if (id_increment == 1) begin
            id_out <= 1;
            id_increment_done <= 1;
         end
         else begin
            id_out <= 0;
            id_increment_done <= 0;
         end
      end
   end

   always@(posedge clk) begin
      if (reset == 1'b1) begin
         n_count <= 0;
      end
      else if (id_out == 1) begin
         n_count <= n_count + 1;
      end
   end

   always@(*) begin
      fout           = n_count[6];
      k_count_down   = !n_count[5];
      clk_fout       = fout;
      clk8x_fout     = n_count[3];
   end
endmodule

interface dpll_if ();
   logic clk;              // Master clock
   logic reset;            // System reset (active high)
   logic clk_fin;          // PLL clock input
   logic clk_fout;         // PLL output clock
   logic clk8x_fout;       // PLL output 8x clock
endinterface