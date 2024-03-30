// top level for a PDP8e

`ifndef SIM
`include "pll.v"
`endif
`include "UP_clock.v"
`include "../imux/imux.v"
`include "../front_panel/front_panel.v"
`include "../front_panel/D_mux.v"
`include "../front_panel/scan_matrix.v"
`include "../serial/serial_top.v"
`include "../oper2/oper2.v"
`include "../ac/ac.v"
`include "../ma/ma.v"
`include "../mem_ext/mem_ext.v"
`ifdef RK8E
`include "../RK8E/rk8e.v"
`endif

`ifndef TSIM
`include "../state_machine/state_machine.v"
`else
`include "../state_machine/state_machine_AMC.v"
`endif

`default_nettype none


/* verilator lint_off LITENDIAN */

module PDP8e (input clk,
 //   output reg led1,output reg led2,
    output runn,
    output [0:2] LR,
    output [0:12] LC,
    output [0:4] SR,
    output tx,
`ifdef SIM
    input clk100,
    input pll_locked,
    input reset,
`endif
    input rx,
    input [0:3] SC,
    output  sdMOSI,
    input   sdMISO,
    output  sdSCLK,sdCS
    );
    /* I/O */
    wire [0:14] addr;
    wire [0:11] ds;
    wire run;

    wire exam;
    wire cont;
    wire extd_addr;
    wire addr_load;
    wire clear;
	wire dep;
	wire halt;
	wire single_step;
	wire sw;
	wire [2:0] dsel;


    wire mskip,skip,eskip;
    wire int_in_prog;
    wire trigger,addr_loadd,extd_addrd,depd,examd,contd,cleard;
    wire [0:11] pc;
    wire [0:11] ma;
    wire [0:11] ac,ac_input,me_bus;
    wire [0:11] mq;
    wire [0:11] instruction,mdout,disk2mem,mem2disk;
	wire [0:14] dmaAddr;
    wire link;
    wire isz_skip,sskip;
    wire int_ena,int_inh,irq;
    wire s_interrupt;
	wire irg;
    wire gtf;
    wire [4:0]  state;
    wire [0:11] serial_data_bus,display_bus;
    wire [0:2] IF,DF;
    wire UF;
    wire UI;
    reg [0:11] rsr;
    wire EAE_mode,EAE_loop,EAE_skip;
    wire sw_active;
    wire index;
`ifdef RK8E    
    wire data_break,to_disk;
    wire disk_interrupt,disk_skip;
    wire break_in_prog;
    wire [0:11] disk_bus;
`endif


    reg [3:0] pll_locked_buf;   // reset circuit by Cliff Wolf
    reg [24:0] counter;
`ifndef SIM
    reg reset;
    wire clk100;
    wire pll_locked;
    pll p1(.clock_in (clk),
        .clock_out (clk100),
        .locked (pll_locked));

    always @(posedge clk)  // was clk
    begin
        pll_locked_buf <= {pll_locked_buf[2:0],pll_locked};
        reset <= ~pll_locked_buf[3];
    end
`else
    always @(posedge clk)
    begin
        rsr <= sr;
    end
`endif

`include "UP_clock.v"
`include "../parameters.v"
`ifdef RK8E
    assign irq = s_interrupt | UI | disk_interrupt;
`else
    assign irq = s_interrupt | UI; 
`endif
	
scan_matrix SX (
	.clk (clk100),
	.reset (reset),
	.EMA (addr[0:2]),
	.A (addr[3:14]),
	.LC (LC),
	.LR (LR),
	.SC (SC),
	.SR (SR),
	.cont (cont),
	.clear (clear),
	.exam (exam),
	.dep (dep),
	.halt (halt),
	.sw (sw),
	.dsel (dsel),
	.single_step (single_step),
	.addr_load (addr_load),
	.extd_addr (extd_addr));

