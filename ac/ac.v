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
    output reg [0:11] ac,
    output reg [0:11] mq);

    reg [0:11] ac_tmp;
    reg [0:4] sc;
    reg il;  // intermediate link used in EAE DAD and  SAM
    wire forbidden;
    reg tmp;

`include "../parameters.v"


    always @(posedge clk)
    begin
        if (reset)
        begin
            ac <= 12'o0000;
            mq <= 12'o0000;
            l <= 1'b0;
            gtf <= 1'b0;
            EAE_mode <= 0;
            EAE_loop <= 0;
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
                EAE_loop <= 0;
                if (EAE_mode == 1'b0) gtf <= 1'b0;  // gtf must be 0 in mode A
            end
            FW:;
            F1:
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
				// Different actions depend  on the mode bit
				// The instructions below execute in this phase of the machine
				// cycle.  Any further operations on the link, ac or mq must
				// happen in the following phases.

                    //12'b111100?0???1:;  //NOP  caught by default
                12'b111100?1???1:  //MQL
                begin
                    mq <= ac;
                    ac <= 12'o0000;
                end
                12'b111101?0???1: ac <= ac | mq;  //MQA
                12'b111101?1???1:  //SWP
                begin
                    mq <= ac;
                    ac <= mq;
                end
                12'b111110?0???1:  ac <= 12'o0000;  //CLA
                12'b111110?1???1:  // CAM
                begin
                    mq <= 12'o0000;
                    ac <= 12'o0000;
                end
                12'b111111?0???1: ac <= mq;        // ACL
                12'b111111?1???1:    // CLA SWP
                begin
                    mq <= 12'o0000;
                    ac <= mq;
                end
                default: begin
                    ac <= ac;
                    l <= l;
                    gtf <= gtf;
                end
            endcase

            F2:  // Non-EAE mode
            casez (instruction)
                12'b1110???????1:           //oper1 IAC
                {l,ac} <= {l,ac} + 13'o00001;
                12'b11111??????0:           //oper2 cla
                ac <= 12'o0000;
                default:;
            endcase
            F2A: // EAE A mode
            if (instruction[6] == 1'b1 ) //SCA in mode A
                ac <= ac | {7'b0,sc };

            else if (instruction == 12'b111100001001)   //7411 NMI can't be combined
                EAE_loop <= 1;

            else begin
                ac <= ac;
                l <= l;
                mq <= mq;
            end

            F2B: //EAE Mode B
            if ((instruction & 12'b111100101111) == 12'b111100101111)
                 // 7457 SAM first phase
                {il,ac_tmp} <= {1'b0,mq} + ~{1'b1,ac} +13'b1;
            else if ((instruction & 12'b111100101111) == 12'b111110111001)
                 // 7471:  skip if mode B
            begin
                ac <= 12'o0000;
                mq <= 12'o0000;
            end

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
				// now some oper3;

				// ac may have already been cleared if it
				// needs to be.  some of the other micro op combinations don't
				// make sense
                12'b1111??0?0011: if (EAE_mode == 1'b0)  // 7403 SCL
                begin
                    sc <= ~mdout[7:11];
                end
                else   //7403 ACS
                begin
                    sc <= ac[7:11];
                    ac <= 12'o0000;
                end
                12'b1111??1?0001: if (EAE_mode == 1'b1)
                    ac <= ac | {7'b0,sc };           //SCA  B mode
                12'b1111?1111011: if (EAE_mode == 1'b1)  //DPIC 757n
                begin // note an earlier phase has swapped ac and mq
                    if (ac == 12'o7777)
                    begin
                        mq <= 12'o0000;
                        if (mq == 12'o7777)
                        begin
                            ac <= 12'o0000;
                            l <= 1'b1;
                        end
                        else
                        begin
                            ac <= mq +12'o0001;
                            l <= 1'b0;
                        end
                    end
                    else
                    begin
                        mq <= ac +12'o0001;
                        ac <= mq;
                        l <= 1'b0;
                    end
                end
                12'b1111?1111101: if (EAE_mode == 1'b1)   //DCM 7575
                begin // note an earlier phase has swapped ac and mq
                    if (ac == 12'o0000)
                    begin  // two's compliment of 0000 is 0000 and a carry
                        if (mq == 12'o0000)
                        begin // no need to swap they are both 0000
                            l <= 1'b1;
                        end
                        else
                        begin
                            l <= 1'b0;
                            ac <= ~mq + 12'o0001;
                            mq <= ac;
                        end
                    end
                    else
                    begin
                        mq <= ~ac + 12'o0001;
                        ac <= ~mq;
                        l <= 1'b0;
                    end
                end
                12'b111100011001: EAE_mode <= 1'b1;      //SWAB 7431
                12'b111100100111: if (EAE_mode == 1'b1)  //SWBA 7447
                begin
                    EAE_mode <= 0;
                    gtf <= 0;
                end
                12'b1111??1?1111:   // 7457 SAM second phase
                if (EAE_mode == 1'b1)
                begin
                    l <= il;
                    ac <= ac_tmp;
                    case ({ac_tmp[0],ac[0],mq[0]})
                        3'b000,3'b010,3'b011,3'b110: gtf <= 1'b1;
                        3'b001,3'b100,3'b101,3'b111: gtf <= 1'b0;
                    endcase
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
            else if (instruction == DAD)  //DAD
                {l,ac } <= {1'b0,ac} + {1'b0,mdout} +{12'o0000,il};
            else if (instruction == DLD)
                ac <= mdout;

            H0:;
            HW:;
            H1:;
            H2: if (clear == 1)
            begin
                ac <= 12'o0000;
                mq <= 12'o0000;
                l <= 1'b0;
                gtf <= 1'b0;
                EAE_mode <= 0;
                EAE_loop <= 0;
                sc <= 5'o00;
            end
            H3:;
            //   EAE stuff
            EAE0:begin   // set up state
                case (instruction & 12'b111100001111)
				    // MUL
                    12'o7405:
                    begin
                        EAE_loop <= 1'b1;
                        sc <= 5'd12;
                    end
					// DIV
                    12'o7407: begin
                        if (mdout < ac)  // this may need to be <=
                        begin
                            EAE_loop <= 1'b0;  // divide overflow terminate
                            sc <= 5'd0;
                        end
                        else
                        begin
                            EAE_loop <= 1'b1;
                            sc <= 5'd13;
                        end
                    end
                    12'o7413, // SHL
                    12'o7417: // LSR
                    if (EAE_mode == 1'b0)
                    begin
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
                            l <= 1'b0;
                            sc <= mdout[7:11] + 5'd1;
                            EAE_loop <= 1'b1;
                        end
                    end
                    else if (mdout[7:11] >= 5'd25 )
                    begin
                        // B Mode  then no need to shift
                        // but the link needs to be cleared
                        l <= 1'b0;
                        ac <= 12'd0;
                        mq <= 12'd0;
                        if (instruction == LSR ) gtf <= 1'b0;
                    end
                    else if  (mdout[7:11] == 5'd0  )
                    begin
                        sc <= 5'o37;
                        EAE_loop <= 0;
                        if (instruction == 12'o7417) l <= 1'b0;
                    end
                    else
                    begin
                        sc <= mdout[7:11];
                        l <= 1'b0;
                        EAE_loop <= 1'b1;
                    end

                    12'o7415:  //ASR
                    if (EAE_mode == 1'b0)    // mode A
                    begin
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
                            l <= ac[0];
                            sc <= mdout[7:11] + 5'd1; //valid shift
                            EAE_loop <= 1'b1;
                        end
                    end
                    else  //mode B
                    if (mdout[7:11] >= 5'd25 )
                    begin
                        sc <= 5'o37;
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
                    begin
                        sc <= mdout[7:11];
                        l <= ac[0];
                        EAE_loop <= 1'b1;
                    end

                    12'o7411:   // NMI
                    if (((ac[0] != ac[1])||
                                (ac[0:1] == 2'o0)) &&
                            (ac[2:11] == 10'o0) &&
                            (mq == 12'o0))
                         // already normalized
                    begin
                        sc <= 5'd0;
                        EAE_loop <= 0;
                        if (EAE_mode == 1'b1)
                            ac <= 12'o0000;
                    end
                    else
                    begin
                        sc <= 5'o0;
                        l <= ac[0];
                        EAE_loop <= 1'b1;
                    end
                    default:;

                endcase
                if ((EAE_mode == 1'b0) && (instruction[6] == 1'b1)) // SCA)
                begin
                    ac <= ac | {7'o00, sc };
                    EAE_loop <= 1'b0;
                end
            end
            EAE1:begin  // iteration state
                if (EAE_loop == 1)
                begin
				  // MUL
                    if (instruction == 12'o7405)
                    begin
                        sc <= sc - 5'd1;
                        if (mq[11] == 1'b1)
                        begin
                            {ac,mq[0]} <= {1'b0, ac} + {1'b0,mdout};
                            mq[1:11] <= mq[0:10];
                        end
                        else
                        begin
                            {ac,mq} <=  {1'b0,ac,mq[0:10]};
                        end

                        if (sc == 5'd1) EAE_loop <= 0;
                    end
					// DIV
                    else if (instruction == 12'o7407)
                    begin // there are two cases here depending upon some
					// condition we either add or subtract from a shifted
					// ac,mq
					// the maintenance manual is hard to follow because of
					// the ac is stored in normal or complement form depending
					// on the last operation
					// we have to remember what the sign bit of the last ac
					// was so we can patch up mq
                        if (sc == 5'o1) // last iteration
                        begin
                            if (ac[0] == 1'b1)
                                ac <= ac + mdout;
                            mq <= {mq[1:11],1'b0};
                        end
                        else if (ac[0] == 1'b0)
                        begin
                            ac <={ac[1:11],mq[0]} - mdout;
                            mq[0:10] <= mq[1:11];
                            if (sc == 5'o14)
                                mq[11] <= 1'b0;
                            else
                                mq[11] <= 1'b1;
                        end
                        else
                        begin
                            ac <={ac[1:11],mq[0]} + mdout;
                            mq[0:10] <= mq[1:11];
                            mq[11] <= 1'b0;
                        end
                        il <= ac[0]; //set up for next iteration
                        tmp <= il ^ ac[0];
                        sc <= sc - 5'd1;
                        if (sc == 5'd1)  EAE_loop <= 1'b0;
                    end

                    else if (instruction == 12'o7411) //NMI
                    begin
                        {l,ac,mq} <= {ac,mq,1'b0};
                        sc <= sc + 5'd1;
					    // conditional set for next iteration
                        if ((ac[1] != ac[2])
                                || ((ac[3:11] == 9'o0)
                                    && (mq == 12'o0)))
                            EAE_loop <= 0;  // we are finished
                    end
                    else if (instruction == 12'o7413)  // SHL
                    begin
                        {l,ac,mq} <= {ac,mq,1'b0};
                        if (sc == 5'd1 ) begin
                            EAE_loop <= 0;
                            if (EAE_mode == 1'b1) sc <=5'o37;
                            else sc <= 5'd0;
                        end
                        else
                            sc <= sc - 5'd1;

                    end
                    else if ((instruction == 12'o7415) ||   // ASR
                            (instruction == 12'o7417))     // LSR
                    begin
                        {ac,mq} <=  {l,ac,mq[0:10]};  // was ac[0] but the setup put ac[0] into l
                        if (EAE_mode == 1'b1) gtf <= mq[11];
                        //l <= ac[0];
                        if (sc == 5'd1 ) begin
                            EAE_loop <= 0;
                            if (EAE_mode == 1'b1)
                                sc <= 5'o37;
                            else sc <= 5'o0;
                        end
                        else sc <= sc - 5'd1;

                    end
                end
            end
            EAE2:;
            EAE3: if (instruction == DAD)  //DAD
                {il,mq } <= {1'b0,mq} + {1'b0,mdout};
            else if (instruction == DLD)
                mq <= mdout;
            EAE4:;
            EAE5:;
            default:;
        endcase

    end

endmodule

