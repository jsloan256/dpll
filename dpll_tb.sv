`timescale 1ns / 1ps

module dpll_tb;
   // Ports
   reg clk = 0;
   reg reset = 0;
   reg clk_fin = 0;
   wire clk_fout;
   wire clk8x_fout;

   dpll dut (clk, reset, clk_fin, clk_fout, clk8x_fout);

   initial begin
      begin
         reset = 1'b1;
         repeat(5) @(posedge clk);
         reset = 1'b0;

         #1000000;
         $finish;
      end
   end

   always
      #5  clk = ! clk ;             // 100 MHz
//    always
//       #2560  clk_fin = ! clk_fin ;  // 100/256 MHz = 390.625 kHz
//       #2500  clk_fin = ! clk_fin ;  // 100/256 MHz = 390.625 kHz
//       #2700  clk_fin = ! clk_fin ;  // 100/256 MHz = 390.625 kHz

   always begin
      #400;
//       #1500;
      forever #1280  clk_fin = ! clk_fin ;  // 100/256 MHz = 390.625 kHz
//       forever #1200  clk_fin = ! clk_fin ;  // 100/256 MHz = 390.625 kHz
   end

   initial begin
      $dumpfile("dump.vcd");
      $dumpvars;
   end
endmodule
