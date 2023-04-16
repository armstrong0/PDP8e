`timescale 1 ns / 10 ps
// assumes about a 100 MHz clock
`define pulse(arg) #1 ``arg <=1 ; #(3*clock_period) ``arg <= 0



module rk8e_basic_tb;
//import sdspi_types::*; 
reg [0:11] din,op,pc,instruction,ac;
wire [0:11] opt;
reg clk;
reg reset;
reg halt;
reg cont;
reg sing_step;
reg trigger;
reg int_req;
reg int_ena;
reg int_inh;
reg write_en;
wire [0:11] disk_bus;
wire [4:0] state;
wire int_in_prog;
reg EAE_loop,EAE_mode;
reg UF;
reg db_read,db_write;
reg  DB;

always @(posedge clk)
begin
  DB <= (state == DB0) || (state == DB1) || (state == DB2);
end

sdsim SDSIM(.clk (clk),
    .reset (reset),
    .clear (clear),
    .sdCS (sdCS),
    .sdMOSI (sdMOSI),
    .sdSCLK (sdSCLK),
    .sdMISO (sdMISO)
);


state_machine SM1(.clk (clk),
          .reset (rst),
          .halt (halt),
          .cont (cont),
          .single_step (sing_step),
          .instruction (op),
          .trigger (trigger),
          .state (state),
          .EAE_mode (EAE_mode),
          .EAE_loop (EAE_loop),
          .UF (UF),
          .db_read (db_read),
          .db_write (db_write),
          .int_ena (int_ena),
          .int_req (int_req),
          .int_inh (int_inh),
          .int_in_prog (int_in_prog));

rk8e RK8 (  .clk (clk),
    .reset (reset),
    .clear (clear),
    .instruction (instruction),
    .state (state),
    .ac (ac),
	.UF (UF),
    .disk_bus (disk_bus),  //from the point of view of the CPU
    /* verilator lint_off SYMRSVDWORD */
    .interrupt (interrupt),
    /* verilator lint_on SYMRSVDWORD */
    .data_break_write (data_break_write),
    .data_break_read (data_break_read),
    .skip (skip)
);

`include "../parameters.v"


integer               data_file    ; // file handle
integer               scan_file    ; // file handle
integer address;
integer dummy;
integer temp;
integer loaded;


always begin  
        #(clock_period/2) clk <= 1;
        #(clock_period/2) clk <= 0;
end

  

 initial begin
 $dumpfile("sdb.vcd");
 $dumpvars(0,clk,reset,DB,RK8,SM1);
 reset <= 1;
 EAE_loop <= 0;
 EAE_mode <= 0;
 UF <= 0;
 sing_step <=  0;
 cont <= 0;
 pc <= 12'd0;
int_req <= 0;
int_ena <= 0;
int_inh <= 1;
trigger <= 0;
db_read <= 0;
db_write <= 0;

#50 reset <= 0;
#1 halt = 0;
sing_step <= 0;
op <= 12'o7200;  // path for 6 and 7 IOT and OP opcodesw
#30 `pulse(cont);
db_write <=1;

#50 op <= 12'o7402;
// now do it again with db_read
db_read <= 1;
db_write <= 0;

op <= 12'o7200;
#50 op <= 12'o7402;
wait(SM1.state == H0);
op <= 12'o5000; // jump direct
#60 `pulse(cont);
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

