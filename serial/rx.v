// we have a 16 x baud clock.  On every rising edge of the baud clock, sample
// the input.
// Check the first few sample to ensure a real start bit
// Then at the appropriate bit times shift rx into the receive shift register.

module rx (
    input reset,
    input clear,
    input clk,
    input rx,
    input clear_flag,
    output reg flag,
    output reg [0:7] char0
);  //  bit 7 is the LSB and was received first

  `include "../parameters.v"

  localparam term_cnt = $rtoi((baud_period / 16) / clock_period);

  localparam start_search = 0,
    check_start = 1,
    check_start1 = 2,
    check_start2 = 3,
    check_start3 = 8,
    bit0 = check_start3 + 16,
    bit1 = bit0 + 16,
    bit2 = bit1 + 16,
    bit3 = bit2 + 16,
    bit4 = bit3 + 16,
    bit5 = bit4 + 16,
    bit6 = bit5 + 16,
    bit7 = bit6 + 16,
    stop_bit = bit7 + 16;

  reg [ 7:0] state;
  reg [14:0] counter;
  reg [ 0:7] char1;  // receive shift register


  always @(posedge clk) begin
    if ((reset == 1'b1) | (clear == 1)) begin
      char1 <= 8'o377;
      char0 <= 8'o377;
      counter <= term_cnt[14:0];
      flag <= 0;
      state <= start_search;
    end else if (clear_flag == 1) flag <= 0;
    else if (counter > 15'o0000) counter <= counter - 1;
    else  // counter reached zero
    begin
      counter <= term_cnt[14:0];
      state   <= state + 1;
      case (state)
        start_search, check_start, check_start1, check_start2, check_start3:
        if (rx == 1) state <= 8'b11111111;
        else char1 <= 8'o377;
        bit0, bit1, bit2, bit3, bit4, bit5, bit6: char1 <= {rx, char1[0:6]};
        bit7: char0 <= {rx, char1[0:6]};

        stop_bit: begin  // rx should be one here
          flag  <= 1;
          state <= start_search;
        end
        default: ;
      endcase
    end
  end
endmodule
