
vlib work
vmap work work

vcom -2008 -work work memory.vhd
vcom -2008 -work work package.vhd
vcom -2008 -work work register_file.vhd
vcom -2008 -work work cpu_subfiles/branch_logic.vhd
vcom -2008 -work work cpu_subfiles/ALU_decoder.vhd
vcom -2008 -work work cpu_subfiles/Main_decoder.vhd
vcom -2008 -work work cpu_subfiles/Control_unit.vhd
vcom -2008 -work work cpu_subfiles/ALU.vhd
vcom -2008 -work work cpu_subfiles/Imm_extension.vhd
vcom -2008 -work work cpu.vhd
vcom -2008 -work work cpu_tb.vhd


vsim -t 1ps work.cpu_tb
run -all