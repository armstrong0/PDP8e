`define SIM
`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0

module PDP8e_tb;
    reg  clk100;
    reg  clk;
    reg  pll_locked;
    reg reset;
    reg  rx;
    reg  [0:11] sr;
    reg  dsel_sw;
    wire [4:0] dsel_led;
    reg  dep;
    reg  sw;
    reg  single_step;
    wire single_stepn;
    reg  halt;
    wire haltn;
    reg  exam;
    reg  cont;
    reg  extd_addr;
    reg  addr_load;
    reg  clear ;
    wire [0:14] address;
    wire led1;
    wire led2;
    wire runn;
    wire [0:14] An;
    wire [0:11] dsn;
    wire tx;
    wire tclk;
    reg serial_io;

`include "../parameters.v"

    always begin  // assumes about a 58 MHz clock
        #9 clk100 <= 1;
        #9 clk100 <= 0;
    end
    always begin  // assumes about a 12 MHz clock
        #42 clk <= 1;
        #42 clk <= 0;
    end
    assign address = ~An;


      PDP8e UUT (.clk (clk),
        .runn (runn),
        .led1 (led1),
        .led2 (led2),
        .An (An),
        .dsn (dsn),
        .tx (tx),
        .clk100 (clk100),
        .pll_locked (pll_locked),
        .reset (reset),
        .rx (rx),
        .sr (sr),
        .dsel_led (dsel_led),
        .dsel_swn (~dsel_sw),
        .dep (dep),
        .sw (sw),
        .single_stepn (single_stepn),
        .haltn (haltn),
        .examn (~exam),
        .contn (~cont),
        .extd_addrn (~extd_addr),
        .addr_loadn (~addr_load),
        .clearn (~clear)) ;


     /* I/O */
    wire [0:11] ds;
    assign dsn = ~ds;
    wire run;

    assign runn = ~run;
   
 

    initial begin


        $dumpfile("system.vcd");
        $dumpvars(0,address,UUT);

        #0 halt <= 1;
        #1 single_step <= 0;
        #1 addr_load <= 0;
        #1 extd_addr <= 0;
        #1 clear <= 0;
        #1 sw <= 0;
        #1 dsel_sw <= 0;
        #1 exam <= 0;
        #1 cont <= 0;
        #1 extd_addr <= 0;
        #1 dep <= 0;
        #1 sr <= 12'o0155;
        #1 pll_locked <= 0;
        #1 rx <= 1; // marking state
        #100 pll_locked <= 1;
        #100 halt <= 0;
        #300;
        #10 `pulse(addr_load);
        #300 `pulse(cont);

        #400 $finish;

    end

endmodule
