module front_panel (
    input clk,
    input reset,
    input [4:0] state,
    input clear,
    input extd_addr,
    input addr_load,
    input dep,
    input exam,
    input cont,
    input dsel_sw,
    input fp_cont,
    output reg sw_active,
    output triggerd,
    output reg fp_trigger,
    output reg cleard,
    extd_addrd,
    addr_loadd,
    depd,
    examd,
    contd,
    dseld,
    output reg [2:0] dsel

);

  `include "../timing.v"




  wire cont_c;
  reg [7:0] switchd;
  reg [6:0] switchl;
  reg [2:0] trig_state;
  reg [9:0] cntr;

  reg trigger1;

  assign {triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd, dseld} = switchd;

  parameter reg [2:0]  //integer
  LATCH = 3'b000,
      WAIT  = 3'b001,
      TRIG1 = 3'b010,
      TRIG2 = 3'b011,
      TRIG3 = 3'b100,
      DELAY = 3'b101,
      REENABLE = 3'b110;


  // don't really care what state the main state machine is in,
  // as every processed
  // switch press is validated for the proper state elsewhere
  always @(posedge clk) begin
    if (reset) begin
      trig_state <= LATCH;
      switchd <= 8'b00000000;
      switchl <= 7'b0000000;
      sw_active <= 1'b0;
      dsel <= 3'b000;
      fp_trigger <= 0;
    end else begin
      case (trig_state)
        LATCH: begin
          switchl <= switchl | {clear, extd_addr, addr_load, dep, exam, cont, dsel_sw};
          // latch inputs
          if (switchl == 7'b0000000) trig_state <= LATCH;
          else begin
            trig_state <= WAIT;
          end
        end
        WAIT: begin
          trig_state <= TRIG1;
          switchd <= {1'b1, switchl};
          switchl <= 7'b0000000;
        end
        TRIG1: begin
          trig_state <= TRIG2;
          switchd <= switchd;
        end
        TRIG2: begin
          trig_state <= TRIG3;
          switchd <= switchd;
          fp_trigger <= 1;
          if (dseld == 1) begin
            if (dsel == 5) dsel <= 0;
            else dsel <= dsel + 1;
          end
        end
        TRIG3: begin
          trig_state <= DELAY;
          switchd <= switchd;
          sw_active <= 1'b1;
        end
        DELAY:
        if (fp_cont == 1) begin
          trig_state <= REENABLE;
          fp_trigger <= 0;
          sw_active  <= 1'b0;
        end else begin
          trig_state <= DELAY;
          switchd <= 8'b00000000;
        end

        REENABLE: begin
          trig_state <= LATCH;
          fp_trigger <= 0;
        end
        default: trig_state <= LATCH;

      endcase
    end
  end

endmodule

