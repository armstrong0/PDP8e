module inst_mux(
    input clock,
    input reset,
    input skip,
    input [4:0] state,
    output reg [0:11] instruction);

`include "../parameters.v"

    always @(posedge clock)
    begin
        if (reset == 1)
            instruction <= 12'o6046; // need to prime the pump
        else
		begin
            if (state == F3)
			begin
			if (skip == 1)
                instruction <= 12'o6046;
            else
                instruction <= 12'o6041;
			end	
        end
    end
endmodule

