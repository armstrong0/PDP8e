#
#	makefile for d8tape
#
#	(C) Copyright 2001, 2003, Robert Krten, all rights reserved.
#	Please see the LICENSE file for more information.
#
#	I collect PDP systems of almost all shapes and sizes; send me an
#	email to "rk@parse.com" if you have one to give away, sell,
#	or trade, or visit the museum at http://www.parse.com/~museum/
#
#	2001 01 07	R. Krten		created
#

DEBUG = -g2
OBJECTS = mem_gen.o pdp8_sys.o 

# mem_merge.o

CFLAGS = $(DEBUG) 
LDFLAGS = $(DEBUG)

Common = Makefile
all: mem_gen mem_gen_bin mem_merge

mem_gen: $(OBJECTS)
	cc $(CFLAGS) -o mem_gen $(OBJECTS) $(LDFLAGS)

mem_merge: mem_merge.o $(Common)
	cc $(CFLAGS) -o mem_merge mem_merge.o $(LDFLAGS)

mem_gen_bin: mem_gen_bin.o  $(Common)  pdp8_sys.o 
	cc $(CFLAGS) -o mem_gen_bin mem_gen_bin.o  pdp8_sys.o  $(LDFLAGS)

main.o: main.c $(Common)

#install:
#	make
#	cp -v core /usr/local/bin/d8tape


clean:
	rm -f *.o core
	rm -f mem_gen mem_merge mem_gen_bin
