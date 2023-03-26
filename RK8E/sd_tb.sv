module sd_tb;
import sd_types::*;
import sdspi_types::*;

reg clk,reset,clear;

wire sdMISO,sdMOSI,sdSCLK, sdCS;
wire [0:11]  dmaDOUT;     //! DMA Data Out of Disk
wire [0:14]  dmaADDR;     //! DMA Address
wire         dmaRD;       //! DMA Read
wire         dmaWR;       //! DMA Write
wire         dmaREQ;      //! DMA Request
logic [0:2]  sdOP;    
logic [0:14] sdMEMaddr;   //! Memory Address
sdDISKaddr_t sdDISKaddr;  //! Disk Address
logic        sdLEN;       //! Sector Length

logic [0:11] dmaDIN;      //! DMA Data Into Disk
logic  dmaGNT;      //! DMA Grant



sd SD(.clk (clk),
    .reset (reset),       //! Clock/Reset
    .clear (clear),       //! IOCLR
    // PDP8 Interface
    .dmaDIN  (dmaDIN),      //! DMA Data Into Disk
    .dmaDOUT (dmaDOUT),     //! DMA Data Out of Disk
    .dmaADDR (dmaADDR),     //! DMA Address
    .dmaRD   (dmaRD),       //! DMA Read
    .dmaWR   (dmaWR),       //! DMA Write
    .dmaREQ  (dmaREQ),      //! DMA Request
    .dmaGNT  (dmaGNT),      //! DMA Grant
    // Interface to SD Hardware
    .sdMISO  (sdMISO),      //! SD Data In
    .sdMOSI  (sdMOSI),      //! SD Data Out
    .sdSCLK  (sdSCLK),      //! SD Clock
    .sdCS    (sdCS),        //! SD Chip Select
    // RK8E Interface
    .sdOP    (sdOP),        //! SD OP
    .sdMEMaddr  (sdMEMaddr),  //! Memory Address
    .sdDISKaddr (sdDISKaddr), //! Disk Address
    .sdLEN      (sdLEN),      //! Sector Length
    .sdSTAT     (sdSTAT)      //! Status

);

sdsim SDM (.clk (clk),
      .reset(reset),
      .clear(clear),
      .sdMISO(sdMISO),
      .sdMOSI(sdMOSI),
      .sdSCLK(sdSCLK),
      .sdCS(sdCS)
);

always begin
    #10 clk <= ~clk;
  end

initial begin
  $dumpfile("sdsim.vcd");
  $dumpvars(0,SD,SDM);

  clk <= 1'b0;
  #50 reset <= 1'b1;
  #50 reset <= 1'b0;
  sdDISKaddr <= 32'd0;
  sdMEMaddr <= 15'd0;
  sdLEN <= 1'b0;
  dmaGNT <= 1'b0;
  #1600000 sdOP <= 3'b10;  // read
  wait (dmaREQ == 1'b1);
  #20 dmaGNT <= 1'b1;
  sdOP <= 3'b000;  // only read one sector
  #15000000 $finish; 

end

endmodule

