module state(
	input clock,
	input reset,
	output reg [4:0] state);
`include "../parameters.v"
	

	always @(posedge clock)
	begin
	if (reset ==1 )
	state <= F0;
	else
        case (state)
	F0: state <= FW;
	FW: state <= F1;
	F1: state <= F2;
	F2: state <= F3;
	F3: state <= F0;
	default: state <= F0;
	endcase
end
endmodule


	
