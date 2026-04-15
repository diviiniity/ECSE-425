
vlib work
vmap work work

vcom -2008 -work work p4/memory.vhd
vcom -2008 -work work p4/package.vhd
vcom -2008 -work work p4/register_file.vhd
vcom -2008 -work work p4/cpu_subfiles/branch_logic.vhd
vcom -2008 -work work p4/cpu_subfiles/ALU_decoder.vhd
vcom -2008 -work work p4/cpu_subfiles/Main_decoder.vhd
vcom -2008 -work work p4/cpu_subfiles/Control_unit.vhd
vcom -2008 -work work p4/cpu_subfiles/ALU.vhd
vcom -2008 -work work p4/cpu_subfiles/Imm_extension.vhd
vcom -2008 -work work p4/cpu.vhd
vcom -2008 -work work p4/cpu_tb.vhd


vsim -t 1ps work.cpu_tb
run -all