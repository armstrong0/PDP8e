all: view_tx verilog format sim

view_tx: sd_types.svh sdspi_types.svh sdspi.sv spi_tb.sv
	iverilog -g2012 sd_types.svh sdspi_types.svh sdspi.sv spi_tb.sv
	vvp a.out
	gtkwave sdspi_test.vcd spi.gtkw

verilog: sd_types.svh sdspi_types.svh sdspi.sv sd.sv
	~/.local/bin/sv2v    sd_types.svh sdspi_types.svh sdspi.sv sd.sv > sd.v	

format:
	~/bin/verible-verilog-format sd.sv --inplace
	~/bin/verible-verilog-format sdspi.sv --inplace
	~/bin/verible-verilog-format sd_types.svh --inplace
	~/bin/verible-verilog-format sdspi_types.svh --inplace
	~/bin/verible-verilog-format sd.v --inplace
	~/bin/verible-verilog-format sdsim.sv --inplace

sim: sdsim.sv sd.sv sdspi.sv sd_types.svh sdspi_types.svh
	iverilog -g2012 sd_types.svh sdspi_types.svh sdsim.sv sd.sv sdspi.sv -o sd.o
	vvp sd.o
	gtkwave sdsim.vcd sdsim.gtkw
	
clean:
	rm -rf  *.vcd
	rm -rf *.v
	rm -rf a.out
	rm -rf *.o
	
	
