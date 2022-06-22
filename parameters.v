// state machine encoding
    parameter F0 = 5'b0000, F1 = 5'b0001 ,F2 = 5'b0010, F3 = 5'b0011,
              D0 = 5'b0100, D1 = 5'b0101, D2 = 5'b0110, D3 = 5'b0111,
              E0 = 5'b1000, E1 = 5'b1001, E2 = 5'b1010, E3 = 5'b1011,
              H0 = 5'b1100, H1 = 5'b1101, H2 = 5'b1110, H3 = 5'b1111;

// instruction encodings
    parameter AND = 3'b000, TAD = 3'b001, ISZ = 3'b010,
              DCA = 3'b011, JMS = 3'b100, JMP = 3'b101,
          OPR = 3'b111, IOT = 3'b110, JMPD =4'b1010,
          JMPI = 4'b1011, JM = 2'b10;
    // calculate in nanoseconds
    //parameter real clock_frequency    =  62250000;  //57750000;
    //parameter real clock_period = 1/clock_frequency*1e9;


	// parameter integer wait_states = 5'd17;  // for serial test on hardware
    // parameter integer wait_states = 5'd1; //normal

`ifndef SIM
    parameter real clock_frequency    =  62250000;  
    parameter real clock_period = 1/clock_frequency*1e9;
    parameter real baud_rate=9600;
    parameter real baud_period = 1.0/baud_rate*1e9;
    parameter tx_term_cnt = $rtoi(baud_period/clock_period); 
`endif

`ifdef SIM
`ifndef TSIM
    // calculate in nanoseconds
    parameter real clock_frequency    =  62250000;  
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
`else
`define address_width13
`endif

`define ONESTOP   // one stop bit for all baud rates greater than 110


`ifndef SIM

    parameter dbnce_nu_bits = $rtoi($clog2($rtoi(0.4*clock_frequency)));
`else
    parameter dbnce_nu_bits = 4;
`endif   


