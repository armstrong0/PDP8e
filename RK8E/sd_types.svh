//-------------------------------------------------------------------
//
// PDP-8 Processor
//
// \brief
//      RK8E Secure Digital Interface Type Definitions
//
// \details
//      This package contains all the type information that is
//      required to use the Secure Digital Disk Interface
//
// \file
//      sd_types.vhd
//
// \author
//      Rob Doyle - doyle (at) cox (dot) net
//
//--------------------------------------------------------------------
/* --
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
--*/

/* translatted from VHDL to SystemVerilog by D.B. Armstrong Apr ,12, 2023 */

// RK8E Secure Digital Interface Type Definition Package
/* verilator lint_off LITENDIAN */
package sd_types;

  // Types
  typedef logic [0:7] sdBYTE_t;  // Byte
  typedef sdBYTE_t [0:5] sdCMD_t;  // SD Commands
  typedef logic sdLEN_t;  // Read/Write Length
  typedef logic [0:14] addr_t;  // 15 bit memory address type
  // added because I did not want to import too many things
  typedef logic [0:31] sdDISKaddr_t;  // SD Sector Address
  typedef logic [0:6] sdCCRC_t;  // Command CRC
  typedef logic [0:15] sdDCRC_t;  // Data CRC

  typedef enum logic [1:0] {
    sdopNOP,    // SD NOP
    sdopABORT,  // Abort Read or Write
    sdopRD,     // Read SD disk
    sdopWR      // write to disk
  } sdOP_t;
  typedef enum logic [2:0] {
    sdstateINIT,    // SD Initializing
    sdstateREADY,   // SD Ready for commands
    sdstateREAD,    // SD Reading
    sdstateWRITE,   // SD Writing
    sdstateDONE,    // SD Done
    sdstateINFAIL,  // SD Initialization Failed
    sdstateRWFAIL
  }  // SD Read/Write Failed
  sdSTATE_t;
  typedef struct packed {
    sdSTATE_t state;  // SD Status
    sdBYTE_t  err;    // Error Status
    sdBYTE_t  val;    // Value Status
    sdBYTE_t  rdCNT;  // Read Count Status
    sdBYTE_t  wrCNT;  // Write Count Status
    sdBYTE_t  debug;
  } sdSTAT_t;  // Debug State

  // Functions

  function sdCCRC_t crc7(sdBYTE_t indat, sdCCRC_t crc);
    begin
      crc7[0] = crc[4] ^ crc[1] ^ crc[0] ^ indat[4] ^ indat[1] ^ indat[0];
      crc7[1] = crc[5] ^ crc[2] ^ crc[1] ^ indat[5] ^ indat[2] ^ indat[1];
      crc7[2] = crc[6] ^ crc[3] ^ crc[2] ^ indat[6] ^ indat[3] ^ indat[2];
      crc7[3] = crc[4] ^ crc[3] ^ indat[7] ^ indat[4] ^ indat[3];
      crc7[4] = crc[5] ^ crc[1] ^ indat[5] ^ indat[1];
      crc7[5] = crc[6] ^ crc[2] ^ indat[6] ^ indat[2];
      crc7[6] = crc[3] ^ crc[0] ^ indat[7] ^ indat[3] ^ indat[0];
    end
    // crc7 = crc16;
  endfunction

  function sdDCRC_t crc16(sdBYTE_t indat, sdDCRC_t crc);
    begin
      crc16[0] = crc[8] ^ crc[4] ^ crc[0] ^ indat[4] ^ indat[0];
      crc16[1] = crc[9] ^ crc[5] ^ crc[1] ^ indat[5] ^ indat[1];
      crc16[2] = crc[10] ^ crc[6] ^ crc[2] ^ indat[6] ^ indat[2];
      crc16[3] = crc[11] ^ crc[7] ^ crc[3] ^ crc[0] ^ indat[7] ^ indat[3] ^ indat[0];
      crc16[4] = crc[12] ^ crc[1] ^ indat[1];
      crc16[5] = crc[13] ^ crc[2] ^ indat[2];
      crc16[6] = crc[14] ^ crc[3] ^ indat[3];
      crc16[7] = crc[15] ^ crc[4] ^ crc[0] ^ indat[3] ^ indat[0];
      crc16[8] = crc[5] ^ crc[1] ^ crc[0] ^ indat[5] ^ indat[1] ^ indat[0];
      crc16[9] = crc[6] ^ crc[2] ^ crc[1] ^ indat[6] ^ indat[2] ^ indat[1];
      crc16[10] = crc[7] ^ crc[3] ^ crc[2] ^ indat[7] ^ indat[3] ^ indat[2];
      crc16[11] = crc[3] ^ indat[3];
      crc16[12] = crc[4] ^ crc[0] ^ indat[4] ^ indat[0];
      crc16[13] = crc[5] ^ crc[1] ^ indat[5] ^ indat[1];
      crc16[14] = crc[6] ^ crc[2] ^ indat[6] ^ indat[2];
      crc16[15] = crc[7] ^ crc[3] ^ indat[7] ^ indat[3];
      crc16 = crc16;
    end
  endfunction

endpackage
