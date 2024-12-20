# Project setup
PROJ      = PDP8e
DEVICE    = 8k

# Files
FILES = PDP8e.v

.PHONY: PDP8e clean burn 


PDP8e: PDP8e.v
	# synthesize using Yosys
	yosys -p "synth_ice40 -top PDP8e -json $(PROJ).json" $(FILES) -l synth.log
	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf PDP8e.pcf -l routing.log

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

SIM: PDP8e.v PDP8e_tb.v
	iverilog -DSIM PDP8e.v PDP8e_tb.v -o IO_sim.o
	vvp IO_sim.o
	gtkwave IO_sim.vcd IO_sim.gtkw

burn:
	iceFUNprog $(PROJ).bin

clean:
	rm -rf *.asc *.bin *blif
	rm -rf *.log
	rm -rf *.vcd
	rm -rf *.json
	rm -rf *.o
	rm -rf obj_dir


verilator: PDP8e.v
	verilator -DSIM -cc PDP8e.v

pll: 
	icepll -i 12 -o 73  -f  pll.v -m

lint: 
	verilator -cc -DSIM PDP8e.v
	
	

