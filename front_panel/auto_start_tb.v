`timescale 1 ns / 10 ps

module auto_start_tb;

  reg clk, reset;
  reg halt;
  reg clear, extd_addr, addr_load, dep, exam, sing_step, cont;
  reg  dsel_sw;
  wire contd;
  wire cleard, extd_addrd, addr_loadd, depd, examd;
  wire [2:0] dsel;
  reg [0:4] state;
  reg fp_cont;
  reg run_ff;
  reg [0:11] sr;
  reg sw;
  reg disk_rdy;

  front_panel FP (
      .clk(clk),
      .fp_trigger(fp_trigger),
      .fp_cont(fp_cont),
      .disk_rdy(disk_rdy),
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
      .sr(sr),
      .sw(sw),
      .dsel(dsel),
      .sw_active(sw_active),
      .reset(reset),
      .state(state)
  );

  always @(posedge clk) begin  // estentially no debounce delay
    if (fp_trigger == 1) #10 fp_cont <= 1;
    else fp_cont <= 0;
    //fp_trigger;
  end
  `include "../parameters.v"  // fo states

  always @(posedge clk) begin
    if (reset) state <= F0;
    else
      case (state)
        F0:
        if (contd == 1) state <= FW;
        else state <= F0;
        FW: state <= F1;
        F1: state <= F2;
        F2: state <= F3;
        F3: state <= F0;
        default: state <= F0;
      endcase
  end



  always begin  // assumes about a 77 MHz clock
    #6.5 clk <= 1;
    #6.5 clk <= 0;
  end

  initial begin
    $dumpfile("auto_start.vcd");
    $dumpvars(0, FP);
    disk_rdy <= 0;
    clear <= 0;
    run_ff <= 0;
    halt <= 0;
    dsel_sw <= 0;
    extd_addr <= 0;
    addr_load <= 0;
    dep <= 0;
    exam <= 0;
    sing_step <= 0;
    cont <= 0;
    sing_step <= 0;
    sr <= 12'o2525;
    sw <= 0;
    // first check to make sure that load addr and cont still work
    #10 reset <= 1;
    #30 reset <= 0;
    #100 cont <= 1;
    #100 cont <= 0;
    // test that sw asserted and load address puts 7777 on the sreg bus

    #500 sw <= 1;
    #100 addr_load <= 1;
    #100 addr_load <= 0;
    // then test autostart
    #100 reset <= 1;
    // sw is still set  
    // releasing reset should start the whole sequence
    #100 reset <= 0;

    #1000 disk_rdy <= 1;
    #5000 $finish;
  end
endmodule
