/*
////////////////////////////////////////////////////////////////////
//!
//! PDP-8 Processor
//!
//! \brief
//!      RK8E Secure Digital Interface
//!
//! \details
//!      The SD Interface reads or writes a 256 word (512 byte)
//!      sector to the SD device.  This interfaces uses a
//!      SPI interface (implemented independantly) to communicate
//!      with the SD device.
//!
//!      The RK8E controller has a LEN bit in the Command Register
//!      which causes the controller to perform a 128 word (256 byte)
//!      disk operation.   This eventually drives the sdLEN pin
//!      of this entity.
//!
//!      Section 11.14.7.11 of the External Bus Options Maintenance
//!      Manual Volume 3 says the following:
//!
//! \code
//!      If the RK8-E has been instructed to write 128 words,
//!      128th word is asserted after 128 words (half block)
//!      have been transferred.   The 128th word ends data
//!      transfer operations  and  the disk reads or writes zeros
//!      until the full block of data (256 words) has been read
//!      or written.
//! \endcode
//!
//!      It is fortunate that the controller works as described
//!      above because interactions between the controller and
//!      the SD disk are always 256 words (512 bytes).  The SD
//!      device cannot support 128 word (256 byte) transfers.
//!
//! \file
//!      sd.vhd
//!
//! \author
//!      Rob Doyle - doyle (at) cox (dot) net
//!
////////////////////////////////////////////////////////////////////
//
//  Copyright (C) 2012 Rob Doyle
//
// This source file may be used  and  distributed without
// restriction provided that this copyright statement is not
// removed from the file  and  that any derivative work contains
// the original copyright notice  and  the associated disclaimer.
//
// This source file is free software; you can redistribute it
// and/or modify it under the terms of the GNU Lesser General
// Public License as published by the Free Software Foundation;
// version 2.1 of the License.
//
// This source is distributed in the hope that it will be
// useful, but WITHOUT ANY WARRANTY; without even the implied
// warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
// PURPOSE. See the GNU Lesser General Public License for more
// details.
//
// You should have received a copy of the GNU Lesser General
// Public License along with this source; if not, download it
// from http://www.gnu.org/licenses/lgpl.txt
//
////////////////////////////////////////////////////////////////////
//
// Comments are formatted for doxygen
//
*/
/* translated to systemverilog dba April 14, 2023 */

//! RK8E Secure Digital Interface Entity

