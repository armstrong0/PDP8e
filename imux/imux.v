//  This module forms the only interface between the CPU proper and the IO 
//  devices.  It multiplexes the skip lines and data from the peripherals 
//  to the CPU
/* verilator lint_off LITENDIAN */
module imux(
input clk,
input reset,
input [4:0] state,
input [0:11] instruction,
input [0:11] ac,
input [0:11] mem_reg_bus,
input [0:11] serial_data_bus,
input iskip,
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

	   default:
	      bus_display <= bus_display; // hold last value
	   endcase
end

always @(*) begin   // purely combinatorial change <= to = for verilator

    //IOT intruction
    case (instruction[0:11])           // uneven decoding
       12'o6004: in_bus = mem_reg_bus;   // program interrupt and flag
       12'o6034: in_bus = serial_data_bus;// teletype keyboard / reader
       12'o6036: in_bus = serial_data_bus;// teletype keyboard / reader
       12'o6214,12'o6224,12'o6234:     //memory manage unit  
              in_bus = mem_reg_bus;
       // will need to add the disk units	      
       default: in_bus = 12'o0000;	      
    endcase
end

always @(*) begin //again for verilator
    case (instruction[0:8] )
       9'o600: skip = mskip;
       9'o603,9'o604: skip = sskip;
       9'o625: skip = mskip;
       default: skip = 0;
       endcase
   end
endmodule
       
       
