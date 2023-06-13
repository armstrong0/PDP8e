# Project setup
PROJ      = PDP8e
DEVICE    = 8k

# Files
FILES = PDP8e.v

.PHONY: PDP8e clean burn

PDP8e:
	# synthesize using Yosys
	yosys -p "synth_ice40 -top top -json $(PROJ).json" $(FILES)
	# Place and route using nextpnr
	nextpnr-ice40 -r --hx8k --json $(PROJ).json --package cb132 --asc $(PROJ).asc --opt-timing --pcf PDP8e.pcf

	# Convert to bitstream using IcePack
	icepack $(PROJ).asc $(PROJ).bin

burn:
	iceFUNprog $(PROJ).bin

clean:
	rm -rf *.asc *.bin *blif
	rm -rf *.log
	rm -rf *.vcd
	rm -rf *.json
	rm -rf obj_dir

