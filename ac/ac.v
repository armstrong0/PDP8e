/* verilator lint_off LITENDIAN */
module Ac (input clk,  // have to rename the mdulate for verilator
    input reset,
    input clear,
    input [4:0] state,
    input [0:11] instruction,
    input [0:11] sr,
    input [0:11] mdout,
    input [0:11] input_bus,
    input UF,
    output reg link,
    output reg gtf,
    output reg EAE_mode,
    output reg EAE_loop,
    output reg [0:11] ac,
    output reg [0:11] mq);

    reg [0:11] ac_tmp;
    reg [0:4] sc;
    reg tmp;
    reg [4:0] amount;
`ifdef EAE
    wire [0:12] div_temp,div_ov;
    assign div_ov = {1'b0 ,ac}   - {1'b0, mdout};
    assign div_temp = {ac,mq[0]} - {1'b0, mdout};
`endif

`include "../parameters.v"


    always @(posedge clk)
    begin
        if (reset | clear)
        begin
            ac <= 12'o0;
            mq <= 12'o0;
            link <= 1'b0;
            gtf  <= 1'b0;
            EAE_mode <= 0;
            EAE_loop <= 0;
            sc <= 5'o00;
        end
        else
        begin
            ac <= ac;
            mq <= mq;
            link <= link;
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
                12'b11100000????:                // nop
                {link,ac} <= {link,ac};
                12'b11100001????:                // cml
                {link,ac} <= {~link,ac};
                12'b11100010????:                // cma
                {link,ac} <= {link,~ac};
                12'b11100011????:                // cml cma
                {link,ac} <= {~link,~ac};
                12'b11100100????:                // cll
                {link,ac} <= {1'b0,ac};
                12'b11100101????:                // cll cml
                {link,ac} <= {1'b1,ac};
                12'b11100110????:                // cll cma
                {link,ac} <= {1'b0,~ac};
                12'b11100111????:                // cll cml cma
                {link,ac} <= {1'b1,~ac};
                12'b11101000????:                // cla
                {link,ac} <= {link,12'o0};
                12'b11101001????:                // cla cml
                {link,ac} <= {~link,12'o0};
                12'b11101010????:                // cla cma
                {link,ac} <= {link,12'o7777};
                12'b11101011????:                // cla cma cml
                {link,ac} <= {~link,12'o7777};
                12'b11101100????:                // cla cll
                {link,ac} <= {1'b0,12'o0};
                12'b11101101????:                // cla cll cml
                {link,ac} <= {1'b1,12'o0};
                12'b11101110????:                // cla cll cma
                {link,ac} <= {1'b0,12'o7777};
                12'b11101111????:                // cla cll cma cml
                {link,ac} <= {1'b1,12'o7777};

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
                    ac <= 12'o0;
                end
                12'b111101?0???1: ac <= ac | mq;  //MQA
                12'b111101?1???1:  //SWP
                begin
                    mq <= ac;
                    ac <= mq;
                end
                12'b111110?0???1:  ac <= 12'o0;  //CLA
                12'b111110?1???1:  // CAM
                begin
                    mq <= 12'o0;
                    ac <= 12'o0;
                end
                12'b111111?0???1: ac <= mq;        // ACL
                12'b111111?1???1:    // CLA SWP
                begin
                    mq <= 12'o0;
                    ac <= mq;
                end
                default: begin
                    ac <= ac;
                    link <= link;
                    gtf <= gtf;
                end
            endcase

            F2:  // Non-EAE mode
            casez (instruction)
                12'b1110???????1:           //oper1 IAC
                {link,ac} <= {link,ac} + 13'o00001;
                12'b11111??????0:           //oper2 cla
                ac <= 12'o0;
                default:;
            endcase
            F2A:; // EAE A mode
            F2B:  //EAE Mode B
            if ((instruction & 12'b111100101111) == 12'b111100101111)
                 // 7457 SAM first phase
                {link,ac_tmp} <= {1'b0,mq} + ~{1'b1,ac} +13'o00001;
            else if ((instruction & 12'b111100101111) == 12'b111110111001)
                 // 7471:  skip if mode B
            begin
                ac <= 12'o0;
                mq <= 12'o0;
            end

            F3: casez(instruction)
                //  all 6000 series instructions need to be inhibited in user
                //  mode, I tried to put the if conditional outside of the
                //  casez, it did not work in simulation or on hardware so
                //  we have a much repeated conditional
                12'o6004: if (UF == 1'b0)  //GTF
                    ac <= {link,gtf,input_bus[2:11]};
                else ac <= ac;
                12'o6005: if (UF == 1'b0)  //RTF
                    {link,gtf} <= ac[0:1];
                12'o6007: if (UF == 1'b0)  //CAF
                begin
                    ac   <= 12'o0;
                    link <= 1'b0;
                    gtf  <= 1'b0;
                    EAE_mode <= 0;
                    EAE_loop <= 0;
                end
                12'o6742,
                12'o6743,
                12'o6744,
                12'o6746,  // Disk actions
                12'o6032: if (UF == 1'b0)
                    ac <= 0;
                else ac <=ac;
                12'o6034: if (UF == 1'b0)
                    ac <= ac | input_bus;
                else ac <= ac;
                12'o6036,12'o6214,12'o6224,12'o6234,  //extended memory
                12'o6747,   // DMAN
                12'o6745:   // DISK status read
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
                    link <= link;
                end
                12'b1110????010? : begin  // RAL
                    ac[0:11]  <= {ac[1:11],link};
                    link <= ac[0];
                end
                12'b1110????011? : begin  // RTL
                    ac[0:11]  <= {ac[2:11],link,ac[0]};
                    link <= ac[1];
                end
                12'b1110????100? : begin  // RAR
                    ac[0:11]  <= {link,ac[0:10]};
                    link <= ac[11];
                end
                12'b1110????101? : begin  // RTR
                    ac[0:11]  <= {ac[11],link,ac[0:9]};
                    link <= ac[10];
                end
                // now some oper3;

                // ac may have already been cleared if it
                // needs to be.  some of the other micro op combinations don't
                // make sense
            //    12'b1111??0?0011: if (EAE_mode == 1'b1)  //  ASC
            //    begin
            //        sc <= ac[7:11];
            //        ac <= 12'o0;
            //    end
                12'b1111??1?0001: if (EAE_mode == 1'b1)
                    ac <= ac | {7'b0,sc };           //SCA  B mode
                12'b111101111011: if (EAE_mode == 1'b1)  //DPIC 7573 XXXXX,7773
                begin // note an earlier phase has swapped ac and mq
                    if (ac == 12'o7777)
                    begin
                        mq <= 12'o0;
                        if (mq == 12'o7777)
                        begin
                            ac <= 12'o0;
                            link <= 1'b1;
                        end
                        else
                        begin
                            ac <= mq + 12'o01;
                            link <= 1'b0;
                        end
                    end
                    else
                    begin
                        mq <= ac + 12'o01;
                        ac <= mq;
                        link <= 1'b0;
                    end
                end
                12'b1111?1111101: if (EAE_mode == 1'b1)   //DCM 7575
                begin // note an earlier phase has swapped ac and mq
                    if (ac == 12'o0)
                    begin  // two's compliment of 0000 is 0000 and a carry
                        if (mq == 12'o0)
                        begin // no need to swap they are both 0000
                            link <= 1'b1;
                        end
                        else
                        begin
                            link <= 1'b0;
                            ac <= ~mq + 12'o01;
                            mq <= ac;
                        end
                    end
                    else
                    begin
                        mq <= ~ac + 12'o01;
                        ac <= ~mq;
                        link <= 1'b0;
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
                    ac <= ac_tmp;
                    case ({ac_tmp[0],ac[0],mq[0]})
                        3'b000,3'b010,3'b011,3'b110: gtf <= 1'b1;
                        3'b001,3'b100,3'b101,3'b111: gtf <= 1'b0;
                        default: gtf <= 0;
                    endcase
                end

                default:
                begin
                    ac <= ac;
                    link <= link;
                end
            endcase

            D0,DW,D1,D2,D3:;
            E0,EW: ac_tmp <= mdout;  // shorten some paths ERROR mdout still settled,
            E1:begin
`ifdef EAE            
            if (instruction == DAD)  //DAD
                {link,mq } <= {1'b0,mq} + {1'b0,mdout};
            else if ((instruction == DLD)||(instruction == CAMDAD))
                mq <= mdout;
