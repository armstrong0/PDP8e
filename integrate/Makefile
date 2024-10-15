all:  t1 t1.1 t2 t3 t4 t5 t6 t7 t8 t9 t10 t11 t12

t1.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM -Wall ../FPGA_image/PDP8e.v PDP8e_tb.v -o t1.o -PPDP8e_tb.test_sel=1
	vvp t1.o -fst

t1.1.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t1.1.o -PPDP8e_tb.test_sel=1.1
	vvp t1.1.o -fst

t2.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t2.o -PPDP8e_tb.test_sel=2
	vvp t2.o -fst

t2.1.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t2.1.o -PPDP8e_tb.test_sel=2.1
	vvp t2.1.o -fst

t3.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t3.o -PPDP8e_tb.test_sel=3
	vvp t3.o -fst 

t4.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t4.o -PPDP8e_tb.test_sel=4
	vvp t4.o -fst

t5.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t5.o -PPDP8e_tb.test_sel=5
	vvp t5.o -fst

t6.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t6.o -PPDP8e_tb.test_sel=6
	vvp t6.o -fst

t7.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t7.o -PPDP8e_tb.test_sel=7
	vvp t7.o -fst

t8.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t8.o -PPDP8e_tb.test_sel=8
	vvp t8.o -fst

t9.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t9.o -PPDP8e_tb.test_sel=9
	vvp t9.o -fst 

t10.o: ../FPGA_image/PDP8e.v PDP8e_tb.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t10.o -PPDP8e_tb.test_sel=10
	vvp t10.o -fst

t11.o: ../FPGA_image/PDP8e.v PDP8e_tb.v ../mem_ext/mem_ext.v
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t11.o -PPDP8e_tb.test_sel=11
	vvp t11.o -fst

t12.o: ../FPGA_image/PDP8e.v PDP8e_tb.v 
	iverilog -DSIM -DTSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t12.o -PPDP8e_tb.test_sel=12
	vvp t12.o -fst

t13.o: ../FPGA_image/PDP8e.v PDP8e_tb.v 
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t13.o -PPDP8e_tb.test_sel=13
	vvp t13.o -fst

t14.o: ../FPGA_image/PDP8e.v PDP8e_tb.v 
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t14.o -PPDP8e_tb.test_sel=14
	vvp t14.o -fst

t15.o: ../FPGA_image/PDP8e.v PDP8e_tb.v 
	iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_tb.v -o t15.o -PPDP8e_tb.test_sel=15
	vvp t15.o -fst

t1: t1.o  
	 rm -f t1.o
	 gtkwave instruction_test_pt1.vcd PDP8e.gtkw & 
	
t1.1: t1.1.o  
	 rm -f t1.1.o
	 gtkwave instruction_test_pt1.1.vcd PDP8e.gtkw & 
	
t2: t2.o  
	 rm -f t1.1.o
	 gtkwave instruction_test_pt2.vcd PDP8e.gtkw &

t2.1: t2.1.o  
	 rm -f t1.1.o
	 gtkwave instruction_test_pt2.vcd PDP8e.gtkw &

t3: t3.o  
	 rm -f t3.o
	 gtkwave Adder_test.vcd PDP8e.gtkw  &
	
t4: t4.o   
	rm -f t4.o
	gtkwave Basic_JMP_JMS_test.vcd PDP8e.gtkw &
	
t5: t5.o  
	rm -f t5.o
	gtkwave TAD_test.vcd PDP8e.gtkw &
	
t6: t6.o 
	rm -f t6.o
	gtkwave AND_test.vcd PDP8e.gtkw &

t7: t7.o 
	rm -f t7.o
	gtkwave ISZ_test.vcd PDP8e.gtkw &

t8: t8.o 
	rm -f t8.o
	gtkwave DCA_test.vcd PDP8e.gtkw &

t9: t9.o 
	rm -f t9.o
	gtkwave RJMP_test.vcd PDP8e.gtkw &

t10: t10.o 
	rm -f t10.o
	gtkwave RJMP_JMS_test.vcd PDP8e.gtkw &

t11: t11.o
	rm -f t11.o
	gtkwave extended_memory.vcd PDP8e.gtkw &

t12: t12.o
	rm -f t12.o
	gtkwave Serial_test.vcd t12.gtkw &

t13: t13.o
	rm -f t13.o
	gtkwave EAE_test1.vcd PDP8e.gtkw &
	
t14: t14.o
	rm -f t14.o
	gtkwave EAE_test2.vcd PDP8e.gtkw &

t15: t15.o
	rm -f t15.o
	gtkwave EAE_EME_test.vcd PDP8e.gtkw &
	
	

clean:
	-rm -f top.a
	-rm -f top.vcd
	-rm -f *.vcd
	-rm -f *.a
	-rm -f *.o
	


