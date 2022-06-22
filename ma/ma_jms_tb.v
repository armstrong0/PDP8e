
`timescale 1 ns / 10 ps
`define CLK clk <= 1;  #5 clk <= 0; #5 ;

`include "../pc/pc.v"

module ma_tb;

reg clk;
reg reset;
reg [4:0] state;
wire [0:11] pc;
reg [0:11] ac;
reg [0:11] sr;
reg [0:2] IF,DF;
reg loadd,depd,examd;
wire [0:11] instruction;
wire [0:11] ma;
wire [0:11] mdout;
wire isz_skip;
integer k;



`include "../parameters.v"

     ma UUT(.clk (clk),
          .reset (reset),
	  .state (state),
          .instruction (instruction),
	  .pc (pc),
	  .ma (ma),
	  .ac (ac),
	  .sr (sr),
	  .IF (IF),
	  .DF (DF),
	  .addr_loadd (loadd),
	  .depd (depd),
	  .examd (examd),
	  .mdout (mdout),
	  .isz_skip (isz_skip));
	  
    pc pc1(.clk (clk),
          .reset (reset),
	  .state (state),
          .instruction (instruction),
	  .ma (ma),
	  .mdout (mdout),
	  .pc (pc),
	  .isz_skip (isz_skip));
always @(posedge clk)
   begin
   if ((instruction == 12'o7402) && (state == F1))
       $finish;
   end


initial begin
   $readmemh("ma_jms.hex", UUT.ram.mem,0,4095);
   $dumpfile("ma_jms_results.vcd");
   $dumpvars(0,clk,reset,state,instruction,pc,ma,mdout,UUT.mdin,UUT.write_en,UUT.addr);
   reset <= 1;
    IF <= 3'o0;
    DF <= 3'o0;
   `CLK
   `CLK
   reset <= 0;
   `CLK
   state <= F0;  // JMS S1
   `CLK
   state <= F1;
   `CLK
   state <= F2;
   `CLK
   state <= F3;
   `CLK
   state <= E0;
   `CLK
   state <= E1;
   `CLK
   state <= E2;
   `CLK
   state <= E3;
   `CLK
   state <= F0;  //JMP I S1
   `CLK
   state <= F1;
   `CLK
   state <= F2;
   `CLK
   state <= F3;
   `CLK
   state <= D0;
   `CLK
   state <= D1;
   `CLK
   state <= D2;
   `CLK
   state <= D3;
   `CLK   
   state <= F0;  //HLT
   `CLK
   state <= F1;  
   `CLK
   state <= F2;  
   `CLK
   state <= F3;  
   `CLK
   state <= F0;  //HLT
   `CLK
   state <= F1;  
   `CLK
   state <= F2;  
   `CLK
   state <= F3;  
   `CLK
end
endmodule





