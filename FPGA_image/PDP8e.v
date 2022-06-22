// top level for a PDP8e

`ifndef SIM
`include "pll.v"
`endif
`include "../imux/imux.v"
`include "../front_panel/front_panel.v"
`include "../front_panel/D_mux.v"
//`include "../int_iot/int_iot.v"
`include "../serial/serial_top.v"
`include "../oper2/oper2.v"
`include "../ac/ac.v"
`include "../pc/pc.v"
`include "../ma/ma.v"
`include "../mem_ext/mem_ext.v"

`ifndef TSIM
`include "../state_machine/state_machine.v"
`else
`include "../state_machine/state_machine_AMC.v"
`endif

`default_nettype none

/* verilator lint_off LITENDIAN */

module top (input clk,
    output reg led1,output reg led2,
    output runn,
    output [0:2] EMAn,
    output [0:11] An,
    output [0:11] dsn,
    output tx,
`ifdef SIM
    input clk100,
    input pll_locked,
	input reset,
`endif
    input rx,
    input [0:11] sr,
    input [0:5] dsel,
    input dep, input sw,
    input single_step, input halt, input examn, input contn,
    input extd_addrn, input addr_loadn, input clearn );
    /* I/O */
    wire [0:2] EMA;
    assign EMAn = ~EMA;
    wire [0:11] A;
    assign An = ~A;
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


    wire mskip,skip,eskip;
    wire int_in_prog;
    wire trigger,addr_loadd,extd_addrd,depd,examd,contd,cleard;
    wire [0:11] pc;
    wire [0:11] ma;
    wire [0:11] ac,ac_input,rac,me_bus;
    wire [0:11] mq;
    wire [0:11] instruction,mdout;
    wire link;
    wire isz_skip,sskip,iskip;
    wire int_ena,int_inh,irq;
    wire s_interrupt;
    wire gtf;
    wire [4:0]  state;
    wire [0:11] serial_data_bus,display_bus;
    wire [0:2] IF,DF;
    wire UF;
    reg [0:11] rsr;



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
 assign irq = s_interrupt;

    ma MA(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .pc (pc),
        .ma (ma),
        .ac (rac),
        .sr (rsr),
        .DF (DF),
        .IF (IF),
        .EMA (EMA),
        .addr (A),
        .int_in_prog (int_in_prog),
        .addr_loadd (addr_loadd),
        .depd (depd),
        .examd (examd),
        .mdout (mdout),
        .isz_skip (isz_skip));

    pc PC(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (instruction),
        .ma (ma),
        .mdout (mdout),
        .pc (pc),
        .int_in_prog (int_in_prog),
        .skip (skip),
        .isz_skip (isz_skip),
        .eskip (eskip));

    state_machine SM(.clk (clk100),
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
        .trigger (trigger));

    ac AC(.clk (clk100),
        .reset (reset),
        .state (state),
        .clear (cleard),
        .instruction (instruction),
        .mdout (mdout),
        .input_bus (ac_input),
        .ac (ac),
        .rac (rac),
        .l (link),
        .gtf (gtf),
        .sr (rsr),
        .mq (mq));

    oper2 oper21(.clk100 (clk100),
        .state (state),
        .instruction (mdout),
        .ac (ac),
        .l (link),
        .skip (skip));

    serial_top ST(.clk (clk100),
        .reset (reset),
        .clear (clear),
        .state (state),
        .instruction (mdout),
        .ac (rac),
        .serial_bus (serial_data_bus),
        .rx (rx),
        .tx (tx),
        .interrupt (s_interrupt),
        .skip (sskip));

//    int_iot INT(
//        .serial_interrupt (s_interrupt),
//        .irq (irq)
//        );

    D_mux DM(.clk (clk100),
        .reset (reset),
        .dsel (dsel),
        .state1 ( {instruction[0:2],2'b00,sw,3'b000}),
        .status ({link,gtf,irq,1'b0,int_ena,{UF,IF,DF}}),
        .ac (rac),
        .mb (mdout),
        .mq (mq),
        .io_bus (display_bus),
        .dout (ds),
        .state (state),
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
        .triggerd (trigger));

    imux IM(.clk (clk100),
        .reset (reset),
        .state (state),
        .instruction (mdout),
        .ac (rac),
        .mem_reg_bus (me_bus),
        .serial_data_bus (serial_data_bus),
        .in_bus (ac_input),
        .bus_display (display_bus),
        .iskip (iskip),
        .sskip (sskip),
        .mskip (mskip),
        .skip (eskip));

    mem_ext ME(.clk (clk100),
        .reset (reset),
        .instruction (instruction),
        .mdout (mdout),
        .sr (rsr),
        .rac (rac),
        .state (state),
        .clear (clear),
        .extd_addrd (extd_addrd),
        .int_in_prog (int_in_prog),
        .int_inh (int_inh),
        .irq (irq),
        .int_ena (int_ena),
        .gtf (gtf),
        .DF (DF),
        .IF (IF),
        .UF (UF),
        .mskip (mskip),
        .me_bus (me_bus));

endmodule
