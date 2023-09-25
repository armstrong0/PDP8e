`define SIM
`timescale 1 ns / 10 ps
`define PULSE(arg) #1 ``arg <=1 ; #(20*clock_period) ``arg <= 0



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
    wire sdMOSI,sdSCLK,sdMISO,sdCS;

    wire diskio;
    assign diskio = (UUT.instruction[0:8] == 9'o674);
    wire troublesome;
    assign troublesome = (address == 15'o07750);

//`include "../FPGA_image/HX_clock.v"
`include "../parameters.v"

    always begin  // clock _period comes from parameters.v
        #(clock_period/2) clk100 <= 1;
        #(clock_period/2) clk100 <= 0;
    end

    always begin  // assumes about a 12 MHz clock
        #42 clk <= 1;
        #42 clk <= 0;
    end
    always @*  begin
        address = {~EMAn,~An};
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
        .clearn (~clear),
        .sdCS (sdCS),
        .sdMOSI (sdMOSI),
        .sdSCLK (sdSCLK),
        .sdMISO (sdMISO)
        );
        
sdsim SDSIM(.clk (clk100),
    .reset (reset),
    .clear (clear),
    .sdCS (sdCS),
    .sdMOSI (sdMOSI),
    .sdSCLK (sdSCLK),
    .sdMISO (sdMISO)
);


    

    initial begin
        #1 $display("clock frequency %f Hz",(clock_frequency)) ;
        #1 $display("baud rate %f Hz ",(baud_rate)) ;
        #1 $display("TX term count %f ",(tx_term_cnt)); 
        #1 $display("RX term count %f ",$rtoi((baud_period /16)/clock_period));
        #1 $display("clock period %f nanoseconds",(clock_period)) ;
        #1 $display("baud_period %f nanoseconds",(baud_period)) ;
        #1 $display("cycle time %f nanoseconds" ,(6*clock_period));
        #1 $display("Slow SPI frequency %f",LoSpiFreq);
        #1 $display("Fast SPI frequency %f",HiSpiFreq);


        #1 sr <= 12'o0200;  // normal start address
        $dumpfile("SDCard.vcd");
        $dumpvars(0,address,diskio,troublesome,UUT);
        $readmemh("zero.hex",UUT.MA.ram.mem,0,8191);
        sr <= 12'o0004;

        #1 reset <= 1;
        #(clock_period*10) reset <=0;
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
        #5000;
        sr <= 12'o0026;
        `PULSE(addr_load);
        #1000 ;
        sr <= 12'o6741;
        `PULSE(dep);
        #1000 ;
        sr <= 12'o5026;
        `PULSE(dep);
        #1000 ;
        sr <= 12'o6743;
        `PULSE(dep);
        #1000 ;
        sr <= 12'o5030;
        `PULSE(dep);
        #1000 ;
        sr <= 12'o0026;
        `PULSE(addr_load);
        #1000 ;
        `PULSE(cont);
        #500 wait (address == 15'o00000);

        #500 wait (UUT.RK8E.status == 12'o4000); // ready
        wait (UUT.RK8E.status == 12'o0000);
        $writememh("b177",UUT.MA.ram.mem,127,255);
        $writememh("b046",UUT.MA.ram.mem,38,63);
        //wait(UUT.instruction == 12'o6744);
        wait(address == 15'o17605);
        $writememh("ram_contents5",UUT.MA.ram.mem,0,8191);
        $writememh("a7577",UUT.MA.ram.mem,3967,4095);
        $writememh("a17746",UUT.MA.ram.mem,8166,8191);
        $finish;
        #40000000  $finish;


    end

endmodule
