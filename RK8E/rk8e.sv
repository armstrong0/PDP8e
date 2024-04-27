/* verilator lint_off LITENDIAN */

/* This module implements an RK8-E controller.  It is intended to interface to
 * a SD Card. The SD card will hold 4 RK05 disk packs. Each of which holds
 * about 1.6 mega words- roughly 2.4 megabytes.  */

/* ended up adding a comment so this file has a change in it. This is so I can
 * prevent git from deleting this file!!!  */
/* that didn't work git deleted the file AGAIN */

/* dba April 03, 2023 */
/* dba April 07, 2023 */
/* dba April 13, 2023 rename rk8e, changed to a sv file */
`include "sd_types.svh"
`include "sdspi_types.svh"



module rk8e
  import sd_types::*;
(
    input             clk,
    input             reset,
    input             clear,
    input      [0:11] instruction,
    input      [ 4:0] state,
    input      [0:11] ac,
    input             UF,
    output reg [0:11] disk_bus,       // input to the  CPU
    /* verilator lint_off SYMRSVDWORD */
    output reg        interrupt,
    /* verilator lint_on SYMRSVDWORD */
    output reg        data_break,
    output reg        to_disk,
    input             break_in_prog,
    output reg        skip,
    output reg [0:14] dmaAddr,
    input      [0:11] dmaDIN,
    output reg [0:11] dmaDOUT,
    // Interface to SD Hardware
    input             sdMISO,         //! SD Data In
    output reg        sdMOSI,         //! SD Data Out
    output reg        sdSCLK,         //! SD Clock
    output reg        sdCS            //! SD Chip Select

);

  wire                flag;
  reg          [ 3:0] toggle;
  reg          [0:11] cmd_reg;  // command register
  reg          [0:11] car;      // current address register
  reg          [0:11] dar;      // disk address  
  reg          [0:11] status;   // status register
  logic               sd_reset; // delayed reset deassertion for the sd card


  // need a write protect for each drive
  reg          [ 0:3] write_lock;
  reg                 disk_flag;
  reg                 sint_ena;
  reg                 dmaGNT;
  sdOP_t              sdOP;
  sdDISKaddr_t        sdDISKaddr;  //! Disk Address
  wire         [0:14] dmaADDR;     //! DMA Address
  wire dmaRD, dmaWR, dmaREQ;
  logic        [0:14] sdMEMaddr;   //! Memory Address
  logic               sdLEN;       //! Sector Length
  sdSTAT_t            sdSTAT;      //! Status

  sdSTATE_t           sdstate;
  sdSTATE_t           last_sdstate;

  assign sdLEN = cmd_reg[5];

  sd SD (
      .clk       (clk),
      .reset     (sd_reset),    //! Clock/Reset
      .clear     (clear),       //! IOCLR
      // PDP8 Interface
      .dmaDIN    (dmaDIN),      //! DMA Data Into Disk
      .dmaDOUT   (dmaDOUT),     //! DMA Data Out of Disk
      .dmaADDR   (dmaADDR),     //! DMA Address
      .dmaRD     (dmaRD),       //! DMA Read
      .dmaWR     (dmaWR),       //! DMA Write
      .dmaREQ    (dmaREQ),      //! DMA Request
      .dmaGNT    (dmaGNT),      //! DMA Grant
      // Interface to SD Hardware
      .sdMISO    (sdMISO),      //! SD Data In
      .sdMOSI    (sdMOSI),      //! SD Data Out
      .sdSCLK    (sdSCLK),      //! SD Clock
      .sdCS      (sdCS),        //! SD Chip Select
      // RK8E Interface
      .sdOP      (sdOP),        //! SD OP
      .sdMEMaddr (sdMEMaddr),   //! Memory Address
      .sdDISKaddr(sdDISKaddr),  //! Disk Address
      .sdLEN     (sdLEN),       //! Sector Length
      .sdSTAT    (sdSTAT)
  );  //! Status


  `include "../parameters.v"
  /* Status Register bit assignment
bit 0 0= busy 1 = done
bit 1 0 stationary 1 head in motion  - always 0
bit 2 unused                         - always 0
bit 3 seek failed = 1                - always 0
bit 4 file not ready = 1             - always 0
bit 5 control busy = 1
bit 6 timing error = 1               - always 0
bit 7 write lock error = 1
bit 8 parity error = 1               - always 0
bit 9 data request late = 1          - always 0
bit 10 drive status error = 1
bit 11 cylinder address error = 1
*/
  /*  command reg bit assignment
bit 0:2 command
    000 read 
    001 read all
    010 set write protect
    011 seek
    100 write
    101 write all
    11x nop
bit 3 interrupt on done
bit 4 set done on seek done
bit 5 block length 0 256 1 128 words
bit 6:8 extended address
bit 9: 10 drive select
bit 11 msb of cylinder
*/

  assign sdDISKaddr = {17'd0, cmd_reg[9:11], dar};
  assign sdMEMaddr  = {cmd_reg[6:8], car};
  assign disk_flag  = (status != 12'o0000);

  always @(posedge clk) begin
    sdstate <= sdSTAT.state;
    if (dmaWR == 1'b1) begin
      dmaAddr <= dmaADDR;  // register and pass through
      data_break <= 1'b1;
    end
    if (state == DB1) // data break is happening so reset request
    begin
      data_break <= 1'b0;
    end

    if ((disk_flag == 1'b1) && (cmd_reg[3] == 1'b1)) interrupt <= 1'b1;
    else interrupt <= 0;
    if (dmaREQ == 1'b1) dmaGNT <= 1'b1;
    else dmaGNT <= 1'b0;

    if ((reset == 1'b1) || (clear == 1'b1)) begin
      skip          <= 1'b0;
      status        <= 12'o0000;
      car           <= 12'o0000;
      dar           <= 12'o0000;
      cmd_reg       <= 12'o0000;
      dmaAddr       <= 15'o00000;
      data_break    <= 1'b0;
      to_disk       <= 1'b0;
      sdOP          <= sdopNOP;
      write_lock[0] <= 1'b0;
      write_lock[1] <= 1'b0;
      write_lock[2] <= 1'b0;
      write_lock[3] <= 1'b0;
      last_sdstate  <= sdstateINIT;
      toggle        <= 4'b0;
	  sd_reset      <= 1'b1;
    end else if ((state == F1) && (UF == 1'b0)) begin
      skip <= 1'b0;
      case (instruction)
        12'o6740: ;
        12'o6741: if (disk_flag == 1'b1) skip <= 1;  //DSKP
        12'o6742:  // DCLC real RK8e has four options here we only do two
        if (ac[11] == 1'b0) status <= 12'o0000;
        else begin
          status <= 12'o0000;
          sdOP   <= sdopABORT;  // stop whatever is in process
        end
        12'o6743:    // DLAG load address and go
          begin
          dar <= ac;
          if ({cmd_reg[11], ac[0:6]} > 8'd202) status[11] <= 1'b1;
          else if ((cmd_reg[0:2] == 3'b000) ||  // read
              (cmd_reg[0:2] == 3'b001)) begin
            to_disk <= 1'b0;
            sdOP <= sdopRD;
          end else if ((cmd_reg[0:2] == 3'b100) ||  // write
              (cmd_reg[0:2] == 3'b101))
            // need to check here for write protect
            if (write_lock[cmd_reg[9:10]] == 1'b1) begin  // set error condition
              status[7] <= 1'b1;
            end else begin
              sdOP <= sdopWR;
              to_disk <= 1'b1;
            end
        end
        12'o6744: car <= ac;  // DLCA load current address
        12'o6745: disk_bus <= status;  // DRST
        12'o6746: // DLDC load command register
          begin
          cmd_reg <= ac;
          status  <= 12'o0000;
          // execute now, cmd does not yet hold the cmd from ac
          if (ac[0:2] == 3'b010) write_lock[ac[9:10]] <= 1'b1;
        end
        12'o6747:
        case (toggle)
          0: begin
            disk_bus <= {toggle, sdSTAT.debug};
            toggle   <= 4'b0001;
          end
          1: begin
            disk_bus <= {toggle, sdSTAT.err};
            toggle   <= 4'b0010;
          end
          2: begin
            disk_bus <= {toggle, sdSTAT.val};
            toggle   <= 4'b0011;
          end
          3: begin
            disk_bus <= {toggle, sdSTAT.rdCNT};
            toggle   <= 4'b0100;
          end
          4: begin
            disk_bus <= {toggle, sdSTAT.rdCNT};
            toggle   <= 4'b0101;
          end
          5: begin
            disk_bus <= {toggle, sdSTAT.state};
            toggle   <= 4'b0;
          end

          default: toggle <= 4'b0;
        endcase
        12'o6007:    // CAF
          begin
          status        <= 12'o0000;
          car           <= 12'o0000;
          dar           <= 12'o0000;
          cmd_reg       <= 12'o0000;
          sdOP          <= sdopNOP;
          to_disk       <= 1'b0;
          // with a real rk05 the operator would press a switch on the disk to
          // clear the write protect, we have no switch, so a reset, clear or
          // CAF resets the write protect flag
          write_lock[0] <= 1'b0;
          write_lock[1] <= 1'b0;
          write_lock[2] <= 1'b0;
          write_lock[3] <= 1'b0;
        end
        default:  ;
      endcase

      // change to a case statement on sdstate
      case (sdstate)
        sdstateINIT: ;  // SD Initializing
        sdstateREADY:   // SD Ready for commands
        if (last_sdstate != sdstateREADY) status[0] <= 1'b1;
        sdstateREAD,    // SD Reading
        sdstateWRITE:   // SD Writing
        begin
          status[0] <= 1'b0;
          if (last_sdstate == sdstateREADY) sdOP <= sdopNOP;
        end
        sdstateDONE: begin
          if ((last_sdstate == sdstateREAD) || (last_sdstate == sdstateWRITE)) begin
            status[0] <= 1'b1;  // SD Done
            car <= dmaADDR[3:14];
          end
        end
        sdstateINFAIL,  // SD Initialization Failed
        sdstateRWFAIL: begin
          status[0]  <= 1'b0;
          status[10] <= 1'b1;
        end
        default: status[0] <= 1'b0;
      endcase
      last_sdstate <= sdstate;

    end
  end
endmodule

