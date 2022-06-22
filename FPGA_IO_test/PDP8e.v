// top level for a PDP8e

`include "pll.v"
`include "../front_panel/front_panel.v"
`include "../state_machine/state_machine.v"
`include "../ma/ma.v"
`default_nettype none



module top (input clk,
	    output led1,output led2,
	    output runn,
	    output [0:2] EMAn, 
        output [0:11] An,
	    output [0:11] dsn,
	    input [0:11] sr,
	    input [0:5] dsel,
	    input dep, input sw,
	    input single_step, input halt, input examn, input contn,
	    input extd_addrn, input addr_loadn, input clearn );
    /* I/O */
    wire [0:2] EMAn,EMA;
    assign EMAn = ~EMA;
    wire [0:11] An,A;
    assign An = ~A;
    wire [0:11] dsn,ds;
    assign dsn = ~ds;     
    wire run; 
    assign runn = ~run;
    wire exam;
    assign exam = ~examn;
    wire cont;
    assign cont = ~contn;
    wire extd_addr;
    assign extd_addr = ~extd_addrn;
    wire addr_load;
    assign addr_load = ~addr_loadn;
    wire clear;
    assign clear = ~clearn;
    
    reg [0:11] pc;
    reg [0:11] ma;
    reg [0:11] ac;
    reg [0:11] mq;
    reg [0:11] ir;
    reg L;
    reg [6:11] savereg;
    reg [4:0]  state;
    wire carry;
    wire L_out;
    wire [0:11] bselo;
    wire [0:11] aselo;
    wire [0:1]  aselc;
    wire [0:11] shift_aco;
    
`include "../parameters.v"

   
    wire clk100; 
    wire pll_locked;
    wire clk;
    reg [0:11] instruction;
    wire int_in_prog,addr_loadd,depd,examd,isz_skip,irq,int_inh,int_ena,contd;
    wire triggerd,cleard,extd_addrd;
    assign instruction = 12'o7402;
    assign rac = 12'o0000;
    //assign int_in_prog = 0;
    reg [0:11] rac,rsr;
    reg [31:0] counter;
  // assign int_in_prog = 0;
   assign int_ena = 0;
   
    pll p1(.clock_in (clk),
        .clock_out (clk100),
	.locked (pll_locked ));

    reg [3:0] pll_locked_buf;   // reset circuit by Cliff Wolf

    wire reset;
    always @(posedge clk)
        pll_locked_buf <= {pll_locked_buf,pll_locked};
    assign reset = ~pll_locked_buf[3];	

    always @(posedge clk100)
    begin
       rsr <= ~sr;
    end


    ma ma1(.clk (clk100),
        .reset (reset),
        .state (state),
//        .instruction (instruction),
        .pc (pc),
        .ma (ma),
        .ac (rac),
        .sr (rsr),
    	.addr (A),
        .int_in_prog (int_in_prog),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
       // .mdout (ds),  //mdout
        .isz_skip (isz_skip));

   state_machine sm1(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .int_req (irq),
        .int_inh (int_inh),
        .int_ena (int_ena),
        .int_in_prog (int_in_prog),
        .halt (halt),
        .single_step (single_step),
        .cont (contd),
        .trigger (triggerd));

   front_panel FP(.clk (clk100),
        .reset (reset),
        .state (state),
        .clear (clear),
        .extd_addr (extd_addr),
        .addr_load (addr_load),
        .dep (dep),
        .exam (exam),
        .cont (cont),
        .sing_step (single_step),
        .halt (halt),
        .triggerd (triggerd),
        .cleard (cleard),
        .extd_addrd (extd_addrd),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
        .contd (contd)
	);





    assign {led1,led2 } = counter[31:30] ^ 8'hff; 
    // assign run = 1;  // test light polarity - LED's are inverted... light
    // is off
    // assign run = sw;  // down is light on up is off so up is 1


    
    assign A[0:11] = ma[0:11];
    assign EMA[0:2] = savereg[9:11];
    assign ds[0:3] = state; 
    /* Count up on every edge of the incoming 12MHz clk */
    always @ (posedge clk100) begin
        counter <= counter + 1;
    end

endmodule
