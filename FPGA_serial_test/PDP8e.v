// top level for a PDP8e

`ifndef SIM
`include "pll.v"
`endif
`include "serial_tx.v"
`include "serial_rx.v"
`default_nettype none


/* verilator lint_off LITENDIAN */

module PDP8e (input clk12,
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
    //wire [0:11] ds;
    reg [0:11] ds;
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
    wire [0:11] serial_data_bus,instruction;
    wire sskip;
    wire [4:0]  state;
    reg [0:11] rsr;
    reg UF;

    wire [11:0] tx_char;
	wire [11:0] rx_char;

`include "HX_clock.v"

    reg [3:0] pll_locked_buf;   // reset circuit by Cliff Wolf
`ifndef SIM
    reg reset;
    wire clk100;
    wire pll_locked;
    pll p1(.clock_in (clk12),
        .clock_out (clk100),
        .locked (pll_locked));

    always @(posedge clk12)
    begin
        pll_locked_buf <= {pll_locked_buf[2:0],pll_locked};
        reset <= ~pll_locked_buf[3];
        rsr <= sr;
    end
`else
    always @(posedge clk12)
    begin
        rsr <= sr;
    end
`endif
    reg [18:0] counter2;
    reg [3:0] counter3;

always @(posedge clk100)
begin
if (reset == 1) counter2 <= 'o0;
else
    counter2 <= counter2 +1;
end

    assign {EMA,A} = counter2[18:4];
    assign run = ~rx;

//`include "../parameters.v"
// this section established the baud rate and transmits charactors at that
// baud rate
// It transmits in order ascii charactors starting at space and ending at ~.
// so it includes numbers punctuation upper and lower case alphabet.
// The output is arranged in 80 column lines.
// lines are terminated with cr / lf.

    
serial_tx TX(
	.clk100 (clk100),
	.reset (reset),
	.tx (tx),
	.tx_char_out (tx_char));


serial_rx RX(
	.reset (reset),
	.clk100 (clk100),
	.rx (rx),
	.rx_char_out (rx_char));



// this section selects what is displayed on the 12 bit data display
//
    reg [0:11] shft_reg;
    
	always @(posedge clk100)
    begin
        if (dsel[0] == 1) begin
            ds <= {4'd0,tx_char}; // displays last char send, very fast
        end
        else if (dsel[1] == 1) begin // allows testing of each switch in the switch register
            ds <= sr;
        end
        else if (dsel[2] == 1) begin // allows testing of every other switch
            ds <= {sw,addr_load,extd_addr,clear,cont,exam,halt,single_step,dep,3'b0};
        end
        else if (dsel[3] == 1) begin // this and the next shifts a single bit thru data display
            ds <= shft_reg;
        end
        else if (dsel[4] == 1) begin
            ds <= shft_reg;
        end
        else if (dsel[5] == 1) begin // display rx charactor
        end
    end

// this section implements left and right shift of a single lit LED	
    reg pps;
    reg [23:0] pps_cntr;
    always @(posedge pps) begin
	if (reset == 1) shft_reg <= 'o0;

	else if (dsel[4] == 1) begin
            if (shft_reg == 0) shft_reg <= 12'o4000;
            else shft_reg <= shft_reg >> 1;
			end
	  else if (dsel[3] == 1) begin
            if (shft_reg == 0) shft_reg <= 1;
            else shft_reg <= shft_reg << 1;
		end	
end

// this section generates a 1 pps clock

    always @(posedge clk12)
    begin
        if (pps_cntr == 0)
        begin
            pps <= ~ pps;
            pps_cntr <= 'd6000000;
        end
        else
            pps_cntr <= pps_cntr -1;

    end

endmodule
