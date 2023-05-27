`define EAE
`define RK8E

// state machine encoding
parameter     F0 = 5'b00000,
              FW = 5'b00001,
              F1 = 5'b00010,
              F2 = 5'b00011,
              F3 = 5'b00100,

              D0 = 5'b00101,
              DW = 5'b00110,
              D1 = 5'b00111,
              D2 = 5'b01000,
              D3 = 5'b01001,

              E0 = 5'b01010,
              EW = 5'b01011,
              E1 = 5'b01101,
              E2 = 5'b01110,
              E3 = 5'b01111,

              H0 = 5'b10000,
              HW = 5'b10001,
              H1 = 5'b10010,
              H2 = 5'b10011,
              H3 = 5'b10100,
// these could have been ifdef out but it would make no difference to the
// resources needed
              EAE0 = 5'b10101,
              EAE1 = 5'b10110,
              EAE2 = 5'b10111,
              EAE3 = 5'b11000,
              EAE4 = 5'b11001,
              EAE5 = 5'b11010,
			  F2A  = 5'b11011,
			  F2B  = 5'b11100,
			  DB0 = 5'b11101,  // data break states
			  DB1 = 5'b11110,
			  DB2 = 5'b11111;


// instruction encodings
parameter AND = 3'b000, TAD = 3'b001, ISZ = 3'b010,
          DCA = 3'b011, JMS = 3'b100, JMP = 3'b101,
          OPR = 3'b111, IOT = 3'b110, JMPD =4'b1010,
          JMPI = 4'b1011, JM = 2'b10 
`ifdef EAE
          ,DAD = 12'o7443,
          DLD = 12'o7763, CAMDAD = 12'o7663, DST=12'o7445,
		  SHL = 12'o7413, ASR = 12'o7415, LSR = 12'o7417,
		  MUL = 12'o7405, DIV = 12'o7407, NMI = 12'o7411;
`else
;
`endif		  

`ifndef SIM
    //parameter real clock_frequency    =  62250000;
    //parameter real clock_frequency    =  79500000;
    parameter real clock_frequency    =  73500000;
    parameter real clock_period = 1/clock_frequency*1e9;
    parameter real baud_rate=9600;
    parameter real baud_period = 1.0/baud_rate*1e9;
    parameter tx_term_cnt = $rtoi(baud_period/clock_period);
`endif
// define the slow and fast clocks of the sd card
// the counts here have to be for 1/2 clock
// error on the low side, especially for 4 MHz
// frequencies will not be exact.
`ifdef RK8E
   parameter real slow_spi =  400000;
   parameter real fast_spi =  2000000; // go too high and the state machines
   // don't work
   parameter slow_dev = $rtoi(clock_frequency/(slow_spi*2));
   parameter nu_divcnt_bits = $rtoi($clog2(slow_dev));
   parameter SlowDiv = slow_dev[nu_divcnt_bits-1:0];
   parameter fast_dev = $rtoi(clock_frequency/(fast_spi*2));
   parameter FastDiv = fast_dev[nu_divcnt_bits-1:0];
   parameter LoSpiFreq = clock_frequency/(SlowDiv*2);
   parameter HiSpiFreq = clock_frequency/(FastDiv*2);

`endif


`ifdef SIM
`ifndef TSIM
    // calculate in nanoseconds
    parameter real clock_frequency    =  84000000;
    parameter real clock_period = 1/clock_frequency*1e9;
    parameter real baud_rate=115200;
    parameter real baud_period = 1.0/baud_rate*1e9;
    parameter tx_term_cnt = $rtoi(baud_period/clock_period);
`else
    // calculate in nanoseconds
    parameter real clock_frequency    =  5000000;
    parameter real clock_period = 1/clock_frequency*1e9;
    parameter real baud_rate=1200;
    parameter real baud_period = 1.0/baud_rate*1e9;
    parameter tx_term_cnt = $rtoi(baud_period/clock_period);
`endif
`endif



parameter MAX_FIELD = 3'b001;

`define ONESTOP   // one stop bit for all baud rates greater than 110

`ifndef SIM
    parameter dbnce_nu_bits = $rtoi($clog2($rtoi(0.4*clock_frequency)));
`else
    parameter dbnce_nu_bits = 4;
`endif

parameter tx_term_nu_bits = $rtoi($clog2(tx_term_cnt));



