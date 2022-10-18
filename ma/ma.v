`include "../ram/ram.v"
module ma(input clk,
    input reset,
    input [0:11] pc,
    input [0:11] ac,
    input [0:11] mq,
    input [0:11] sr,
    input [4:0] state,
    input addr_loadd,depd,examd,
    input int_in_prog,
    input [0:2] IF,DF,
    output reg [0:11] addr,
    output reg [0:2] EMA,
    output reg isz_skip,
    output reg [0:11] instruction,
    output reg [0:11] ma,
    output reg [0:11] mdout
);

    reg [0:4] current_page;
    reg [0:11] mdin;
    reg write_en;
    wire [0:11] mdtmp;

`include "../parameters.v"

    ram ram(.din (mdin),
        .addr ({EMA[2],addr}),
        .write_en (write_en),
        .clk (clk),
        .dout (mdtmp));



    // address mux
    always @*  // just replace <= with = for verilator
    begin
        addr = ma;
        EMA = IF;
        case (state)
            F0,FW: //,F1,F2,F3:
            addr = pc;
            default:
            addr = ma;
        endcase
        case (state)
            E0,EW,E1,E2,E3,EAE2,EAE3,EAE4,EAE5: 
			// use indirect addressing
            if ((((instruction[0:2] == AND) ||
                (instruction[0:2] == TAD) ||
                (instruction[0:2] == ISZ) || // need to add EAE intructions
                (instruction[0:2] == DCA)) &&
                (instruction[3] == 1'b1))    // this specifies deferred
				|| (instruction & 12'b111100000001)== 12'b111100000001) 
				// EAE mode B indirect
                EMA = DF;
            else
                EMA = IF;
            default: EMA = IF;
        endcase
    end

    always @(posedge clk)
    begin
        if (reset)
        begin
            ma <=  12'o0000;
            isz_skip <= 0;
            instruction <= 12'o7000;
            current_page <= 0;
            write_en <= 0;
        end
        else
        begin
            write_en <= 0;
            ma <= ma;
            mdin <= mdin;
            case (state)
                F0: begin
                    ma <= pc;
                end
                FW:begin
                    if (EMA > MAX_FIELD)
                    begin
                        mdout <= 12'o0000;
                        instruction <= 12'o0000;
                    end
                    else
                    begin
                        mdout <= mdtmp;
                        instruction <= mdtmp;
                    end
					ma <= pc + 12'o0001;
                end
                F1: ; //instruction <= mdout;
                F2: begin
				         current_page <= pc[0:4];
						 mdout <= mdtmp;
					end	 
                F3: begin
                    case(instruction[0:2])
                        0,1,2,3,4,5:
                        if (instruction[4] == 0 )  //page 0
                            ma <= {5'b00000,instruction[5:11]};
                        else
                            ma <= {current_page,instruction[5:11]};
							// pc has already been incremented
                        6,7: ma <= pc;
						//  pc is problably not valid until the end of F3
						//  so assign ma here is probably irrelavent
                        default:;
                    endcase
                end
                D0:;
                DW: if (EMA > MAX_FIELD)
                    mdout <= 12'o0000;
                else
                    mdout <= mdtmp;
                D1: if (ma[0:8] == 9'o001 )
                begin
                    mdin <= mdout + 12'o0001;
                    if (EMA <= MAX_FIELD) write_en <= 1;
                end
                D2: if (ma[0:8]  == 9'o001 )
                    ma <= mdout + 12'o0001;
                else
                    ma <= mdout;
                D3: ;
                E0:;
                EW: begin
                    if (int_in_prog == 1)
                    begin
                        instruction <= 12'o4000;
                        ma <= 12'o0000;
                        mdin <= pc;
                    end
                    else case (instruction[0:2])
                            ISZ,AND,TAD:;
                            JMS: mdin <= pc;
                            default:;
                        endcase
                    mdout <= mdtmp;
                    if (EMA > MAX_FIELD)
                        mdout <= 12'o0000;
                    else
                        mdout <= mdtmp;
                end
                E1: case (instruction[0:2])
                    ISZ: begin
                        mdin <= mdout + 12'o0001;
                        if (EMA <= MAX_FIELD) write_en <=1;
                        if (mdout == 12'o7777) isz_skip <= 1 ;
                    end
                    JMS: begin
                        if (EMA <= MAX_FIELD) write_en <= 1;
                        mdin <= pc;
                    end
                    DCA: begin
                        mdin <= ac;
                        if (EMA <= MAX_FIELD) write_en <= 1;
                    end
                    default: ;
                endcase
                E2: case (instruction[0:2])
                    ISZ: isz_skip <= isz_skip;
                    DCA:;
                    default:;
                endcase
                E3:  isz_skip <= 0;
                H0:;
                HW:  if (EMA > MAX_FIELD)
                    mdout <= 12'o0000;
                else
                    mdout <= mdtmp ;
                H1: if (addr_loadd == 1'b1)
                    ma <= sr;
                else if (depd == 1'b1)
                begin
                    mdin <= sr;
                    if (EMA <= MAX_FIELD) write_en <= 1;
                end
                H2: if ((depd ==1'b1) | (examd == 1'b1))
                    ma <= ma + 12'o0001;
                H3:;
				// EAE accesses
				EAE2: begin 
				    if((instruction & 12'b111100101111) == 12'o7445)  // DST
				    begin
					    mdin <= ac;
						write_en <= 1'b1;
					end	
                    else if (EMA > MAX_FIELD)
                        mdout <= 12'o0000;
                    else
                        mdout <= mdtmp;
					end
				EAE3:ma <= ma + 1;	
						
				EAE4:if((instruction & 12'b111100101111) == 12'o7445)  // DST
				    begin
					    mdin <= mq;
						write_en <= 1'b1;
					end	

                    else if (EMA > MAX_FIELD)
                        mdout <= 12'o0000;
                    else
                        mdout <= mdtmp;

                default:;
            endcase
        end
    end
endmodule



