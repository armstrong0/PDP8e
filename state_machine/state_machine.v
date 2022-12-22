
/* verilator lint_off LITENDIAN */
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
    input EAE_mode,
    input EAE_loop,
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
                F2: casez (instruction)
                    12'b1111??0?0101,   //7405 MUY
                    12'b1111??0?0111:   //7407 DIV
                    if (EAE_mode == 1'b0) state <= EAE0;
                    else state <= D0;
                    12'b111100001001,   //7411 NMI
                    12'b1111??0?1011,   //7413 SHL
                    12'b1111??0?1101,   //7415 ASR
                    12'b1111??0?1111:   //7417 LSR
                    state <= EAE0;
                    12'b1111??1?0011,   // DAD become DLD if ac/mq cleared
                    12'b1111??1?0101:   // DST
                    if (EAE_mode == 1'b1) state <= D0;
					else state <= 

                    12'b1111??0?0001,   // NOP        normal flow
                    12'b1111??0?0011,   // SCL or ACS normal flow

                    12'b1111??1?0111,   // SWBA       normal flow
                    12'b1111??1?1001,   // DPSZ       normal flow
                    12'b1111?1111011,   // DPIC       normal flow
                    12'b1111?1111101,   // DCM        normal flow
                    12'b1111??1?1111,   // SAM        normal flow
                    12'b111100011001:   // SWAB
                    state <= F3;
                    default:
                    state <= F3;
                endcase
                F3: if ((instruction[0:1] == 2'b11) || // IOT & OPER
                        (instruction[0:3] == 4'b1010)) // JMP D
                begin
                    if (halt == 1)
                        state <= H0;
                    else if (({instruction[0:3],instruction[10:11]} == 6'b111110) //halt
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
                else if (instruction[3] == 1) // defer cycle/
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
                else  // if EAE instruction
                if ((instruction & 12'b111100000001 ) == 12'b111100000001)
                    state <= EAE2;
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

                EAE0: state <= EAE1;
                EAE1: if (EAE_loop == 1) state <= EAE1;
                else state <= F3;
                EAE2: state <= EAE3;
				// need to vector off to EAE0 if MUL or DIV
				// if we reached this it is a mode B EAE instruction
				// only MUL and DIV have bit 6 set 0 here.
                EAE3: if(instruction[6] == 1'b0) state <= EAE0;
                else  state <= EAE4;
                EAE4: state <= EAE5;
                EAE5: state <= E3;   // back to normal processing

                default: state <= H0;
            endcase
    end
endmodule

