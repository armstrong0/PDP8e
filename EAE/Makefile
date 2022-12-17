.PRECIOUS: %.vcd %.ob

all: shl asr lsr mul div dpsz dpic dcm sam dad dst swap sca_asc dst dst_ext

%.ob:../FPGA_image/PDP8e.v PDP8e_EAE_tb.v  ../ac/ac.v ../state_machine/state_machine.v ../ma/ma.v %.hex
	-iverilog -DSIM ../FPGA_image/PDP8e.v PDP8e_EAE_tb.v -o $*.ob -PPDP8e_tb.test_sel=14

%.vcd: %.ob
	vvp $*.ob -fst
	-sleep 1    # wait for vvp to finish
	-mv SHL_Test1.vcd $*.vcd
 
%.hex: %.pa
	~/bin/palbart $<
	~/bin/mem_gen_bin $*.bin $*.hex
	-cp $*.hex t14.hex

%: %.vcd 	
	gtkwave $*.vcd t13.gtkw &

clean:
	-rm -f top.a
	-rm -f top.vcd
	-rm -f *.vcd
	-rm -f *.a
	-rm -f *.o *.ob
	-rm -f *.lst
	-rm -f *.bin *.err
	-rm -f *.hex
	


