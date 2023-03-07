all: view_tx

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


clean:
	rm *.vcd
	rm *.v
	rm a.out
	
	
