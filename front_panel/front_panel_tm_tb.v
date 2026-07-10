`timescale 1 ns / 10 ps
module front_panel_tb;

  reg clk, reset;
  reg halt;
  reg clear, extd_addr, addr_load, dep, exam, sing_step, cont;
  wire contd;
  wire cleard, extd_addrd, addr_loadd, depd, examd;

  wire [0:11] dout;
  reg [0:11] status, ac, mq, mb, io_bus, sr;
  reg [4:0] state;
  reg [3:11] state1;
  reg dsel_sw;
  reg run_ff;
  wire sw_active;
  wire [2:0] dsel;
  wire [0:4] dsel_led;
  wire run_led;

  wire [0:2] trig_stateo;
  wire [0:4] count;
  `include "../parameters.v"

front_panel FP (
      .clk(clk),
      .clear(clear),
      .extd_addr(extd_addr),
      .addr_load(addr_load),
      .dep(dep),
      .exam(exam),
      .dsel_sw(dsel_sw),
      .cont(cont),
      .cleard(cleard),
      .extd_addrd(extd_addrd),
      .addr_loadd(addr_loadd),
      .depd(depd),
      .examd(examd),
      .contd(contd),
      .fp_trigger(fp_trigger),
      .fp_cont(fp_cont),
      .dsel(dsel),
      .sw_active(sw_active),
      .reset(reset),
      .state(state)
  );

  D_mux DM (
      .clk(clk),
      .reset(reset),
      .dsel(dsel),
      .state(state),
      .state1(state1),
      .status(status),
      .ac(ac),
      .mb(mb),
      .mq(mq),
      .io_bus(io_bus),
      .sw_active(sw_active),
      .dout(dout),
      .dsel_led(dsel_led),
      .run_ff(run_ff),
      .run_led(run_led)
  );

  HX_clock HX (
      .reset(reset),
      .clk(clk),
      .fp_trigger(fp_trigger),
      .fp_cont(fp_cont)
  );
  always begin  // assumes about a 71.4 MHz clock
    #7 clk <= 1;
    #7 clk <= 0;
  end

  initial begin

    $dumpfile("timing.vcd");
    $dumpvars(0, FP, DM, HX);

    clear <= 0;
    run_ff <= 0;
    halt <= 0;
    dsel_sw <= 0;
    ac = 12'o1111;
    mq <= 12'o2222;
    mb <= 12'o3333;
    io_bus <= 12'o5555;
    status <= 12'o6666;
    state1 = 12'b000111111111;
    extd_addr <= 0;
    addr_load <= 0;
    dep <= 0;
    exam <= 0;
    sing_step <= 0;
    cont <= 0;
    sing_step <= 0;
    state <= F1;  // F0 does not assert any of FS, DS, ES

    #10 dsel_sw <= 0;

    #15 reset <= 1;
    #40 reset <= 0;
    // #24 clear <= 1;
    // #100 clear <= 0;
    #40 cont <= 1;
    #40 cont <= 0;

    #3500000 $finish;
  end


endmodule

