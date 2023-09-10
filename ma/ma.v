`ifdef up5k
`include "../spram/up_spram.v"
`else
`include "../ram/ram.v"
`endif

module ma (
    input clk,
    input reset,
    input [0:11] pc,
    input [0:11] ac,
    input [0:11] mq,
    input [0:11] sr,
    input sw,
    input [4:0] state,
    input addr_loadd,depd,examd,
    input int_in_prog,
    input [0:2] IF,DF,
`ifdef RK8E
    input [0:14] dmaAddr,
    input [0:11] disk2mem,
    input to_disk,
    output reg [0:11] mem2disk,
`endif
    output wire [0:2] EMA,
    output reg index,
    output reg isz_skip,
    output reg [0:11] instruction,
    output reg [0:11] ma,
    output reg [0:11] mdout
);

  reg [0:4] current_page;
  reg [0:11] mdin, idx_tmp;
  reg write_en;
  wire [0:11] mdtmp;
  reg [0:14] eaddr;
  `include "../parameters.v"

  assign EMA  = eaddr[0:2];
 // assign addr = eaddr[3:14];

`ifdef up5k
  up_spram ram (
      .wdata({4'b0,mdin}),
      .addr(eaddr),
      .wr  (write_en),
      .clk(clk),
      .rdata(mdtmp)
  );
`else
  ram ram (
      .din(mdin),
      .addr(eaddr),
      .write_en(write_en),
      .clk(clk),
      .dout(mdtmp)
  );
`endif




  // address mux
  always @*  // just replace <= with = for verilator
    begin
    eaddr = {IF, ma};
    case (state)
      F0, FW: eaddr = {IF, pc};
      F1,F2,F3: eaddr = {IF,ma};
`ifdef RK8E
      DB0, DB1: eaddr = dmaAddr;
`endif
      E0, EW, E1, E2, E3:
      // use indirect addressing
      if (((instruction[0:2] == AND) ||
                        (instruction[0:2] == TAD) ||
                        (instruction[0:2] == ISZ) ||
                        (instruction[0:2] == DCA)) &&
                    (instruction[3] == 1'b1))   // this bit specifies deferred
        eaddr = {DF, ma};
      else eaddr = {IF, ma};
      D0,DW,D1,D2,D3, DW1, EAE2, EAE3, EAE4, EAE5: eaddr = {IF, ma};
      default: eaddr = {IF, ma};
    endcase
  end

  always @(posedge clk) begin
    if (reset) begin
      ma <= 12'o0000;
      isz_skip <= 0;
      instruction <= 12'o7000;
      current_page <= 0;
      write_en <= 0;
      index <= 1'b0;
    end else begin
      write_en <= 0;
      ma <= ma;
      mdin <= mdin;
      case (state)
        F0: begin
          ma <= pc;
        end
        FW: begin
          mdout <= mdtmp;
          instruction <= mdtmp;
          ma <= pc + 12'o0001;  // set up for fetch of immediate operand or address
        end
        F1: ;
        F2A, F2B, F2: begin
          current_page <= pc[0:4];
          mdout <= mdtmp;
        end
        F3: begin
          case (instruction[0:2])
            0, 1, 2, 3, 4, 5:
            if (instruction[4] == 0)  //page 0
              ma <= {5'b00000, instruction[5:11]};
            else ma <= {current_page, instruction[5:11]};
            // pc has already been incremented
            6, 7: ;
            default: ;
          endcase
        end
        D0:if (ma[0:8] == 9'o001) index <= 1'b1 ;
           else index <= 1'b0;
        DW: mdout <= mdtmp;
        D1:if (index == 1'b1) begin
          mdin <= mdout + 12'o0001;
          idx_tmp <= mdout +12'o0001;
          write_en <= 1;
        end
        else ma <= mdout;
        DW1: // only get here if we have auto indcexing
          ma <= idx_tmp;
        D2: begin
          //mdin <= mq;
          index <= 1'b0;
        end
        D3: ;
        E0: ;
        EW: begin
          if (int_in_prog == 1) begin
            instruction <= 12'o4000;
            ma <= 12'o0000;
            mdin <= pc;
          end else
            case (instruction[0:2])
              ISZ, AND, TAD: ;
              JMS: mdin <= pc;
              default: ;
            endcase
          mdout <= mdtmp;
        end
        E1:
        case (instruction[0:2])
          ISZ: begin
            mdin <= mdout + 12'o0001;
            write_en <= 1;
            if (mdout == 12'o7777) isz_skip <= 1;
          end
          JMS: begin
            write_en <= 1;
            mdin <= pc;
          end
          DCA: begin
            mdin <= ac;
            write_en <= 1;
          end
          default: ;
        endcase
        E2:
        case (instruction[0:2])
          ISZ: isz_skip <= isz_skip;
          DCA: ;
          default: ;
        endcase
        E3: isz_skip <= 0;
        H0: ;
        HW: mdout <= mdtmp;
        H1:
        if (addr_loadd == 1'b1)
          if (sw == 1'b1) ma <= 12'o7777;
          else ma <= sr;
        else if (depd == 1'b1) begin
          mdin <= sr;
          write_en <= 1;
        end
        H2: if ((depd == 1'b1) | (examd == 1'b1)) ma <= ma + 12'o0001;
        H3: ;
        // EAE accesses
`ifdef EAE
        EAE2: begin
          if ((instruction & 12'b111100101111) == DST) begin
            mdin <= mq;
            write_en <= 1'b1;
          end
          mdout <= mdtmp;

        end
        EAE3: begin
          ma   <= ma + 1;
          mdin <= ac;
        end

        EAE4:
        if ((instruction & 12'b111100101111) == DST) begin
          mdin <= ac;
          write_en <= 1'b1;
        end
        EAE5: mdout <= mdtmp;
`endif
`ifdef RK8E
        DB0:
        if (to_disk == 1'b0) begin
          mdin <= disk2mem;
          write_en <= 1'b1;
        end
        DB1:begin
         mdin <= disk2mem  ;
         if (to_disk == 1'b1) begin
          mem2disk <= mdtmp;
         end
         end

`endif

        default: ;
      endcase
    end
  end
endmodule



