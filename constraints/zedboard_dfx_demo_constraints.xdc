# ============================================================================
# ZedBoard Rev. D
# Adaptive TPU manual-DFX hardware demo
#
# Device:
# XC7Z020-CLG484-1
# ============================================================================


# ----------------------------------------------------------------------------
# 100 MHz PL oscillator
# ----------------------------------------------------------------------------

set_property PACKAGE_PIN Y9 [get_ports clk_100mhz]
set_property IOSTANDARD LVCMOS33 [get_ports clk_100mhz]

create_clock \
    -period 10.000 \
    -name sys_clk \
    -waveform {0.000 5.000} \
    [get_ports clk_100mhz]


# ----------------------------------------------------------------------------
# Push buttons
# ----------------------------------------------------------------------------

# BTNC = reset

set_property PACKAGE_PIN P16 [get_ports btn_reset]
set_property IOSTANDARD LVCMOS33 [get_ports btn_reset]


# BTNU = start

set_property PACKAGE_PIN T18 [get_ports btn_start]
set_property IOSTANDARD LVCMOS33 [get_ports btn_start]


# ----------------------------------------------------------------------------
# SW0 = manual DFX isolate/reset
# ----------------------------------------------------------------------------

set_property PACKAGE_PIN F22 [get_ports sw_isolate]
set_property IOSTANDARD LVCMOS33 [get_ports sw_isolate]


# ----------------------------------------------------------------------------
# User LEDs LD0 ... LD7
# ----------------------------------------------------------------------------

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


# ----------------------------------------------------------------------------
# Asynchronous board inputs
# ----------------------------------------------------------------------------

set_false_path -from [get_ports btn_reset]
set_false_path -from [get_ports btn_start]
set_false_path -from [get_ports sw_isolate]