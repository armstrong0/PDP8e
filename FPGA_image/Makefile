# Project setup
PROJ      = PDP8e
DEVICE    = 8k

# Files
FILES = PDP8e.v

.PHONY: PDP8e clean burn

PDP8e:
	# synthesize using Yosys
	yosys -p "synth_ice40 -top top -json $(PROJ).json" $(FILES) -l synth.log
	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf PDP8e.pcf -l routing.log

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

burn:
	iceFUNprog $(PROJ).bin

clean:
	rm *.asc *.bin *blif
	rm top_design
	rm top.vcd

sim: PDP8e.v PDP8e_tb.v 
	iverilog -DSIM PDP8e_tb.v PDP8e.v -o PDP8e_design
	vvp PDP8e_design
	gtkwave top.vcd top.gtkw

# was 62.25
pll: 
	icepll -i 12 -o 62.25  -f  pll.v -m
	

