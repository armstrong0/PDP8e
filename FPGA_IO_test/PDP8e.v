// top level for a PDP8e

parameter real clock_frequency = 66000000;

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
    assign EMAn = ~EMA;
    assign An = ~A;
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

	wire [2:0] EMA;
	wire [0:11] A;
	wire [0:11] ds;
    
    reg [0:11] pc;
    wire [0:11] ma;
    reg [0:11] ac;
    reg [0:11] mq;
    reg [0:11] ir;
    reg L;
    reg [0:6] savereg;
    reg [4:0]  state;
    wire carry;
    wire L_out;
    wire [0:11] bselo;
    wire [0:11] aselo;
    wire [0:1]  aselc;
    wire [0:11] shift_aco;
    
`include "../parameters.v"
/* verilator lint_off LITENDIAN */

   
    wire clk100; 
    wire pll_locked;
    reg [0:11] instruction;
    wire int_in_prog,addr_loadd,depd,examd,isz_skip,irq,int_inh,int_ena,contd;
    wire triggerd,cleard,extd_addrd;
	
	wire sw_active;
	wire index;
    //assign int_in_prog = 0;
    reg [0:11] rac,rsr;
    reg [31:0] counter;
	reg [0:2] DF,IF;
	reg UF;

	reg EAE_loop,EAE_mode,gtf;
	wire EAE_skip;
	
  // assign int_in_prog = 0;
   assign int_ena = 0;
   
    pll p1(.clock_in (clk),
        .clock_out (clk100),
	.locked (pll_locked ));

    reg [3:0] pll_locked_buf;   // reset circuit by Cliff Wolf

    wire reset;
    always @(posedge clk)
        pll_locked_buf <= {pll_locked_buf[2:0],pll_locked};
    assign reset = ~pll_locked_buf[3];	

    always @(posedge clk100)
    begin
       rsr <= ~sr;
	   if (reset == 1'b1)
	   begin
          rac = 12'o0000;
		  DF <= 3'b0;
		  IF <= 3'b0;
		  UF <= 1'b0;
		  EAE_loop <= 1'b0;
		  EAE_mode <= 1'b0;
		  gtf <= 1'b0;
		  pc <= 12'd0;
	   end	  
    end


    ma ma1(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .pc (pc),
        .ma (ma),
        .mq (mq),
        .ac (rac),
        .sr (rsr),
    	//.addr (A),
        .int_in_prog (int_in_prog),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
		.sw (sw),
		.IF (IF),
		.DF (DF),
		.EMA (EMA),
       // .mdout (ds),  //mdout
		.index (index),
        .isz_skip (isz_skip));

   state_machine sm1(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),

		.ac (ac),   // bad design?  needed for a singel instruction DPSZ
		.mq (mq),
        
		.index (index),  

        .int_req (irq),
        .int_inh (int_inh),
        .int_ena (int_ena),
        .int_in_prog (int_in_prog),
		.UF (UF),

		.EAE_loop (EAE_loop),
		.EAE_mode (EAE_mode),
		.EAE_skip (EAE_skip),
		.gtf (gtf),
		
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
        .contd (contd),
		
		.sw_active (sw_active)
	);





    assign {led1,led2 } = counter[31:30] ^ 2'b11; 
    // assign run = 1;  // test light polarity - LED's are inverted... light
    // is off
     assign run = sw;  // down is light on up is off so up is 1


    
    assign A[0:11] = ma[0:11];
	/* verilator lint_off SELRANGE */
    assign EMA[0:2] = savereg[4:6];
    assign ds[0:4] = state; 
	assign ds[5:11] = counter[31:25];
    /* Count up on every edge of the incoming 12MHz clk */
    always @ (posedge clk100) begin
        counter <= counter + 1;
    end

endmodule
