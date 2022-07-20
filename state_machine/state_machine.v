module state_machine(input clk,
    input reset,
    input halt,
    input single_step,
    input cont,
    input int_req,
    input int_ena,
    input int_inh,
    input UF,
    input trigger,
    input [0:11] instruction,
    output reg int_in_prog,
    output reg [4:0] state);


`include "../parameters.v"

    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= H0;
            int_in_prog <= 0;
        end
        else case (state)

                // fetch cycle
                F0: begin
                    if (~single_step | cont)
                        state <= FW;
                    else state <= F0;
                    int_in_prog <= 0;

                end
                FW: state <= F1;
                F1: state <= F2;
                F2:begin
                    state <= F3;
                end
                F3:if ((instruction[0:1] == 2'b11) || (instruction[0:3] == 4'b1010))
                    	// IOT | OPER | JMP D
                    
                begin
					// IOT, OPER and JMP D instructions execute in the fetch
                    if (halt == 1)
                        state <= H0;
                    else
                    if (({instruction[0:3],instruction[10:11]} == 6'b111110)
                            && (UF == 1'b0))
                         // halt instruction, not in user mode
                        state <= H0;
                    else if  ((int_req & int_ena & ~int_inh )
                            && (instruction != 12'o6002))
                         //this solves the ion/iof/ion/iof problem
                    begin
                        int_in_prog <= 1;
                        state <= E0;
                    end

                    else state <= F0;
                end
                else if (instruction[3] == 1)
                     // defer cycle/
                    state <= D0;
                else
                    state <= E0;

                D0: if (~single_step |  cont )
                    state <= DW;
                else
                    state <= D0;
                DW: state <= D1;
                D1: state <= D2;
                D2: state <= D3;
                //  if it is a jmp I then F0 is the desired state
                D3: if (instruction[0:3] == 4'b1011)
                begin
                    if (int_req & int_ena & ~int_inh)
                    begin
                        int_in_prog <= 1;
                        state <= E0;
                    end
                    else if (halt == 1)
                        state <= H0;
                    else
                        state <= F0;
                end
                else
                    state <= E0;
                // execute cycle
                E0: if (~single_step |  cont )
                    state <= EW;
                else
                    state <= E0;
                EW: state <= E1;
                E1: state <= E2;
                E2: state <= E3;
                E3: if (halt == 1)
                    state <= H0;
                else if (int_in_prog == 1)
                    state <= F0;
                else if(int_req & int_ena & ~int_inh )
                begin
                    int_in_prog <= 1;
                    state <= E0;
                end
                else
                    state <= F0;


                H0: state <= HW;
                HW: if (trigger & ~cont) state <= H1;
                else if ( ~cont) state <= H0;
                else state <= F0;
                H1: state <= H2;
                H2: state <= H3;
                H3: state <= H0;
                default: state <= H0;
            endcase
    end
endmodule

