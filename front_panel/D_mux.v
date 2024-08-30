/* verilator lint_off LITENDIAN */

module D_mux (
    input clk,
    input reset,
    input [5:0] dsel,
    input [4:0] state,
    input [3:11] state1,
    input [0:11] status,
    input [0:11] ac,
    input [0:11] mb,
    input [0:11] mq,
    input [0:11] io_bus,
    input sw_active,
    output reg [0:11] dout,
    output reg run_led
);
  `include "../parameters.v"

  reg FS, DS, ES, HS;

  always @* begin
    case (state)
      DB0, DB1, F0, FW, F1, F2, F3, F2A, F2B: begin
        run_led = 1;
        FS = 1;
        DS = 0;
        ES = 0;
        HS = 0;
      end
      D0, DW, D1, D2, D3: begin
        run_led = 1;
        FS = 0;
        DS = 1;
        ES = 0;
        HS = 0;
      end
      E0, EW, E1, E2, E3, EAE0, EAE1: begin
        run_led = 1;
        FS = 0;
        DS = 0;
        ES = 1;
        HS = 0;
      end
      default:   // all the halt states plus undefined states
            begin
        FS = 0;
        DS = 0;
        ES = 0;
        HS = 1;
        if (sw_active == 1) run_led = 1;
        else run_led = 0;
      end
    endcase

  end

  always @(posedge clk) begin

    // state (F D E IR0 IR1 IR2 MD_Dir DATA_CONT SW PAUSE BRK_PROG BRK
    // status (link, gt int_bus NO_int ION UM IF0 IF1 IF2 DF0 DF1 DF2)
    // ac mb mq bus
    if (dsel[5] == 1) dout <= {FS, DS, ES, state1};
    else if (dsel[4] == 1) dout <= status;
    else if (dsel[3] == 1) dout <= ac;
    else if (dsel[2] == 1) dout <= mb;
    else if (dsel[1] == 1) dout <= mq;
    else if (dsel[0] == 1) dout <= io_bus;
    else  dout <= {FS, DS, ES, state1}; 
    end
endmodule


