add_wave_group dut_ports
add_wave dut/clk          -into dut_ports
add_wave dut/reset        -into dut_ports
add_wave dut/clk_fin      -into dut_ports -color cyan
add_wave dut/clk_fout     -into dut_ports -color cyan
add_wave dut/clk8x_fout   -into dut_ports -color cyan

add_wave_group dut_signals
add_wave dut/fout                -into dut_signals
add_wave dut/k_count_enable      -into dut_signals
add_wave dut/k_count             -into dut_signals
add_wave dut/k_count_down        -into dut_signals
add_wave dut/k_count_borrow      -into dut_signals
add_wave dut/k_count_carry       -into dut_signals
add_wave dut/id_increment        -into dut_signals
add_wave dut/id_decrement        -into dut_signals
add_wave dut/id_increment_done   -into dut_signals
add_wave dut/id_decrement_done   -into dut_signals
add_wave dut/id_out              -into dut_signals
add_wave dut/n_count             -into dut_signals

run -all