`endif            
            end
            E2: if (instruction[0:2] == AND)
                ac <= ac & mdout;
            else if (instruction[0:2] == TAD)
                {link,ac} <= {link,ac} + {1'b0,mdout};
            else {link,ac} <= {link,ac} ;

            E3:begin
            if (instruction[0:2] == DCA) ac <= 12'o0;
`ifdef EAE
            else if (instruction == DAD)  //DAD
                {link,ac } <= {1'b0,ac} + {1'b0,mdout} +{12'o0,link};
            else if ((instruction == DLD) || (instruction ==CAMDAD)) //
                ac <= mdout;
`endif
            end

            HW:;
            H1:;
            H2: if (clear == 1)
            begin
                ac <= 12'o0;
                mq <= 12'o0;
                link <= 1'b0;
                gtf <= 1'b0;
                EAE_mode <= 0;
                EAE_loop <= 0;
                sc <= 5'o00;
            end
            H3:;
            //   EAE stuff
`ifdef EAE
            EAE2:
            begin   // set up state
                case (instruction & 12'b111100001111)
                    // at this point in execution MUL DIV and NMI are the same
                    // for both A and B modes
                    // MUL
                    12'o7405:
                    begin
                        link <= 1'b0;
                        EAE_loop <= 1'b1;
                        sc <= 5'd12;
                    end
                    // DIV
                    12'o7407: begin
                        if (div_ov[0] == 1'b0) // divide overflow
                        begin
                            link <= 1'b1;
                            sc <= 5'd1;
                            EAE_loop <= 1'b0;
                            mq <= {mq[1:11], 1'b1};
                        end
                        else
                        begin
                            EAE_loop <= 1'b1;
                            sc <= 5'd0;
                            link <= 1'b0;
                        end
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
                            ac <= 12'o0;
                    end
                    else
                    begin
                        sc <= 5'o0;
                        link <= ac[0];
                        EAE_loop <= 1'b1;
                    end
                    default:;
                endcase

                if (EAE_mode == 1'b0) 
                ////  MODE A
                begin  
                   if (instruction[6] == 1'b1) // SCA)
                   begin
                       ac <= ac | {7'o00, sc };
                       EAE_loop <= 1'b0;
                   end
                   case (instruction & 12'b111100001111)
                       12'o7403:  sc <= ~mdout[7:11]; //SCL
                       12'o7417, // LSR
                       12'o7413: // SHL
                       //if (EAE_mode == 1'b0)
                       begin
                           if (mdout[7:11] >= 5'd24 ) // then no need to shift
                           begin
                               sc <= 5'd0;
                               EAE_loop <= 0;
                               {link,ac,mq} <= 25'b0;
                           end
                           else
                           begin
                               link <= 1'b0;
                               sc <= mdout[7:11] + 5'd1;
                               EAE_loop <= 1'b1;
                           end
                       end
                  
                        12'o7415:  //ASR
                        begin
                            if (mdout[7:11] >= 5'd24 ) // then no need to shift
                            begin
                                sc <= 5'b0;
                                EAE_loop <= 1'b0;
                                if ( ac[0] == 1'b0) // positive number
                                begin
                                   {link,ac,mq} <= 25'b0;
                                end
                                else
                                begin  // negative number
                                   {link,ac,mq} <= ~25'b0;
                                end
                            end
                            else
                            begin
                                link <= ac[0];
                                sc <= mdout[7:11] + 5'd1; //valid shift
                                EAE_loop <= 1'b1;
                            end
                        end
                                 endcase
                end
////  MODE B         
                else
                   case (instruction & 12'b111100001111)
                    12'o7403: //  ACS
                    begin
                        sc <= ac[7:11];
                        ac <= 12'o0;
                    end
                    12'o7417, // LSR
                    12'o7413: // SHL
                    if (mdout[7:11] >= 5'd25 )
                    begin
                        {link,ac,mq} <= 25'b0;
                        if (instruction == LSR ) gtf <= 1'b0;
                    end
                    else if  (mdout[7:11] == 5'd0  )
                    begin
                        sc <= 5'o37;
                        EAE_loop <= 0;
                        if (instruction == 12'o7417) link <= 1'b0;
                    end
                    else
                    begin
                        sc <= mdout[7:11];
                        link <= 1'b0;
                        EAE_loop <= 1'b1;
                    end

                    12'o7415:  //ASR
                    if (mdout[7:11] >= 5'd25 )
                    begin
                        sc <= 5'o37;
                        EAE_loop <= 1'b0;
                        if ( ac[0] == 1'b0) // positive number
                        begin
                            ac <= 12'o0;
                            mq <= 12'o0;
                            link <= 1'b0;
                            gtf <= 1'b0;
                        end
                        else
                        begin  // negative number
                            ac <= 12'o7777;
                            mq <= 12'o7777;
                            link  <= 1'b1;
                            gtf <= 1'b1;

                        end
                    end
                    else if (mdout[7:11] == 5'd0)
                    begin
                        EAE_loop <= 1'b0;
                        link <= ac[0];
                    end
                    else
                    begin
                        sc <= mdout[7:11];
                        link <= ac[0];
                        EAE_loop <= 1'b1;
                    end
                default:;

                endcase
            end
            EAE3:
            begin  // iteration state
                case (instruction & 12'b111100001111)
                    12'o7405: //MUL
                    if (EAE_loop == 1'b1)
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
                    12'o7407:  // DIV
                    begin // the original PDP8e used non restoring division.
                    // here I am using restoring devision BUT since the old
                    // values are still around I use those, shifted without
                    // the subtraction
                        if (link == 1'b0)   // no overflow
                        begin
                            if (div_temp[0] == 1'b0)
                            begin
                                ac <=  div_temp[1:12];
                                mq <= {mq[1:11], 1'b1};
                            end
                            else

                            begin
                                ac <= {ac[1:11],mq[0]};
                                mq <= {mq[1:11],1'b0};
                            end
                            sc <= sc + 5'd1;
                            if (sc == 5'd10)  EAE_loop <= 1'b0;
                        end
                    end

                    12'o7411:  // must be exact
                    begin
                    if ((instruction == 12'o7411) && (EAE_loop == 1'b1)) //NMI
                    begin
                        {link,ac,mq} <= {ac,mq,1'b0};
                        sc <= sc + 5'd1;
                        // conditional set for next iteration
                        if ((ac[1] != ac[2])
                                || ((ac[3:11] == 9'o0)
                                    && (mq == 12'o0)))
                            EAE_loop <= 0;  // we are finished
                    end
                   end
 
                    12'o7413:  // SHL
                    if (EAE_loop == 1'b1)
                    begin
                        {link,ac,mq} <= {ac,mq,1'b0};
                        if (sc == 5'd1 ) begin
                            EAE_loop <= 0;
                            if (EAE_mode == 1'b1) sc <=5'o37;
                            else sc <= 5'd0;
                        end
                        else
                            sc <= sc - 5'd1;

                    end
                    12'o7415,   // ASR
                    12'o7417:   // LSR
                    if (EAE_loop == 1'b1)
                    begin
                        {ac,mq} <=  {link,ac,mq[0:10]};
                        if (EAE_mode == 1'b1) gtf <= mq[11];
                        if (sc == 5'd1 ) begin
                            EAE_loop <= 0;
                            if (EAE_mode == 1'b1)
                                sc <= 5'o37;
                            else sc <= 5'o0;
                        end
                        else sc <= sc - 5'd1;

                    end

                    default:;
                endcase
            end
`endif
            default:;
        endcase

    end

endmodule

