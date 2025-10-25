`define SIM
`timescale 1 ns / 10 ps
`define PULSE(arg) #1 ``arg <=1 ; #(20*clock_period) ``arg <= 0



module PDP8e_tb;
  reg clk100;
  reg clk;
  reg pll_locked;
  reg reset;
  reg rx;
  reg [0:11] sr;
  reg dep;
  reg sw;
  reg single_step;
  reg halt;
  reg exam;
  reg cont;
  reg extd_addr;
  reg addr_load;
  reg clear;
  reg [0:14] address;
  wire led1;
  wire led2;
  wire runn;
  wire [0:14] An;
  wire [0:11] dsn;
  wire tx;
  wire tclk;
  wire sdMOSI, sdSCLK, sdMISO, sdCS;

  wire diskio;
  assign diskio = (UUT.instruction[0:8] == 9'o674);
  wire serialio;
  assign serialio = ((UUT.instruction[0:8] == 9'o603) || 
                    (UUT.instruction[0:8] == 9'o604));
  wire DLAC;
  assign DLAC = (UUT.instruction == 12'o6744);
  wire troublesome;
  assign troublesome = (address == 15'o07750);

  wire haltn;
  wire single_stepn;
  assign haltn = ~halt;
  assign single_stepn = ~single_step;
  reg dsel_swn;

  reg halt_addr;

  `include "../parameters.v"
//  localparam clock_period = 1e9 / clock_frequency;
  always begin  // clock _period comes from parameters.v
    #(clock_period / 2) clk100 <= 1;
    #(clock_period / 2) clk100 <= 0;
  end

  always begin  // assumes about a 12 MHz clock
    #42 clk <= 1;
    #42 clk <= 0;
  end


  PDP8e UUT (
      .clk(clk),
      .runn(runn),
      .led1(led1),
      .led2(led2),
      .An(An),
      .dsn(dsn),
      .tx(tx),
      .clk100(clk100),
      .pll_locked(pll_locked),
      .reset(reset),
      .rx(rx),
      .sr(sr),
      .dsel_swn (dsel_swn),
      .dep(dep),
      .sw(sw),
      .single_stepn(single_stepn),
      .haltn(haltn),
      .examn(~exam),
      .contn(~cont),
      .extd_addrn(~extd_addr),
      .addr_loadn(~addr_load),
      .clearn(~clear),
      .sdCS(sdCS),
      .sdMOSI(sdMOSI),
      .sdSCLK(sdSCLK),
      .sdMISO(sdMISO)
  );


  sdsim SDSIM (
      .clk(clk100),
      .reset(reset),
      .clear(clear),
      .sdCS(sdCS),
      .sdMOSI(sdMOSI),
      .sdSCLK(sdSCLK),
      .sdMISO(sdMISO)
  );




  initial begin
    #1 $display("clock frequency %f Hz", (clock_frequency));
    #1 $display("baud rate %f Hz ", (baud_rate));
    #1 $display("clock period %f nanoseconds", (clock_period));
    #1 $display("cycle time %f nanoseconds", (6 * clock_period));
    #1 dsel_swn <= 1;
    #1 halt <= 1;
    #1 sr <= 12'o0200;  // normal start address
    $dumpfile("SDCard.vcd");
    $readmemh("zero.hex", UUT.MA.ram.mem, 0, 8191);
    $dumpvars(0,address, diskio,serialio,UUT);
    sr <= 12'o0004;

    #1 reset <= 1;
    #(clock_period * 10) reset <= 0;
    #1 single_step <= 0;
    #1 sw <= 0;
    #1 exam <= 0;
    #1 cont <= 0;
    #1 extd_addr <= 0;
    #1 addr_load <= 0;
    #1 dep <= 0;
	#1 clear <= 0;
    //#1 dsel <= 6'b001000;
    #1 sr <= 12'o0200;
    #1 pll_locked <= 0;
    #1 rx <= 1;  // marking state
    #100 pll_locked <= 1;
    #1 halt <= 0;
    #5000;
    sr <= 12'o0030;  // loop until disk is ready
    `PULSE(addr_load);
    #1000;
    sr <= 12'o6743; // DLAG
    `PULSE(dep);
    #1000;
    sr <= 12'o5031;
    `PULSE(dep);
    #1000;
    sr <= 12'o6747; // starting here allows the reading of the diagnostics
    // if the boot procedure works this will all be overwritten
    `PULSE(dep);
    #1000;
	sr <= 12'o7402; // HLT pressing cont will mode to the next diagnostic
	`PULSE(dep);
	#1000;
    sr <= 12'o5032; // JMP .
    `PULSE(dep);
    #1000;
    sr <= 12'o0030;
    `PULSE(addr_load);
     wait(UUT.disk_rdy == 1);

    #1000;
    `PULSE(cont);
    #28000000 $finish;
     wait(serialio ==1);
    #50000 $finish;


  end

endmodule
