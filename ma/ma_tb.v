
`timescale 1 ns / 10 ps
`define CLK clk <= 1;  #5 clk <= 0; #5;


module ma_tb;

reg clk;
reg reset;
reg [4:0] state;
reg [0:11] pc;
reg [0:11] ac;
reg [0:11] sr;
reg [0:2] IF,DF;
reg loadd,depd,examd;
wire [0:11] instruction;
wire [0:14] addr;
wire [0:11] mdout;
wire isz_skip;
integer k;



`include "../parameters.v"
`include "../FPGA_image/HX_clock.v"

  localparam clock_period = 1e9 / clock_frequency;



     ma UUT(.clk (clk),
      .reset (reset),
	  .state (state),
      .instruction (instruction),
//	  .pc (pc),
	  .eaddr (addr),
	  .ac (ac),
	  .sr (sr),
	  .IF (IF),
	  .DF (DF),
	  .addr_loadd (loadd),
	  .depd (depd),
	  .examd (examd),
	  .mdout (mdout),
	  .isz_skip (isz_skip));

initial begin
   $readmemh("ma_test.hex", UUT.ram.mem,0,4095);
   $dumpfile("ma_results.vcd");
   $dumpvars(0,UUT);
   reset <= 1;
   loadd <=0;
   examd <= 0;
   depd <=0;
   ac <= 12'o7070;
   sr <= 12'o0200;

   IF <= 3'o0;
   DF <= 3'o0;
   clk <= 0;
   `CLK
   reset <= 0;
sr <= 12'o0007;
   state <= H0;  // load addr 0007
   `CLK 
   loadd <= 1;   
   state <= H1;
   `CLK
   state <= H2;
   `CLK
   loadd <= 0;
   state <= H3;
   `CLK

  // pc <= 12'o0200; 
   state <= F0; // JMP L1  (210)
   `CLK
   state <= F1;
   `CLK
   state <= F2;
   `CLK
   state <= F3; // pc <= 12'o0210;
   `CLK
   state <= F0; // JMP I D1    
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
   state <= D3; pc <= 12'o0220;
   `CLK
   state <= F0; // JMP I I1 (addr 10 230 auto inc)
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
   state <= D3; pc <= 12'o0231;
   `CLK
   state <= F0; // ISZ
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
   pc <= pc + 12'o0001;    state <= F0;  // ISZ
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
   pc <= pc + 12'o0002;  // because of the skip

   state <= F0; //DCA 
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

   //pc <= pc + 12'o0001;
   state <= F0;  // (300) JMS S1 (277)
   `CLK   
   state <= F1; // pc <= pc + 12'o0001;
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
   state <= E3; //  pc <= ma + 12'o0001;
   `CLK

  // pc <= pc + 12'o0001;
   state <= F0; //JMP I S1
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
   state <= D3; // pc <= ma; 

   `CLK

  // pc <= pc + 12'o0001;
   state <= F0; // DCA
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

  // pc <= pc + 12'o0001;
   state <= F0; // TAD L1
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

  // pc <= pc + 12'o0001;
   state <= F0; // AND
   `CLK   
   state <= F1;
   `CLK
   state <= F2; pc <= pc + 12'o0001;

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
 state <= F0; // HLT
   `CLK   
   state <= F1;
   `CLK
   state <= F2;
   `CLK
   state <= F3;
   `CLK
   

sr <= 12'o0007;
   state <= H0;  // load addr 0007
   `CLK 
   loadd <= 1;   
   state <= H1;
   `CLK
   state <= H2;
   `CLK
   loadd <= 0;
   state <= H3;
   `CLK

sr <= 12'o0707;
   state <= H0; // exam 0007 then incrementing to 0010
   `CLK 
   examd <= 1;   
   state <= H1;
   `CLK
   state <= H2;
   `CLK
   examd <= 0;
   state <= H3;
   `CLK


   state <= H0;  // put 0707 ino 0010
   `CLK 
   depd <= 1;
   state <= H1;
   `CLK 
   state <= H2;
   `CLK 
   depd <=0;
   state <= H3;
   `CLK 

sr <= 12'o0007; // reload 0007
   state <= H0;
   loadd <= 1;   
   `CLK 
   state <= H1;
   `CLK 
   state <= H2;
   `CLK 
   state <= H3;
   loadd <= 0;   
   `CLK 
sr <= 12'o0707;
   state <= H0; // examine
   `CLK 
   examd <= 1;   
   state <= H1;
   `CLK
   state <= H2;
   `CLK
   examd <= 0;
   state <= H3;
   `CLK
sr <= 12'o0707;
   state <= H0; // examine
   `CLK 
   examd <= 1;   
   state <= H1;
   `CLK
   state <= H2;
   `CLK
   examd <= 0;
   state <= H3;
   `CLK


end
endmodule





