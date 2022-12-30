module pc(
    input clk,
    input reset,
    input skip,eskip,
    input isz_skip,
    input [4:0] state,
    input [0:11] ma,
    input [0:11] instruction,
    input [0:11] mdout,
    input int_in_prog,
    output reg [0:11] pc);

    reg [0:11] next_pc,skip_pc;

`include "../parameters.v"

    always @(posedge clk) begin

        if (reset)
        begin
            pc <= 12'o0200;
        end
        else
            pc <= pc;
        case (state)
            F0:;
            FW:;
            F1:;
            F2A,F2B,F2: begin
                skip_pc <= pc + 12'o0002;
                next_pc <= pc + 12'o0001;
            end
            F3: begin
                if ((instruction[0:1] == 2'b11) && ((skip == 1) || (eskip ==1)))
                    pc <= skip_pc;
                else if(instruction[0:3] == JMPD)
                begin // jmp direct
                    if (instruction[4] == 0)   // page 0
                        pc <= { 5'b00000,instruction[5:11]};
                    else  // current page
                        pc <= {pc[0:4],instruction[5:11]};
                end
                else
                    pc <= next_pc;
            end
            D0,D1,D2:;
            D3:  if (instruction [0:3] == JMPI )// jmp indirect
                pc <= ma;
            E0:;
            E1:;
            E2: if (instruction[0:2] == JMS)
                if (int_in_prog)
                    next_pc <= 12'o0001;
                else
                    next_pc <= ma +12'o0001;
                else if ((instruction[0:2] == ISZ) && (isz_skip == 1'b1))
                    next_pc <= next_pc + 12'o0001;
            E3: if (eskip == 1'b1)
                pc <= skip_pc;
            else
                pc <= next_pc;
            H0,H1,H2: ;
            H3: pc <= ma;  // sync the pc with the ma
            default:;
        endcase

    end
endmodule
