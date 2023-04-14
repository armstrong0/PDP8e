all: view_tx verilog format sim_read sim_write sim_basic

view_tx: sd_types.svh sdspi_types.svh sdspi.sv spi_tb.sv
	iverilog -g2012 sd_types.svh sdspi_types.svh sdspi.sv spi_tb.sv
	vvp a.out
	gtkwave sdspi_test.vcd spi.gtkw

verilog: sd_types.svh sdspi_types.svh sdspi.sv sd.sv
	~/.local/bin/sv2v    sd_types.svh sdspi_types.svh sdspi.sv sd.sv > sd.v	
	~/bin/verible-verilog-format sd.v --inplace


format:
	~/bin/verible-verilog-format sd.sv --inplace
	~/bin/verible-verilog-format sdspi.sv --inplace
	~/bin/verible-verilog-format sd_types.svh --inplace
	~/bin/verible-verilog-format sdspi_types.svh --inplace
	~/bin/verible-verilog-format sdsim.sv --inplace
	~/bin/verible-verilog-format sd_tb.sv --inplace
	
sim_read: sdsim.sv sd.sv sdspi.sv sd_types.svh sdspi_types.svh sd_tb.sv
	iverilog -g2012 sd_types.svh sdspi_types.svh sdsim.sv sd.sv sdspi.sv sd_tb.sv -o sd.o
	vvp sd.o
	gtkwave sdsim.vcd sdsim.gtkw

sim_write: sdsim.sv sd.sv sdspi.sv sd_types.svh sdspi_types.svh sd_tb.sv
	iverilog -g2012 -DWRITE sd_types.svh sdspi_types.svh sdsim.sv sd.sv sdspi.sv sd_tb.sv -o sd.o
	vvp sd.o
	gtkwave sdsim.vcd sdsim.gtkw

sim_basic: rk8e_basic_tb.v rk8e_top.v sdsim.sv sd.sv sdspi.sv sd_types.svh sdspi_types.svh sd_tb.sv ../state_machine/state_machine.v 
	iverilog -g2012 rk8e_basic_tb.v rk8e_top.v ../state_machine/state_machine.v sd_types.svh sdspi_types.svh sdsim.sv sd.sv sdspi.sv  -o sdb.o
	vvp sdb.o
	gtkwave sdb.vcd sdsim.gtkw


clean:
	rm -rf  *.vcd
	rm -rf *.v
	rm -rf a.out
	rm -rf *.o
	
	
