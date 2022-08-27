`timescale 1ns / 1ps

class transaction;
   rand integer fin_frequency;      // PLL clock input (clk_fin) frequency
   rand integer fin_phase;          // PLL clock input (clk_fin) phase
   integer fout_frequency;          // PLL clock output (clk_fout) frequency
   integer fout_phase;              // PLL clock output (clk_fout) phase
   integer fout8x_frequency;        // PLL 8x clock output (clk8x_fout) frequency
   integer fout8x_phase;            // PLL 8x clock output (clk8x_fout) phase

   constraint fin_frequency_con {
      fin_frequency == 390625;
   }

   constraint fin_phase_con {
      fin_phase >= -180;
      fin_phase <= 180;
   }

   function void display(input string tag);
      $display("[%0s] fin: %0d Hz %0d degrees\tfout: %0d Hz %0d degrees\tfout8x: %0d Hz %0d degrees ", tag, fin_frequency, fin_phase, fout_frequency, fout_phase, fout8x_frequency, fout8x_phase);
   endfunction

   function transaction copy();
      copy = new();
      copy.fin_frequency      = this.fin_frequency;
      copy.fin_phase          = this.fin_phase;
      copy.fout_frequency     = this.fout_frequency;
      copy.fout_phase         = this.fout_phase;
      copy.fout8x_frequency   = this.fout8x_frequency;
      copy.fout8x_phase       = this.fout8x_phase;
   endfunction
endclass

module trn_tb;
   transaction trn;

   initial begin
      trn = new();
      trn.fin_frequency = 444123;
      trn.fin_phase = 90;
      trn.display("TOP");
   end

   initial begin
      $dumpfile("dump.vcd");
      $dumpvars;   
   end
endmodule

class generator;
   transaction trn;
   mailbox #(transaction) g2d_mbx;     // Mailbox for data from generator to driver (g2d)
   event done;                         // Generator has completed the requested number of transactions
   event drv_next;                     // Driver has completed the previous transaction
   event sco_next;                     // Scoreboard has completed the previous transcation
   int count = 0;                      // Number of transactions to do per run()

   function new (mailbox #(transaction) g2d_mbx);
      this.g2d_mbx = g2d_mbx;
      trn = new();
   endfunction

   task run();
      repeat(count) begin
         assert(trn.randomize) else $error("Randomization Failed");

         trn.display("GEN");
         g2d_mbx.put(trn);
         @(drv_next);
         @(sco_next);
      end

      ->done;
   endtask
endclass
