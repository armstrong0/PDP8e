all: view_tx verilog format sim sim_basic rk8e.v full_read sdsim.v


view_tx: sd_types.svh sdspi_types.svh sdspi.sv spi_tb.sv
	iverilog -g2012 sd_types.svh sdspi_types.svh sdspi.sv spi_tb.sv
	vvp a.out
	gtkwave sdspi_test.vcd spi.gtkw

rk8e.v:  rk8e.sv sd_types.svh sdspi_types.svh sdspi.sv sd.sv
	~/.local/bin/sv2v rk8e.sv sd_types.svh sdspi_types.svh sdspi.sv sd.sv >rk8e.v 
	~/bin/verible-verilog-format rk8e.v --inplace

sdsim.v:sdsim.sv
	~/.local/bin/sv2v sdsim.sv > sdsim.v


verilog: rk8e.sv sd.sv rk8e.sv sd_types.svh sdspi_types.svh sdspi.sv sd.sv
	~/.local/bin/sv2v sd_types.svh sdspi_types.svh sdspi.sv sd.sv > sd.v	
	~/.local/bin/sv2v rk8e.sv sd_types.svh sdspi_types.svh sdspi.sv sd.sv >rk8e.v 
	~/.local/bin/sv2v sdsim.sv > sdsim.v

format:
	~/bin/verible-verilog-format sd.sv --inplace
	~/bin/verible-verilog-format sdspi.sv --inplace
	~/bin/verible-verilog-format sd_types.svh --inplace
	~/bin/verible-verilog-format sdspi_types.svh --inplace
	~/bin/verible-verilog-format sdsim.sv --inplace
	~/bin/verible-verilog-format sd_tb.sv --inplace
	~/bin/verible-verilog-format rk8e.sv --inplace
	
sim: sdsim.sv sd.sv sdspi.sv sd_types.svh sdspi_types.svh sd_tb.sv
	iverilog -g2012 sd_types.svh sdspi_types.svh sdsim.sv sd.sv sdspi.sv sd_tb.sv -o sd.o
	vvp sd.o
	gtkwave sdsim.vcd sdsim.gtkw

sim_write: sdsim.sv sd.sv sdspi.sv sd_types.svh sdspi_types.svh sd_tb.sv
	iverilog -g2012 -DWRITE sd_types.svh sdspi_types.svh sdsim.sv sd.sv sdspi.sv sd_tb.sv -o sd.o
	vvp sd.o
	gtkwave sdsim.vcd sdsim.gtkw

sim_basic: rk8e_basic_tb.v rk8e.sv sdsim.sv sdspi.sv ../state_machine/state_machine.v ../ma/ma.v sdsim.sv sd.sv
	iverilog -DSIM -g2012 rk8e_basic_tb.v rk8e.sv ../state_machine/state_machine.v ../ma/ma.v sdsim.sv sd.sv sdspi.sv -o sdb.o
	vvp sdb.o
	gtkwave sdb.vcd sdsim.gtkw


sim_verilog: rk8e_basic_tb.v rk8e.v sdsim.v ../state_machine/state_machine.v ../ma/ma.v sdsim.v sd.sv
	iverilog -DSIM rk8e_basic_tb.v rk8e.v ../state_machine/state_machine.v ../ma/ma.v -o sdb.o
	vvp sdb.o
	gtkwave sdb.vcd sdsim.gtkw

full_read: ../FPGA_image/PDP8e.v PDP8e_tb.v rk8e.v sdsim.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v sdsim.v -o sdcard.o 
	vvp sdcard.o -fst
	gtkwave SDCard.vcd full_debug.gtkw &





clean:
	rm -rf  *.vcd
	rm -rf sd.v
	rm -rf sdsim.v 
	rm -rf rk8e.v
	rm -rf a.out
	rm -rf *.o
	
	
