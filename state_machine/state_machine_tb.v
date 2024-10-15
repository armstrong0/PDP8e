`define SIM
`timescale 1 ns / 10 ps
// assumes about a 58 MHz clock
//`define clock_period = 18;
`define pulse(arg) #1 ``arg <=1 ; #(4*clock_period) ``arg <= 0




module state_machine_tb;

  reg [0:11] din, op, pc;
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
      .instruction(op),
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

  integer data_file;  // file handler
  integer scan_file;  // file handler
  integer address;
  integer dummy;
  integer temp;
  integer loaded;
  `define NULL 0    


  always begin
    #(clock_period / 2) clk <= 1;
    #(clock_period / 2) clk <= 0;
  end


  // code to load instructions in to op (instruction register)
  always @(posedge clk) begin
    if ((stateo == F0) && (~sing_step | cont) && (loaded == 1)) begin
      op <= opt;
      // $display(op);
      address <= address + 1;
    end

  end


  initial begin
    $dumpfile("state_test.vcd");
    $dumpvars(0, SM1);
    rst <= 1;
    EAE_loop <= 0;
    EAE_mode <= 0;
	index <= 1'b0;
    UF <= 0;
    loaded <= 0;
    sing_step <= 0;
    cont <= 0;
    pc <= 12'd0;
    int_req <= 0;
    int_ena <= 0;
    int_inh <= 1;
    trigger <= 0;
    //db_read <= 0;
    //db_write <= 0;

    #500 rst <= 0;
    address <= 1;  // first addess is the reset state
    data_file = $fopen("ops.txt", "r");
    if (data_file == `NULL) begin
      $display("data_file handle was NULL");
      $finish;
    end

    while (!$feof(
        data_file
    )) begin
      dummy = $fscanf(data_file, "%o \n", temp);
      $displayo(temp[11:0]);
      din <= temp[11:0];
      write_en <= 1;
      #30;
      write_en <= 0;
      address  <= address + 1;
    end
    $fclose(data_file);
    address <= 0;

    #50 loaded <= 1;

    #1 halt = 0;
    #20 `pulse(cont);
    #1346 sing_step <= 1;
    // the following tests single machine cycles for 1,2 and 3 MC instructions
    #60 `pulse(cont);
    #60 `pulse(cont);
    #60 `pulse(cont);
    #60 `pulse(cont);
    #60 `pulse(cont);
    #60 `pulse(cont);
    #100 sing_step <= 0;
    #10 int_ena <= 1;
    #1 int_inh <= 0;
    #135 int_req <= 1;
	wait(stateo == 5'o20);
    #100 `pulse(cont);
	wait(stateo == 5'o20);
    #100 `pulse(cont);
	wait(stateo == 5'o20);
    #100 `pulse(cont);
    #1 int_ena <= 0;
    #1 int_req <= 0;
    #50 halt <= 1;
	#150 halt <= 0;
	wait(stateo == 5'o20);
    #100 `pulse(cont);
	wait(stateo == 5'o20);
	index <= 1'b1;
    #100 `pulse(cont);
	wait(stateo == 5'o20);
    #100 `pulse(cont);

    data_break <= 1;
    #1000 $finish;


    #1000 $finish;



  end
endmodule

