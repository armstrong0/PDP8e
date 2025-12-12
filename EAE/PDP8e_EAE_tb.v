`define SIM
`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0
`define pulse1(arg) #1 ``arg <=1 ; #1400 ``arg <= 0


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
  reg [0:23] acmq;
  reg dsel_swn;
  wire led1;
  wire led2;
  wire runn;
  wire [0:14] An;
  wire [0:11] dsn;
  wire tx;
  wire tclk;

  `include "../parameters.v"
  `include "../FPGA_image/HX_clock.v"


  always begin  // clock _period comes from parameters.v
    #(clock_period / 2) clk100 <= 1;
    #(clock_period / 2) clk100 <= 0;
  end

  always begin  // assumes about a 12 MHz clock
    #42 clk <= 1;
    #42 clk <= 0;
  end
  always @* begin
    address <= ~An;
    acmq <= {UUT.AC.ac, UUT.AC.mq};
  end

  always @(posedge clk100) begin
    rx <= tx;
  end
  parameter test_sel = 2;


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
      .single_stepn(~single_step),
      .haltn(~halt),
      .examn(~exam),
      .contn(~cont),
      .extd_addrn(~extd_addr),
      .addr_loadn(~addr_load),
      .clearn(~clear)
  );



  always @(posedge clk) begin

    if (((UUT.instruction & 12'o7403) == 12'o7402) && (UUT.state == F0)) begin
        if ($time > 6000) begin
          $display("Stopped %d because of a Halt", $time);
          $display("Address:%o", address);
          #1000 $finish;
        end
	end	
  end




  initial begin
    #1 $display("clock frequency %f", (clock_frequency));
    #1 $display("baud rate %f ", (baud_rate));
    #1 $display("clock period %f", (clock_period));
    #1 $display("cycle time %f nanoseconds", (6 * clock_period));
    #1 sr <= 12'o0200;  // normal start address
    $dumpfile("SHL_Test1.vcd");
    $readmemh("t14.hex", UUT.MA.ram.mem, 0, 8191);
    $dumpvars(0,acmq, UUT);
    #0 halt <= 1;
    #1 reset <= 1;
    #1 clear <= 0;
    #1 single_step <= 0;
    #1 sw <= 0;
    #1 exam <= 0;
    #1 cont <= 0;
    #1 extd_addr <= 0;
    #1 addr_load <= 0;
    #1 dep <= 0;
    #1 dsel_swn <= 1;
    #1 sr <= 12'o0200;
    #1 pll_locked <= 0;
    #1 rx <= 1;  // marking state
    #100 pll_locked <= 1;
    #10 halt <= 0;
    #100 reset <= 0;


    //#1000 sr <= 12'o0200;
    #1000 sr <= 12'o5156;
    #1000 `pulse(addr_load);
    #1000 `pulse(cont);
    #580000 $finish;


  end

endmodule
