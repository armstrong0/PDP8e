// top level for a PDP8e

`ifndef SIM
`include "pll.v"
`endif
`include "../serial/serial_top.v"
`include "state.v"
`include "inst_mux.v"
`include "char_mux.v"

`default_nettype none


/* verilator lint_off LITENDIAN */

module PDP8e (input clk,
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
    input extd_addrn, input addr_loadn, input clearn
    );
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
    wire [0:11] ac;
    wire [0:11] instruction;
    wire sskip;
    wire [4:0]  state;
    reg [0:11] rsr;
    reg UF;


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
	UF <= 0;
    end
`endif


`include "../parameters.v"

    inst_mux IM (.clock (clk100),
         .reset (reset),
	 .skip (sskip),
	 .state (state),
	 .instruction (instruction));
	 
    char_mux CM (.clock (clk100),
         .reset (reset),
	 .state (state),
	 .skip (sskip),
	 .ochar (ac));


    state SM(.clock (clk100),
        .reset (reset),
        .state (state)
        );

    serial_top ST(.clk (clk100),
        .reset (reset),
        .clear (1'b0),
        .state (state),
        .instruction (instruction),
        .ac (ac),
    //    .serial_bus (serial_data_bus),
        .rx (rx),
        .tx (tx),
        .UF (UF),
      //  .interrupt (s_interrupt),
        .skip (sskip));


endmodule
