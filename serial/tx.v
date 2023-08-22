module tx (
    input clk100,
    input reset,
    input clear,
    input [0:11] char,
    input load,
    input clear_flag,
    input set_flag,
    output reg flag,
    output reg tx
);

  /* verilator lint_off LITENDIAN */
  reg [13:0] period_cntr;
  reg [3:0] state;
  reg [0:7] tto;
  reg loaded;
  `include "../parameters.v"

  parameter IDLE =4'd0, START = 4'd1,
    BIT0 = 4'd2, BIT1 = 4'd3, BIT2 = 4'd4, BIT3 = 4'd5,
	BIT4 = 4'd6, BIT5 = 4'd7, BIT6 = 4'd8, BIT7 = 4'd9,
	STOP1 = 4'd10, STOP2 = 4'd11;

  always @(posedge clk100) begin
    if (reset | clear) begin
      flag <= 0;
      tto <= 8'o040;
      loaded <= 0;
      period_cntr <= 14'd16;
      state <= IDLE;
      tx <= 1;
    end else begin
      if (clear_flag == 1) flag <= 0;
      if (set_flag == 1) flag <= 1;
      if ((state == IDLE) && (load == 1))  //(state == STOP1) || (state == STOP2))
                    // && (load == 1)) // book says to use
                	// SPF 6040 to set the flag to start the output BUT
                	// the diagnostics
                	// don't do that.  Removed the flag requirement in the
                	// above
                	// allow loads in stop1 and stop2
            begin
        tto <= char[4:11];
        flag <= 0;
        loaded <= 1;
      end
      //if (state == START) flag <= 0;
      //if (state == STOP1) flag <= 1;

      period_cntr <= period_cntr - 14'd1;
      // actions happen at the end of the state!
      if (period_cntr == 14'd0)
        case (state)
          IDLE: begin
            if (loaded == 1) //&& (flag == 1))
                        begin
              state <= START;
              period_cntr <= tx_term_cnt[13:0];
              flag <= 0;
            end else begin
              state <= IDLE;
              period_cntr <= 14'd16;
            end
          end
          START: begin
            loaded <= 0;
            period_cntr <= tx_term_cnt[13:0];
            state <= BIT0;
          end

          // this depends on the states being in sequence
          // each state follows the previous at intervals of 1 baud
          BIT0, BIT1, BIT2, BIT3, BIT4, BIT5, BIT6, BIT7: begin
            period_cntr <= tx_term_cnt[13:0];
            state <= state + 4'b0001;
            if (state == BIT7) flag <= 1;
          end
          STOP1: begin
`ifdef ONESTOP
            state <= IDLE;
            period_cntr <= 14'd16;
`else
            state <= STOP2;
            period_cntr <= tx_term_cnt[13:0];
`endif

          end
          STOP2: begin  // we are done set up for the next
            state <= IDLE;  // loaded might be set but idle will
            // sort it out very quickly
            period_cntr <= 14'd16;
          end

          default: period_cntr <= 14'd16;

        endcase
      case (state)
        IDLE: tx <= 1;
        START: tx <= 0;  // send start bit
        BIT0: tx <= tto[7];
        BIT1: tx <= tto[6];
        BIT2: tx <= tto[5];
        BIT3: tx <= tto[4];
        BIT4: tx <= tto[3];
        BIT5: tx <= tto[2];
        BIT6: tx <= tto[1];
        BIT7: tx <= tto[0];
        STOP1: tx <= 1;
        STOP2: tx <= 1;
        default: tx <= 1;
      endcase

    end
  end
endmodule

