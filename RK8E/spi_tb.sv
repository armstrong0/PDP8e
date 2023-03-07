`timescale 1 ns / 10 ps

import sd_types::*;
import sdspi_types::*;
module spi_tb;


logic clk;
logic rst;
spiOP_t spiOP;
reg sdBYTE_t spiTXD;
wire sdBYTE_t spiRXD;
reg spiMISO;

wire spiSCLK;
wire spiMOSI;
wire spiCS;
wire spiDONE;
logic spiMIS0;

sdspi UUT(
 .clk (clk),
 .rst (rst),
 .spiOP (spiOP),
 .spiTXD (spiTXD),
 .spiRXD (spiRXD),
 .spiCS (spiCS),
 .spiDONE (spiDONE),
 .spiMOSI (spiMOSI),
 .spiMISO (spiMISO),
 .spiSCLK (spiSCLK));

always begin
	#5 clk <= ~clk;
end	

initial begin

 $dumpfile("sdspi_test.vcd");
 $dumpvars(0,UUT);


    spiMISO <= 1'b0;
    clk <= 1'b0;
	rst <= 1'b1;
	spiOP <= spiNOP;
	#50 spiOP <= spiCSL;
	 #50  rst <= 1'b0;
	 #50 spiOP <= spiSLOW;
	 spiTXD <= 8'h55;
	 #15 spiOP <= spiCSH;
	 #15 spiOP <= spiTR;
	 #15 spiOP <= spiNOP;
	 wait(spiDONE == 1'b1)
	 #10 spiOP <= spiFAST;
	 #15 spiOP <= spiCSL;
	 #15 spiOP <= spiCSH;
	 #10 spiTXD <= 8'haa;
	 #10 spiOP <= spiTR;
	 wait(spiDONE == 1'b1)
	 #300 $finish;

     
end
endmodule



