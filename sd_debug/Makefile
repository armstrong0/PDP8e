all:  full_read palbart dumprk05.bin dumprk05 dumprk05.hex dump_vcd dump_hex

dump_hex: dump_hex.bin

dump_oct: dump_oct.bin

dump_hex.bin:  dump_hex.pal palbart
	./palbart dump_hex.pal

dump_oct.bin:  dump_oct.pal palbart
	./palbart dump_oct.pal
	~/bin/mem_gen_bin dump_oct.bin dump_oct.hex 

hex2oct: hex2oct.c
	gcc hex2oct.c -o hex2oct	


palbart: palbart.c
	gcc palbart.c -o palbart

dumprk05: dumprk05.c 
	gcc dumprk05.c -o dumprk05

dumprk05.bin: dumprk05.pal palbart
	./palbart dumprk05.pal

dumprk05.hex: dumprk05.bin
	~/bin/mem_gen_bin dumprk05.bin dumprk05.hex

write_sector.hex: write_sector.pal
	~/bin/palbart write_sector.pal
	~/bin/mem_gen_bin write_sector.bin write_sector.hex

	

../RK8E/sdsim.v: ../RK8E/sdsim.sv
	~/.local/bin/sv2v ../RK8E/sdsim.sv > ../RK8E/sdsim.v

../RK8E/rk8e.v: ../RK8E/rk8e.sv
	~/.local/bin/sv2v -DSIM ../RK8E/rk8e.sv ../RK8E/sd_types.svh ../RK8E/sdspi_types.svh ../RK8E/sdspi.sv ../RK8E/sd.sv >../RK8E/rk8e.v 
	
	

full_read: ../FPGA_image/PDP8e.v PDP8e_tb.v ../RK8E/rk8e.v ../RK8E/sdsim.v dumprk05.hex
	iverilog -g2012 -DSIM -DRK8E ../FPGA_image/PDP8e.v PDP8e_tb.v ../RK8E/sdsim.v -o sdcard.o 
	vvp sdcard.o -fst
	gtkwave SDCard.vcd full_debug.gtkw &

write :  ../FPGA_image/PDP8e.v PDP8e_tb.v ../RK8E/rk8e.v ../RK8E/sdsim.v write_sector.hex
	iverilog -g2012 -DSIM -DRK8E ../FPGA_image/PDP8e.v  PDP8e_tb.v ../RK8E/sdsim.v -o sdcard.o
	vvp sdcard.o -fst
	gtkwave SDCard.vcd full_debug.gtkw &
	

clean:
	rm -rf  *.vcd
	rm -rf a.out
	rm -rf *.o *.lst SDcard.vcd
	rm -rf hex2oct dump_rk05
	rm -rf palbart
	rm -rf *.hex
	rm -rf *.bin
	
	
	