`include "../parameters.v"

module sd
  import sdspi_types::*;
  import sd_types::*;
(
    /* verilator lint_off LITENDIAN */
    input                      clk,
    input                      reset,       //! Clock/Reset
    input                      clear,       //! IOCLR
    // PDP8 Interface
    input               [0:11] dmaDIN,      //! DMA Data Into Disk
    output reg          [0:11] dmaDOUT,     //! DMA Data Out of Disk
    output reg          [0:14] dmaADDR,     //! DMA Address
    output reg                 dmaRD,       //! DMA Read
    output reg                 dmaWR,       //! DMA Write
    output reg                 dmaREQ,      //! DMA Request
    input                      dmaGNT,      //! DMA Grant
    // Interface to SD Hardware
    input                      sdMISO,      //! SD Data In
    output reg                 sdMOSI,      //! SD Data Out
    output reg                 sdSCLK,      //! SD Clock
    output reg                 sdCS,        //! SD Chip Select
    // RK8E Interface
    input  sdOP_t              sdOP,        //! SD OP
    input               [0:14] sdMEMaddr,   //! Memory Address
    input  sdDISKaddr_t        sdDISKaddr,  //! Disk Address
    input                      sdLEN,       //! Sector Length
    output sdSTAT_t            sdSTAT      //! Status
);


  //
  //! SDSPI Instance
  //

  sdspi SDSPI (
      .rst (reset),
      .clk   (clk),
      .spiOP   (spiOP),
      .spiTXD  (spiTXD),
      .spiRXD  (spiRXD),
      .spiMISO (sdMISO),
      .spiMOSI (sdMOSI),
      .spiSCLK (sdSCLK),
      .spiCS   (sdCS),
      .spiDONE (spiDONE)
  );


  //
  //! RK8E Secure Digital Interface RTL

  // Sending leading 0xff just sends clocks with data parked.
  //

  sdCMD_t sdCMD0 = '{8'h40, 8'h00, 8'h00, 8'h00, 8'h00, 8'h95};
  sdCMD_t sdCMD8 = '{8'h48, 8'h00, 8'h00, 8'h01, 8'haa, 8'h87};
  sdCMD_t sdCMD13 = '{8'h4d, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};
  sdCMD_t sdACMD41 = '{8'h69, 8'h40, 8'h00, 8'h00, 8'h00, 8'hff};
  sdCMD_t sdCMD55 = '{8'h77, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};
  sdCMD_t sdCMD58 = '{8'h7a, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};

  typedef enum logic [5:0] {
    stateRESET,
    // Init States
    stateINIT00,
    stateINIT01,
    stateINIT02,
    stateINIT03,
    stateINIT04,
    stateINIT05,
    stateINIT06,
    stateINIT07,
    stateINIT08,
    stateINIT09,
    stateINIT10,
    stateINIT11,
    stateINIT12,
    stateINIT13,
    stateINIT14,
    stateINIT15,
    stateINIT16,
    stateINIT17,
    // Read States
    stateREAD00,
    stateREAD01,
    stateREAD02,
    stateREAD03,
    stateREAD04,
    stateREAD05,
    stateREAD06,
    stateREAD07,
    stateREAD08,
    stateREAD09,
    // Write States
    stateWRITE00,
    stateWRITE01,
    stateWRITE02,
    stateWRITE03,
    stateWRITE04,
    stateWRITE05,
    stateWRITE06,
    stateWRITE07,
    stateWRITE08,
    stateWRITE09,
    stateWRITE10,
    stateWRITE11,
    stateWRITE12,
    stateWRITE13,
    stateWRITE14,
    stateWRITE15,
    stateWRITE16,
    // Other States
    stateFINI,
    stateIDLE,
    stateDONE,
    stateINFAIL,
    stateRWFAIL
  } state_t;

  state_t state;  //! Current State
  spiOP_t spiOP;  //! SPI Op
  wire sdBYTE_t spiRXD;  //! SPI Received Dataa
  sdBYTE_t spiTXD;  //! SPI Transmit Data
  wire spiDONE;  //! Asserted  SPI is done
  logic [11:0] bytecnt;  //! Byte Counter
  sdCMD_t sdCMD17;  //! CMD17
  sdCMD_t sdCMD24;  //! CMD24
  addr_t memADDR;  //! Memory Address
  logic [0:3] memBUF;  //! Memory Buffer
  logic memREQ;  //! DMA Request
  logic abort;  //! Abort this command
  sdBYTE_t rdCNT;  //! Read Counter
  sdBYTE_t wrCNT;  //! Write Counter
  sdBYTE_t err;  //! Error State
  sdBYTE_t val;  //! Error Value
  sdSTATE_t sdSTATE;  //! State
  localparam logic [11:0] nCR = 8;  //! NCR from SD Spec 
  localparam logic [11:0] nAC = 1023;  //! NAC from SD Spec
  localparam logic [11:0] nWR = 20;  //! NWR from SD Spec



  //!
  //! SD_STATE:
  //! This process assumes a 50 MHz clock
  //! Now calculates timout based on logic clock from paramters.v maybe

  always @(posedge clk) begin

    if ((reset == 1'b1 | clear == 1)) begin
      err     <= 8'b0;
      val     <= 8'b0;
      rdCNT   <= 8'b0;
      wrCNT   <= 8'b0;
      bytecnt <= 0;
      dmaRD   <= 1'b0;
      dmaWR   <= 1'b0;
      memREQ  <= 1'b0;
      memBUF  <= 4'b0;
      memADDR <= 15'b0;
      dmaDOUT <= 12'b0;
      spiTXD  <= 8'b0;
      sdCMD17 <= '{8'h51, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};
      sdCMD24 <= '{8'h58, 8'h00, 8'h00, 8'h00, 8'h00, 8'hff};
      abort   <= 1'b0;
      bytecnt <= 0;
      spiOP   <= spiCSH;
      sdSTATE <= sdstateINIT;
      state   <= stateRESET;
    end else begin

      dmaRD <= 1'b0;
      dmaWR <= 1'b0;
      spiOP <= spiNOP;

      if ((sdOP == sdopABORT) && (state != stateIDLE)) abort <= 1'b1;

      case (state)

        //
        // stateRESET:
        //
        default: ;

        stateRESET: begin
          bytecnt <= 0;
          state   <= stateINIT00;
        end
        //
        // stateINIT00
        //  Send 8x8 clocks cycles
        //  Spec says 74 clocks, this should be 8 + 4 =12 bytes
        //  8 clocks per byte - 96 clocks
        //

        stateINIT00: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 12) begin
              bytecnt <= 0;
              spiOP   <= spiCSL;
              state   <= stateINIT01;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateINIT01:
        //  Send GO_IDLE_STATE command (CMD0)
        //

        stateINIT01: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateINIT02;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD0[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateINIT02:
        //  Read R1 Response from CMD0
        //  Response should be 8'h01
        //

        stateINIT02: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                state   <= stateRESET;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              spiOP   <= spiCSH;
              bytecnt <= 0;
              if (spiRXD == 8'h01) state <= stateINIT03;
              else state <= stateRESET;
            end
          end
        end



        //
        // stateINIT03:
        //  Send 8 clock cycles
        //

        stateINIT03: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            spiOP   <= spiCSL;
            bytecnt <= 0;
            state   <= stateINIT04;
          end
        end

        //
        // stateINIT04:
        //   Send SEND_IF_COND (CMD8)
        //

        stateINIT04: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateINIT05;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD8[bytecnt];
              bytecnt <= bytecnt + 1;
            end

        end

        //
        // stateINIT05
        //  Read first byte R1 of R7 Response
        //  Response should be 8'h01 for V2.00 initialization or
        //  8'h05 for V1.00 initialization.
        //

        stateINIT05: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)

              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h01;
                state   <= stateINFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              bytecnt <= 0;
              if (spiRXD == 8'h01) state <= stateINIT06;
              else if (spiRXD <= 8'h05) begin
                err   <= 8'h02;
                state <= stateINFAIL;
              end else begin
                spiOP <= spiCSH;
                err   <= 8'h03; // fail version 1
                state <= stateINFAIL;
              end
            end
        end

        //
        // stateINIT06
        //  Read 32-bit Response to CMD8
        //  Response should be 8'h00_00_01_aa"
        //    8'h01 - Voltage
        //    8'h55 - Pattern
        //

        stateINIT06: begin
          case (bytecnt)
            0: begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 1;
            end
            1: begin
              if (spiDONE == 1'b1)
                if (spiRXD == 8'h00) begin
                  spiOP   <= spiTR;
                  spiTXD  <= 8'hff;
                  bytecnt <= 2;
                end else begin
                  err   <= 8'h04;
                  state <= stateINFAIL;
                end
            end
            2:
            if (spiDONE == 1'b1)
              if (spiRXD == 8'h00) begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= 3;
              end else begin
                err <= 8'h05;
                state <= stateINFAIL;
              end

            3:
            if (spiDONE == 1'b1)
              if (spiRXD == 8'h01) begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= 4;
              end else begin
                err   <= 8'h06;
                state <= stateINFAIL;
              end
            4:
            if (spiDONE == 1'b1)
              if (spiRXD == 8'haa) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                state   <= stateINIT07;
              end else begin
                err   <= 8'h07;
                state <= stateINFAIL;
              end
            default: ;
          endcase
        end


        //
        // stateINIT07:
        //  Send 8 clock cycles
        //

        stateINIT07: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            spiOP   <= spiCSL;
            bytecnt <= 0;
            state   <= stateINIT08;
          end
        end

        //
        // stateINIT08:
        //   Send APP_CMD (CMD55)
        //

        stateINIT08: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateINIT09;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD55[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateINIT09:
        //  Read R1 response from CMD55.
        //  Response should be 8'h01
        //

        stateINIT09: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h08;
                state   <= stateINFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              spiOP   <= spiCSH;
              bytecnt <= 0;
              if (spiRXD == 8'h01) state <= stateINIT10;
              else state <= stateINIT07;
            end
        end

        //
        // stateINIT10:
        //  Send 8 clock cycles
        //

        stateINIT10: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            spiOP   <= spiCSL;
            bytecnt <= 0;
            state   <= stateINIT11;
          end
        end

        //
        // stateINIT11:
        //  Send SD_SEND_OP_COND (ACMD41)
        //

        stateINIT11: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateINIT12;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdACMD41[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateINIT12:
        //  Read R1 response from ACMD41.
        //  Response should be 8'h00
        //

        stateINIT12: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h09;
                state   <= stateINFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              spiOP   <= spiCSH;
              bytecnt <= 0;
              if (spiRXD == 8'h00) state <= stateINIT13;
              else state <= stateINIT07;
            end
        end



        //
        // stateINIT13
        //  Send 8 clock cycles
        //

        stateINIT13: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            spiOP   <= spiCSL;
            bytecnt <= 0;
            state   <= stateINIT14;
          end
        end

        //
        // stateINIT14:
        //  Send READ_OCR (CMD58)
        //

        stateINIT14: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateINIT15;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD58[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end
        //
        // stateINIT15
        //  Read first byte of R3 response to CMD58
        //  Response should be 8'h00
        //

        stateINIT15: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h0a;
                state   <= stateINFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              bytecnt <= 0;
              if (spiRXD == 8'h00) state <= stateINIT16;
              else begin
                spiOP <= spiCSH;
                err   <= 8'h0b;
                state <= stateINFAIL;
              end
            end
        end


        //
        // stateINIT16
        //  Response should be "e0_ff_80_00"
        //  Read 32-bit OCR response to CMD58
        //

        stateINIT16: begin
          case (bytecnt)
            0: begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 1;
            end
            1: begin
              if (spiDONE == 1'b1) begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= 2;
              end
            end
            2:
            if (spiDONE == 1'b1) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 3;
            end
            3:
            if (spiDONE == 1'b1) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 4;
            end
            4:
            if (spiDONE == 1'b1) begin
              spiOP   <= spiCSH;
              bytecnt <= 0;
              state   <= stateINIT17;
            end
            default: ;
          endcase
        end

        //
        // stateINIT17:
        //  Send 8 clock cycles
        //

        stateINIT17: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            bytecnt <= 0;
            spiOP   <= spiFAST;
            state   <= stateIDLE;
          end
        end

        //
        // stateIDLE:
        //  Wait for a command to process.
        //  Once the SD card is initialized, it waits in this state
        //  for either a read (sdopRD) or a write (sdopWR) command.
        //

        stateIDLE: begin
          abort   <= 1'b0;
          sdSTATE <= sdstateREADY;
          case (sdOP)
            sdopNOP: state <= stateIDLE;
            sdopRD: begin
              rdCNT <= rdCNT + 1;
              state <= stateREAD00;
            end
            sdopWR: begin
              wrCNT <= wrCNT + 1;
              state <= stateWRITE00;
            end
            default: state <= stateIDLE;
          endcase
        end

        //
        // stateREAD00:
        //  Setup Read Single Block (CMD17)
        //

        stateREAD00: begin
          sdSTATE    <= sdstateREAD;
          memADDR    <= sdMEMaddr;
          sdCMD17[0] <= 8'h51;
          sdCMD17[1] <= sdDISKaddr[0:7];
          sdCMD17[2] <= sdDISKaddr[8:15];
          sdCMD17[3] <= sdDISKaddr[16:23];
          sdCMD17[4] <= sdDISKaddr[24:31];
          sdCMD17[5] <= 8'hff;
          bytecnt    <= 0;
          spiOP      <= spiCSL;
          state      <= stateREAD01;
        end

        //
        // stateREAD01:
        //  Send Read Single Block (CMD17)
        //

        stateREAD01: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateREAD02;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD17[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateREAD02:
        //  Read R1 response from CMD17
        //  Response should be 8'h00
        //

        stateREAD02: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h0c;
                sdSTATE <= sdstateRWFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              bytecnt <= 0;
              if (spiRXD == 8'h00) state <= stateREAD03;
              else begin
                spiOP <= spiCSH;
                err <= 8'h0d;
                sdSTATE <= sdstateRWFAIL;
              end
            end
        end

        //
        // stateREAD03:
        //  Find 'Read Start token' which should be 8'hfe
        //

        stateREAD03: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nAC) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h0e;
                sdSTATE <= sdstateRWFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              bytecnt <= 0;
              if (spiRXD == 8'hfe) state <= stateREAD04;
              else begin
                spiOP <= spiCSH;
                err <= 8'h0f;
                val <= spiRXD;
                sdSTATE <= sdstateRWFAIL;
              end
            end
        end

        //
        // stateREAD04:
        //  Acquire DMA.  Setup for loop.
        //

        stateREAD04: begin
          memREQ <= 1'b1;
          if (dmaGNT == 1'b1) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 0;
            state   <= stateREAD05;
          end
        end

        //
        // stateREAD05:
        //  Read LSBYTE of data from disk (even addresses)
        //  Loop destination
        //

        stateREAD05: begin
          if (spiDONE == 1'b1) begin
            spiOP <= spiTR;
            spiTXD <= 8'hff;
            bytecnt <= bytecnt + 1;
            dmaDOUT[4:11] <= spiRXD[0:7];
            state <= stateREAD06;
          end
        end

        //
        // stateREAD06:
        //  Read MSBYTE of data from disk (odd addresses).
        //  Discard the top four bits forming a 12-bit word
        //  from the two bytes.
        //

        stateREAD06: begin
          if (spiDONE == 1'b1) begin
            spiOP <= spiTR;
            spiTXD <= 8'hff;
            dmaDOUT[0:3] <= spiRXD[4:7];
            state <= stateREAD07;
          end
        end


        //
        // stateREAD07:
        //  Write disk data to memory.
        //  If memREQ is not asserted, we are reading the second
        //  128 words of a 128 word read.  Notice no DMA occurs
        //  to memory  and  the bits are dropped.
        //

        stateREAD07: begin
          if (memREQ == 1'b1) dmaWR <= 1'b1;
          state <= stateREAD08;
        end

        //
        // stateREAD08:
        //  This state checks the loop conditions:
        //  1.  An abort command causes the loop to terminate immediately.
        //  2.  If sdLEN is asserted (128 word read) at byte 255,
        //      the memory write DMA request is dropped.  The DMA address
        //      stops incrementing.  The state machine continues to read
        //      all 256 words (512 bytes).
        //  3.  At word 256 (byte 512), the loop terminates.
        //

        stateREAD08: begin
          if (abort == 1'b1) begin
            memREQ  <= 1'b0;
            spiOP   <= spiCSH;
            bytecnt <= 0;
            state   <= stateFINI;
          end else if (bytecnt == 511) begin
            memREQ  <= 1'b0;
            memADDR <= memADDR + 1;
            bytecnt <= 0;
            state   <= stateREAD09;
          end else if ((bytecnt >= 255) && (sdLEN == 1'b1)) begin
            memREQ  <= 1'b0;
            bytecnt <= bytecnt + 1;
            state   <= stateREAD05;
          end else begin
            memADDR <= memADDR + 1;
            bytecnt <= bytecnt + 1;
            state   <= stateREAD05;
          end
        end

        //
        // stateREAD09:
        //  Read 2 bytes of CRC which is required for the SD Card.
        //

        stateREAD09: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (bytecnt != 8) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= bytecnt +1 ;
            end else if (bytecnt == 8) begin
              spiOP   <= spiCSH;
              bytecnt <= 0;
              state   <= stateFINI;
            end
        end

        //
        // stateWRITE00:
        //  Setup Write Single Block (CMD24)
        //

        stateWRITE00: begin
          sdSTATE    <= sdstateWRITE;
          memADDR    <= sdMEMaddr;
          sdCMD24[0] <= 8'h58;
          sdCMD24[1] <= sdDISKaddr[0:7];
          sdCMD24[2] <= sdDISKaddr[8:15];
          sdCMD24[3] <= sdDISKaddr[16:23];
          sdCMD24[4] <= sdDISKaddr[24:31];
          sdCMD24[5] <= 8'hff;
          bytecnt    <= 0;
          spiOP      <= spiCSL;
          state      <= stateWRITE01;
        end

        //
        // stateWRITE01:
        //  Send Write Single Block (CMD24)
        //

        stateWRITE01: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              bytecnt <= 0;
              state   <= stateWRITE02;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD24[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateWRITE02:
        //  Read R1 response from CMD24
        //  Response should be 8'h00
        //

        stateWRITE02: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h10;
                state   <= stateRWFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else begin
              bytecnt <= 0;
              if (spiRXD == 8'h00) state <= stateWRITE03;
              else begin
                spiOP <= spiCSH;
                val   <= spiRXD;
                err   <= 8'h11;
                state <= stateRWFAIL;
              end
            end
        end

        //
        // stateWRITE03:
        //  Send 8 clock cycles
        //

        stateWRITE03: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
          end else if (spiDONE == 1'b1) begin
            bytecnt <= 0;
            state   <= stateWRITE04;
          end
        end

        //
        // stateWRITE04:
        //  Send "Write Start Token".  The write start token is 8'hfe
        //

        stateWRITE04: begin
          if (bytecnt == 0) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hfe;
            bytecnt <= 1;

            memREQ  <= 1'b1;  // moved one state earlier
          end else if (spiDONE == 1'b1) begin
            bytecnt <= 0;
            state   <= stateWRITE05;
          end
        end

        //
        // stateWRITE05:
        //  Start a DMA Read Address Cycle
        //

        stateWRITE05: begin
          //memREQ <= 1'b1;
          if (dmaGNT == 1'b1) state <= stateWRITE06;
        end

        //
        // stateWRITE06:
        //  Loop destination
        //  This is the data phase of the read cycle.
        //  If memREQ is not asserted, we are writing the second
        //  128 words of a 128 word write.  Notice no DMA occurs.
        //

        stateWRITE06: begin
          if (memREQ == 1'b1) dmaRD <= 1'b1;
          state <= stateWRITE07;
        end

        //
        // stateWRITE07:
        //  Write LSBYTE of data to disk (even addresses)
        //   This state has two modes:
        //    If memREQ is asserted we are operating normally.
        //    If memREQ is negated we are writing the last 128
        //     words of a 128 word operation.  Therefore we
        //     write zeros.  See file header.
        //

        stateWRITE07: begin
          spiOP <= spiTR;
          if (memREQ == 1'b1) begin
            memBUF <= dmaDIN[0:3];
            spiTXD <= dmaDIN[4:11];
          end else begin
            memBUF <= 4'b0000;
            spiTXD <= 8'b0000_0000;
          end
          state <= stateWRITE08;
        end

        //
        // stateWRITE08:
        //  Write MSBYTE of data to disk (odd addresses)
        //  Note:  The top 4 bits of the MSBYTE are zero.
        //

        stateWRITE08:
        if (spiDONE == 1'b1) begin
          spiOP   <= spiTR;
          spiTXD  <= {4'b0000, memBUF};
          bytecnt <= bytecnt + 1;
          state   <= stateWRITE09;
        end

        //
        // stateWRITE09:
        //  This is the addr phase of the read cycle.
        //

        stateWRITE09: begin
          if (spiDONE == 1'b1)
            if (abort == 1'b1) begin
              memREQ  <= 1'b0;
              spiOP   <= spiCSH;
              bytecnt <= 0;
              state   <= stateFINI;
            end else if (bytecnt == 511) begin
              memREQ  <= 1'b0;
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 0;
              memADDR <= memADDR + 1;
              state   <= stateWRITE10;
            end else if ((bytecnt == 255) && (sdLEN == 1'b1)) begin
              memREQ  <= 1'b0;
              // the folowing line was commented out as we want CS low to
              // write the next 128 16 bit zero words and then teminate
              // normally DBA April 7, 2023
              // spiOP   <= spiCSH;
              bytecnt <= bytecnt + 1;
              state   <= stateWRITE06;
            end else begin
              bytecnt <= bytecnt + 1;
              memADDR <= memADDR + 1;
              state   <= stateWRITE06;
            end
        end

        //
        // stateWRITE10:
        //  Write CRC bytes
        //

        stateWRITE10: begin
          if (spiDONE == 1'b1)
            if (bytecnt == 0) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 1;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 0;
              state   <= stateWRITE11;
            end
        end

        //
        // stateWRITE11:
        //  Read Data Response.  The response is is one byte long
        //    and  has the following format:
        //
        //   xxx0sss1
        //
        //    Where x is don't-care  and  sss is a 3-bit status field.
        //     010 is accepted,
        //     101 is rejected due to CRC error and
        //     110 is rejected due to write error.
        //

        stateWRITE11: begin
          if (spiDONE == 1'b1)
            if (spiRXD[3:7] == 5'b0_010_1) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 0;
              state   <= stateWRITE12;
            end else begin
              spiOP   <= spiCSH;
              val     <= spiRXD;
              err     <= 8'h12;
              bytecnt <= 0;
              state   <= stateRWFAIL;
            end
        end

        //
        // stateWRITE12:
        //  Wait for busy token to clear.   The disk reports
        //  all zeros while the write is occurring.
        //

        stateWRITE12: begin
          if (spiDONE == 1'b1)
            if (spiRXD == 8'h00) begin
              if (bytecnt == 4095) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h13;
                state   <= stateRWFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            end else begin
              bytecnt <= 0;
              state   <= stateWRITE13;
            end
        end

        //
        // stateWRITE13:
        //  Send "Send Status" Command (CMD13)
        //

        stateWRITE13: begin
          if ((spiDONE == 1'b1) || (bytecnt == 0))
            if (bytecnt == 6) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 0;
              state   <= stateWRITE14;
            end else begin
              spiOP   <= spiTR;
              spiTXD  <= sdCMD13[bytecnt];
              bytecnt <= bytecnt + 1;
            end
        end

        //
        // stateWRITE14:
        //  Check first byte of CMD13 response
        //  Status:
        //   Bit 0: Zero
        //   Bit 1: Parameter Error
        //   Bit 2: Address Error
        //   Bit 3: Erase Sequence Error
        //   Bit 4: COM CRC Error
        //   Bit 5: Illegal Command
        //   Bit 6: Erase Reset
        //   Bit 7: Idle State
        //

        stateWRITE14: begin
          if (spiDONE == 1'b1)
            if (spiRXD == 8'hff)
              if (bytecnt == nCR) begin
                spiOP   <= spiCSH;
                bytecnt <= 0;
                err     <= 8'h14;
                state   <= stateRWFAIL;
              end else begin
                spiOP   <= spiTR;
                spiTXD  <= 8'hff;
                bytecnt <= bytecnt + 1;
              end
            else if ((spiRXD == 8'h00) || (spiRXD == 8'h01)) begin
              spiOP   <= spiTR;
              spiTXD  <= 8'hff;
              bytecnt <= 0;
              state   <= stateWRITE15;
            end else begin
              spiOP   <= spiCSH;
              bytecnt <= 0;
              val     <= spiRXD;
              err     <= 8'h15;
              state   <= stateRWFAIL;
            end
        end

        //
        // stateWRITE15:
        //  Check second byte of CMD13 response
        //  Status:
        //   Bit 0: Out of range
        //   Bit 1: Erase Param
        //   Bit 2: WP Violation
        //   Bit 3: ECC Error
        //   Bit 4: CC Error
        //   Bit 5: Error
        //   Bit 6: WP Erase Skip
        //   Bit 7: Card is locked
        //

        stateWRITE15:
        if (spiDONE == 1'b1)
          if (spiRXD == 8'h00) begin
            spiOP   <= spiTR;
            spiTXD  <= 8'hff;
            bytecnt <= 1;
            state   <= stateWRITE16;
          end else begin
            spiOP   <= spiCSH;
            bytecnt <= 0;
            val     <= spiRXD;
            err     <= 8'h16;
            state   <= stateRWFAIL;
          end


        //
        // stateWRITE16:
        //  Send 8 clock cycles.   Pull CS High.
        //

        stateWRITE16:
        if (spiDONE == 1'b1) begin
          spiOP   <= spiCSH;
          bytecnt <= 0;
          state   <= stateFINI;
        end

        //
        // stateFINI:
        //  Send 8 clock cycles
        //

        stateFINI:
        if (bytecnt == 0) begin
          spiOP   <= spiTR;
          spiTXD  <= 8'hff;
          bytecnt <= 1;
        end else if (spiDONE == 1'b1) begin
          bytecnt <= 0;
          state   <= stateDONE;
        end


        //
        // stateDONE:
        //

        stateDONE: begin
          sdSTATE <= sdstateDONE;
          state   <= stateIDLE;
        end

        //
        // stateINFAIL:
        //  Initialization failed somehow.
        //

        stateINFAIL: begin
          sdSTATE <= sdstateINFAIL;
          state   <= stateINFAIL;
        end

        //
        // stateRWFAIL:
        //  Read or Write failed somehow.
        //

        stateRWFAIL: begin
          sdSTATE <= sdstateRWFAIL;
          state   <= stateRWFAIL;
        end
        //default: state <= stateRESET;

      endcase




      /* //
      //! SDSPI Instance
      //

      sdspi SDSPI (
        .reset (reset),
        .clk   (clk),
        .spiOP   (spiOP),
        .spiTXD  (spiTXD),
        .spiRXD  (spiRXD),
        .spiMISO (sdMISO),
        .spiMOSI (sdMOSI),
        .spiSCLK (sdSCLK),
        .spiCS   (sdCS),
        .spiDONE (spiDONE)
      ); */

      case (state)
        stateINIT00:  sdSTAT.debug <= 8'b00000000;
        stateINIT01:  sdSTAT.debug <= 8'b0000_0001;
        stateINIT02:  sdSTAT.debug <= 8'b0000_0010;
        stateINIT03:  sdSTAT.debug <= 8'b0000_0011;
        stateINIT04:  sdSTAT.debug <= 8'b0000_0100;
        stateINIT05:  sdSTAT.debug <= 8'b0000_0101;
        stateINIT06:  sdSTAT.debug <= 8'b0000_0110;
        stateINIT07:  sdSTAT.debug <= 8'b0000_0111;
        stateINIT08:  sdSTAT.debug <= 8'b0000_1000;
        stateINIT09:  sdSTAT.debug <= 8'b0000_1001;
        stateINIT10:  sdSTAT.debug <= 8'b0000_1010;
        stateINIT11:  sdSTAT.debug <= 8'b0000_1011;
        stateINIT12:  sdSTAT.debug <= 8'b0000_1100;
        stateINIT13:  sdSTAT.debug <= 8'b0000_1101;
        stateINIT14:  sdSTAT.debug <= 8'b0000_1110;
        stateINIT15:  sdSTAT.debug <= 8'b0000_1111;
        stateINIT16:  sdSTAT.debug <= 8'b0001_0000;
        stateINIT17:  sdSTAT.debug <= 8'b0001_0001;
        // Read states
        stateREAD00:  sdSTAT.debug <= 8'b0010_0000;
        stateREAD01:  sdSTAT.debug <= 8'b0010_0001;
        stateREAD02:  sdSTAT.debug <= 8'b0010_0010;
        stateREAD03:  sdSTAT.debug <= 8'b0010_0011;
        stateREAD04:  sdSTAT.debug <= 8'b0010_0100;
        stateREAD05:  sdSTAT.debug <= 8'b0010_0101;
        stateREAD06:  sdSTAT.debug <= 8'b0010_0110;
        stateREAD07:  sdSTAT.debug <= 8'b0010_0110;
        stateREAD08:  sdSTAT.debug <= 8'b0010_0110;
        stateREAD09:  sdSTAT.debug <= 8'b0010_0110;
        // Write states
        stateWRITE00: sdSTAT.debug <= 8'b0011_0000;
        stateWRITE01: sdSTAT.debug <= 8'b0011_0001;
        stateWRITE02: sdSTAT.debug <= 8'b0011_0010;
        stateWRITE03: sdSTAT.debug <= 8'b0011_0011;
        stateWRITE04: sdSTAT.debug <= 8'b0011_0100;
        stateWRITE05: sdSTAT.debug <= 8'b0011_0101;
        stateWRITE06: sdSTAT.debug <= 8'b0011_0110;
        stateWRITE07: sdSTAT.debug <= 8'b0011_0111;
        stateWRITE08: sdSTAT.debug <= 8'b0011_1000;
        stateWRITE09: sdSTAT.debug <= 8'b0011_1001;
        stateWRITE10: sdSTAT.debug <= 8'b0011_1010;
        stateWRITE11: sdSTAT.debug <= 8'b0011_1010;
        stateWRITE12: sdSTAT.debug <= 8'b0011_1010;
        stateWRITE13: sdSTAT.debug <= 8'b0011_1010;
        stateWRITE14: sdSTAT.debug <= 8'b0011_1010;
        stateWRITE15: sdSTAT.debug <= 8'b0011_1010;
        stateWRITE16: sdSTAT.debug <= 8'b0011_1010;
        // Other states
        stateRESET:   sdSTAT.debug <= 8'b1111_0000;
        stateIDLE:    sdSTAT.debug <= 8'b1111_0001;
        stateINFAIL:  sdSTAT.debug <= 8'b1111_0010;
        stateRWFAIL:  sdSTAT.debug <= 8'b1111_0011;
        default:      sdSTAT.debug <= 8'b1111_0100;
      endcase
    end
    // asynchronous assignements to output signals
    dmaADDR      = memADDR;
    dmaREQ       = memREQ;
    sdSTAT.err   <= err;
    sdSTAT.val   <= val;
    sdSTAT.rdCNT <= rdCNT;
    sdSTAT.wrCNT <= wrCNT;
    sdSTAT.state <= sdSTATE;


  end
endmodule
