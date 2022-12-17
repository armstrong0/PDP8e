
/* verilator lint_off LITENDIAN */

module mem_ext
   (
    input clk,
    input reset,
    input [0:11] instruction,
    input [0:11] mdout,
    input [0:11] sr,
    input [0:11] ac,
    input [4:0] state,
    input clear,
    input extd_addrd,
    input gtf,
    input int_in_prog,
    input irq,
    output reg int_ena,
    output reg int_inh,
    output reg mskip,
    output reg UF,   // user flag
    output reg UI,   // user interrupt
    output reg [0:2] DF,
    output reg [0:2] IF,
    output reg [0:11] me_bus);

    reg [0:5] SF;
    reg [0:2] IB;
    reg UB; // user buffer - hold the user flag until JMS or JMP then transferred to UF
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
                F1:
                case (instruction) // these should only get executed when
			     	// in executive mode or in an interrupt
                    12'o6003: if ((UF == 1'b0) && (irq == 1 ))    mskip <= 1; // SRQ
                    12'o6006: if (gtf == 1'b1)  mskip <= 1; // SGT
                    12'o6000: if ((UF == 1'b0) && (int_ena == 1)) mskip <= 1; // SKON
                    12'o6254: if ((UF == 1'b0) && (UI == 1)) mskip <= 1;      // SINT
                    default:;
                endcase

                F2: begin
                    casez (instruction)
					   // these are prevented from loading into ac by ac
					   // module
                        12'o6004:if (UF == 1'b0)
                            me_bus <= { 2'b00,irq,1'b0,(int_ena|int_delay),
                                savereg};//GTF
                        else UI <= 1'b1;
                        12'o6204: if (UF == 1'b0) UI <= 1'b0;  // CUI
                        12'o6214: if (UF == 1'b0)
                            me_bus <= ac | {6'o00,DF,3'o0} ;// RDF
                        else UI <= 1'b1;
                        12'o6224: if (UF == 1'b0)
                            me_bus <= ac | {6'o00,IF,3'o0} ;// RIF
                        else UI <= 1'b1;
                        12'o6234: if (UF == 1'b0)
                            me_bus <= ac | {5'o00,savereg} ;// RIB
                        else UI <= 1'b1;
                        12'b1111?????010, // HLT
                        12'b1111?????100, // OSR LAS 
                        12'b1111?????110: if (UF == 1'b1) UI <= 1'b1; // OSR LAS
                        12'b1010????????:  // JMP DIRECT
                        begin
                            if (int_inh == 1)
                            begin;
                                IF <= IB;
                                UF <= UB;
                                int_inh <=0;
                            end
                        end
                        default:;
                    endcase

                    if ((instruction[0:2] == 3'b110) && (UF == 1'b1)) UI <= 1;

                    if (int_delay == 1) begin
                        int_ena <= 1;
                        int_delay <= 0;
                    end
                end
                F3:
                begin
                    casez (instruction)
                        12'o6000: if (UF == 1'b0)
                        begin //SKON
                            int_delay <= 0;
                            int_ena <= 0;
                        end
                        12'o6001: if (UF == 1'b0)
                            int_delay <= 1; //ION
                        12'o6002: if (UF == 1'b0) begin //IOF
                            int_delay <= 0;
                            int_ena <= 0;
                        end
                        12'o6005:if (UF == 1'b0) //RTF
                        begin
                            {UB,IB,DF} <= ac[5:11];
                            int_delay <= 1;
                            int_inh <= 1;
                        end
                        12'o6007: if (UF == 1'b0)
                        begin //CAF clear all flags
                            int_ena   <= 0;
                            int_delay <= 0;
                            UF <= 0;
                            UI <= 0;
                        end
                        else UI <= 1'b1;
                        12'o62?1: if (UF == 1'b0)
                            DF <= instruction[6:8] ; //62N1 CDF
                        12'o62?2: if (UF == 1'b0)
                        begin
                            IB <= instruction[6:8] ; //62N2 CIF
                            int_inh <= 1;
                        end
                        12'o62?3: if (UF == 1'b0)
                        begin
                            IB <= instruction[6:8]; //62N3 CDF,CIF
                            DF <= instruction[6:8];
                            int_inh <= 1;
                        end
                        12'o6204: if (UF == 1'b0)  UI <=0;
                        12'o6244: if (UF == 1'b0)
                        begin   //RMF
                            UB <= savereg[0];
                            IB <= savereg[1:3];
                            DF <= savereg[4:6];
                            int_inh <= 1;
                        end
                        12'o6254:;  // SINT
                        12'o6264: if (UF == 1'b0) UB <= 0; // CUF
                        12'o6274: if (UF == 1'b0)
                        begin
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
                    DF <= 3'o0;
                    UF <= 0;
                    UB <= 0;
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
                    UB <= 0;
                end
                H2: if (clear == 1)
                begin
                    int_ena <= 0;
                    int_delay <= 0;
                end
                H3:;
                default:;
            endcase
    end
endmodule