`ifdef RK8E    
rk8e RK8E (
    .clk (clk100) ,
    .reset (reset),
    .clear (clear),
    .instruction (instruction) ,
    .state (state),
    .ac (ac),
    .UF (UF),
	.dmaAddr (dmaAddr),
    .disk_bus (disk_bus ),
    .interrupt (disk_interrupt),
    .data_break (data_break),
    .to_disk (to_disk ),
    .break_in_prog (break_in_prog ),
    .skip (disk_skip) ,
    .dmaDIN (mem2disk),
    .dmaDOUT (disk2mem),
    .sdMISO (sdMISO),
    .sdMOSI (sdMOSI),
    .sdSCLK (sdSCLK),
    .sdCS (sdCS)
);
`endif

    ma MA(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
	.skip (skip),
        .eskip (eskip),
        .eaddr (addr),
        .ac (ac),
        .mq (mq),
        .sr (rsr),
        .DF (DF),
        .IF (IF),
       .int_in_prog (int_in_prog),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
	.sw (sw),
`ifdef RK8E		
.to_disk (to_disk),
.disk2mem (disk2mem),
.dmaAddr (dmaAddr),
.mem2disk (mem2disk),
`endif		
        .mdout (mdout),
        .index (index));

/*    pc PC(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .ma (ma),
        .mdout (mdout),
        .pc (pc),
        .int_in_prog (int_in_prog),
        .skip (skip),
        .isz_skip (isz_skip),
        .eskip (eskip)
    );
*/
    state_machine SM(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .ac (ac),
        .mq (mq),
        .EAE_loop (EAE_loop),
        .EAE_mode (EAE_mode),
       // .EAE_skip (EAE_skip),
       // .gtf (gtf),
        .int_req (irq),
        .int_inh (int_inh),
        .int_ena (int_ena),
        .int_in_prog (int_in_prog),
`ifdef RK8E		
		.break_in_prog (break_in_prog),
        .data_break (data_break),
        .to_disk (to_disk),
`endif		
        .UF (UF),
        .halt (halt),
        .single_step (single_step),
        .cont (contd),
        .trigger (trigger));

    Ac AC(.clk (clk100),
        .reset (reset),
        .state (state),
        .clear (cleard),
        .instruction (instruction),
        .mdout (mdout),
        .input_bus (ac_input),
        .ac (ac),
        .link (link),
        .gtf (gtf),
        .UF (UF),
        .UI (UI),
        .EAE_mode (EAE_mode),
        .EAE_loop (EAE_loop),
        .sr (rsr),
        .mq (mq));

    oper2 oper21(.clk100 (clk100),
        .state (state),
        .instruction (instruction),
        .ac (ac),
        .l (link),
        .skip (skip));

    serial_top ST(.clk (clk100),
        .reset (reset),
        .clear (cleard),
        .state (state),
        .instruction (instruction),
        .ac (ac),
        .serial_bus (serial_data_bus),
        .rx (rx),
        .tx (tx),
        .UF (UF),
        .interrupt (s_interrupt),
        .skip (sskip));

    D_mux DM(.clk (clk100),
        .reset (reset),
        .dsel (dsel),
`ifdef RK8E		
        .state1 ( {instruction[0:2],2'b00,sw,1'b0,break_in_prog,EAE_mode} ),
`else		
        .state1 ( {instruction[0:2],2'b00,sw,2'b00,EAE_mode} ),
`endif		
        .status ({link,gtf,irq,1'b0,int_ena,{UF,IF,DF}}),
        .ac (ac),
        .mb (mdout),
        .mq (mq),
        .io_bus (display_bus),
        .dout (ds),
        .state (state),
        .sw_active (sw_active),
        .run_led (run));

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
        .cleard (cleard),
        .extd_addrd (extd_addrd),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
        .contd (contd),
        .triggerd (trigger),
        .sw_active (sw_active));

    imux IM(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .ac (ac),
        .mem_reg_bus (me_bus),
        .serial_data_bus (serial_data_bus),
        .in_bus (ac_input),
        .bus_display (display_bus),
`ifdef RK8E		
        .disk_bus (disk_bus),
        .disk_skip (disk_skip),
`endif		
      //  .EAE_skip (EAE_skip),
      //  .EAE_mode (EAE_mode),
        .sskip (sskip),
        .mskip (mskip),
        .skip (eskip));

    mem_ext ME(.clk (clk100),
        .reset (reset),
        .instruction (instruction),
        .mdout (mdout),
        .sr (rsr),
        .ac (ac),
        .state (state),
        .clear (cleard),
        .extd_addrd (extd_addrd),
        .int_in_prog (int_in_prog),
        .int_inh (int_inh),
        .irq (irq),
        .int_ena (int_ena),
        .gtf (gtf),
        .DF (DF),
        .IF (IF),
        .UF (UF),
        .UI (UI),
        .mskip (mskip),
        .me_bus (me_bus));

endmodule
