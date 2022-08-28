# DPLL

A simple SystemVerilog digital phase-locked loop based (roughly) on TI's [SDLA005B](http://www.ti.com/lit/an/sdla005b/sdla005b.pdf) application note. The design includes a SystemVerilog testbench demonstrating a full generator, driver, monitor, and scoreboard testbench environment.

# DUT: DPLL Design Description

```mermaid
graph TD;
  Scalar --> V["Pass by Value"]
  Array  --> R["Pass by Reference"]
  R --> U["u[] --> update array after passing]"] --> u1["`ref int a[]`"]
  R --> A["v[] --> access array after passing (but don't update)]"] --> v1["`const ref int a[]`"]
```

```mermaid
graph LR;
   clk_fin  --> XOR
   clk_fout --> XOR

   XOR -- k_count_enable --> k_counter


```

