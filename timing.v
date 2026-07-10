
parameter real baud_rate = 115200; //10 clocks per output 

`define ONESTOP // one stop bit for all baud rates greater than 110
`ifdef SIM
localparam sw_dbnc = 1;
`else
localparam sw_dbnc = 300;
`endif
// define the startup delay allowed for the sd card
// units of milliseconds

`ifdef SIM
parameter sd_delay = 2;

`else
parameter sd_delay = 10'd500;
`endif

// define the slow and fast clocks of the sd card
// Error on the low side, especially for 4 MHz
// frequencies will not be exact.  Frequencies are in Hz

// NOTE that these frequencies influence the initialization time
// there is a timeout in sd.sv that may come into play
parameter real slow_spi = 1000000;
parameter real fast_spi = 1000000;
// go too high and the state machines don't work!


