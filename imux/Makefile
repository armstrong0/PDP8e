all: basic

imux_base: imux.v imux_base_tb.v
	iverilog imux.v imux_base_tb.v -o imux_base

imux_base.vcd: imux_base
	vvp imux_base

basic:  imux_base.vcd	
	gtkwave imux_base.vcd imux.gtkw &


clean:
	rm -rf *_design
	rm -rf *.vcd
	rm -rf imux_base


