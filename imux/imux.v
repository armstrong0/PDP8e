//  This module forms the only interface between the CPU proper and the IO
//  devices.  It multiplexes the skip lines and data from the peripherals
//  to the CPU
/* verilator lint_off LITENDIAN */
module imux(
    input clk,
    input reset,
    input [4:0]  state,
    input [0:11] instruction,
    input [0:11] ac,
    input [0:11] mem_reg_bus,
    input [0:11] serial_data_bus,
//`ifdef RK8E
    input [0:11] disk_bus,
    input disk_skip,
//`endif
    input sskip,
    input mskip,
    output reg skip,
    output reg [0:11] in_bus,
    output reg [0:11] bus_display);

    reg [0:11] lac;
    reg [0:11] lin_bus;
`include "../parameters.v"


    always @(posedge clk) begin
        if (reset)
            bus_display <= 12'o0000;
        else if (state == F2)
        begin
            lac <= ac;
            lin_bus <= in_bus;
        end
        else if (state == F3)
            case (instruction[0:11])
                12'o6004: bus_display <= lin_bus;
                12'o6005: bus_display <= lac;
                12'o6036: bus_display <= lin_bus;
                12'o6044: bus_display <= lac;
                12'o6046: bus_display <= lac;
                12'o6743,
                12'o6744,
                12'o6746: bus_display <= lac;
                12'o6745: bus_display <= linbus;

                default:
                bus_display <= bus_display; // hold last value
            endcase
    end

    always @(*) begin   // purely combinatorial change <= to = for verilator

    //IOT intruction
        case (instruction[0:11])               // uneven decoding
            12'o6004: in_bus = mem_reg_bus;    // program interrupt and flag
            12'o6034: in_bus = serial_data_bus;// teletype keyboard / reader
            12'o6036: in_bus = serial_data_bus;// teletype keyboard / reader
            12'o6214,12'o6224,12'o6234:        // memory manage unit
            in_bus = mem_reg_bus;
`ifdef RK8E
            12'o6745,
            12'o6747:in_bus = disk_bus;      // RK8E disk
            // note we are not showing the disk transfers!
`endif
            default: in_bus = 12'o0000;
        endcase
    end

    always @(*) begin //again for verilator
        casez (instruction[0:11] )
            12'o6003: skip = mskip;
            12'o6000: skip = mskip;
            12'o603?,12'o604?: skip = sskip;
            12'o625?: skip = mskip;
`ifdef RK8E
            12'o6741: skip = disk_skip;
`endif
            default: skip = 0;
        endcase
    end
endmodule


