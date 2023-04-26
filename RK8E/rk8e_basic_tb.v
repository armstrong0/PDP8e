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

wire sdCS,sdMOSI,sdMISO,sdSCLK;

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
          .instruction (instruction),
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
    .skip (skip),
	     // Interface to SD Hardware
    .sdMISO    (sdMISO),      //! SD Data In
    .sdMOSI    (sdMOSI),      //! SD Data Out
    .sdSCLK    (sdSCLK),      //! SD Clock
    .sdCS      (sdCS)        //! SD Chip Select

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
#60 `pulse(cont);
wait(state == F0);
instruction <= 12'o6007;  // CAF
// the #100 before the wait is so we progress from state F0 to FW
// so they all don't collapse to 1 wait
#100 wait (state <= F0);
ac <= 12'b010_000_000_000;  // write protect drive 0
instruction <= 12'o6746;
#100 wait (state <= F0);
ac <= 12'b010_000_000_010;  // write protect drive 1
instruction <= 12'o6746;
#100 wait (state <= F0);
ac <= 12'b010_000_000_100;  // write protect drive 2
instruction <= 12'o6746;
#100 wait (state <= F0);
ac <= 12'b010_000_000_110;  // write protect drive 3
instruction <= 12'o6746;
#100 wait (state == F0);
ac <= 12'b100_100_000_000;
instruction <= 12'o6746;
#100 wait (state == F0);
// now try to write to the disk
ac <= 12'b100_000_000_000;
instruction <= 12'o6746;


#100 wait (RK8.status[0] == 1'b0)
#1000000 $finish;



end
endmodule

