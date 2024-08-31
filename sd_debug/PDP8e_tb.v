`define SIM
`timescale 1 ns / 10 ps
`define PULSE(arg) #1 ``arg <=1 ; #(20*clock_period) ``arg <= 0

module la_ram (din, reset, instruction,state, clk);// 8196 x 12

  `include "../parameters.v"
    localparam addr_width = 15;
    localparam data_width = 12;
    reg [14:0] addr;
    input [data_width-1:0] din;
    input reset, clk;
    input [0:11] instruction;
    input [4:0] state;
    reg [data_width-1:0] mem [(1<<addr_width)-1:0];
    
    always @(posedge clk)
    begin
    if (reset ==1) addr <= 0;
    else if ( instruction ==12'o6046)
    begin if (state == F2) 
    mem[addr] <= din;
    else if (state == F3)
	addr <= addr +1;
	end
    end
    endmodule



module PDP8e_tb;
  reg clk100;
  reg clk;
  reg pll_locked;
  reg reset;
  reg rx;
  reg [0:11] sr;
  reg [0:5] dsel;
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
  wire serial_tx;
  assign serial_tx = UUT.instruction ==12'o6046;
  
  wire [0:11] tx_char;
  assign tx_char = (( UUT.ac ) && (serial_tx == 1));

  wire DLAC;
  assign DLAC = (UUT.instruction == 12'o6744);

  wire haltn;
  wire single_stepn;
  assign haltn = ~halt;
  assign single_stepn = ~single_step;

  reg halt_addr;

  `include "../parameters.v"
  localparam clock_period = 1e9 / clock_frequency;
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
      .dsel(dsel),
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

 la_ram LARAM(
       .clk (clk100),
       .reset (reset),
       .din (UUT.ac),
       .state (UUT.state),
       .instruction (UUT.instruction));


  initial begin
    #1 $display("clock frequency %f Hz", (clock_frequency));
    #1 $display("baud rate %f Hz ", (baud_rate));
    #1 $display("clock period %f nanoseconds", (clock_period));
    #1 $display("cycle time %f nanoseconds", (6 * clock_period));

    #1 halt <= 1;
    #1 sr <= 12'o0200;  // normal start address
    $dumpfile("SDCard.vcd");
    $readmemh("dumprk05.hex", UUT.MA.ram.mem, 0, 8191);
    $dumpvars(0,tx_char,diskio,serialio,serial_tx,UUT);

    #1 reset <= 1;
    #(clock_period * 30) reset <= 0;
    #1 single_step <= 0;
    #1 sw <= 0;
    #1 exam <= 0;
    #1 cont <= 0;
    #1 extd_addr <= 0;
    #1 addr_load <= 0;
    #1 dep <= 0;
	#1 clear <= 0;
    #1 dsel <= 6'b001000;
    #1 sr <= 12'o0200;
    #1 pll_locked <= 0;
    #1 rx <= 1;  // marking state
    #100 pll_locked <= 1;
    #100 halt <= 0;
    #5000;
    sr <= 12'o0200;  
    `PULSE(addr_load);
    #1000;
    sr <= 12'o0000; 
    #4000000;
    `PULSE(cont);
    //#1000 $finish;
    #12000000 $finish;
 

  end
 final begin
	 $writememh("dumpac.hex",LARAM.mem,0,1250); // 0, 16383);
	 $writememh("mem.hex",UUT.MA.ram.mem,512,1536);
  end

endmodule
