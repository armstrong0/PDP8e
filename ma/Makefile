all: view_ma view_pc view_jms view_st

ma_test.bin: ma_test.pa
	palbart ma_test.pa

#ma_pc.bin: ma_pc.pa
#	palbart ma_pc.pa

ma_jms.bin: ma_jms.pa
	palbart ma_jms.pa

ma_test.hex: ma_test.bin
	mem_gen ma_test.bin ma_test.hex 
	
#ma_pc.hex: ma_pc.bin
#	mem_gen ma_pc.bin ma_pc.hex 
	
ma_jms.hex: ma_jms.bin
	mem_gen ma_jms.bin ma_jms.hex 
	
ma_design: ma.v ma_tb.v ma_test.hex
	iverilog ma.v ma_tb.v -o ma_design

ma_st_design: ma.v ma_jms_st_tb.v ma_test.hex
	iverilog ma.v ma_jms_st_tb.v -o ma_st_design


ma_pc_design: ma.v ma_pc_tb.v ../pc/pc.v ma_test.hex
	iverilog ma.v ma_pc_tb.v -o ma_pc_design

ma_results.vcd: ma_design
	vvp ma_design

ma_pc_results.vcd: ma_pc_design
	vvp ma_pc_design

ma_jms_st_results.vcd:ma_st_design
	vvp ma_st_design

ma_jms_design: ma.v ma_jms_tb.v ma_jms.hex
	iverilog ma.v ma_jms_tb.v -o ma_jms_design

ma_jms_results.vcd: ma_jms_design
	vvp ma_jms_design

view_ma:  ma_results.vcd	
	gtkwave ma_results.vcd ma.gtkw &

view_pc:  ma_pc_results.vcd	
	gtkwave ma_pc_results.vcd ma.gtkw &

view_jms:  ma_jms_results.vcd	
	gtkwave ma_jms_results.vcd ma_jms.gtkw &

view_st:  ma_jms_st_results.vcd	
	gtkwave ma_jms_st_results.vcd ma_st.gtkw &

clean:
	rm -rf *design
	rm -rf *.vcd

vdent:
	~/bin/vdent <ma.v > t.v
	mv t.v ma.v

