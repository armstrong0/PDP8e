all: view_ma view_st

ma_test.bin: ma_test.pa
	~/bin/palbart ma_test.pa

ma_jms.bin: ma_jms.pa
	~/bin/palbart ma_jms.pa

ma_test.hex: ma_test.bin
	~/bin/mem_gen ma_test.bin ma_test.hex 
	
ma_jms.hex: ma_jms.bin
	~/bin/mem_gen ma_jms.bin ma_jms.hex 
	
ma_design: ma.v ma_tb.v ma_test.hex
	iverilog ma.v ma_tb.v -o ma_design

ma_st_design: ma.v ma_jms_st_tb.v ma_test.hex
	iverilog ma.v ma_jms_st_tb.v -o ma_st_design

ma_results.vcd: ma_design
	vvp ma_design

ma_jms_st_results.vcd:ma_st_design
	vvp ma_st_design

view_ma:  ma_results.vcd	
	gtkwave ma_results.vcd ma.gtkw &

view_st:  ma_jms_st_results.vcd	
	gtkwave ma_jms_st_results.vcd ma_st.gtkw &

clean:
	rm -rf *design
	rm -rf *.vcd
	rm -rf *.lst
	rm -rf *.bin
	rm -rf *.hex
	

vdent:
	~/bin/vdent <ma.v > t.v
	mv t.v ma.v

