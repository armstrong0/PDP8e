/* verilator lint_off LITENDIAN */

module ac (input clk,  // have to rename the mdulate for verilator
    input reset,
    input clear,
    input [4:0] state,
    input [0:11] instruction,
    input [0:11] sr,
    input [0:11] mdout,
    input [0:11] input_bus,
    input UF,
    input UI,
    output reg l,
    output reg gtf,
    output reg EAE_mode,
    output reg EAE_done,
    output reg [0:11] ac,
    output reg [0:11] rac,
    output reg [0:11] rmq);

    reg [0:11] ac_tmp,mq;
    reg [0:4] sc;
    reg AC_ALL_0;
    reg AC_ALL_1;
    reg MQ_ALL_0;
    reg MQ_ALL_1;


`include "../parameters.v"

    always @(posedge clk)
    begin
        if (reset|clear)
        begin
            ac <= 12'o0000;
            rac <= 12'o0000;
            mq <= 12'o0000;
            l <= 1'b0;
            gtf <= 1'b0;
        end
        else
        begin
            ac <= ac;
            mq <= mq;
            l <= l;
        end
        case (state)
            F0: begin // set up for EAE DPIC DAD DPSZ DCM
                rac <= ac;
                rmq <= mq;
                if (ac == 12'o0000) AC_ALL_0 <= 1; else AC_ALL_0 <= 0;
                if (ac == 12'o7777) AC_ALL_1 <= 1; else AC_ALL_1 <= 0;
                if (mq == 12'o0000) MQ_ALL_0 <= 1; else MQ_ALL_0 <= 0;
                if (mq == 12'o7777) MQ_ALL_1 <= 1; else MQ_ALL_1 <= 0;
            end

            F1: casez (instruction)
			    // oper1 instructions
                12'b11100000????:  begin ac <= ac;       l <=  l; end // nop
                12'b11100001????:  begin ac <= ac;       l <= ~l; end // cml
                12'b11100010????:  begin ac <= ~ac;      l <=  l; end // cma
                12'b11100011????:  begin ac <= ~ac;      l <= ~l; end // cml cma
                12'b11100100????:  begin ac <= ac;       l <=  0; end // cll
                12'b11100101????:  begin ac <= ac;       l <=  1; end // cll cml
                12'b11100110????:  begin ac <= ~ac;      l <=  0; end // cll cma
                12'b11100111????:  begin ac <= ~ac;      l <=  1; end // cll cml cma
                12'b11101000????:  begin ac <= 12'o0000; l <=  l; end // CLA
                12'b11101001????:  begin ac <= 12'o0000; l <= ~l; end // cla cml
                12'b11101010????:  begin ac <= 12'o7777; l <=  l; end // cla cma
                12'b11101011????:  begin ac <= 12'o7777; l <= ~l; end // cla cma cml
                12'b11101100????:  begin ac <= 12'o0000; l <=  0; end // cla cll
                12'b11101101????:  begin ac <= 12'o0000; l <=  1; end // cla cll cml
                12'b11101110????:  begin ac <= 12'o7777; l <=  0; end // cla cll cma
                12'b11101111????:  begin ac <= 12'o7777; l <=  1; end // cla cll cma cml
				//oper3 instructions
                12'b111100000001: ;               //NOP
                12'b111100010001:begin            //MQL
                    mq <=ac;
                    ac <= 12'o0000;
                end
                12'b111101000001: ac <= ac | mq;  //MQA
                12'b111101010001: begin           //SWP
                    mq <= ac;
                    ac <= mq;
                end
                12'b111110000001: ac <= 12'o0000;  //CLA
                12'b111110010001: begin
                    mq <= 12'o0000;
                    ac <= 12'o0000;
                end
                12'b111111000001: ac <= mq;        //ACL
                12'b111111010001: begin
                    ac <= mq;
                    mq <= 12'o0000;
                end
				// EAE instruction
                12'b111100011001: EAE_mode <= 1;  //SWAB
                12'b111100100111: EAE_mode <= 0;  //SWBA
                12'b111100100001: ac <= ac | {7'b0,sc }; //SCA
                12'b111110100001: ac <=  {7'b0,sc };     //SCA

                default: begin
                    ac <= ac;
                    l <= l;
                    gtf <= gtf;
                end
            endcase

            F2:
            casez (instruction)
                12'b11111??????0:           //oper2 cla
                ac <= 12'o0000;
                12'b1110???????1:           //oper1 IAC
                {l,ac} <= {l,ac} + 13'o00001;
                default:
                begin
                    ac <= ac;
                    l <= l;
                    mq <= mq;
                end
            endcase


            F3:
            casez(instruction)
				//  all 6000 series instructions need to be inhibited in user
				//  mode, I tried to put the if conditional outside of the
				//  casez, it did not work in simulation or on hardware so
				//  we have a much repeated conditional
                12'o6004: if (UF == 1'b0)  //GTF
                    ac <= {l,gtf,input_bus[2:11]};
                else ac <= ac;
                12'o6005: if (UF == 1'b0)  //RTF
                    {l,gtf} <= ac[0:1];
                12'o6007: if (UF == 1'b0)  //CAF
                begin
                    ac <= 12'o0000;
                    l <= 1'b0;
                    gtf <= 1'b0;  //added this Jan 25 2022
                    EAE_mode <= 0;
                    EAE_done <= 0;
                end
                12'o6032: if (UF == 1'b0)
                    ac <= 0;
                else ac <=ac;
                12'o6034: if (UF == 1'b0)
                    ac <= ac | input_bus;
                else ac <= ac;
                12'o6036,12'o6214,12'o6224,12'o6234:
                if (UF == 1'b0)
                    ac <= input_bus;
                else ac <= ac;
               	// oper2 switch operations
                12'b1111?????1?0: if (UF == 1'b0)
                    ac <= ac | sr; // ac may have been cleared in previous phase
                // oper 1 shifts
                12'b1110????000?, // essentially nops
                12'b1110????110?,
                12'b1110????111?:;
                12'b1110????001? : begin  // byte swap
                    ac[0:11]  <= {ac[6:11],ac[0:5]};
                    l <= l;
                end
                12'b1110????010? : begin  // RAL
                    ac[0:11]  <= {ac[1:11],l};
                    l <= ac[0];
                end
                12'b1110????011? : begin  // RTL
                    ac[0:11]  <= {ac[2:11],l,ac[0]};
                    l <= ac[1];
                end
                12'b1110????100? : begin  // RAR
                    ac[0:11]  <= {l,ac[0:10]};
                    l <= ac[11];
                end
                12'b1110????101? : begin  // RTR
                    ac[0:11]  <= {ac[11],l,ac[0:9]};
                    l <= ac[10];
                end
                default:
                begin
                    ac <= ac;
                    l <= l;
                end
            endcase
            D0,D1,D2,D3:;
            E0:; // ac_tmp <= mdout;  // shorten some paths ERROR mdout still settled,
            E1: ac_tmp <= mdout;
            E2: if (instruction[0:2] == AND)
                ac <= ac & ac_tmp;
            else if (instruction[0:2] == TAD)
                {l,ac} <= {l,ac} + {1'b0,ac_tmp};
            else {l,ac} <= {l,ac} ;

            E3: if (instruction[0:2] == DCA) ac <= 12'o0000;
            H0:rac <= ac;
            H1: if (clear == 1)
            begin
                ac <= 12'o0000;
                l <= 1'b0;
            end
            H2:;
            H3:;
            default:;
        endcase

    end

endmodule

