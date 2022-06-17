all: view_ac view_cla

ac_results: ac.v ac_tb.v
	iverilog ac.v ac_tb.v -o ac_results

cla_results: ac.v cla_tb.v
	iverilog ac.v cla_tb.v -o cla_results

ac_results.vcd: ac_results
	vvp ac_results


cla_results.vcd: cla_results
	vvp cla_results


view_ac: ac_results.vcd
	gtkwave ac_results.vcd ac.gtkw &

view_cla: cla_results.vcd
	gtkwave cla_results.vcd cla.gtkw &

clean:
	rm -rf *_results
	rm -rf *.vcd
