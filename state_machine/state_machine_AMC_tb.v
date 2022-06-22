`define SIM
`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #400 ``arg <= 0




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
wire rdy;
wire [4:0] stateo;
wire int_in_prog;

state_machine SM1(.clk (clk),
          .reset (rst),
	      .halt (halt),
	      .cont (cont),
	      .single_step (sing_step),
          .instruction (op),
		  .pc (pc),
	      .trigger (trigger),
		  .rdy (rdy),
	      .state (stateo),
	      .int_ena (int_ena),
	      .int_req (int_req),
		  .int_inh (int_inh),
	      .int_in_prog (int_in_prog));


`include "../parameters.v"


integer data_file    ; // file handler
integer scan_file    ; // file handler
integer dummy;
integer temp;
`define NULL 0    


always begin  
        #100 clk <= 1; // 5 MHz clock
        #100 clk <= 0;
end

  



  
// code to load instructions in to op (instruction register)
 always @(posedge clk)
 begin
 if (stateo == F1) 
 begin
     dummy = $fscanf(data_file,"%o \n",temp);
	 $displayo(temp);
     op <= temp;
	 if ($feof(data_file)) begin
	     $fclose(data_file);
		 $display("Ran out of op codes");
		 #10000 $finish;
	 end
 end
 end


 initial begin
 $dumpfile("AMC.vcd");
 $dumpvars(0,clk,rst,op,halt,cont,sing_step,trigger,stateo,int_ena,int_req,int_in_prog,int_inh,opt,SM1);

 data_file = $fopen("ops.txt", "r");
 if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
 end

 rst <= 1;
 sing_step <=  0;
 cont <= 0;
 pc <= 12'd0;
 int_req <= 0;
 int_ena <= 0;
 int_inh <= 1;
 trigger <= 0;

#500 rst <= 0;
   
#200 halt <= 0;
#200 cont <= 1;
#400 cont <= 0;
#15460 sing_step <= 1;
#1400 cont <=1;
wait (stateo == F0);
// the following tests single machine cycles for 1,2 and 3 MC instructions
#800 cont <= 0; // needs to be longer than 1 cycle
#800 cont <= 1;
#800 cont <= 0;
#800 cont <= 1;
#800 cont <= 0;
#800 cont <= 1;
#800 cont <= 0;
#800 cont <= 1;
#800 cont <= 0;
#2000 cont <= 1;
#800 cont <= 0;
#2000 cont <= 1;
#800 cont <= 0;
#2000 cont <= 1;
#800 cont <= 0;
#2000 cont <= 1;
#800 cont <= 0;
#2000 cont <= 1;
#800 cont <= 0;

#5000 sing_step <= 0;
#100 int_ena <= 1;
#10 int_inh <= 0;
#1350 int_req <= 1;
wait(op == 12'o7402);
#3000 cont <= 1;
#600 cont <= 0;
wait(op == 12'o7402);
#3000 cont <= 1;
#600 cont <= 0;
wait(op == 12'o7402);
#3000 cont <= 1;
#600 cont <= 0;
#2250 int_ena <= 0;
#10 int_req <= 0;
#500 halt <= 1;
#500 cont <= 1;
#600 cont <= 0;
#3500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
//  now test indirect
#10 pc <= 12'o0077;  // only the leftmost 5 bits should matter

#4500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
#4500 cont <= 1;
#600 cont <= 0;
$display("At end of initial begin");
#9000 $finish;



end
endmodule

