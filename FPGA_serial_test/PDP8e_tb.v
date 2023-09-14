`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0

`define pulse1(arg) #1 ``arg <=1 ; #1400 ``arg <= 0


module PDP8e_tb;
    reg  clk100;
    reg  clk;
    reg  pll_locked;
    reg reset;
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
	reg serial_io;

`include "../parameters.v"

    always begin  // clock _period comes from parameters.v
        #(clock_period/2) clk100 <= 1;
        #(clock_period/2) clk100 <= 0;
    end

    always begin  // assumes about a 12 MHz clock
        #42 clk <= 1;
        #42 clk <= 0;
    end
    always @* begin
        address <= {~EMAn,~An};
    end
    always @(posedge clk100)
    begin
        //rx <= tx;  // used in serial tests
        serial_io <= ((UUT.instruction[0:8] == 9'o603) || 
	                 (UUT.instruction[0:8] == 9'o604)) ;
    end


    PDP8e UUT (.clk (clk),
        .runn (runn),
        .led1 (led1),
        .led2 (led2),
        .EMAn (EMAn),
        .An (An),
        .dsn (dsn),
        .tx (tx),
        .clk100 (clk100),
        .pll_locked (pll_locked),
        .reset (reset),
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
        #1 $display("clock frequency %f",(clock_frequency)) ;
        #1 $display("baud rate %f ",(baud_rate)) ;
        #1 $display("clock period %f",(clock_period)) ;

        #1 $display("cycle time %f nanoseconds" ,(6*clock_period));


        #1 sr <= 12'o0200;  // normal start address
         $dumpfile("Hardware_serial_test.vcd");
         $dumpvars(0,UUT);
        //        $readmemh( "Diagnostics/dhkaf-a.hex", UUT.MA.ram.mem,0,4095);
        #0 halt <= 1;
        #1 reset <= 1;
		#1 clear <= 0;
        #( clock_period*10) reset <=0;
        #1 single_step <= 0;
        #1 sw <= 0;
        #1 exam <= 0;
        #1 cont <= 0;
        #1 extd_addr <= 0;
        #1 addr_load <= 0;
        #1 dep <= 0;
        #1 dsel <= 6'b001000;
        #1 sr <= 12'o0200;
        #1 pll_locked <= 0;
        #1 rx <= 1; // marking state
        #100 pll_locked <= 1;
        #100 halt <= 0;
        #4000000 $finish;


    end

endmodule
