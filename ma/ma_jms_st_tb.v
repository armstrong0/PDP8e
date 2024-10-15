
`timescale 1 ns / 10 ps

//`include "../pc/pc.v"
`include "../state_machine/state_machine.v"

module ma_tb;

reg clk;
reg reset;
wire [4:0] state;
reg [0:11] ac;
reg [0:11] sr;
reg [0:2] IF,DF;
reg loadd,depd,examd;
wire [0:11] instruction;
wire [0:14] ma;
wire [0:11] mdout;
wire skip;
wire eskip;
wire int_in_prog;
integer k;
reg halt,single_step,cont,trigger;
reg int_ena,int_req,int_inh;


`include "../parameters.v"

     ma UUT(.clk (clk),
      .reset (reset),
      .state (state),
      .instruction (instruction),
      .eaddr (ma),
      .ac (ac),
      .sr (sr),
      .IF (IF),
      .DF (DF),
      .addr_loadd (loadd),
      .depd (depd),
      .examd (examd),
      .mdout (mdout),
      .skip (skip),
      .eskip (eskip),
      .int_in_prog (int_in_prog));
      
 /*   pc pc1(.clk (clk),
          .reset (reset),
      .state (state),
          .instruction (instruction),
      .ma (ma),
      .mdout (mdout),
      .pc (pc),
      .isz_skip (isz_skip));
*/	  
      
    state_machine sm1(.clk (clk),
       .reset (reset),
       .state (state),
       .instruction (instruction),
       .halt (halt),
       .single_step (single_step),
       .cont (cont),
       .trigger (trigger),
       .int_in_prog (int_in_prog),
       .int_ena (int_ena),
       .int_inh (int_inh),
       .int_req (int_req));


always @(posedge clk)
   begin
   if ((instruction == 12'o7402) && (state == H0))
       $finish;
   end

always begin
   #5 clk <= 1;  
   #5 clk <= 0;  ;
end

initial begin
   $readmemh("ma_test.hex", UUT.ram.mem,0,4095);
   $dumpfile("ma_jms_st_results.vcd");
   $dumpvars(0,UUT);
   reset <= 1;
   int_ena <= 0;
   int_req <= 0;
   int_inh <= 1;
   IF <= 3'o0;
   DF <= 3'o0;
   ac <= 12'o5555;
   sr <= 12'o0200;

   halt <= 1;
   single_step <=0;
   cont <= 0;
   trigger <=0;
   clk <= 0; 
   #50 reset <= 0;
   #20 loadd <= 1;
   #60 loadd <= 0;
   #60 halt <= 0;
   #10 cont <= 1;
   #100 cont <= 0;
   #5000 $finish ;
end
endmodule





