`define SIM
`timescale 1 ns / 10 ps
// assumes about a 100 MHz clock
`define clock_period = 10;
`define pulse(arg) #1 ``arg <=1 ; #(3*clock_period) ``arg <= 0




module state_machine_tb;

reg [0:11] din,op,pc;
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
reg EAE_loop,EAE_mode;
reg UF;
reg data_break,to_disk;
reg  DB;

always @(posedge clk)
begin
  DB <= ((stateo == DB0) || (stateo == DB1) );
end


state_machine SM1(.clk (clk),
          .reset (rst),
          .halt (halt),
          .cont (cont),
          .single_step (sing_step),
          .instruction (op),
          .trigger (trigger),
          .state (stateo),
          .EAE_mode (EAE_mode),
          .EAE_loop (EAE_loop),
          .UF (UF),
          .data_break (data_break),
          .to_disk (to_disk),
          .int_ena (int_ena),
          .int_req (int_req),
          .int_inh (int_inh),
          .int_in_prog (int_in_prog));



`include "../parameters.v"


integer address;
integer dummy;
integer temp;
integer loaded;
`define NULL 0    


always begin  
        #(clock_period/2) clk <= 1;
        #(clock_period/2) clk <= 0;
end

  

 initial begin
 $dumpfile("DB.vcd");
 $dumpvars(0,clk,rst,DB,SM1);
 rst <= 1;
 EAE_loop <= 0;
 EAE_mode <= 0;
 UF <= 0;
 loaded <= 0;
 sing_step <=  0;
 cont <= 0;
 pc <= 12'd0;
int_req <= 0;
int_ena <= 0;
int_inh <= 1;
trigger <= 0;
data_break  <= 0;
to_disk <= 0;

#50 rst <= 0;
#1 halt = 0;
sing_step <= 0;
// the following tests single machine cycles for 1,2 and 3 MC instructions
op <= 12'o7200;  // path for 6 and 7 IOT and OP opcodesw
data_break <= 0;
#30 `pulse(cont);
data_break <= 1;
to_disk <= 0;
#50 op <= 12'o7402;
// now do it again with db_read
data_break  <= 1;
to_disk <= 0;

op <= 12'o7200;
#50 op <= 12'o7402;
halt <= 1;
wait(SM1.state == H0);
op <= 12'o5000; // jump direct
#60 `pulse(cont);
$finish;
wait(SM1.state == DB1);
wait(DB == 0);
#50 op <= 12'o7402;
op <= 12'o5400; // jump indirect
wait(SM1.state == DB1);
#50 op <= 12'o7402;
op <= 12'o1000; // TAD E
wait(SM1.state == DB1);
#50 op <= 12'o7402;
op <= 12'o1400; // TAD I
wait(SM1.state == DB1);
#50 op <= 12'o7402;


#60 `pulse(cont);
#60 `pulse(cont);
#60 `pulse(cont);
#60 `pulse(cont);
#1000 $finish;



end
endmodule

