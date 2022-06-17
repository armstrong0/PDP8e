

mem_view: mem_ext.v mem_ext_tb.v mem_ext.hex
	iverilog -DSIM mem_ext_tb.v mem_ext.v -o mem_ext.o
	vvp mem_ext.o
	gtkwave mem_ext.vcd mem_ext.gtkw

mem_ext.hex: mem_ext.pal
	macro8x  mem_ext.pal
	mem_gen_bin mem_ext.bin mem_ext.hex

clean: 
	rm -f *.o
	rm -f *.vcd
	rm -f *.bin
	rm -f *.rim
	rm -f *.bin
	rm -f *.lst
	

