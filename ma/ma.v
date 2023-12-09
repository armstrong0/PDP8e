`ifdef up5k
`include "../spram/up_spram.v"
`else
`include "../ram/ram.v"
`endif

module ma (
    input clk,
    input reset,
    input [0:11] ac,
    input [0:11] mq,
    input [0:11] sr,
    input sw,
    input [4:0] state,
    input addr_loadd,
    depd,
    examd,
    input int_in_prog,
    input [0:2] IF,
    DF,
    input skip,
    input eskip,
`ifdef RK8E
    input [0:14] dmaAddr,
    input [0:11] disk2mem,
    input to_disk,
    output reg [0:11] mem2disk,
`endif
    output reg index,
    output reg [0:11] instruction,
    output reg [0:11] mdout,
    output reg [0:14] eaddr  // drives the panel LEDs
);

  reg [0:4] current_page;
  reg [0:11] mdin, idx_tmp, pc, next_pc, skip_pc;
  reg write_en;
  wire [0:11] mdtmp;
  `include "../parameters.v"


`ifdef up5k
  up_spram ram (
      .wdata({4'b0, mdin}),
      .addr(eaddr),
      .wr(write_en),
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




  always @(posedge clk) begin
    if (reset) begin
      eaddr <= 15'o00000;
      instruction <= 12'o7000;
      current_page <= 0;
      write_en <= 0;
      index <= 1'b0;
    end else begin
      write_en <= 0;
      eaddr[3:14] <= eaddr[3:14];
      mdin <= mdin;
      case (state)
        F0: begin
          pc <= eaddr[3:14];
        end
        FW: begin
          mdout <= mdtmp;
          instruction <= mdtmp;
          eaddr[3:14] <= pc + 12'o0001;  // set up for fetch of immediate operand or address
        end
        F1: ;
        F2A, F2B, F2: begin
          current_page <= pc[0:4];
          mdout <= mdtmp;
          skip_pc <= pc + 12'o0002;
          next_pc <= pc + 12'o0001;

        end
        F3: begin
          casez (instruction[0:4])
            5'b0???0: eaddr <= {IF, 5'b00000, instruction[5:11]};
            5'b0???1: eaddr <= {IF, current_page, instruction[5:11]};
            5'b100?0:  // JMS page 0
            eaddr <= {IF, 5'b0, instruction[5:11]};
            5'b100?1:  // JMS current page
            eaddr <= {IF, current_page, instruction[5:11]};
            5'b101?0: // JMP page 0
            begin
              eaddr   <= {IF, 5'b0, instruction[5:11]};
              next_pc <= {5'b0, instruction[5:11]};
            end
            5'b101?1: // JMP current page
            begin
              eaddr   <= {IF, current_page, instruction[5:11]};
              next_pc <= {current_page, instruction[5:11]};
            end
            5'b11???:  // 6 and 7 OPR and IOT
            if ((skip == 1) || (eskip == 1)) begin
              eaddr   <= {IF, skip_pc};
              next_pc <= skip_pc;
            end else eaddr <= {IF, next_pc};
          endcase
        end
        D0: if (eaddr[3:11] == 9'o001) index <= 1'b1;
 else index <= 1'b0;
        DW: begin
          mdout <= mdtmp;
        end
        D1:
        if (index == 1'b1) begin
          mdin <= mdout + 12'o0001;
          idx_tmp <= mdout + 12'o0001;
          write_en <= 1;
        end
        D2: begin  // only get here if we have auto indexing
          eaddr[3:14] <= idx_tmp;
        end
        D3: begin
          if  ((instruction[0:2] == AND) ||
                 (instruction[0:2] == TAD) ||
                 (instruction[0:2] == ISZ) ||
                 (instruction[0:2] == DCA) || 
                ((instruction & 12'b111100000001) == 12'b111100000001))
            eaddr[0:2] <= DF;
          if (index == 1) begin
            index <= 0;
            eaddr[3:14] <= idx_tmp;
            if (instruction[0:2] == JMP) next_pc <= idx_tmp;
          end else begin
            eaddr[3:14] <= mdout;
            if (instruction[0:2] == JMP) next_pc <= mdout;
          end
        end
        E0: ;
        EW: begin
          if (int_in_prog == 1) begin
            instruction <= 12'o4000;
            eaddr <= 15'o0000;
            mdin <= next_pc;
          end else
            case (instruction[0:2])
              ISZ, AND, TAD: ;
              JMS: mdin <= next_pc;
              default: ;
            endcase
          mdout <= mdtmp;
        end
        E1:
        case (instruction[0:2])
          ISZ: begin
            mdin <= mdout + 12'o0001;
            write_en <= 1;
            if (mdout == 12'o7777) next_pc <= skip_pc;
          end
          JMS: begin
            write_en <= 1;
            mdin <= next_pc;
          end
          DCA: begin
            mdin <= ac;
            write_en <= 1;
          end
          default: ;
        endcase
        E2: begin
          case (instruction[0:2])
            ISZ: ;
            DCA: ;
            JMS:
            if (int_in_prog) begin
              eaddr   <= 15'o0001;
              next_pc <= 12'o0001;
            end else next_pc <= eaddr[3:14] + 1;
          endcase
        end
        E3: begin
          // on interrupt we go to IF 0 set up in E2 above
          if (int_in_prog == 1) eaddr <= {3'b000, next_pc};
          else eaddr <= {IF, next_pc};
        end
        H0: ;
        HW: mdout <= mdtmp;
        H1:
        if (addr_loadd == 1'b1)
          if (sw == 1'b1) eaddr[3:14] <= 12'o7777;
          else eaddr[3:14] <= sr;
        else if (depd == 1'b1) begin
          mdin <= sr;
          write_en <= 1;
        end
        H2: if ((depd == 1'b1) | (examd == 1'b1)) eaddr[3:14] <= eaddr[3:14] + 12'o0001;
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
          eaddr[3:14] <= eaddr[3:14] + 1;
          mdin <= ac;
        end

        EAE4: begin
          if ((instruction & 12'b111100101111) == DST) begin
            mdin <= ac;
            write_en <= 1'b1;
          end

          mdout <= mdtmp;
        end
        EAE5: ;
`endif
`ifdef RK8E
        DB0:
        if (to_disk == 1'b0) begin
          mdin <= disk2mem;
          write_en <= 1'b1;
        end
        DB1: begin
          mdin <= disk2mem;
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



