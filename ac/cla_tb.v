`define CLK clk <= 1; #5 clk  <= 0; # 5;
`define MC  state <= F0;`CLK ; state <= F1; `CLK ;state <=F2; `CLK ;state <=F3; `CLK
module ac_tb;

    reg clk;
    reg reset;
    reg [3:0] state;
    wire [0:11] ac;
    wire [0:11] mq;
    reg [0:11] mdout;
    reg [0:11] instruction;


`include "../parameters.v"

    ac UUT(.clk (clk),
        .reset (reset),
        .state (state),
        .mdout (mdout),
        .instruction (instruction),
        .ac (ac),
		.l (l),
        .mq (mq));
	
always @(posedge clk)
begin
  if (state == F1) instruction <= mdout;
end

    initial begin
        $dumpfile("cla_results.vcd");
        $dumpvars(0,clk,reset,state,mdout,ac,l,mq);
		//,UUT.mdout,UUT.oper1U.aco,UUT.oper1U.instruction);
        reset <= 1;
        clk <= 1;
        `CLK
        reset <= 0;
        state <= F0;
        mdout <= 12'o7240;
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7600;
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;

        mdout <= 12'o7201;  // loads 1 into ac
        
        `MC
        state <= F0;
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
    end
endmodule

