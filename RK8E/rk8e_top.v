/* verilator lint_off LITENDIAN */

/* This module implements an RK8-E controller.  It is intended to interface to
 * a SD Card. The SD card will hold 4 RK05 disk packs. Each of which holds
 * about 1.6 mega words- roughly 2.4 megabytes.  */

/* ended up adding a comment so this file has a change in it. This is so I can
 * prevent git from deleting this file!!!  */
/* that didn't work git deleted the file AGAIN */

/* dba April 03, 2023 */
/* dba April 07, 2023 */


module rk8e_top (
    input clk,
    input reset,
    input clear,
    input [0:11] instruction,
    input [4:0] state,
    input [0:11] ac,
    output reg [0:11] disk_bus,  //from the point of view of the CPU
    /* verilator lint_off SYMRSVDWORD */
    output reg interrupt,
    /* verilator lint_on SYMRSVDWORD */
    output reg data_break_write,
    output reg data_break_read,
    output reg skip
);

  wire        flag;
  reg  [0:11] cmd_reg;  // command register
  reg  [0:11] car;  // current address register
  reg  [0:11] disk_ar;  // disk address  - need one for each disk ?
  reg  [ 7:0] buffer_address;
  reg  [0:11] status;  // status register


  // need a write protect for each drive
  reg  [ 0:3] write_lock;
  reg         disk_flag;
  reg         sint_ena;


  `include "../parameters.v"
  /*
Status Register
bit 0 0= done 1 = busy
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
  assign disk_flag = (status != 12'o0000);
  always @(posedge clk) begin

    if ((status[0] == 1'b0) && (cmd_reg[3] == 1'b1)) interrupt <= 1;
    else interrupt <= 0;
    if (state == F1) begin
      skip <= 0;
      case (instruction)
        12'o6741: if ((disk_flag == 1'b1) && (UF == 1'b0)) skip <= 1;  //DSKP
        12'o6745: disk_bus <= status;  //
        default:  ;
      endcase
    end
  end



  always @(posedge clk) begin
    if ((reset == 1) || (clear)) begin
      status        <= 12'o0000;
      car           <= 12'o0000;
      dar           <= 12'o0000;
      cmd_reg       <= 12'o0000;
      write_lock[0] <= 1'b0;
      write_lock[1] <= 1'b0;
      write_lock[2] <= 1'b0;
      write_lock[3] <= 1'b0;
    end

    if ((state == F1) && (UF == 1'b0))
      case (instruction)
        12'o6740: ;
        12'o6741: ;  // DSKP skip if done or error
        12'o6742:    // DCLC real RK8e has four options here we will just 
		             //   clear the status register
        begin
          status <= 12'o0000;
        end
        12'o6743:    // DLAG load address and go
                begin
          dar <= ac;
        end
        12'o6744:    // DLCA load current addressa
                begin
          car <= ac;
        end
        12'o6745: ;  // DRST clear ac and load the status register
        12'o6746:   // DLDC load command register
                begin
          cmd_reg <= ac;
          status  <= 12'o0000;
        end
        12'o6747: ;  // DMAN not implemented
        12'o6007:    // CAF
                begin
          status        <= 12'o0000;
          car           <= 12'o0000;
          dar           <= 12'o0000;
          cmd_reg       <= 12'o0000;
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
    else if ((state == F2) && (UF == 1'b0) && (instruction == 12'o6746))  // decode command

      case (cmd_reg[0:2])
        0:  // read data
            // send command to sdcard driver
        ;
        1: ;  // read all
        2:  // set write protect
        write_lock[cmd_reg[9:10]] <= 1'b1;
        3: ;  // seek only - a nop with an sdcard
        4:  // write data  - check for write lock
        if (write_lock[cmd_reg[9:10]] == 1'b1) begin  // set error condition
          status[7] <= 1'b1;
        end else begin  // do write
          // send command to sdcard driver
        end
        5: ;  // write all
        default: ;
      endcase
    else if ((state == F2) && (UF == 1'b0) && (instruction == 12'o6743))
      if ({cmd_reg[11], dar[0:6]} > 8'd203) status[11] <= 1'b1;

  end
endmodule

