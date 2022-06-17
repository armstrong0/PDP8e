`define SIM
`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0




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
//wire rdy;
wire [3:0] stateo;
wire int_in_prog;

state_machine SM1(.clk (clk),
          .reset (rst),
	      .halt (halt),
	      .cont (cont),
	      .single_step (sing_step),
          .instruction (op),
		  //.pc (pc),
	      .trigger (trigger),
		  //.rdy (rdy),
	      .state (stateo),
	      .int_ena (int_ena),
	      .int_req (int_req),
		  .int_inh (int_inh),
	      .int_in_prog (int_in_prog));

ram mem (.din (din),
         .addr (address[12:0]),
		 .write_en (write_en),
		 .clk (clk),
		 .dout (opt));


`include "../parameters.v"


integer               data_file    ; // file handler
integer               scan_file    ; // file handler
integer address;
integer dummy;
integer temp;
integer loaded;
`define NULL 0    


always begin  // assumes about a 58 MHz clock
        #9 clk <= 1;
        #9 clk <= 0;
end

  
// code to load instructions in to op (instruction register)
 always @(posedge clk)
 begin
 if ((stateo == F0)  && (~sing_step|cont) && (loaded == 1))
   begin
      op <= opt;
	 // $display(op);
	  address <= address + 1;
   end

 end


 initial begin
 $dumpfile("state_test.vcd");
 $dumpvars(0,clk,rst,op,halt,cont,sing_step,trigger,stateo,int_ena,int_req,int_in_prog,address,mem,loaded,int_inh,SM1);
 rst <= 1;
 loaded <= 0;
 sing_step <=  0;
 cont <= 0;
 pc <= 12'd0;
int_req <= 0;
int_ena <= 0;
int_inh <= 1;
trigger <= 0;

#500 rst <= 0;
  address <= 1;  // first addess is the rest state
  data_file = $fopen("ops.txt", "r");
  if (data_file == `NULL) begin
    $display("data_file handle was NULL");
    $finish;
  end
  
  while (!$feof(data_file)) begin
      dummy = $fscanf(data_file,"%o \n",temp);
	  $displayo(temp[11:0]);
	  din <= temp[11:0];
	  write_en <= 1;
	  #30 ;
	  write_en <= 0;
	  address <= address +1;
  end
  $fclose(data_file); 
  address <= 0;
  
#50 loaded <= 1;

#1 halt = 0;
#20 cont <=1;
#20 cont <= 0;
#1346 sing_step <= 1;
#100 cont <=1;
// the following tests single machine cycles for 1,2 and 3 MC instructions
#60 cont <= 0; // needs to be longer than 1 cycle
#60 cont <= 1;
#60 cont <= 0;
#60 cont <= 1;
#60 cont <= 0;
#60 cont <= 1;
#60 cont <= 0;
#60 cont <= 1;
#60 cont <= 0;
#60 cont <= 1;
#60 cont <= 0;
#100 sing_step <= 0;
#10 int_ena <= 1;
#1 int_inh <= 0;
#135 int_req <= 1;
#300 cont <= 1;
#60 cont <= 0;
#300 cont <= 1;
#60 cont <= 0;
#225 int_ena <= 0;
#1 int_req <= 0;
#50 halt <= 1;
#50 cont <= 1;
#60 cont <= 0;
#250 cont <= 1;
#60 cont <= 0;
#250 cont <= 1;
#60 cont <= 0;


#5000 $finish;



end
endmodule

