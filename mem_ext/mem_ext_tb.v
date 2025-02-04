`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0


`include "../ma/ma.v"
`include "../state_machine/state_machine.v"



module mem_ext_tb;

  mem_ext ME (
      .clk(clk),
      .reset(reset),
      .instruction(instruction),
      .ac (ac),
      .sr(sr),
      .state(state),
      .clear(clear),
      .extd_addrd(extd_addrd),
      .irq(irq),
      .int_inh(int_inh),
      .int_in_prog(int_in_prog),
      .UF(UF),
      .DF(DF),
      .IF(IF),
      .UI(UI),
      .mskip(mskip),
      .me_bus(me_bus)
  );

  ma MA (
      .clk(clk),
      .reset(reset),
      .state(state),
      .instruction(instruction),
      .int_in_prog(int_in_prog),
      .eaddr(eaddr),
      .ac(ac),
      .sr(sr),
      .IF(IF),
      .DF(DF),
      .addr_loadd(loadd),
      .depd(depd),
      .examd(examd),
      .mdout(mdout)
  );

  state_machine SM1 (
      .clk(clk),
      .reset(reset),
      .halt(halt),
      .cont(cont),
      .single_step(sing_step),
      .instruction(instruction),
      .trigger(trigger),
      .state(state),
      .int_ena(int_ena),
      .int_req(irq),
      .int_inh(int_inh),
      .int_in_prog(int_in_prog)
  );


  reg clk;
  reg reset;
  reg clear;
  reg extd_addrd;
  reg halt;
  reg cont;
  reg sing_step;
  reg int_ena;
  //reg irq;
  reg loadd;
  reg trigger;
  reg examd;
  reg depd;
  reg gtf;


  reg [0:11] ac;
  reg [0:11] sr;

  wire [0:14] eaddr;
  wire [0:11] mdout;
  wire [0:11] instruction;
  wire [4:0] state;
  wire [0:2] DF;
  wire [0:2] IF;
  wire UF;
  wire UI;
  wire irq;
  wire [0:11] me_bus;
  wire int_inh;
  wire int_in_prog;
  wire skip, mskip;
assign irq = UI;


  localparam clock_period = 1e9 / clock_frequency;
  `include "../parameters.v"
  initial begin

    clk <= 0;
    forever begin
      #(clock_period / 2) clk <= 1;
      #(clock_period / 2) clk <= 0;
    end
  end

  always @(posedge clk) begin
    if ((state == E1) && (int_in_prog == 1'b1)) int_ena <= 0;

  end

  initial begin
    $dumpfile("mem_ext.vcd");
    $readmemh("mem_ext.hex", MA.ram.mem, 0, 8191);
    $dumpvars(0);
    #1 halt <= 0;
    #1 sing_step <= 0;
//    #1 irq <= 0;
    #1 int_ena <= 0;
    #1 depd <= 0;
    #1 examd <= 0;
    #1 trigger <= 0;
    #1 extd_addrd <= 0;
    #1 clear <= 0;
    #1 gtf <= 0;
    #1 cont <= 0;
    #1 loadd <= 0;
    #100 `pulse(reset);
    #100 `pulse(clear);
    sr <= 12'o0200;
    ac <= 12'o0;
    // to get the state machine off its base state it needs trigger
    // at the same time the other signal happens
    #100 trigger <= 1;
    #1 loadd <= 1;
    #140 trigger <= 1;
    #5 loadd <= 0;


    #500 `pulse(cont);
    #3800 int_ena <= 1;
//    #236 irq <= 1;
    #10000 $finish;
  end


endmodule

