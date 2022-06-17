`define CLK #5 clk <= 1; #5 clk  <= 0;

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
		.l (l),
        .ac (ac),
        .mq (mq));
always @(posedge clk)
begin
  if(state == F1) instruction <= mdout;
end

    initial begin
        $dumpfile("ac_results.vcd");
        $dumpvars(0,clk,reset,state,mdout,ac,l,mq,UUT.mdout);
		//,UUT.oper1U.aco,UUT.oper1U.instruction);
        reset <= 1;
        clk <= 1;
        `CLK
        reset <= 0;
        state <= F0;
        mdout <= 12'o7040;
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7200;
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7215;  // loads 2 into ac  
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7421; // AC -> MQ  CLR AC
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7124; //loads 1 into ac
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7501;  // OR MQ and AC
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7621;  //clear AC MQ
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7124; //loads 1 into ac
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7601; // CLA
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7124; //loads 1 into ac
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7521; // SWP
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7701; // MA -> AC
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o7721; // MQ -> AC clr MQ
        `CLK
        state <= F1;
        `CLK
        state <= F2;
        `CLK
        state <= F3;
        `CLK
        state <= F0;
        mdout <= 12'o6000;  //IOT
        `MC
        mdout <= 12'o7000; // NOP
        `MC
        mdout <= 12'o7010;  // RAR
        `MC
        mdout <= 12'o7010;  // RAR 
        `MC
        mdout <= 12'o7004;  // RAL
        `MC
        mdout <= 12'o7004;  // RAL
        `MC
        mdout <= 12'o7012;  //RTR
        `MC
        mdout <= 12'o7012;  // RTR
        `MC
        mdout <= 12'o7006; // RTL
        `MC
        mdout <= 12'o7006;  // RTL
        `MC
        mdout <= 12'o7002;  //BSW
        `MC
        mdout <= 12'o7002; // BSW
        `MC
        mdout <= 12'o7014; // invalid
        `MC
        mdout <= 12'o7016; // invalid
        `MC
        mdout <= 12'o7000;  // NOP
        `MC
        mdout <= 12'o7201;  //load 1 into AC
        `MC
        mdout <= 12'o7001; // IAC
        `MC
        mdout <= 12'o7001; // IAC
		`MC
		`MC
		#20 $finish;
    end
endmodule

