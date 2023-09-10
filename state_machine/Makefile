all: view view_AMC view_db

AMC: state_machine_AMC.v state_machine_AMC_tb.v ../ram/ram.v ops.txt
	iverilog -DTSIM  state_machine_AMC.v state_machine_AMC_tb.v ../ram/ram.v -o AMC

DB: state_machine.v state_machine_db_tb.v
	iverilog state_machine.v state_machine_db_tb.v -DSIM -DRK8E -o DB

state_design: state_machine.v state_machine_tb.v ../ram/ram.v ops.txt
	iverilog -DSIM -DRK8E state_machine.v state_machine_tb.v ../ram/ram.v -o state_design

AMC.vcd: AMC
	vvp AMC

DB.vcd: DB
	vvp DB

state_test.vcd: state_design
	vvp state_design

view: state_test.vcd
	gtkwave state_test.vcd state.gtkw &

view_AMC: AMC.vcd
	gtkwave AMC.vcd state.gtkw &
    
view_db: DB.vcd
	gtkwave DB.vcd state.gtkw &

clean: 
	rm -rf *vcd
	rm -rf state_design
	rm -rf AMC
	rm -rf DB
	rm -rf obj_dir/

vdent:
	~/bin/vdent < state_machine.v > t.v
	mv t.v state_machine.v
	
	

