`timescale 1 ns / 10 ps
module front_panel_tb;

reg clk,reset;
reg clear, extd_addr,addr_load,dep,exam,sing_step,cont;
wire contd;
wire cleard , extd_addrd , addr_loadd , depd , examd; 

reg [4:0] state;
wire [0:2] trig_stateo;
wire [0:4] count;
`include "../parameters.v"
		 
front_panel UUT(.clk (clk),
                .clear (clear),
                .extd_addr (extd_addr),
		.addr_load (addr_load),
		.dep (dep),
		.exam (exam),
		.sing_step (sing_step),
		.cleard (cleard), 
		.extd_addrd (extd_addrd), 
		.addr_loadd (addr_loadd) , 
		.depd (depd),
		.examd (examd), 
		.cont (cont),
		.contd (contd),
                .reset (reset),
		.state (state));

initial begin

$dumpfile("front_panel.vcd");
$dumpvars(0,clk,reset,clear,extd_addr,addr_load,dep,exam,state,sing_step,cont,cleard ,extd_addrd,addr_loadd,depd,examd,contd,UUT.trigger1,UUT.trig_state,UUT.trig_cnt);

clk = 0;
forever
  #10  clk = ~clk;
end

initial begin
clear <= 0;
extd_addr  <= 0;
addr_load  <= 0;
dep  <= 0;
exam <= 0;
sing_step <= 0;
cont <= 0;
state <= H0;

#15 reset <= 1;
#25 reset <= 0;
#24 clear <= 1;
#100 clear <= 0;
//#50 state <= F0;
#20 cont <= 1;
#20 cont <=0;
//#440 sing_step <= 1;
#355 extd_addr <= 1;
#80 extd_addr <= 0;
#500 addr_load <= 1;
#50 addr_load <= 0;

//#60 sing_step <= 0;
//#225 state <= H0;
#500 exam <= 1;
#25 exam <= 0;
#50 exam <= 1;
#25 exam <= 0;
#300 dep <= 1;
#25 dep <= 0;
#500 cont <= 1;
#50 cont <= 0;


#500 $finish;
end


endmodule

