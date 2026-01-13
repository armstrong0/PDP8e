
module oper2(input clk100,
             input [4:0] state,
             input [0:11] instruction,
             input [0:11] ac,
			 input [0:11] mq,
			 input EAE_mode,
			 input gtf,
             input l,
             output reg skip);

`include "../parameters.v"
    reg ac_zero;
    always @(posedge clk100)
      begin
        if (state == F0)
        begin
            if (ac == 12'o0000) ac_zero <= 1;
        else
            ac_zero <= 0;
        skip <= 0;
        end
        else if (state == F1)
        skip <= ((({instruction[0:3],instruction[11]} == 5'b11110) &&
        ((!instruction[8] && ((instruction[5] && ac[0]) ||
                (instruction[6] && ac_zero) ||
                (instruction[7] && l)))
        ||
        ( instruction[8] && ((!instruction[5] || !ac[0]) &&
                (!instruction[6] || !ac_zero) &&
                (!instruction[7] || !l)))))
`ifdef EAE                
		|| ((instruction == 12'o7451) && 
		        (((ac | mq) == 12'o0000) &&
		        (EAE_mode == 1))) 
`endif                
		|| ((instruction == 12'o6006) && (gtf == 1'b1)) );

    end
	
endmodule

