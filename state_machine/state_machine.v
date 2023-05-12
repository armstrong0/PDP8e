
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
    input [0:11] instruction, ac, mq,
    input EAE_mode,
    input EAE_loop,
    input gtf,
    input db_write, db_read,   // data break write is to disk read is from disk
    output reg EAE_skip,
    output reg int_in_prog,
    output reg break_in_prog,
    output reg [4:0] state);

    wire db;
    reg [4:0] next_state;

`include "../parameters.v"

    assign db = (db_write| db_read);
	assign break_in_prog = ((state == DB0) || (state == DB1) || (state == DB2));

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
                    if (single_step & ~cont)
                        state <= F0;
                    else if (halt & ~cont)
                        state <= H0;
                    else
                        state <= FW;
                    int_in_prog <= 0;
                    EAE_skip <= 1'b0;
                end
                FW: state <= F1;
                F1: casez (instruction & 12'b111100101111)
					//12'b1111??0?0001,
                    12'b111100000011,
                    12'b111100000101,
                    12'b111100000111,
                    12'b111100001001,
                    12'b111100001011,
                    12'b111100001101,
                    12'b111100001111,
                    12'b111100100001,
                    12'b111100100011,
                    12'b111100100101, // SWAB missing see below
                    12'b111100101001,
                    12'b111100101011,
                    12'b111100101101,
                    12'b111100101111: // very crude way to specify
					// any extended EAE operation
                    begin
                        if (EAE_mode == 1'b0) state <= F2A;
                        else state <= F2B;
                    end
                    12'b111100100111,     // SWBA just follow normal flow
                    12'b111100011001:     // SWAB anction taken by ac in F3;
                    state <= F2;
                    default:
                    state <= F2;
                endcase
                F2: state <= F3;  // non-EAE case
                F2A: casez (instruction)  // Mode A
                    12'b1111??0?0001: state <= F3;  //NOP
                    12'b1111??0?0011:   //SCL ACS
                    begin
                        EAE_skip <= 1'b1;
                        state <= EAE0;
                    end
                    12'b1111??0?0101,   //7405 MUY
                    12'b1111??0?0111:   //7407 DIV
                    begin
                        EAE_skip <= 1'b1;
                        state <= EAE0;
                    end
                    12'b111100001001: state <= EAE0;  //7411 NMI
                    12'b1111??0?1011,   //7413 SHL
                    12'b1111??0?1101,   //7415 ASR
                    12'b1111??0?1111:   //7417 LSR
                    begin
                        EAE_skip <= 1'b1;
                        state <= EAE0;
                    end

                    12'b1111??1?0001:  state <= F3 ;  // SCL both A and B
                    12'b1111??1?0011:   // SCA - SCL
                    begin
                        EAE_skip <= 1'b1;
                        state <= F3;
                    end
                    12'b1111??1?0101,   // SCA - MUL
                    12'b1111??1?0111:   // SCA - DIV
                    begin
                        EAE_skip <= 1'b1;
                        state <= EAE0;
                    end
                    12'b1111??1?1001:   // SCA - NMI
                    state <= EAE0;
                    12'b1111?1111011,   // SCA - SHL
                    12'b1111?1111101,   // SCA - ASR
                    12'b1111??1?1111:   // SCA - LSR
                    begin
                        state <= EAE0;
                        EAE_skip <= 1'b1;
                    end

                    default:
                    state <= F3;
                endcase

                F2B: casez (instruction) // mode B

                    12'b110000000110:
                    if (gtf == 1'b1) EAE_skip <= 1;
                    12'b1111??0?0001:;  //NOP
                    12'b1111??0?0011:   //SCL ACS
                    state <= F3;
                    12'b1111??0?0101,   //7405 MUY
                    12'b1111??0?0111:   //7407 DIV
                    begin
                        EAE_skip <= 1'b1;
                        state <= D0;
                    end
                    12'b111100001001:
                    state <= EAE0;      //7411 NMI
                    12'b1111??0?1011,   //7413 SHL
                    12'b1111??0?1101,   //7415 ASR
                    12'b1111??0?1111:   //7417 LSR
                    begin
                        EAE_skip <= 1'b1;
                        state <= EAE0;
                    end

                    12'b1111??1?0001: state <= F3;  // SCA B 7441
                    12'b1111??1?0011,   // DAD - DLD 7443
                    12'b1111??1?0101:   // DST 7445
                    begin
                        EAE_skip <= 1'b1;
                        state <= D0;
                    end
                     // 12'b1111??1?0111:   // SWBA 7447 taken care of in F2
                     // state <= F3;
                    12'b1111??1?1001:   // DPSZ 7451
                    begin
                        if ((ac | mq) == 12'o0000) EAE_skip <= 1'b1;
                        state <= F3;
                    end
                    12'b1111?1111011,   // DPIC 7573
                    12'b1111?1111101,   // DCM  7575
                    12'b1111??1?1111:   // SAM  7457
                    state <= F3;
                    default:
                    state <= F3;
                endcase
                F3: if ((instruction[0:1] == 2'b11) || // IOT & OPER
                        (instruction[0:3] == 4'b1010)) // JMP D
                begin
                    if (({instruction[0:3],instruction[10:11]} == 6'b111110) //halt
                            && (UF == 1'b0))
                         // halt instruction, not in user mode
                        state <= H0;
                    else if (db == 1'b1)
                    begin
                        next_state <= F0; // rememeber where we were going
                        state <= DB0;
                    end
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
                begin
                    if (db == 1'b1)
                    begin
                        next_state <= D0;
                        state <= DB0;
                    end
                    else
                        state <= D0;
                end
                else if (db == 1'b1) // next cycle is execute
                begin
                    next_state <= E0;
                    state <= DB0;
                end
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
                    if (db == 1'b1)
                    begin
                        next_state <= F0;
                        state <= DB0;
                    end
                    else if (int_req & int_ena & ~int_inh)
                    begin
                        int_in_prog <= 1;
                        state <= E0;
                    end
                    else
                        state <= F0;
                end
                else  // if EAE instruction - execute
                if ((instruction & 12'b111100000001 ) == 12'b111100000001)
                begin if (db == 1'b1)
                    begin
                        next_state <= EAE2;
                        state <= DB0;
                    end
                    else
                        state <=   EAE2;
                end
                else if (db == 1'b1) // not EAE
                begin
                    next_state <= E0;
                    state <= DB0;
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
                E3:
                if(int_req & int_ena & ~int_inh & ~int_in_prog ) // test for interrupt
                begin
                    int_in_prog <= 1;
                    state <= E0;
                    if (db == 1'b1)
                    begin
                        next_state <= E0;
                        state <= DB0;
                    end
                end
                else if (db == 1'b1)
                begin
                    next_state <= F0;
                    state <= DB0;
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
                // data break
                DB0: state <= DB1;
                DB1: if (db_write == 1'b1) state <= DB2;
                else state <= next_state;  // data break read from disk
                DB2: state <= next_state;

                default: state <= H0;
            endcase
    end
endmodule

