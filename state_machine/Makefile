all: view view_AMC 

AMC: state_machine_AMC.v state_machine_AMC_tb.v ../ram/ram.v ops.txt
	iverilog -DTSIM  state_machine_AMC.v state_machine_AMC_tb.v ../ram/ram.v -o AMC

state_design: state_machine.v state_machine_tb.v ../ram/ram.v sm.hex
	iverilog -DSIM -DRK8E state_machine.v state_machine_tb.v ../ram/ram.v -o state_design

sm.bin: sm.pa
	~/bin/palbart sm.pa

sm.hex: sm.bin
	~/bin/mem_gen sm.bin sm.hex

AMC.vcd: AMC
	vvp AMC

state_test.vcd: state_design
	vvp state_design

view: state_test.vcd
	gtkwave state_test.vcd state.gtkw &

view_AMC: AMC.vcd
	gtkwave AMC.vcd state.gtkw &

clean: 
	rm -rf *vcd
	rm -rf state_design
	rm -rf AMC
	rm -rf DB
	rm -rf obj_dir/
	rm -rf *.bin
	rm -rf *.lst
	rm -rf *.hex
	rm -rf *.err

vdent:
	~/bin/vdent < state_machine.v > t.v
	mv t.v state_machine.v
	
	

