# Project setup
PROJ      = PDP8e
DEVICE    = 8k

# Files
FILES = PDP8e.v

.PHONY: PDP8e clean burn ../RK8E/rk8e.v sim

PDP8e: ../RK8E/rk8e.v
	cp clock.v ../clock.v
	# synthesize using Yosys
	yosys -p "synth_ice40 -top PDP8e -json $(PROJ).json" $(FILES) -l synth.log
	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf PDP8e.pcf -l routing.log

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

../RK8E/rk8e.v: ../RK8E/rk8e.sv
	$(MAKE) -C../RK8E/ -f Makefile verilog

sim: PDP8e_tb.v PDP8e.v inst_mux.v char_mux.v
	iverilog -DSIM PDP8e_tb.v PDP8e.v -o PDP8e.o
	vvp PDP8e.o
	gtkwave Hardware_serial_test.vcd serial_test.gtkw


burn:
	iceFUNprog $(PROJ).bin

clean:
	rm -rf *.asc *.bin *blif
	rm -rf *.log
	rm -rf top_design
	rm -rf *.vcd
	rm -rf *json
	rm -rf obj_dir

verilator: PDP8e.v
	verilator -DSIM -cc PDP8e.v

# was 62.25
pll: 
	icepll -i 12 -o 74.00  -f  pll.v -m

lint: 
	verilator -cc -DSIM PDP8e.v
	
	

