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
    output reg EAE_loop,
    output reg EAE_skip,
    output reg [0:11] ac,
    output reg [0:11] rac,
    output reg [0:11] rmq);

    reg [0:11] ac_tmp,mq;
    reg [0:4] sc;
	reg il;  // intermediate link used in EAE Double Add
    reg AC_ALL_0;
    reg AC_ALL_1;
    reg MQ_ALL_0;
    reg MQ_ALL_1;
    wire forbidden;

`include "../parameters.v"

    assign forbidden = ((EAE_mode == 0) && (instruction == 12'o7411) ||
			       ((EAE_mode == 1) &&((instruction == 12'o7411) ||
				    (instruction == 12'b111101111011) ||
				    (instruction == 12'b111111111011) ||
				    (instruction == 12'b111101111101) ||
				    (instruction == 12'b111111111101))));

    always @(posedge clk)
    begin
        if (reset|clear)
        begin
            ac <= 12'o0000;
            rac <= 12'o0000;
            mq <= 12'o0000;
            l <= 1'b0;
            gtf <= 1'b0;
            EAE_mode <= 0;
            EAE_loop <= 0;
            EAE_skip <= 0;
            sc <= 5'o00;
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
                EAE_loop <= 0;
                EAE_skip <= 0;
            end
            FW:;
            F1: begin
                casez (instruction)
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
                // below are the instructoions that are part of the base
				// PDP8e.  Without the EAE the bits used by the EAE are set to
				// zero.  However when we implement the EAE we need to
				// consider that some of those bits need to be set.
				// Additionally depending upon the EAE instructions some of
				// these operations are forbidden.
				// Different actions depend  on the mode bit
				// The instructions below execute in this phase of the machine
				// cycle.  Any further operations on the link, ac or mq must
				// happen in the following phases.

                    //12'b111100?0???1:;  //NOP  caught by default
                    12'b111100?1???1: if (!forbidden)
                    begin     //MQL
                        mq <=ac;
                        ac <= 12'o0000;
                    end
                    12'b111101?0???1: if (!forbidden) ac <= ac | mq;  //MQA
                    12'b111101?1???1: if (!forbidden)
                    begin           //SWP
                        mq <= ac;
                        ac <= mq;
                    end
                    12'b111110?0???1: if (!forbidden) ac <= 12'o0000;  //CLA
                    12'b11111001???1: if (! forbidden)
                    begin
                        mq <= 12'o0000;
                        ac <= 12'o0000;
                    end
                    12'b111111?0???1: if (!forbidden)
                        ac <= mq;        //ACL
                    12'b111111?1???1: if (!forbidden)
                    begin
                        ac <= mq;
                        mq <= 12'o0000;
                    end
                    default: begin
                        ac <= ac;
                        l <= l;
                        gtf <= gtf;
                    end
                endcase
            end
            F2: casez (instruction)
                12'b1110???????1:           //oper1 IAC
                {l,ac} <= {l,ac} + 13'o00001;
                12'b11111??????0:           //oper2 cla
                ac <= 12'o0000;
				// oper3
                12'b111100011001: EAE_mode <= 1;  //SWAB 7431
                12'b111100100111:                 //SWBA 7447
                begin
                    EAE_mode <= 0;
                    gtf <= 0;
                end
                12'b111110111001:   // 7671:// skip if mode B
                begin
                    ac <= 12'o0000;
                    mq <= 12'o0000;
                    if(EAE_mode == 1'b1) EAE_skip <= 1;
                end
                12'b111100101001: if (EAE_mode == 1) //7451 DPSZ
                begin
                    if(( AC_ALL_0 == 1) && (MQ_ALL_0 == 1)) EAE_skip <= 1;
                end
                12'b1111??0?0011:   //7403 SCL
                if (EAE_mode == 1'b0) EAE_skip <= 1;
                12'b1111??0?0101,   //7405 MUY
                12'b1111??0?0111 :; //7407 DIV
                12'b1111??0?1011,   //7413 SHL
                12'b1111??0?1101,   //7415 ASR
                12'b1111??0?1111:   //7417 LSR
                begin
                    EAE_skip <= 1;
                    EAE_loop <= 1;
                end
                12'b111100001001:   //7411 NMI can't be combined
                EAE_loop <= 1;


                default:
                begin
                    ac <= ac;
                    l <= l;
                    mq <= mq;
                end
            endcase


            F3: casez(instruction)
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
                    EAE_loop <= 0;
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
				// now some oper3
				// ac may have already been cleared if it
				// needs to be.  some of the other micro op combinations don't
				// make sense
                12'b111100100001:   ac <= ac | {7'b0,sc }; //SCA These two
				// instructions mean the same thing in mode A or B
				// the previous phase may have done things to the AC and MQ
				// as indicated by the question marks...
                12'b1111??0?0011: if (EAE_mode == 1'b0)  // 7403 SCL
                begin
                    sc <= ~mdout[7:11];
                    EAE_skip <= 1;
                end
                else   //7403 ACS
                begin sc <= ac[7:11];
                    ac <= 12'o0000;
                end
                12'b1111?1111011:   //DPIC 7573
                if (MQ_ALL_1 == 1'b1)
                begin
                    mq <= 12'o0000;
                    if (AC_ALL_1 == 1'b1)
                    begin
                        ac <= 12'o0000;
                        l <= 1'b1;
                    end
                    else
                    begin
                        ac <= ac +12'o0001;
                        l <= 1'b0;
                    end
                end
                else
                begin
                    mq <= mq +12'o0001;
                    l <= 1'b0;
                end

                12'b1111?1111101:   //DCM 7575
                if (MQ_ALL_0 == 1'b1)
                begin  // 0000 complimented then add 1 results in all 0 mq and a carry
                    if (AC_ALL_0 == 1'b1)
                    begin
                        l <= 1'b1;
                    end
                    else
                    begin
                        l <= 1'b0;
                        ac <= ~ac + 12'o0001;
                    end
                end
                else
                begin
                    mq <= ~mq + 12'o0001;
                    l <= 1'b0;
                end
                12'b1111??1?1111:   // 7457 SAM
                if (EAE_mode == 1'b1)
                begin
                    {gtf,ac } <= {mq[0],mq} + ~{ac[0],ac} + 13'b1;
                end
                default:
                begin
                    ac <= ac;
                    l <= l;
                end
            endcase

            D0,DW,D1,D2,D3:;
            E0,EW:; // ac_tmp <= mdout;  // shorten some paths ERROR mdout still settled,
            E1: ac_tmp <= mdout;
            E2: if (instruction[0:2] == AND)
                ac <= ac & ac_tmp;
            else if (instruction[0:2] == TAD)
                {l,ac} <= {l,ac} + {1'b0,ac_tmp};
            else {l,ac} <= {l,ac} ;

            E3: if (instruction[0:2] == DCA) ac <= 12'o0000;
			else if ((instruction & 12'b111100101111) == 12'o7443)  //DAD
			begin
			     {l,ac } <= {1'b0,ac} + {1'b0,mdout} + il;
			end	 

            H0:rac <= ac;
            HW:;
            H1: if (clear == 1)
            begin
                ac <= 12'o0000;
                l <= 1'b0;
            end
            H2:;
            H3:;
            //   EAE stuff 
            EAE0:begin   // set up state
                case (instruction & 12'b111100001111)
				    // MUL
					// 12'o7405:
					// DIV
					// 12'o7407:
                    12'o7413: // SHL
                    if (EAE_mode == 1'b0)
                    begin
                        gtf <= 0;
                        if (mdout[7:11] >= 5'd24 ) // then no need to shift
                        begin
                            sc <= 5'd0;
                            ac <= 12'd0;
                            mq <= 12'd0;
                            l  <= 1'b0;
                            EAE_loop <= 0;
                        end
                        else
                        begin
                            sc <= mdout[7:11] + 5'd1;
                        end
                    end
                    else if ((mdout[7:11] >= 5'd25 )||
                            (mdout[7:11] == 5'd0  ))
                        	// B Mode
                        	// then no need to shift
                    begin
                        sc <= 5'd0;
                        ac <= 12'd0;
                        mq <= 12'd0;
                        l  <= 1'b0;
                        EAE_loop <= 0;
                    end
                    else
                        sc <= mdout[7:11];

                    12'o7415:  //ASR
                    if (EAE_mode == 1'b0)    // mode A
                    begin
                        gtf <= 1'b0;
                        if (mdout[7:11] >= 5'd24 ) // then no need to shift
                        begin
                            sc <= 5'b0;
                            EAE_loop <= 1'b0;
                            if ( ac[0] == 1'b0) // positive number
                            begin
                                ac <= 12'd0;
                                mq <= 12'd0;
                                l <= 1'b0;
                            end
                            else
                            begin  // negative number
                                ac <= 12'o7777;
                                mq <= 12'o7777;
                                l  <= 1'b1;
                            end
                        end
                        else
                        begin
                            sc <= mdout[7:11] + 5'd1; //valid shift
                        end
                    end
                    else  //mode B
                    if (mdout[7:11] >= 5'd25 )
                    begin
                        sc <= 5'b0;
                        EAE_loop <= 1'b0;
                        if ( ac[0] == 1'b0) // positive number
                        begin
                            ac <= 12'd0;
                            mq <= 12'd0;
                            l <= 1'b0;
                            gtf <= 1'b0;
                        end
                        else
                        begin  // negative number
                            ac <= 12'o7777;
                            mq <= 12'o7777;
                            l  <= 1'b1;
                            gtf <= 1'b1;

                        end
                    end
                    else if (mdout[7:11] == 5'd0)
                    begin
                        EAE_loop <= 1'b0;
                        l <= ac[0];
                    end
                    else
                        sc <= mdout[7:11];

                    12'o7417: //LSR
                    if (mdout[7:11] > 25 ) // then no need to shift
                    begin
                        ac <= 12'd0;
                        mq <= 12'd0;
                        l  <= 1'b0;
                        sc <= 5'd0;
                        EAE_loop <= 0;
                    end
                    else
                    if (EAE_mode == 1'b0)
                    begin
                        sc <= mdout[7:11] + 5'd1;
                    end
                    else
                        sc <= mdout[7:11];


                    12'o7411:   // NMI
                    if (((ac[0] != ac[1])||
                                (ac[0:1] == 2'o0)) &&
                            (ac[2:11] == 10'o0) &&
                            (mq == 12'o0))
                         // already normalized
                    begin
                        sc <= 5'd0;
                        EAE_loop <= 0;
                    end
                    else
                        sc <= 5'o0;
                    default:;

                endcase
            end
            EAE1:begin  // iteration state
                if (EAE_loop == 1)
                begin
				  // MUL
					// 12'o7405:
					// DIV
					// 12'o7407:

                    if (instruction == 12'o7411) //NMI
                    begin
                        {l,ac,mq} <= {ac,mq,1'b0};
                        sc <= sc + 5'd1;
					    // conditional set for next iteration
                        if ((ac[1] != ac[2])
                                || ((ac[3:11] == 9'o0)
                                    && (mq == 12'o0)))
                            EAE_loop <= 0;  // we are finished
                    end
                    if (instruction == 12'o7413)  // SHL
                    begin
                        {l,ac,mq} <= {ac,mq,1'b0};
                        sc <= sc - 5'd1;
                        if (sc == 5'd1 ) EAE_loop <= 0;
                    end
                    if (instruction == 12'o7415)   // ASR
                    begin
                        {ac,mq} <=  {ac[0],ac,mq[0:10]};
                        if (EAE_mode == 1'b1) gtf <= mq[11];
                        ac[0] <= ac[0];
                        l <= ac[0];
                        sc <= sc - 5'd1;
                        if (sc == 5'd1 ) EAE_loop <= 0;
                    end
                    if (instruction == 12'o7417) // LSR
                    begin
                        {ac,mq} <=  {1'b0,ac,mq[0:10]};
                        if (EAE_mode == 1'b1) gtf <= mq[11];
                        l <= 0;
                        sc <= sc - 5'd1;
                        if (sc == 5'd1 ) EAE_loop <= 0;
                    end
                end
               // if (sc == 5'd1 ) EAE_loop <= 0;
            end
			EAE2:;
			EAE3:;
			EAE4:
			if ((instruction & 12'b111100101111) == 12'o7443)  //DAD
			begin
			     {il,mq } <= {1'b0,mq} + {1'b0,mdout};
			end	 
			EAE5:;

            default:;
        endcase

    end

endmodule

