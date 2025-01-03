`timescale 10 ns / 100 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0

`define pulse1(arg) #1 ``arg <=1 ; #1400 ``arg <= 0


module PDP8e_tb;
    reg  clk100;
    reg  clk;
    reg  pll_locked;
    reg reset;
    reg  rx;
    reg  [0:11] sr;
    reg  dsel_sw;
    wire [0:4] dsel_led;
    reg  dep;
    reg  sw;
    reg  single_step;
    reg  halt;
    reg  exam;
    reg  cont;
    reg  extd_addr;
    reg  addr_load;
    reg  clear ;
    wire [0:14] An,address;
    wire led1;
    wire led2;
    wire run;
    wire runn;
    wire [0:11] dsn;
    wire tx;
    wire tclk;
    assign address = ~An;
    assign run = ~runn;

`include "HX_clock.v"
 parameter real baud_rate=9600;
 parameter integer baud_period = 1e9/baud_rate;
 parameter real clock_period = 1e9/clock_frequency;
 parameter integer clkby2 = clock_period/2;

    always begin  // clock _period comes from parameters.v
        #clkby2 clk100<= 1;
        #clkby2 clk100<= 0;
    end

    always begin  // assumes about a 12 MHz clock
        #42 clk <= 1;
        #42 clk <= 0;
    end
    
   

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
        .dep (dep),
        .sw (sw),
        .single_stepn (~single_step),
        .haltn (~halt),
        .examn (~exam),
        .contn (~cont),
        .extd_addrn (~extd_addr),
        .addr_loadn (~addr_load),
        .clearn (~clear),
        .dsel_swn (~dsel_sw)) ;



    initial begin
        #1 $display("clock frequency %f",(clock_frequency)) ;
        #1 $display("baud rate %f ",(baud_rate)) ;
        #1 $display("clock period %f",(clock_period)) ;
        #1 $display("cycle time %f nanoseconds" ,(6*clock_period));


        #1 sr <= 12'o0200;  // normal start address
         $dumpfile("IO_sim.vcd");
         $dumpvars(0,UUT);
        #1 halt <= 1;
		#1 rx <= 1;
        #1 reset <= 1;
		#1 clear <= 0;
        #( clock_period*10) reset <=0;
        #1 single_step <= 0;
        #1 sw <= 0;
        #1 exam <= 0;
        #1 cont <= 0;
        #1 extd_addr <= 0;
        #1 addr_load <= 0;
        #1 dep <= 0;
        #1 dsel_sw <= 0;
        #1 sr <= 12'o0200;
        #1 pll_locked <= 0;
        #1 rx <= 1; // marking state
        #100 pll_locked <= 1;
        #100 halt <= 0;
		#10 dsel_sw <= 1; 
        #1000 dsel_sw <= 0;
        #150000 rx <= 0;
		#(baud_period*2) rx <=1;
		#(baud_period) rx <=0;
		#(baud_period) rx <=1;
		#(baud_period) rx <=0;
		#(baud_period) rx <=1;
		#(baud_period) rx <=0;
		#(baud_period) rx <=1;
       
		#1000000 dsel_sw <= 1; 
        #1000 dsel_sw <= 0;
        #2000000 dsel_sw <= 1;

        #1000 dsel_sw <= 0;
        #6000000 $finish;


    end

endmodule
