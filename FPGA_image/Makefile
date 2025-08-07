# Project setup
PROJ      = PDP8e
DEVICE    = 8k

# Files
FILES = PDP8e.v

.PHONY: PDP8e clean burn ../RK8E/rk8e.v

PDP8e: ../RK8E/rk8e.v
	# synthesize using Yosys
	yosys -p "synth_ice40 -top PDP8e -json $(PROJ).json" $(FILES) -l synth.log
	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf PDP8e.pcf -l routing.log

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

../RK8E/rk8e.v: ../RK8E/rk8e.sv
	$(MAKE) -C../RK8E/ -f Makefile verilog

burn:
	iceFUNprog $(PROJ).bin

place:
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf PDP8e.pcf -l routing.log
	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

	


clean:
	rm -rf *.asc *.bin *blif
	rm -rf *.log
	rm -rf *.vcd
	rm -rf *.json
	rm -rf obj_dir
	$(MAKE) -C Test_SW -f Makefile clean
	

sim: PDP8e.v PDP8e_tb.v 
	iverilog -DSIM PDP8e_tb.v PDP8e.v -o PDP8e_design
	vvp PDP8e_design
	gtkwave top.vcd top.gtkw

verilator: PDP8e.v
	verilator -DSIM -cc PDP8e.v

pll: 
	icepll -i 12 -o 73  -f  pll.v -m

lint: 
	verilator -cc -DSIM PDP8e.v
	
	

