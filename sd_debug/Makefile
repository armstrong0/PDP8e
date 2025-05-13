all:  full_read palbart dumprk05.bin dumprk05 dumprk05.hex dump_vcd

hex2oct: hex2oct.c
	gcc hex2oct.c -o hex2oct	


palbart: palbart.c
	gcc palbart.c -o palbart

dumprk05: dumprk05.c 
	gcc dumprk05.c -o dumprk05

dumprk05.bin: dumprk05.pal
	./palbart dumprk05.pal

dumprk05.hex: dumprk05.bin
	~/bin/mem_gen_bin dumprk05.bin dumprk05.hex
	

../RK8E/sdsim.v: ../RK8E/sdsim.sv
	~/.local/bin/sv2v ../RK8E/sdsim.sv > ../RK8E/sdsim.v

../RK8E/rk8e.v:
	~/.local/bin/sv2v -DSIM ../RK8E/rk8e.sv ../RK8E/sd_types.svh ../RK8E/sdspi_types.svh ../RK8E/sdspi.sv ../RK8E/sd.sv >../RK8E/rk8e.v 
	
	

full_read: ../FPGA_image/PDP8e.v PDP8e_tb.v ../RK8E/rk8e.v ../RK8E/sdsim.v
	iverilog -g2012 -DSIM -DRK8E ../FPGA_image/PDP8e.v PDP8e_tb.v ../RK8E/sdsim.v -o sdcard.o 
	vvp sdcard.o -fst
	gtkwave SDCard.vcd full_debug.gtkw &



clean:
	rm -rf  *.vcd
	rm -rf a.out
	rm -rf *.o *.lst SDcard.vcd
	rm -rf hex2oct dump_rk05
	rm -rf *.hex
	rm -rf *.bin
	
	
	
