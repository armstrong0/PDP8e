all: view_front view_front_st view_system view_timing auto_start_RK8E auto_start_CSD

front_design: front_panel.v D_mux.v front_panel_tb.v
	iverilog -DSIM -g2012 front_panel.v D_mux.v front_panel_tb.v -o front_design

front_panel.vcd: front_design
	vvp front_design

front_tm: front_panel.v front_panel_tm_tb.v
	iverilog -g2012 -DSIM front_panel.v D_mux.v front_panel_tm_tb.v ../FPGA_image/HX_clock.v -o front_tm

timing.vcd : front_tm
	vvp front_tm

front_st: front_panel.v front_panel_st_tb.v
	iverilog -DSIM -g2012 front_panel.v front_panel_st_tb.v -o front_st



front_st.vcd: front_st
	vvp front_st

system.vcd: front_panel.v PDP8e_tb.v
	iverilog -DSIM -g2012  PDP8e_tb.v ../FPGA_image/PDP8e.v -o system.o
	vvp system.o
		

view_front: front_panel.vcd
	gtkwave front_panel.vcd front_panel.gtkw &


view_front_st: front_st.vcd
	gtkwave front_st.vcd front_st.gtkw &

view_system: system.vcd
	gtkwave system.vcd system.gtkw   

view_timing: timing.vcd
	gtkwave timing.vcd front_timing.gtkw
	
auto_start_RK8E: front_panel.v auto_start_tb.v
	iverilog -g2012 -DAS_RK8E front_panel.v auto_start_tb.v -o auto_start.o
	vvp auto_start.o
	gtkwave auto_start.vcd auto_start.gtkw

auto_start_CSD: front_panel.v auto_start_tb.v
	iverilog -g2012 -DAS_CSD front_panel.v auto_start_tb.v -o auto_start.o
	vvp auto_start.o
	gtkwave auto_start.vcd auto_start.gtkw

clean:
	rm -rf front_design front_st  *.vcd front_tm
	rm -rf *.o

	
vdent:
	~/bin/vdent <front_panel.v > t.v
	mv t.v front_panel.v
	~/bin/vdent <D_mux.v > t.v
	mv t.v D_mux.v

