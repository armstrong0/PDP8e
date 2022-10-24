This directory contains the test bed (PDP8e_tb.v) to test the PDP8e contained 
in the FPGA_image directory.  This test bed uses the top level PDP8e.  There
are a few changes made using ifdefines: 

the PLL is not used in simulation, instead the test bed generates a clock.

The baud rate is increased significantly in order to speed up simulation

The debounce counter is made much smaller to enable shorter simulation times.

On the computer I am using about the maximum simulation time is about 10
seconds this takes MANY minutes and loads the machine significantly,

It might be possible to do better with Verilator instead of iverilog.  However
what is working is almost enough, some tests run to completion, other make it
through a single pass whilst others I am not sure how far they go...

The test bed selects portions of verilog to execute depending upon a test
selection parameter passed in.  There are three case statements, one to do the
initial loading of the hex file, the second that controls the inputs to the
PDP8e, i.e. switch register and keyswitches like halt, cont exam dep ...  The
third watches the addresses being accessed and the intruction pulled from
memory.  It is set to finish the simulation if a halt occurs and prints out
informative messages when certain address are found.  The coverage of these
meesages is not very consistant across different tests.  Tests that I had
trouble with tend to have better coverage.

The structure of the test bed is not all that good, it has grown as I have
learned about coding in verilog and figuring out new ways to make thing easier
to do.

There are 14 tests possible (designated t1, t1.1, t2, t2.1, t2 .. t12.  The
names of the VCD files produced tells you what is being tested.  For each test
a hex file is loaded, the hex file comes from within the Diagnostics directory.
In the diagnostics directory are the hex files, a bin file with the same 4 (or
5) charactor base name.  It maybe prepended with maindec-8e-  (or in caps).
Also is a documentation file with the same base part of the file name.  That
documentation files describes how to run the test on a real PDP8e.  For the
most part the test bed file does that work.  

The last test t12 is a serial interface test.  The test has many sub parts,
some of which are expected to run while others are not.  Any test trying to do
timing will be troublesome as this PDP8e is way faster that the original.  A
new state machine design was created that added delay states to increase the
execution time of the state.  The state machine is then run at a simulation
frequecy of 5 MHz.  The test is set to run at 1200 baud.  Prog0 and prog1 are
the two sets if tests that test the logic implemention, the rest mostly test
the ASR33 or ASR37.

One thing that t12 requires is loopback tx to tx.  I unhooked the recieve line
of the FPGA from the USB to serial converter and tied tx to rx.  I realized
later that I could have "rewired" it inside of the test bed without changing the
hardware.

Now the tx tests run as well as the rx tests.

I don't think it is practical to try to run these serial tests on hardware.  5
MHz clock would have to be generated, the modified state machine would have to
be used.  The real clock on hardware is somewhat over 60 MHz.  The modified
state machine has 2 or 3 "wait" states added to each Machine cycle. The
hardware PDPE is running some 18 times (or more) faster than the original. 

Each machine cycle needs to take 1.2 microseconds.
The FPGA currently runs at 62.25 MHz.  How many phases do I need?  1.2x 10-6 /
(1/62.25 *10+6) = 74.7.  This seems excessive try 16 MHz...  = 19.2  assume 20
and calcuate the frequency..  20 = 0.0000012/(1/f)  1/f = 0.0000012/20  f =
1/(0.0000012/20) f = 20/0.0000012 - 16.66666 MHz if we go with 21 then f =
17.5 MHz...  try that... 1191 nanoseconds...

Settled on 5 MHz (in simulation) add 2 cycles to F, 2/3 cycles to D and 3
cycles to E.


