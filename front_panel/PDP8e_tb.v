`define SIM
`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0

module PDP8e_tb;
    reg  clk100;
    reg  clk;
    reg  pll_locked;
    reg  rx;
    reg  [0:11] sr;
    reg  [0:5] dsel;
    reg  dep;
    reg  sw;
    reg  single_step;
    reg  halt;
    reg  exam;
    reg  cont;
    reg  extd_addr;
    reg  addr_load;
    reg  clear ;
    reg [0:14] address;
    wire led1;
    wire led2;
    wire runn;
    wire [0:2] EMAn;
    wire [0:11] An;
    wire [0:11] dsn;
    wire tx;
    wire tclk;

`include "../parameters.v"

    always begin  // assumes about a 58 MHz clock
        #9 clk100 <= 1;
        #9 clk100 <= 0;
    end
    always begin  // assumes about a 12 MHz clock
        #42 clk <= 1;
        #42 clk <= 0;
    end
    always @* begin
        address <= {~EMAn,~An};
    end

    parameter test_sel=2;

    top UUT (.clk (clk),
        .runn (runn),
        .led1 (led1),
        .led2 (led2),
        .EMAn (EMAn),
        .An (An),
        .dsn (dsn),
        .tx (tx),
        .clk100 (clk100),
        .pll_locked (pll_locked),
        .rx (rx),
        .sr (sr),
        .dsel (dsel),
        .dep (dep),
        .sw (sw),
        .single_step (single_step),
        .halt (halt),
        .examn (~exam),
        .contn (~cont),
        .extd_addrn (~extd_addr),
        .addr_loadn (~addr_load),
        .clearn (~clear)) ;



    initial begin


        $dumpfile("front_panel_system_test.vcd");
        $dumpvars(0,address,UUT);

        #0 halt <= 1;
        #1 single_step <= 0;
        #1 sw <= 0;
        #1 exam <= 0;
        #1 cont <= 0;
        #1 extd_addr <= 0;
        #1 dep <= 0;
        #1 dsel <= 6'b001000;
        #1 sr <= 12'o0155;
        #1 pll_locked <= 0;
        #1 rx <= 1; // marking state
        #100 pll_locked <= 1;
        #100 halt <= 0;
        #300;
        `pulse(addr_load);
        #400 $finish;

    end

endmodule
