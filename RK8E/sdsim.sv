/*
//
// PDP-8 Processor
//
// \brief
//      SD Sim Testbench
//
// \details
//      Test Bench.
//
// \file
//      sdsim.vhd
//
// \author
//      Rob Doyle - doyle (at) cox (dot) net
//
//
    Copyright (C) 2012 Rob Doyle

   This source file may be used and distributed without
   restriction provided that this copyright statement is not
   removed from the file and that any derivative work contains
   the original copyright notice and the associated disclaimer.

   This source file is free software;you can redistribute it
   and/or modify it under the terms of the GNU Lesser General
   Public License as published by the Free Software Foundation;
   version 2.1 of the License.

   This source is distributed in the hope that it will be
   useful, but WITHOUT ANY WARRANTY;without even the implied
   warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
   PURPOSE. See the GNU Lesser General Public License for more
   details.

   You should have received a copy of the GNU Lesser General
   Public License along with this source;if not, download it
   from http://www.gnu.org/licenses/lgpl.tx


   Comments are formatted for doxygen

*/


// SDSIM Test Bench Behav

module sdsim (
    input  logic clk,
    reset,
    clear,
    sdCS,
    sdMOSI,
    sdSCLK,
    output logic sdMISO
);



  // SPI Simulation

  typedef logic [0:55] sdCMD_t;
  sdCMD_t spiRX;  //         
  sdCMD_t spiTX;  //        
  typedef enum logic [3:0] {
    stateRESET,
    stateRSP,
    stateREAD0,
    stateREAD1,
    stateREAD2,
    stateWRITE0,
    stateWRITE1,
    stateWRITE2,
    stateWRITE3,
    stateWRITE4
  } state_t;
  state_t        state;
  logic   [ 5:0] bitcnt;
  logic   [ 8:0] bytecnt;
  logic   [31:0] index;


  //   Disk Registers


  typedef logic [0:7] byte_t;

  typedef byte_t [0:3325951] image_t;  // reduced the image file size, so gtkwave 
  //doesn't segfault
  image_t image;
  logic [1:0] clkstat;
  integer c;
  int imageFILE;

  initial begin

    c = 0;
    // sdWP <= 1'b0;
    // read the image file
    $write("Reading Disk Image...");
    imageFILE = $fopen("../media/systemdisk.rk05", "r+b");
    c = $fread(image, imageFILE, 0, 256);
    $write("Done Reading Disk Image.");
    $display();
    $write("Read ");
    $write(c);
    $display(" bytes");


  end

  // SD Interface


  always @(posedge clk) begin
    if (reset == 1'b1) begin
      spiRX <= 8'hff;
      spiTX <= 56'hff_ff_ff_ff_ff_ff_ff;
      state <= stateRESET;
      index <= 0;
    end else begin  //if rising_edge(clk)
      clkstat <= {clkstat[0], sdSCLK};

      if (sdCS == 1'b1) spiRX <= 8'hff;
      else if (clkstat == 2'b01) spiRX <= {spiRX[1:55], sdMOSI};

      case (state)
        stateRESET:   // do intialization
          begin
          // CMD0:
          if (spiRX[0:7] == 8'h40) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 15;
              spiTX  <= 56'hff_01_ff_ff_ff_ff_ff;
              state  <= stateRSP;
            end
          end  // CMD8:
          else if (spiRX[0:7] == 8'h48) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 55;
              spiTX  <= 56'hff_01_00_00_01_aa_ff;
              state  <= stateRSP;
            end
          end  //  CMD13:
               //  Send Status
          else if (spiRX[0:7] == 8'h4d) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 39;
              spiTX  <= 56'hff_ff_00_00_ff_ff_ff;
              state  <= stateRSP;
            end
          end  // CMD17:
               // Read Single
          else if (spiRX[0:7] == 8'h51) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 47;
              spiTX  <= 56'hff_ff_00_ff_ff_fe_ff;
              index  <= spiRX[27:39] * 512;
              state  <= stateREAD0;
            end
          end  // CMD24:
               // Write Single
          else if (spiRX[0:7] == 8'h58) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 47;
              spiTX  <= 56'hff_ff_00_ff_ff_fe_ff;
              index  <= spiRX[27:39] * 512;
              state  <= stateWRITE0;
            end
          end  // ACMD41:
          else if (spiRX[0:7] == 8'h69) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 23;
              spiTX  <= 56'hff_00_ff_ff_ff_ff_ff;
              state  <= stateRSP;
            end
          end  // CMD55:
          else if (spiRX[8:15] == 8'h77) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 15;
              spiTX  <= 56'hff_01_ff_ff_ff_ff_ff;
              state  <= stateRSP;
            end
          end  // CMD58:
          else if (spiRX[0:7] == 8'h7a) begin
            if (clkstat == 2'b10) begin
              bitcnt <= 55;
              spiTX  <= 56'hff_00_e0_ff_80_00_ff;
              state  <= stateRSP;
            end
          end
        end
        //   Send Response:
        stateRSP:
        if (bitcnt == 0) begin
          state <= stateRESET;
        end else if (clkstat == 2'b10) begin
          bitcnt <= bitcnt - 1;
          spiTX  <= {spiTX[1:55], 1'b1};
        end

        //  stateREAD0:
        stateREAD0:
        if (clkstat == 2'b10) begin
          if (bitcnt == 0) begin
            bitcnt  <= 7;
            bytecnt <= 0;
            spiTX   <= {image[index], 48'h00_00_00_00_00_00};
            index   <= index + 1;
            state   <= stateREAD1;
          end else begin
            bitcnt <= bitcnt - 1;
            spiTX  <= {spiTX[1:55], 1'b1};
          end
        end
        //  stateREAD1
        stateREAD1:
        if (clkstat == 2'b10) begin
          if (sdCS == 1'b1) begin
            spiTX <= 56'hff_ff_ff_ff_ff_ff_ff;
            state <= stateRESET;
          end else if (bitcnt == 0) begin
            if (bytecnt == 511) begin
              bitcnt <= 15;
              spiTX  <= 56'hff_ff_ff_ff_ff_ff_ff;
              state  <= stateREAD2;
            end else begin
              bitcnt  <= 7;
              spiTX   <= {image[index], 48'h00_00_00_00_00_00};
              index   <= index + 1;
              bytecnt <= bytecnt + 1;

            end
          end else begin
            bitcnt <= bitcnt - 1;
            spiTX  <= {spiTX[1:55], 1'b1};
          end
        end
        //   stateREAD2:
        //   Send 2 CRC bytes
        stateREAD2:
        if (clkstat == 2'b10)
          if (bitcnt == 0) begin
            state <= stateRESET;
          end else begin
            bitcnt <= bitcnt - 1;
            spiTX  <= {spiTX[1:55], &1'b1};
          end
        // stateWRITE0:
        stateWRITE0:
        if (clkstat == 2'b10)
          if (bitcnt == 0) begin
            bitcnt <= 7;
            bytecnt <= 0;
            image[index] <= spiRX[48 : 55];
            spiTX <= 56'hff_ff_ff_ff_ff_ff_ff;
            index <= index + 1;
            state <= stateWRITE1;
          end else begin
            bitcnt <= bitcnt - 1;
            spiTX  <= {spiTX[1:55], 1'b1};
          end
        //   stateWRITE1
        stateWRITE1:
        if (clkstat == 2'b10)
          if (sdCS == 1'b1) begin
            spiTX <= 56'hff_ff_ff_ff_ff_ff_ff;
            state <= stateRESET;
          end else if (bitcnt == 0) begin
            if (bytecnt == 511) begin
              bitcnt <= 55;
              spiTX  <= 56'hff_05_00_00_00_00_ff;
              state  <= stateWRITE2;
            end else begin
              bitcnt <= 7;
              image[index] <= spiRX[48 : 55];
              spiTX <= 56'hff_ff_ff_ff_ff_ff_ff;
              index <= index + 1;
              bytecnt <= bytecnt + 1;
            end
          end else begin
            bitcnt <= bitcnt - 1;
            spiTX  <= {spiTX[1:55], 1'b1};
          end
        //   stateWRITE2:
        //   Write 2 CRC bytes plus some busy (zero) tokens
        stateWRITE2:
        if (clkstat == 2'b10) begin
          if ((bitcnt == 0) || (sdCS == 1'b1)) begin
            // bitcnt  <= 15;
            // bytecnt <= 0;
            // spiTX   <= 56'h00_ff_ff_ff_ff_ff_ff;
            state <= stateRESET;
          end else begin
            bitcnt <= bitcnt - 1;
            spiTX  <= {spiTX[1:55], 1'b1};
          end
        end

        default: ;
      endcase

    end
    sdMISO <= spiTX[0];

  end
endmodule

