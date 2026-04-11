
vlib work
vmap work work

vcom -2008 -work work memory.vhd
vcom -2008 -work work register_file.vhd
vcom -2008 -work work cpu.vhd
vcom -2008 -work work cpu_tb.vhd


vsim -t 1ps work.cpu_tb
run -all