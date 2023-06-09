all: ram clean

ram: ram_tb.v ram.v
	iverilog ram_tb.v ram.v -o ram.o
	vvp ram.o 
	gtkwave ram_results.vcd ram.gtkw

clean:
	rm -rf *.o
	rm -rf *.vcd
	
