SUBDIRS = ac pc imux ma EAE state_machine FPGA_image FPGA_IO_test integrate \
	front_panel mem_gen mem_ext serial RK8E

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
