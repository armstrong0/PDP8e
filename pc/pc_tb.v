`timescale 1 ns / 10 ps
`define CLK #5 clk <= 1;  #5 clk <= 0;
module pc_tc;
//  NOTES XXXXXX
//  have tested basic jump direct - need to check both zero page and current
//  page.  Then need to test indirect jump
//  Have tested a basic skip, but need to test with both operate, io AND ISZ
//  Once this is done should enhance to add JMS support direct and indirect as
//  well as return (JMP I to the address stored at the beginning of subroutine
//  )

wire [0:11] pc;
reg [0:11] instruction;
reg clk;
reg reset;
reg skip;
reg [0:11] ma;
reg [3:0] state;
reg isz_skip;

`include "../parameters.v"


   pc UUT(.clk (clk),
          .reset (reset),
	  .pc (pc),
	  .instruction (instruction),
	  .ma (ma),
	  .skip (skip),
	  .isz_skip (isz_skip),
	  .state (state));



initial begin
  $dumpfile("pc_results.vcd");
  $dumpvars(0,clk,reset,state,instruction,skip,isz_skip,pc,ma,instruction);
  reset <=1;
  ma <= 12'o0000;
  skip  <= 0;
  isz_skip <= 0;
  clk   <= 0;
  state <= F0;
  instruction <= 12'o5000;
 `CLK
  #5 reset <= 0;
 `CLK
  state <= F1;
 `CLK
  state  <= F2;
 `CLK
  state <= F3;
 `CLK
  state <= F0; 
  instruction <= 12'o7000;
 `CLK
   state <= F1;
   skip <= 1;
 `CLK
 state  <= F2;
 `CLK
 state  <= F3;
skip <= 0;
 `CLK
state <= F0;
`CLK
state <= F1;
`CLK
state <= F2;
`CLK 
state <= F3;
`CLK 
state <= F0;
instruction <= 12'o5177;  // jump to the last location on page 0
`CLK
state <= F1;
`CLK
state <= F2;
`CLK 
state <= F3;
`CLK 
state <= F0;
instruction <= 12'o5377;  // jump to the last location on page 1 (current page)
`CLK
state <= F1;
`CLK
state <= F2;
`CLK 
state <= F3;
`CLK 
state <= F0;
instruction <= 12'o5377;  // jump to the last location on page 2 (current page)
`CLK
state <= F1;
`CLK
state <= F2;
`CLK 
state <= F3;
`CLK 
state <= F0;
instruction <= 12'o5077;  // jump to the middle-ish location on page 
`CLK
// now do an indirect jump via page zero 
// 
state <= F1;
`CLK
state <= F2;
`CLK
state <= F3;
`CLK
state <= F0;
instruction <= 12'o5455;
`CLK
state <= F1;
`CLK
state <= F2;
`CLK
state <= F3;
`CLK
ma <= 12'o3333;
state <= D0;
`CLK
state <= D1;
`CLK
state <= D2;
`CLK
state <= D3;
`CLK
state <= F0;
`CLK
// test ISZ ma does the incrementing and testing, then pc does the skip
// (increment pc)
state <= F0;
instruction <= 12'o2000;
`CLK
state <= F1;
`CLK
state <= F2;
`CLK
state <= F3;
`CLK
ma <= 12'o3333;
state <= E0;
`CLK
state <= E1;
`CLK
isz_skip <=1;
state <= E2;
`CLK
state <= E3;
isz_skip <=0;
`CLK
state <= F0;
`CLK
// test JMS, the pc part of it consists of incrementing the PC to one past the
// start of the subroutine
state <= F0;
instruction <= 12'o4000;
`CLK
state <= F1;
`CLK
state <= F2;
`CLK
state <= F3;
`CLK
ma <= 12'o5333;
state <= E0;
`CLK
state <= E1;
`CLK
state <= E2;
`CLK
isz_skip <=0;
state <= E3;
`CLK
state <= F0;
`CLK


end

endmodule

