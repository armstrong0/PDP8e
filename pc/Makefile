all: view


pc_design: pc.v pc_tb.v 
	iverilog pc.v pc_tb.v -o pc_design

pc_results.vcd: pc_design
	vvp pc_design

view:  pc_results.vcd	
	gtkwave pc_results.vcd pc.gtkw &
clean:
	rm -rf pc_design
	rm -rf pc_results.vcd

vdent:
	~/bin/vdent <pc.v > t.v
	mv t.v pc.v


