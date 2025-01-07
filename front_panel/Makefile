all: view_front view_front_st view_system

front_design: front_panel.v D_mux.v front_panel_tb.v
	iverilog -DSIM front_panel.v D_mux.v front_panel_tb.v -o front_design

front_panel.vcd: front_design
	vvp front_design

front_st: front_panel.v front_panel_st_tb.v
	iverilog -DSIM front_panel.v front_panel_st_tb.v -o front_st



front_st.vcd: front_st
	vvp front_st

system.vcd: front_panel.v PDP8e_tb.v
	iverilog -DSIM PDP8e_tb.v ../FPGA_image/PDP8e.v -o system.o
	vvp system.o
		

view_front: front_panel.vcd
	gtkwave front_panel.vcd front_panel.gtkw &


view_front_st: front_st.vcd
	gtkwave front_st.vcd front_st.gtkw &

view_system: system.vcd
	gtkwave system.vcd system.gtkw    

clean:
	rm -rf front_design front_st  *.vcd
	rm -rf *.o

	
vdent:
	~/bin/vdent <front_panel.v > t.v
	mv t.v front_panel.v
	~/bin/vdent <D_mux.v > t.v
	mv t.v D_mux.v

