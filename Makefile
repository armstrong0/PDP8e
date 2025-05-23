SUBDIRS = ac pc imux ma EAE state_machine FPGA_image FPGA_up5k FPGA_IO_test integrate \
	front_panel mem_gen mem_ext serial RK8E sd_debug

.PHONY: clean vdent

clean:
	for dir in $(SUBDIRS); do \
	$(MAKE) -C $$dir -f Makefile $@; \
	done
	rm -rf *~


vdent:
	for dir in $(SUBDIRS); do \
	$(MAKE) -C $$dir -f Makefile $@; \
	done
