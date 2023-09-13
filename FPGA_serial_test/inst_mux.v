module inst_mux(
    input clock,
    input reset,
    input skip,
    input state,
    output reg [0:11] instruction);

`include "../parameters.v"

    always @(posedge clock)
    begin
        if (reset == 1)
            instruction <= 12'o6041;
        else case (state)
                F0:;
                FW,F1,F2,F3:
                if (skip == 1'b1)
                    instruction <= 12'o6046;
                else
                    instruction <= 12'o6041;
                default: instruction <= 12'o7000;
		


            endcase
    end
endmodule

