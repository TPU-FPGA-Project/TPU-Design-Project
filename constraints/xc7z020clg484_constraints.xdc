# ============================================================
# ZedBoard Rev. D constraints
# Target device: XC7Z020-CLG484-1
# ============================================================

# ------------------------------------------------------------
# 100 MHz PL clock
# ------------------------------------------------------------

set_property PACKAGE_PIN Y9 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

# 100 MHz = 10 ns clock period
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk_100mhz]


# ------------------------------------------------------------
# Pushbuttons
# ------------------------------------------------------------

# BTNC: reset
set_property PACKAGE_PIN P16 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]

# BTNU: start
set_property PACKAGE_PIN T18 [get_ports btn_start]
set_property IOSTANDARD LVCMOS33 [get_ports btn_start]

# These buttons are asynchronous to clk_100mhz.
# btn_start is synchronized inside zedboard_demo_top.
set_false_path -from [get_ports btn_reset]
set_false_path -from [get_ports btn_start]


# ------------------------------------------------------------
# Four slide switches: SW0 to SW3
# ------------------------------------------------------------

set_property PACKAGE_PIN F22 [get_ports {sw[0]}]
set_property PACKAGE_PIN G22 [get_ports {sw[1]}]
set_property PACKAGE_PIN H22 [get_ports {sw[2]}]
set_property PACKAGE_PIN F21 [get_ports {sw[3]}]

set_property IOSTANDARD LVCMOS33 [get_ports {sw[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {sw[3]}]


# ------------------------------------------------------------
# Eight user LEDs: LD0 to LD7
# ------------------------------------------------------------

set_property PACKAGE_PIN T22 [get_ports {led[0]}]
set_property PACKAGE_PIN T21 [get_ports {led[1]}]
set_property PACKAGE_PIN U22 [get_ports {led[2]}]
set_property PACKAGE_PIN U21 [get_ports {led[3]}]
set_property PACKAGE_PIN V22 [get_ports {led[4]}]
set_property PACKAGE_PIN W22 [get_ports {led[5]}]
set_property PACKAGE_PIN U19 [get_ports {led[6]}]
set_property PACKAGE_PIN U14 [get_ports {led[7]}]

set_property IOSTANDARD LVCMOS33 [get_ports {led[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[4]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[5]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[6]}]
set_property IOSTANDARD LVCMOS33 [get_ports {led[7]}]

create_debug_core u_ila_0 ila
set_property ALL_PROBE_SAME_MU true [get_debug_cores u_ila_0]
set_property ALL_PROBE_SAME_MU_CNT 2 [get_debug_cores u_ila_0]
set_property C_ADV_TRIGGER false [get_debug_cores u_ila_0]
set_property C_DATA_DEPTH 1024 [get_debug_cores u_ila_0]
set_property C_EN_STRG_QUAL true [get_debug_cores u_ila_0]
set_property C_INPUT_PIPE_STAGES 0 [get_debug_cores u_ila_0]
set_property C_TRIGIN_EN false [get_debug_cores u_ila_0]
set_property C_TRIGOUT_EN false [get_debug_cores u_ila_0]
set_property port_width 1 [get_debug_ports u_ila_0/clk]
connect_debug_port u_ila_0/clk [get_nets [list clk_100mhz_IBUF_BUFG]]
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe0]
set_property port_width 4 [get_debug_ports u_ila_0/probe0]
connect_debug_port u_ila_0/probe0 [get_nets [list {core_result_index[0]} {core_result_index[1]} {core_result_index[2]} {core_result_index[3]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe1]
set_property port_width 32 [get_debug_ports u_ila_0/probe1]
connect_debug_port u_ila_0/probe1 [get_nets [list {core_result_data[0]} {core_result_data[1]} {core_result_data[2]} {core_result_data[3]} {core_result_data[4]} {core_result_data[5]} {core_result_data[6]} {core_result_data[7]} {core_result_data[8]} {core_result_data[9]} {core_result_data[10]} {core_result_data[11]} {core_result_data[12]} {core_result_data[13]} {core_result_data[14]} {core_result_data[15]} {core_result_data[16]} {core_result_data[17]} {core_result_data[18]} {core_result_data[19]} {core_result_data[20]} {core_result_data[21]} {core_result_data[22]} {core_result_data[23]} {core_result_data[24]} {core_result_data[25]} {core_result_data[26]} {core_result_data[27]} {core_result_data[28]} {core_result_data[29]} {core_result_data[30]} {core_result_data[31]}]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe2]
set_property port_width 1 [get_debug_ports u_ila_0/probe2]
connect_debug_port u_ila_0/probe2 [get_nets [list core_busy]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe3]
set_property port_width 1 [get_debug_ports u_ila_0/probe3]
connect_debug_port u_ila_0/probe3 [get_nets [list core_done]]
create_debug_port u_ila_0 probe
set_property PROBE_TYPE DATA_AND_TRIGGER [get_debug_ports u_ila_0/probe4]
set_property port_width 1 [get_debug_ports u_ila_0/probe4]
connect_debug_port u_ila_0/probe4 [get_nets [list core_result_valid]]
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_100mhz_IBUF_BUFG]
