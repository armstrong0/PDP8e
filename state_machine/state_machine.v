module state_machine (
    input clk,
    input reset,
    input halt,
    input single_step,
    input cont,
    input int_req,
    input int_ena,
    input int_inh,
    input UF,
    input trigger,
    /* verilator lint_off ASCRANGE */ 
    input [0:11] instruction,
    ac,
    mq,
    input EAE_mode,
    input EAE_loop,
    input index,  // auto increment occuring
`ifdef RK8E
    input data_break,  // data break write is to disk read is from disk
    input to_disk,
    output reg break_in_prog,
`endif
    output reg int_in_prog,
    output reg [4:0] state,
    output reg run_ff
);

  reg [4:0] next_state;

  `include "../parameters.v"


  always @(posedge clk) begin
    if (reset) begin
      state <= F0;
      run_ff <= 0;
      int_in_prog <= 0;
`ifdef RK8E
      break_in_prog <= 1'b0;
`endif
    end else
      case (state)

        // fetch cycle
        F0: begin
`ifdef RK8E        
          if (data_break == 1'b1) begin  // tried to ifdef this out,
            //format doesn't allow it, it should be optimized out
            state <= DB0;
            break_in_prog <= 1'b1;
          end else 
`endif
          if (run_ff == 0)  begin
            if (cont == 1) begin
                state <= FW;
                run_ff <= 1;
            end    
            else if (trigger == 1) state <= HW;
            else state <= F0;
          end  
          else if((int_req & int_ena & ~int_inh )  &&
                            (instruction != 12'o6002))
               //this solves the ion/iof/ion/iof problem
              begin
            int_in_prog <= 1;
            state <= E0;
          end else begin
            state <= FW;
            int_in_prog <= 0;
          end
        end
        FW: state <= F1;
        F1: begin
          run_ff <= 1;
          casez (instruction & 12'b111100101111)
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
              // any extended EAE operation -- let the compiler figure it out
            begin
              if (EAE_mode == 1'b0) state <= F2A;
              else state <= F2B;
            end
            12'b111100100111,  // SWBA just follow normal flow
            12'b111100011001:  // SWAB action taken by ac in F3;
            state <= F2;
            default: state <= F2;
          endcase
        end
        F2: state <= F3;  // non-EAE case
`ifdef EAE
        F2A:
        casez (instruction)  // Mode A
          12'b1111??0?0101,  // 7405 MUY
          12'b1111??0?0111,  // 7407 DIV
          12'b1111??0?1011,  // 7413 SHL
          12'b1111??0?1101,  // 7415 ASR
          12'b1111??0?1111,  // 7417 LSR
          12'b1111??1?0101,  // SCA - MUL
          12'b1111??1?0111,  // SCA - DIV
          12'b1111?1111011,  // SCA - SHL
          12'b1111?1111101,  // SCA - ASR
          12'b1111??1?1111,  // SCA - LSR
          12'b1111??1?1001,  // SCA - NMI
          12'b111100001001:  // 7411 NMI
          state <= EAE0;
          12'b1111??0?0011,  // 7403 SCL 
          12'b1111??1?0011,  // SCA - SCL
          12'b1111??1?0001,  // SCL both A and B
          12'b1111??0?0001:
          state <= F3;  //NOP
          default: state <= F3;
        endcase

        F2B:
        casez (instruction)  // mode B

          12'b111100001001,  // 7411 NMI
          12'b1111??0?1011,  // 7413 SHL
          12'b1111??0?1101,  // 7415 ASR
          12'b1111??0?1111:  // 7417 LSR
          state <= EAE0;
          12'b1111??0?0101,  // 7405 MUY
          12'b1111??0?0111,  // 7407 DIV
          12'b1111??1?0011,  // DAD - DLD 7443 ,CAMDAD
          12'b1111??1?0101:  // DST 7445
          state <= D0;
          // 12'b1111??1?0111:   // SWBA 7447 taken care of in F2
          // state <= F3;
          12'b1111??1?1001,  // DPSZ 7451
          12'b1111??0?0001,  // NOP
          12'b1111?1111011,  // DPIC 7573
          12'b1111?1111101,  // DCM  7575
          12'b1111??1?1111,  // SAM  7457
          12'b1111??1?0001,  // SCA  7441
          12'b1111??0?0011:  // SCL ACS
          state <= F3;
          default: state <= F3;
        endcase
        E1:
        if ((instruction & 12'o7455) == 12'o7405) state <= EAE0;  // MUL or DIV
        else state <= E2;
        EAE0: state <= EAE1;
        EAE1:
        if (EAE_loop == 1) begin
          state <= EAE1;
        end else begin
          state <= F3;
        end
`endif
        F3:
        casez (instruction)
          // OPR IOT JMP D (single cycle)
          12'b1111??????10: begin
            if (UF == 1'b0) begin  // halt instruction
              run_ff <= 0;
              state   <= F0;  // halt instruction, not in user mode
              end
            else
            begin
              run_ff <= 1;
              state <= F0;  //UI should be set 
            end
          end
          12'b1111??????00,  // remaining group 2  ops
          12'b1111???????1,  // group 3 ops
          12'b1110????????,  // group 1 op
          12'b1010????????,  // JMP Direct
          12'b110?????????:  // IOT instructions
          begin
            state <= F0;
            if (halt == 1) run_ff <=0;
          end
          12'b0??1????????,  // AND TAD ISZ DCA defer cycle
          12'b10?1????????:  // JMS, JMP defer
          begin
            state <= D0;
          end
          12'b1000????????:  // JMS direct 
          state <= E0;
          default: begin
            state <= E0;
          end
        endcase
        D0:
        if (~single_step | cont) state <= DW;
        else state <= D0;
        DW:
        if (index == 1) state <= D1;
        else state <= D3;
        D1: state <= D2;
        D2: state <= D3;
        //  if it is a jmp I then F0 is the desired state
        D3:
        if (instruction[0:3] == JMPI) begin
          state <= F0;
          if (halt == 1) run_ff <=0;
        end else state <= E0;

        // execute cycle
        E0: begin
          if (~single_step | cont) state <= EW;
          else state <= E0;
        end
        EW: state <= E1;
`ifndef EAE
        E1: state <= E2; // replaced by E1 in EAE which has a conditional branch
`endif
        E2: state <= E3;
        E3: begin
            state <= F0;
            if (halt == 1) run_ff <=0;
            end
        HW: state <= H1;
        H1: state <= H2;
        H2: state <= H3;
        H3: state <= F0;

`ifdef RK8E
        // data break
        DB0: state <= DB1;
        DB1: begin
          state <= F0;
          break_in_prog <= 1'b0;
        end
`endif
        default: state <= F0;
      endcase
  end
endmodule

