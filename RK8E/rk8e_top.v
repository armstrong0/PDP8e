/* verilator lint_off LITENDIAN */

/* This module implements an RK8-E controller.  It is intended to interface to
 * a SD Card. The SD card will hold 4 RK05 disk packs. Each of which holds
 * about 1.6 mega words- roughly 2.4 megabytes.  */

module rk8e_top(
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
    output reg skip);

    wire flag;
    wire [0:7] rx_disk_bus;
    reg [0:11] cmd_reg;  // command register
    reg [0:11] car;      // current address register
    reg [0:11] disk_ar;  // disk address  - need one for each disk ?
    reg [7:0] buffer_address;
    reg [0:11] status;   // status register


    // need a write protect for each drive
    reg [0:3] write_lock;

    reg sint_ena;

    always @(posedge clk)
    begin
        if (rx_flag == 1) disk_bus <= {4'b0000,rx_disk_bus};
    end

`include "../parameters.v"


    always @(posedge clk) begin

        if ((flag == 1) && (sint_ena ==1)) interrupt <= 1;
        else interrupt <= 0;
        if (state == F1)
        begin
            skip <= 0;
            case (instruction)
                12'o6741: if ((disk_flag == 1)&& (UF == 1'b0)) skip <= 1;
                12'o6745: disk_bus <= status;
                default:;
            endcase
        end
    end



    always @(posedge clk)
    begin
        if ((reset ==1) | (clear))
        begin
            clear_tx <= 0;
            set_tx <= 0;
            sint_ena <= 1;
            clear_rx <= 0;
        end

        if (state == F0)
        begin
            load_tx <= 0;
            clear_tx <= 0;
            clear_rx <= 0;
            set_tx <= 0;
        end
        if ((state == F1) && (UF == 1'b0))
            case (instruction)
                12'o6740:;
                12'o6741:; // skip if transfer done or error
                12'o6742:;
                12'o6743:  // DLAG laod address and go
                begin
                    dar <= ac;
                end
                12'o6744: // load current addressa
                begin
                    car <= ac;
                end
                12'o6745:;
                12'o6746: // load command
                begin
                    cmd_reg <= ac;
                    status <= 12'o0000;
                end
                12'o6007: //CAF
                begin
                    status  <= 12'o0000;
                    car     <= 12'o0000;
                    dar     <= 12'o0000;
                    cmd_reg <= 12'o0000;
                end
                default:;
            endcase
    end
endmodule

