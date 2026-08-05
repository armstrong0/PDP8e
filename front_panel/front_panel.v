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
    input disk_rdy,
    input [0:11] sr,
    input sw,
    output reg sw_active,
    output reg swr,
    output triggerd,
    output reg fp_trigger,
    output reg cleard,
    extd_addrd,
    addr_loadd,
    depd,
    examd,
    contd,
    dseld,
    output reg [0:11] rsr,
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

  // autostart control
  reg AutoStart;
  reg [2:0] AS_state;

  parameter reg [2:0]  //integer
  LATCH = 3'b000,
      WAIT  = 3'b001,
      TRIG1 = 3'b010,
      TRIG2 = 3'b011,
      TRIG3 = 3'b100,
      TRIG4 = 3'b111,
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
      rsr <= 0;
      // need to test here to see if we need to autostart
      if (sw == 1) begin
        AS_state <= 1;
        swr <= 0;  // inhibit sw for addr load from rsr
      end else AS_state <= 0;
    end else begin
      // when sw is set when we power up we go through a bootstrap
      // for the RK8e / RK05
      //    this intails setting 12`o0030  asserting addr_load
      //                 setting 12'o6743  asserting dep
      //                 setting 12'o5031  asserting dep
      //                 setting 12'o0030 asserting addr_load .
      //                 asserting cont
      case (trig_state)
        LATCH: begin

          case (AS_state)
            0: begin
              rsr <= sr;
              swr <= sw;  // pass sw through so that ma can check and load the bus
              switchl <= switchl | {clear, extd_addr, addr_load, dep, exam, cont, dsel_sw};
              // latch inputs
              if (switchl == 7'b0000000) trig_state <= LATCH;
              else begin
                trig_state <= WAIT;
              end
            end

            1: begin
              rsr <= 12'o0030;
              if (disk_rdy == 1) // wait for sd card to be available
              begin
                AS_state <= 2;
                switchl <= 7'b0010000;
                trig_state <= WAIT;
              end else trig_state <= LATCH;

            end  // addr load

            2: begin
              rsr <= 12'o6743;
              AS_state <= 3;
              switchl <= 7'b0001000;
              trig_state <= WAIT;
            end
            3: begin
              rsr <= 12'o5031;
              AS_state <= 4;
              switchl <= 7'b0001000;
              trig_state <= WAIT;
            end
            4: begin
              rsr <= 12'o0030;
              AS_state <= 5;
              switchl <= 7'b0010000;
              trig_state <= WAIT;
            end
            5: begin
              AS_state <= 0;
              switchl <= 7'b0000010;
              trig_state <= WAIT;
            end  // required to produce the cont signal
            default: begin
              rsr <= sr;
              AS_state <= 0;
            end
          endcase
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
          if (AS_state == 0) fp_trigger <= 1;
          if (dseld == 1) begin
            if (dsel == 5) dsel <= 0;
            else dsel <= dsel + 1;
          end
        end
        TRIG3: begin
          if (AS_state == 0) trig_state <= DELAY;
          else trig_state <= TRIG4;
          switchd   <= switchd;
          sw_active <= 1'b1;
        end
        TRIG4: begin
          trig_state <= REENABLE;
          sw_active <= 1'b0;
          switchd <= 8'b00000000;
        end
        DELAY:
        if (fp_cont == 1) begin
          trig_state <= REENABLE;
          fp_trigger <= 0;
          sw_active <= 1'b0;
          switchd <= 8'b00000000;
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
