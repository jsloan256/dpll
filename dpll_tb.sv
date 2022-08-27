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
      fin_phase >= 0;
      fin_phase <= 360;
   }

   function void display(input string tag);
      $display("[%0s] fin: %7d Hz %3d degrees     fout: %7d Hz %3d degrees     fout8x: %7d Hz %3d degrees ",
               tag, fin_frequency, fin_phase, fout_frequency, fout_phase, fout8x_frequency, fout8x_phase);
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
         // @(sco_next);      // Comment this line out to run drv_tb
      end

      ->done;
   endtask
endclass

class driver;
   virtual dpll_if dif;
   transaction trn;
   mailbox #(transaction) g2d_mbx;
   event drv_next;
   integer fin_period;
   integer fin_delay;

   function new(mailbox #(transaction) g2d_mbx);
      this.g2d_mbx = g2d_mbx;
   endfunction

   task reset();
      dif.reset <= 1'b1;
      dif.clk_fin <= 1'b0;

      repeat(5) @(posedge dif.clk);
      dif.reset <= 1'b0;
      $display("[DRV] RESET DONE");
   endtask

   task run();
      forever begin
         g2d_mbx.get(trn);
         trn.display("DRV");

         fin_period = int'((1/(real'(trn.fin_frequency))) * 1000000000);
         fin_delay = int'(real'(fin_period) * (real'(trn.fin_phase) / 360));
         $display("[DRV] fin_period: %0d, fin_delay: %0d", fin_period, fin_delay);

         dif.clk_fin = 1'b0;
         @(posedge dif.clk);
         #(fin_delay);

         // Wait for about 1ms for the PLL to settle
         repeat(500) begin
            #(fin_period/2)
            dif.clk_fin = 1'b1;
            #(fin_period/2)
            dif.clk_fin = 1'b0;
         end

         ->drv_next;
      end
   endtask
endclass

module drv_tb;
   generator gen;
   driver drv;
   event drv_next;
   event done;
   mailbox #(transaction) g2d_mbx;

   dpll_if dif ();
   dpll dut (dif.clk, dif.reset, dif.clk_fin, dif.clk_fout, dif_clk8x_fout);

   initial begin
      dif.clk <= 0;
   end

   always #5 dif.clk <= ~dif.clk;

   initial begin
      g2d_mbx = new();
      gen = new(g2d_mbx);
      drv = new(g2d_mbx);
      gen.count  = 5;
      drv.dif = dif;

      drv.drv_next = drv_next;
      gen.drv_next = drv_next;
   end

   initial begin
      drv.reset();

      fork
         gen.run();
         drv.run();
      join_none

      wait(gen.done.triggered);
      $finish();
   end

   initial begin
      $dumpfile("dump.vcd");
      $dumpvars;   
   end
endmodule
