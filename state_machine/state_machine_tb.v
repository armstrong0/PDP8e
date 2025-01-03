`define SIM
`timescale 1 ns / 10 ps
// assumes about a 58 MHz clock
//`define clock_period = 18;
`define pulse(arg) #1 ``arg <=1 ; #(4*clock_period) ``arg <= 0




module state_machine_tb;

  reg [0:11] din, op, pc,instruction;
  wire [0:11] opt;
  reg clk;
  reg rst;
  reg halt;
  reg cont;
  reg sing_step;
  reg trigger;
  reg int_req;
  reg int_ena;
  reg int_inh;
  reg write_en;
  wire [4:0] stateo;
  wire int_in_prog;
  reg EAE_loop, EAE_mode;
  reg index;
  reg UF;
  reg data_break, to_disk;


  state_machine SM1 (
      .clk(clk),
      .reset(rst),
      .halt(halt),
      .cont(cont),
      .single_step(sing_step),
      .instruction(instruction),
      .trigger(trigger),
      .state(stateo),
      .EAE_mode(EAE_mode),
      .EAE_loop(EAE_loop),
	  .index (index),
      .UF(UF),
      .data_break(data_break),
      .to_disk(to_disk),
      .int_ena(int_ena),
      .int_req(int_req),
      .int_inh(int_inh),
      .int_in_prog(int_in_prog)
  );

  ram mem (
      .din(din),
      .addr(address[14:0]),
      .write_en(write_en),
      .clk(clk),
      .dout(opt)
  );


  `include "../parameters.v"
   localparam clock_period = 1e9/clock_frequency;

  integer address;


  always begin
    #(clock_period / 2) clk <= 1;
    #(clock_period / 2) clk <= 0;
  end

  always @(posedge clk)
  begin
    if (stateo == FW)
    begin 
        instruction <= opt;
    end    
    if (stateo == F1)
        address <= address + 1;
    if (stateo == EW)
        if (int_in_prog == 1) int_inh <= 1;
    if (stateo == DB0) data_break <= 0;

  end      

  initial begin
    $dumpfile("state_test.vcd");
    $dumpvars(0,address,opt, SM1);
    $readmemh("sm.hex",mem.mem,0,4095);
    rst <= 1;
    EAE_loop <= 0;
    EAE_mode <= 0;
	index <= 1'b0;
    UF <= 0;
    sing_step <= 0;
    cont <= 0;
    pc <= 12'd0;
    write_en <= 0;
    int_req <= 0;
    int_ena <= 0;
    int_inh <= 1;
    trigger <= 0;
    halt <= 1;
    data_break <= 0;
    #500 rst <= 0;
    #10 address <= 'o21;

    #1 halt = 1;
    #160 `pulse(cont);
    // the following tests a variety of instructions
    // and the halt / continue operation
    // as well as deferred 
    // deferred auto-increment is not tested here as index is not assert
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #160 `pulse(cont);
    #100 halt <= 0;
    #160 `pulse(cont);
    //the following tests interrupt processing
    #160 int_ena <= 1;
    #10 int_inh <= 0;
    #10 int_req <= 1;
    #100 `pulse(cont);
    // test free run
    
    #200 `pulse(cont);
    wait(SM1.halt_ff==1);
    // verify halt states
    #100 `pulse(trigger);
    wait(SM1.halt_ff == 1);
    // index is set from the address that defer is accessing, it is set here so
    // any deferred will appear to be auto indexedto  
    #100 index <= 1;
    #10 `pulse(cont);
    wait(SM1.halt_ff == 1);
    index <= 0;
    #10 `pulse(cont);
    wait(SM1.halt_ff == 1);
    #10 sing_step <= 1;
    #160 `pulse(cont);
    #160 `pulse(cont);
    #360 `pulse(cont);
    #10 sing_step <= 0;
    wait(SM1.halt_ff == 1);
    #20 data_break <= 1;
    #100 `pulse(cont);
    wait(SM1.halt_ff == 1);
    #1 EAE_mode <= 0;
    #1 EAE_loop <= 1;
    #100 `pulse(cont);
    #20 EAE_loop <= 0;
    wait(SM1.halt_ff == 1);
    #1 EAE_mode <= 1;
    #1 EAE_loop <= 1;
    #100 `pulse(cont);
    #20 EAE_loop <= 0;
    wait(SM1.halt_ff == 1);
    #100 `pulse(cont);
    wait(SM1.halt_ff == 1);
    #330 $finish;

  end
endmodule

