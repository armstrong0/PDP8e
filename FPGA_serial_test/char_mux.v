module char_mux(
    input clock,
    input reset,
    input [4:0] state,
    input skip,
    output reg [0:11] ochar);
    reg [0:11] char;
   // reg [0:11] ochar;
    reg [6:0] clmn_cntr;
// this module provides charactors to the uart
// it sequences through the 96 (95?) printable characters represented
// by a 7 bit ascii representation.  It also produces CR/LF characters at
// column 80 so that a standard terminal shows a continuous sequence moving
// from one line to the next
// nothing happens in this module unless the skip signal is true...
//
`include "../parameters.v"

    always @(posedge clock) begin
        if (reset == 1)
        begin
            char <= 12'o0040;
			ochar <= 12'o0252;
            clmn_cntr <= 0 ;
        end
        else if (skip == 1)
            case (state)
                FW,F1,F2:  // need to output char
                begin
                    if ( clmn_cntr == (7'd79 + 7'o040))
                    begin
                        ochar <=   7'o015; // charriage return
                    end
                    else if ( clmn_cntr == (7'd80 + 7'o040))
                    begin
                        ochar <=   7'o011; //linefeed// linefeed
                    end
                    else ochar <= char;

                end
                F3:
                begin
                    if (clmn_cntr <= (7'd79 )) begin
                        clmn_cntr <= clmn_cntr + 1;
                        char <= char +1;
                    end
                    else if (clmn_cntr > 7'd81)
                        char <= 7'o040;
                end
		default:;
            endcase
    end
endmodule




