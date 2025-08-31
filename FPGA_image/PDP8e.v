// top level for a PDP8e

`ifndef SIM
`include "pll.v"
`include "HX_clock.v"
`endif
`include "../imux/imux.v"
`include "../front_panel/front_panel.v"
`include "../front_panel/D_mux.v"
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
    output reg led1,output reg led2,
    output runn,
    output [0:14] An,
    output [0:11] dsn,
`ifdef SIM
    input clk100,
    input pll_locked,
    input reset,
`endif
    input [0:11] sr,

    input dsel_swn,
    output [4:0] dsel_led, // two outputs drive low, 3 drive high combo lights one LED
    
    input dep, input sw,
    input single_stepn, input haltn, input examn, input contn,
    input extd_addrn, input addr_loadn, input clearn,
`ifdef RK8E
    input   sdMISO,
    output  sdMOSI,
    output  sdSCLK,sdCS,
`endif
    input rx,
    output tx
    );
    /* I/O */
    assign An = ~addr;
    wire [0:11] ds;
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
    wire halt;
    assign halt = ~haltn;
    wire single_step;
    assign single_step = ~single_stepn;

    wire dsel_sw;
    assign dsel_sw = ~dsel_swn;
    wire [2:0] dsel;
    wire dseld;


    wire mskip,skip,eskip;
    wire int_in_prog;
    wire trigger,addr_loadd,extd_addrd,depd,examd,contd,cleard;
    wire [0:11] pc;
    wire [0:14] addr;
    wire [0:11] ac,ac_input,me_bus;
    wire [0:11] mq;
    wire [0:11] instruction,mdout;
    wire [0:14] dmaAddr;
    wire link;
    wire sskip;
    wire int_ena,int_inh,irq;
    wire s_interrupt;
    wire gtf;
    wire [4:0]  state;
    wire [0:11] serial_data_bus,display_bus;
    wire [0:2] IF,DF;
    wire UF;
    wire UI;
    reg [0:11] rsr;
    wire EAE_mode,EAE_loop;
    wire sw_active;
    wire run_ff;
    wire index;

    wire disk_rdy;
`ifdef RK8E
    wire data_break,to_disk;
    wire disk_interrupt,disk_skip;
    wire break_in_prog;
    wire [0:11] disk_bus,disk2mem,mem2disk;
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
        rsr <= sr;
    end
`else
    always @(posedge clk)
    begin
        rsr <= sr;
    end
`endif


`include "../parameters.v"
`ifdef RK8E
    assign irq = s_interrupt | UI | disk_interrupt;
`else
    assign irq = s_interrupt | UI;
`endif


`ifdef RK8E
`ifndef SIM
`include "HX_clock.v"
`endif
rk8e RK8E (
    .clk (clk100) ,
    .reset (reset),
    .clear (cleard),
    .instruction (instruction) ,
    .state (state),
    .ac (ac),
    .UF (UF),
    .dmaAddr (dmaAddr),
    .disk_bus (disk_bus ),
    .interrupt (disk_interrupt),
    .data_break (data_break),
    .to_disk (to_disk ),
    .sd_delay (sd_delay1),
    .disk_rdy (disk_rdy),
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
        .extd_addrd (extd_addrd),
        .sw (sw),
`ifdef RK8E
        .to_disk (to_disk),
        .disk2mem (disk2mem),
        .dmaAddr (dmaAddr),
        .mem2disk (mem2disk),
	.data_break (data_break),
`endif
        .mdout (mdout),
        .index (index));


    state_machine SM(.clk (clk100),
        .reset (reset),
        .clear (cleard),
        .state (state),
        .instruction (instruction),

        .ac (ac),
        .mq (mq),

        .index (index),

        .int_req (irq),
        .int_inh (int_inh),
        .int_ena (int_ena),
        .int_in_prog (int_in_prog),
        .UF (UF),

        .EAE_loop (EAE_loop),
        .EAE_mode (EAE_mode),
`ifdef RK8E
        .break_in_prog (break_in_prog),
        .data_break (data_break),
        .to_disk (to_disk),
`endif
        .halt (halt),
        .single_step (single_step),
        .cont (contd),
        .run_ff (run_ff),
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
        .EAE_mode (EAE_mode),
        .EAE_loop (EAE_loop),
        .sr (rsr),
        .mq (mq));

    oper2 oper21(.clk100 (clk100),
        .state (state),
        .instruction (instruction),
        .ac (ac),
		.mq (mq),
		.EAE_mode (EAE_mode),
		.gtf (gtf),
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
        .state (state),
`ifdef RK8E
        .state1 ( {instruction[0:2],2'b00,sw,disk_rdy,break_in_prog,EAE_mode} ),
`else
        .state1 ( {instruction[0:2],2'b00,sw,2'b00,EAE_mode} ),
`endif
        .status ({link,gtf,irq,int_inh,int_ena,{UF,IF,DF}}),
        .ac (ac),
        .mb (mdout),
        .mq (mq),
   //     .io_bus (display_bus),
        .io_bus ({state,sw_active,EAE_loop,5'd0}),
        .sw_active (sw_active),
        .run_ff (run_ff),
        .dout (ds),
        .dsel_led (dsel_led),
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
        .cleard (cleard),
        .extd_addrd (extd_addrd),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
        .contd (contd),
        .dsel_sw (dsel_sw),
        .dsel (dsel),
        .triggerd (trigger),
        .dseld (dseld),
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
