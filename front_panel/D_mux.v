/* verilator lint_off LITENDIAN */

module D_mux (
    input clk,
    input reset,
    input [2:0] dsel,
    input [4:0] state,
    input [3:11] state1,
    input [0:11] status,
    input [0:11] ac,
    input [0:11] mb,
    input [0:11] mq,
    input [0:11] io_bus,
    input run_ff,
    input sw_active,
    output reg [4:0] dsel_led,
    output reg [0:11] dout,
    output reg run_led
);
  `include "../parameters.v"

  reg FS, DS, ES;

  always @(posedge clk) begin

    if (run_ff == 1) begin
      if (sw_active == 0) begin
        run_led <= 1;
      end else begin
        run_led <= 0;
      end
    end else begin
      if (sw_active == 1) begin
        run_led <= 1;
      end else begin
        run_led <= 0;
      end
    end


    case (state)
`ifdef RK8E    
          DB0, DB1, 
`endif
      F0:  if (run_ff == 1) FS <= 1; else FS <= 0;
      FW, F1, F2, F3, F2A, F2B: begin
        FS <= 1;
        DS <= 0;
        ES <= 0;
      end
      D0, DW, D1, D2, D3: begin
        FS <= 0;
        DS <= 1;
        ES <= 0;
      end
`ifdef EAE
       EAE0, EAE1, EAE2, EAE3,
`endif     
      E0, EW, E1, E2, E3: begin
        FS <= 0;
        DS <= 0;
        ES <= 1;
      end
      default:   // all the halt states plus undefined states
            begin
        FS <= 0;
        DS <= 0;
        ES <= 0;
      end
    endcase

  end

  always @(posedge clk) begin

    // state (F D E IR0 IR1 IR2 MD_Dir DATA_CONT SW PAUSE BRK_PROG BRK
    // status (link, gt int_bus NO_int ION UM IF0 IF1 IF2 DF0 DF1 DF2)
    // ac mb mq bus
    case (dsel)
      0: begin
        dout <= {FS, DS, ES, state1};
        dsel_led <= 5'b01100;
      end
      1: begin
        dout <= status;
        dsel_led <= 5'b01010;
      end
      2: begin
        dout <= ac;
        dsel_led <= 5'b01001;
      end
      3: begin
        dout <= mb;
        dsel_led <= 5'b10100;
      end
      4: begin
        dout <= mq;
        dsel_led <= 5'b10010;
      end
      5: begin
        dout <= io_bus;
        dsel_led <= 5'b10001;
      end
      default: begin
        dout <= {FS, DS, ES, state1};
        dsel_led <= 5'b01100;
      end
    endcase
  end
endmodule


