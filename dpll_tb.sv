`timescale 1ns / 1ps

class transaction;
   rand int fin_frequency;      // PLL clock input (clk_fin) frequency
   rand int fin_phase;          // PLL clock input (clk_fin) phase
   int fout_frequency;          // PLL clock output (clk_fout) frequency
   int fout_phase;              // PLL clock output (clk_fout) phase
   int fout8x_frequency;        // PLL 8x clock output (clk8x_fout) frequency
   int fout8x_phase;            // PLL 8x clock output (clk8x_fout) phase

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
   event next;                         // Scoreboard has completed the previous transaction
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
         @(next);
      end

      ->done;
   endtask
endclass

class driver;
   virtual dpll_if dif;
   transaction trn;
   mailbox #(transaction) g2d_mbx;
   event next;          // Only used for testing in drv_tb
   int fin_period;
   int fin_delay;

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

         ->next;
      end
   endtask
endclass

module drv_tb;
   generator gen;
   driver drv;
   event d2g_next;
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

      drv.next = d2g_next;
      gen.next = d2g_next;
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

class monitor;
   virtual dpll_if dif;
   transaction trn;
   mailbox #(transaction) m2s_mbx;
   time fout_posedge;
   time fout_last_posedge;
   int fout_period;
   real average_fout_period;

   function new(mailbox #(transaction) m2s_mbx);
      this.m2s_mbx = m2s_mbx;
   endfunction

   // TODO: Add parallel functions to calculate clk8_out frequency (and periods?)
   task run();
      trn = new();

      forever begin
         repeat(489) @(posedge dif.clk_fout); // Ignore the first 490 cycles of clk_fout;

         @(posedge dif.clk_fout)
         fout_posedge = $time;

         average_fout_period = 0;
         repeat(10) begin
            @(posedge dif.clk_fout);
            fout_last_posedge = fout_posedge;
            fout_posedge = $time;
            fout_period = fout_posedge - fout_last_posedge;
            average_fout_period = average_fout_period + (1/10)*fout_period;

            $display("[MON] fout_period = %s", fout_period);
         end

         $display("[MON] average_fout_period = %0f", average_fout_period);
         trn.fout_frequency = int'(1/(real'(average_fout_period)/1000000000));

         m2s_mbx.put(trn);
         trn.display("MON");
      end
   endtask
endclass

class scoreboard;
   mailbox #(transaction) m2s_mbx;
   transaction trn;
   event next;

   function new(mailbox #(transaction) m2s_mbx);
      this.m2s_mbx = m2s_mbx;
   endfunction

   task run();
      forever begin
         m2s_mbx.get(trn);
         trn.display("SCO");

         // Check output frequency and phase

         ->next;
      end
   endtask
endclass

class environment;
   generator   gen;
   driver      drv;
   monitor     mon;
   scoreboard  sco;

   mailbox #(transaction) g2d_mbx;
   mailbox #(transaction) m2s_mbx;

   event g2s_next;
   virtual dpll_if dif;

   function new(virtual dpll_if dif);
      g2d_mbx = new();
      gen = new(g2d_mbx);
      drv = new(g2d_mbx);

      m2s_mbx = new();
      mon = new(m2s_mbx);
      sco = new(m2s_mbx);

      this.dif = dif;
      drv.dif = this.dif;
      mon.dif = this.dif;

      gen.next = g2s_next;
      sco.next = g2s_next;
   endfunction

   task pre_test();
      drv.reset();
   endtask

   task tast();
      fork
         gen.run();
         drv.run();
         mon.run();
         sco.run();
      join_any
   endtask

   task post_test();
      wait(gen.done.triggered);
      $finish();
   endtask
endclass