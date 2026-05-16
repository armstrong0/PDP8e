all: view_tx view_rx view_top view_pdp8

pdp8: serial_top.v tx.v rx.v ../FPGA_image/PDP8e.v
	iverilog -DSIM PDP8e_tb.v ../FPGA_image/PDP8e.v -o pdp8
	vvp pdp8

top: serial_top.v serial_tb.v
	iverilog -DSIM serial_top.v serial_tb.v -o top
	vvp top


tx: tx.v tx_tb.v ../parameters.v
	iverilog -DSIM tx.v tx_tb.v -o tx
	vvp tx
	#gtkwave tx.vcd tx.gtkw	&

rx: rx.v rx_tb.v ../parameters.v
	iverilog -DSIM rx.v rx_tb.v -o rx 
	vvp rx -fst
	
view_pdp9: pdp8
	gtkwave serial_test.vcd pdp8.gtkw
	
view_tx: tx
	gtkwave tx.vcd tx.gtkw & 

view_rx:rx 
	gtkwave rx.vcd rx.gtkw	&

view_top: top
	gtkwave top.vcd top.gtkw &


vdent: rx.v tx.v serial_top.v
	~/bin/vdent < rx.v > t.v
	mv t.v rx.v
	~/bin/vdent < tx.v > t.v
	mv t.v tx.v
	~/bin/vdent <serial_top.v > t.v
	mv t.v serial_top.v

verilator: rx.v tx.v serial_top.v
	verilator -cc serial_top.v
	
clean: 
	rm -f *vcd
	rm -f brg
	rm -f tx
	rm -f rx
	rm -rf top
	rm -f *.vcd
	rm -f *design
	rm -rf top_tx
	

