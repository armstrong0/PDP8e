
/* verilator lint_off LITENDIAN */

module mem_ext
   (
    input clk,
    input reset,
    input [0:11] instruction,
    input [0:11] mdout,
    input [0:11] sr,
    input [0:11] rac,
    input [3:0] state,
    input clear,
    input extd_addrd,
    input gtf,
    input int_in_prog,
    input irq,
    output reg int_ena,
    output reg int_inh,
    output reg mskip,
    output reg UF,   // user flag
    output reg [0:2] DF,
    output reg [0:2] IF,
    output reg [0:11] me_bus);

    reg [0:5] SF;
    reg [0:2] IB;
    reg UI;  // user interrupt
    reg UB;  // user buffer - hold the user flag until JMS or JMP then transferred to UF 
    reg [0:6] savereg;
    reg int_delay;

`include "../parameters.v"

    always @(posedge clk)
    begin
        if (reset | clear)
        begin
            savereg <= 7'o000;
            IF <= 3'o0;
            IB <= 3'o0;
            DF <= 3'o0;
            SF <= 6'o0;
            UF <= 0;
            UB <= 0;
            UI <= 0;
            int_inh <= 0;
            int_ena <= 0;
            int_delay <= 0;

        end
        else
            case (state)
                F0:;
                F1: case (mdout) // same as instruction but valid in F1

                    12'o6204: if (UF == 1'b1 )  mskip <= 1;      // SUF // was UI
                    12'o6003: if (irq == 1 )    mskip <= 1;      // SRQ
                    12'o6006: if (gtf)          mskip <= 1;      // SGT
                    12'o6000: if (int_ena == 1) mskip <= 1;      // SKON
					12'o6254: if (UI == 1)      mskip <= 1;      // SINT
                    default:;
                endcase


                F2: begin
                    casez (instruction) // now instruction is valid
                        12'o6004: me_bus <= { 2'b00,irq,1'b0,(int_ena|int_delay),savereg};//GTF
                        12'o6214: me_bus <= rac | {6'o00,DF,3'o0} ;//6214 RDF
                        12'o6224: me_bus <= rac | {6'o00,IF,3'o0} ;//6224 RIF
                        12'o6234: me_bus <= rac | {5'o00,savereg} ;//6234 RIB
                        12'b1010????????:  // JMP DIRECT
                        begin
                            if (int_inh == 1)
                            begin;
                                IF <= IB;  // what about user flag?
                                int_inh <=0;
                            end
                        end
                        default:;
                    endcase
                    if (int_delay == 1) begin
                        int_ena <= 1;
                        int_delay <= 0;
                    end

                end
                F3:
                begin
                    casez (instruction)
                        12'o6000:
                        begin //SKON
                            int_delay <= 0;
                            int_ena <= 0;
                        end
                        12'o6001: int_delay <= 1; //ION
                        12'o6002: begin //IOF
                            int_delay <= 0;
                            int_ena <= 0;
                        end
                        12'o6005:    //RTF
                        begin
                            {UF,IB,DF} <= rac[5:11];
                            int_delay <= 1; // 
                            int_inh <= 1;   //
                        end
                        12'o6007:   begin //CAF clear all flags
                            int_ena   <= 0;
                            int_delay <= 0;
                            int_inh   <= 0;
                            UF <= 0;
                        end
                        12'o62?1: DF <= instruction[6:8] ; //62N1 CDF
                        12'o62?2: begin
                            IB <= instruction[6:8] ; //62N2 CIF
                            int_inh <= 1;
                        end
                        12'o62?3: begin
                            IB <= instruction[6:8]; //62N3 CDF,CIF
                            DF <= instruction[6:8];
                            int_inh <= 1;
                        end
                        12'o6204: UF <=0; // was UI
                        12'o6244: begin   //RMF
                            UF <= savereg[0];
                            IB <= savereg[1:3];
                            DF <= savereg[4:6];
                            int_inh <= 1;
                        end
                        12'o6254:;  // SINT
                        12'o6264: UB <= 0;  //
                        12'o6274: begin
                            UB <= 1;
                            int_inh <= 1;
                        end
                        default:;
                    endcase
                    mskip <= 0;
                end
                D0,D1:;
                D2:  if ((int_inh == 1'b1) && (instruction[0:3] == JMPI))
                begin
                    int_inh <= 0;
                    IF <= IB;
					UF <= UB;
                end
                D3:;
                E0: if (int_in_prog == 1'b1)
                begin
                    savereg <= {UF,IF,DF};
                    IF <= 3'o0;
                    DF <= 3'o0;  // need to save the user flag?
					UF <= 0;
                    int_ena <= 0;
                    int_delay <= 0;
                end
                E1:;
                E2: begin 
				   if (instruction[0:2] == JMS)
                    begin
				       if (int_inh == 1'b1) 
				       begin
                          IF <= IB;
					      UF <= UB;
                          int_inh <= 0;
					   end
                    end
				 end
                E3:;
                H0:;
                H1: if (extd_addrd ==1'b1)
                begin
                    IF <= sr[6:8];
                    IB <= sr[6:8];
                    DF <= sr[9:11];
                    UF <= 0;
                end
                H2: if (clear == 1)
                begin
                    int_ena <= 0;
                    int_delay <= 0;
                end
                H3:;
            endcase
    end
endmodule


