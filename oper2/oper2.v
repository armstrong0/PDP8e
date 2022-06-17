
module oper2(input clk100, inout [3:0] state,input [0:11] instruction, input [0:11] ac,input l,output reg skip);
// instruction neeeds to be hooked to mdout for valid results
`include "../parameters.v"
    reg ac_zero;
    always @(posedge clk100)
	  begin
	    if (state == F0)
		begin
		    if (ac == 12'o0000) ac_zero <= 1;
		else
		    ac_zero <= 0;
		end
	    else if (state == F1)
	    skip <= (({instruction[0:3],instruction[11]} == 5'b11110)  &&
        ((!instruction[8] && ((instruction[5] && ac[0]) || 
                (instruction[6] && ac_zero) ||
                (instruction[7] && l)))
        ||

        ( instruction[8] && ((!instruction[5] || !ac[0]) &&
                (!instruction[6] || !ac_zero) &&
                (!instruction[7] || !l)))));
    end
endmodule

