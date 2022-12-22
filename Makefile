SUBDIRS = ac pc imux ma EAE state_machine FPGA_image integrate front_panel \
	mem_gen mem_ext serial

.PHONY: clean vdent

clean:
	for dir in $(SUBDIRS); do \
	$(MAKE) -C $$dir -f Makefile $@; \
	done


vdent:
	for dir in $(SUBDIRS); do \
	$(MAKE) -C $$dir -f Makefile $@; \
	done
