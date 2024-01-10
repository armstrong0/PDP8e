/*--------------------------------------------------------------------
//
// PDP-8 Processor
//
// \brief
//      RK8E Secure Digital SPI Interface
//
// \details
//      This interface communicates with the Secure Digital Chip
//      at the physical layer.
//
// \file
//      sdspi.vhd
//
// \author
//      Rob Doyle - doyle (at) cox (dot) net
//
--------------------------------------------------------------------
--
--  Copyright (C) 2012 Rob Doyle
--
-- This source file may be used and distributed without
-- restriction provided that this copyright statement is not
-- removed from the file and that any derivative work contains
-- the original copyright notice and the associated disclaimer.
--
-- This source file is free software; you can redistribute it
-- and/or modify it under the terms of the GNU Lesser General
-- Public License as published by the Free Software Foundation;
-- version 2.1 of the License.
--
-- This source is distributed in the hope that it will be
-- useful, but WITHOUT ANY WARRANTY; without even the implied
-- warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
-- PURPOSE. See the GNU Lesser General Public License for more
-- details.
--
-- You should have received a copy of the GNU Lesser General
-- Public License along with this source; if not, download it
-- from http://www.gnu.org/licenses/lgpl.txt
--
--------------------------------------------------------------------
--
-- Comments are formatted for doxygen
-- */



//--
// RK8E Secure Digital SPI Interface Entity
// --
`include "../FPGA_image/HX_clock.v"
`include "../parameters.v"

   parameter slow_dev = $rtoi(clock_frequency/(slow_spi*2));
   parameter nu_divcnt_bits = $clog2(slow_dev);
   parameter SlowDiv = slow_dev[nu_divcnt_bits-1:0];
   parameter fast_dev = $rtoi(clock_frequency/(fast_spi*2));
   parameter FastDiv = fast_dev[nu_divcnt_bits-1:0];
   parameter LoSpiFreq = clock_frequency/(SlowDiv*2);
   parameter HiSpiFreq = clock_frequency/(FastDiv*2);



module sdspi
  import sdspi_types::*;
  import sd_types::*;
(
    input  logic    clk,      // Clock/Reset
    input  logic    rst,
    input  spiOP_t  spiOP,    // Operation */
    input  sdBYTE_t spiTXD,   // Transmit Data */
    output sdBYTE_t spiRXD,   // Receive Data */
    input  logic    spiMISO,  // Data In
    output reg      spiMOSI,  // Data Out
    output reg      spiSCLK,  // Clock
    output reg      spiCS,    // Chip Select
    output reg      spiDONE   // Done */

);


  // RK8E Secure Digital SPI Interface RTL

  typedef enum logic [2:0] {
    stateRESET,
    stateIDLE,
    stateTXH,
    stateTXL,
    stateTXM,
    stateTXN
  } state_t;
  state_t state;
  logic [2:0] bitcnt;
  sdBYTE_t txd;
  sdBYTE_t rxd;

  logic [nu_divcnt_bits-1:0] clkcnt, clkdiv;  // integer range 0 to 1024;
  //  logic [9:0] clkdiv;  // integer range 0 to 1024;
  //  localparam logic [9:0] SlowDiv = slow_div;
  //  localparam logic [9:0] FastDiv = fast_div;


  typedef enum logic [1:0] {
    sdopNOP,    // SD NOP
    sdopABORT,  // Abort Read or Write
    sdopRD,     // Read SD disk
    sdopWR
  } sdop_t;  // Write SD disk


  always @(posedge clk) begin
    if (rst == 1'b1) begin
      spiDONE <= 1'b0;
      txd     <= 8'b1;
      rxd     <= 8'b1;
      spiCS   <= 1'b1;
      bitcnt  <= 3'b0;
      clkcnt  <= 0;
      clkdiv  <= SlowDiv;
      state   <= stateRESET;
    end else
      case (state)
        stateRESET: begin
          clkdiv <= SlowDiv;
          state  <= stateIDLE;
        end
        stateIDLE: begin
          spiDONE <= 1'b0;
          case (spiOP)
            spiNOP:  ;
            spiCSL:  spiCS <= 1'b0;
            spiCSH:  spiCS <= 1'b1;
            spiFAST: clkdiv <= FastDiv;
            spiSLOW: clkdiv <= SlowDiv;
            spiTR: begin
              clkcnt <= clkdiv;
              bitcnt <= 3'd7;
              txd    <= spiTXD;
              state  <= stateTXL;
            end
            default: ;
          endcase
          ;
        end
        stateTXL:
        if (clkcnt == 0) begin
          clkcnt <= clkdiv;
          rxd    <= {rxd[1:7] , spiMISO};
          state  <= stateTXH;
        end else clkcnt <= clkcnt - 1;
        stateTXH:
        if (clkcnt == 0) begin
          if (bitcnt == 0) begin
            clkcnt <= clkdiv;
            state  <= stateTXM;
          end else begin
            clkcnt <= clkdiv;
            txd    <= {txd[1:7], 1'b1};
            bitcnt <= bitcnt - 1;
            state  <= stateTXL;
          end
        end else clkcnt <= clkcnt - 1;
        stateTXM:
        if (clkcnt == 0) begin
          clkcnt <= clkdiv;
          state  <= stateTXN;
        end else clkcnt <= clkcnt - 1;
        stateTXN:
        if (clkcnt == 0) begin
          clkcnt  <= clkdiv;
          spiDONE <= 1'b1;
          state   <= stateIDLE;
        end else clkcnt <= clkcnt - 1;
        default: ;
      endcase
    //end

    case (state)
      stateIDLE, stateTXH: spiSCLK <= 1'b1;
      stateTXN: spiSCLK <= 1'b1;
      stateTXL: spiSCLK <= 1'b0;
      default: spiSCLK <= 1'b1;
    endcase
    spiMOSI <= txd[0];
    spiRXD  <= rxd;
  end
endmodule

