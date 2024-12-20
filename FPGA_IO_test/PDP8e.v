// top level for a PDP8e

`ifndef SIM
`include "pll.v"
`endif
`include "serial_tx.v"
`include "serial_rx.v"
`default_nettype none


/* verilator lint_off LITENDIAN */

module PDP8e (
    input clk,
    output reg led1,
    output reg led2,
    output runn,
    output [0:14] An,
    output [0:11] dsn,
    output tx,
`ifdef SIM
    input clk100,
    input pll_locked,
    input reset,
`endif
    input rx,
    input [0:11] sr,
    input dsel_swn,
    output reg [4:0] dsel_led,
    input dep,
    input sw,
    input single_stepn,
    input haltn,
    input examn,
    input contn,
    input extd_addrn,
    input addr_loadn,
    input clearn
);
  /* I/O */
  assign An = ~addr;
  wire [0:14] addr;
  //wire [0:11] ds;
  reg  [0:11] ds;
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
  reg dsel_true;
  reg [15:0] dsel_cntr;

  reg [0:11] rsr;
  reg [5:0] dsel;

  wire [11:0] tx_char;
  wire [11:0] rx_char;

  `include "HX_clock.v"

  reg [3:0] pll_locked_buf;  // reset circuit by Cliff Wolf
`ifndef SIM
  reg  reset;
  wire clk100;
  wire pll_locked;
  pll p1 (
      .clock_in(clk),
      .clock_out(clk100),
      .locked(pll_locked)
  );

  always @(posedge clk) begin
    pll_locked_buf <= {pll_locked_buf[2:0], pll_locked};
    reset <= ~pll_locked_buf[3];
    rsr <= sr;
  end
`else
  always @(posedge clk) begin
    rsr <= sr;
  end
`endif
  reg [24:0] counter2;

  always @(posedge clk100) begin
    if (reset == 1) counter2 <= 'o0;
    else counter2 <= counter2 + 1;
  end

  assign addr = counter2[24:10];
  assign run  = ~rx;

  // this section established the baud rate and transmits charactors at that
  // baud rate
  // It transmits in order ascii charactors starting at space and ending at ~.
  // so it includes numbers punctuation upper and lower case alphabet.
  // The output is arranged in 80 column lines.
  // lines are terminated with cr / lf.


  serial_tx TX (
      .clk100(clk100),
      .reset(reset),
      .tx(tx),
      .tx_char_out(tx_char)
  );


  serial_rx RX (
      .reset(reset),
      .clk100(clk100),
      .rx(rx),
      .rx_char_out(rx_char)
  );



`ifdef SIM
`define  PPS_CNT 24'd65
`define  DSEL_CNT 16'd65 
`else
`define PPS_CNT 24'd65535
`define DSEL_CNT  16'd65535
`endif

  //
  reg [0:11] shft_reg;

  always @(posedge clk) begin
    if (reset == 1) begin
      ds <= 12'd0;
    end else if (dsel[0] == 1) begin
      ds <= {4'd0, tx_char};  // displays last char send, very fast
    end else if (dsel[1] == 1) begin  // allows testing of each switch in the switch register
      ds <= sr;
    end else if (dsel[2] == 1) begin  // allows testing of every other switch
      ds <= {sw, addr_load, extd_addr, clear, cont, exam, halt, single_step, dep, 2'b0, pll_locked};
    end else if (dsel[3] == 1) begin  // this and the next shifts a single bit thru data display
      ds <= shft_reg;
    end else if (dsel[4] == 1) begin
      ds <= shft_reg;
    end else if (dsel[5] == 1) begin  // display rx charactor
      ds <= rx_char;
    end
  end

  // this section implements left and right shift of a single lit LED	
  reg pps;
  reg [23:0] pps_cntr;
  always @(posedge clk) begin
    if (reset == 1) shft_reg <= 'o0;

    else if ((dsel[4] == 1) && (pps == 1)) begin
      if (shft_reg == 0) shft_reg <= 12'o4000;
      else shft_reg <= shft_reg >> 1;
    end else if ((dsel[3] == 1) && (pps == 1)) begin
      if (shft_reg == 0) shft_reg <= 1;
      else shft_reg <= shft_reg << 1;
    end
  end

  always @(posedge clk) begin
    if (reset == 1) begin
      dsel <= 6'b100000;
      dsel_cntr <= 0;
      dsel_true <= 0;
    end else if ((dsel_true == 1) && (dsel_cntr == 0)) begin
      dsel_cntr <= `DSEL_CNT;
      dsel <= {dsel[0], dsel[5:1]};
      dsel_true <= 0;
    end else if (dsel_cntr != 0) begin
      dsel_cntr <= dsel_cntr - 1;
      dsel_true <= 0;
    end

    if ((dsel_sw == 1) && (dsel_cntr == 0)) begin
      dsel_true <= 1;
    end

    case (dsel)
      6'b100000: dsel_led <= 5'b01100;
      6'b010000: dsel_led <= 5'b01010;
      6'b001000: dsel_led <= 5'b01001;
      6'b000100: dsel_led <= 5'b10100;
      6'b000010: dsel_led <= 5'b10010;
      6'b000001: dsel_led <= 5'b10001;
      default:   dsel_led <= 5'b01100;
    endcase
  end

  // this section generates a 1 pps clock
  always @(posedge clk) begin
    if (reset == 1) begin
      pps <= 0;
      pps_cntr <= `PPS_CNT;
    end else if (pps_cntr == 0) begin
      pps <= 'b1;
      pps_cntr <= `PPS_CNT;
    end else begin
      pps_cntr <= pps_cntr - 1;
      pps <= 0;
    end
  end
endmodule
