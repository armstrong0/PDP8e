all: tx view_rx view_top view_top1 top_tx

top_tx: serial_top.v serial_tb.v
	iverilog -DSIM serial_top.v serial_tb.v -o top_tx
	vvp top_tx


tx: tx.v tx_tb.v ../parameters.v
	iverilog -DSIM tx.v tx_tb.v -o tx
	vvp tx
	#gtkwave tx.vcd tx.gtkw	&

rx: rx.v rx_tb.v ../parameters.v
	iverilog rx.v rx_tb.v -o rx 

rx.vcd: rx
	vvp rx -fst

top_design: serial_top.v serial_tb.v ../parameters.v
	iverilog serial_top.v serial_tb.v -o top_design

top1_design: serial_top.v serial1_tb.v ../parameters.v
	iverilog serial_top.v serial1_tb.v -o top1_design

top_tx.vcd: top_design
	vvp top_design

top1.vcd:top1_design
	vvp top1_design
	
view_tx: top_tx
	gtkwave top_tx.vcd top_tx.gtkw & 

view_rx:rx.vcd 
	gtkwave rx.vcd rx_rx.gtkw	&

view_top: top_tx.vcd
	gtkwave top_tx.vcd top.gtkw &

view_top1: top1.vcd
	gtkwave top1.vcd top.gtkw &

top_tx : top_tx.vcd
	gtkwave top_tx.vcd
	
clean: 
	rm -f *vcd
	rm -f brg
	rm -f tx
	rm -f rx
	rm -f *design
	rm -rf top_tx
	

