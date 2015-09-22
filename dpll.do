workspace create dpll_space
design create dpll_design .
design open dpll_design
waveformmode asdb
cd {../..}
vlog -v2k5 -msg 0 \
source/edgedet.v \
source/dpll.v \
source/dpll_tb.v

vsim -O5 +access +r -t 1ps -lib titan_design -L pmi_work -L pcsd_aldec_work dpll_design.dpll_tb

add wave -noupdate -format logic /dpll_tb/dpll_inst/rst
add wave -noupdate -format logic /dpll_tb/dpll_inst/clk_in
add wave -noupdate -format logic /dpll_tb/dpll_inst/clk_ref
add wave -noupdate -format logic /dpll_tb/dpll_inst/clk_out
add wave -noupdate -format logic /dpll_tb/dpll_inst/clk_out_8x
add wave -noupdate -format hex /dpll_tb/dpll_inst/state
add wave -noupdate -format hex /dpll_tb/dpll_inst/increment
add wave -noupdate -format hex /dpll_tb/dpll_inst/decrement
add wave -noupdate -format hex /dpll_tb/dpll_inst/n_count

run -all
