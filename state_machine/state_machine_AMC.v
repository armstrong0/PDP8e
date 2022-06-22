module state_machine(input clk,
    input reset,
    input halt,
    input single_step,
    input cont,
    input int_req,
    input int_ena,
    input int_inh,
    input trigger,
    input [0:11] instruction,pc,
    output reg int_in_prog,
    output reg [4:0] state,
	output reg rdy);
	
    reg [1:0] cnt;

`include "../parameters.v"

    always @(posedge clk)
    begin
        if (reset)
        begin
            state <= H0;
            int_in_prog <= 0;
			cnt <= 2'b10;
        end
        else case (state)

                // fetch cycle
                F0: begin
                    if ((~single_step | cont) && (cnt == 2'b00 ))
                        state <= F1;
                    else 
					begin 
					    state <= F0;
						if ( cnt != 0) 
                            cnt <= cnt - 2'b01;
					end	
                    int_in_prog <= 0;
                end
                F1: state <= F2;
                F2:begin
                    state <= F3;
                   end
                F3:if ((instruction[0:1] == 2'b11) || (instruction[0:3] == 4'b1010)) // IOT | OPER | JMP D

                begin
					// IOT, OPER and JMP D instructions execute in the fetch
                    if (halt == 1)
                        state <= H0;
                    else                  
                    if ({instruction[0:3],instruction[10:11]} == 6'b111110)
                         // halt instruction
                        state <= H0;
                    else if  ((int_req & int_ena & ~int_inh )
                            && (instruction != 12'o6002))
                         //this solves the ion/iof/ion/iof problem
                        begin
                            int_in_prog <= 1;
                            state <= E0;
                            cnt <= 2'b11;
                        end
					
                    else 
					begin 
					    state <= F0;
                        cnt <= 2'b10;
					end	
                end
                else if (instruction[3] == 1)
				begin
                     // defer cycle/
                    state <= D0;
					// test for auto indexed locations
					if (instruction[4:8] == 5'b00001) //page 0
                        cnt <= 2'b11;
					// note that the PC is not updated until the end of F3 
					else if ((instruction[4:8] == 5'b10001) && (pc[0:3] == 4'b0000)) // current page
                        cnt <= 2'b11;
                    else
                        cnt <= 2'b10;  // not auto indexed
				end	
                else
				begin
                    state <= E0;
                    cnt <= 2'b11;
				end

                D0: if ((~single_step |  cont ) && (cnt == 2'b00))
                    state <= D1;
                else
				begin
                    state <= D0;
					if ( cnt != 0) 
			    		cnt <= cnt -2'b01;
				end
                D1: state <= D2;
                D2: state <= D3;
                //  if it is a jmp I then F0 is the desired state
                D3: if (instruction[0:3] == 4'b1011)
                begin
                    if (int_req & int_ena & ~int_inh)
                    begin
                        int_in_prog <= 1;
                        state <= E0;
						cnt <= 2'b11;
                    end
                    else if (halt == 1)
                        state <= H0;
                    else
					begin
                        state <= F0;
						cnt <= 2'b10;
					end
                end
                else
				begin
                    state <= E0;
					cnt <= 2'b11;
				end
                // execute cycle
                E0: if ((~single_step |  cont ) && (cnt == 2'b00))
                    state <= E1;
                else
				begin
                    state <= E0;
					if ( cnt != 0) 
					    cnt <= cnt - 2'b01;
				end
                E1: state <= E2;
                E2: state <= E3;
                E3: if (halt == 1)
                    state <= H0;
                else if (int_in_prog == 1)
				begin
				    state <= F0;
				   cnt <= 2'b10;
				end	
				else if(int_req & int_ena & ~int_inh )
                    begin
                        int_in_prog <= 1;
                        state <= E0;
					    cnt <= 2'b11;
                    end
                else
				begin
                   state <= F0;
				   cnt <= 2'b10;
				end
                

                H0: if (trigger & ~cont) state <= H1;
                else if ( ~cont) state <= H0;
                else begin
				    state <= F0;
				    cnt <= 2'b10;
				end
                H1: state <= H2;
                H2: state <= H3;
                H3: if (~cont)
                    state <= H0;
                else
                    state <= F0;
            endcase
    end
endmodule

