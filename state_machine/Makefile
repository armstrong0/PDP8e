all: view view_AMC

AMC: state_machine_AMC.v state_machine_AMC_tb.v ../ram/ram.v ops.txt
	iverilog state_machine_AMC.v state_machine_AMC_tb.v ../ram/ram.v -o AMC

state_design: state_machine.v state_machine_tb.v ../ram/ram.v ops.txt
	iverilog state_machine.v state_machine_tb.v ../ram/ram.v -o state_design

AMC.vcd: AMC
	vvp AMC

state_test.vcd: state_design
	vvp state_design

view: state_test.vcd
	gtkwave state_test.vcd state.gtkw &

view_AMC: AMC.vcd
	gtkwave AMC.vcd state.gtkw &
    

clean: 
	rm *vcd
	rm state_design
	rm AMC

