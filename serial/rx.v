// we have a 16 x baud clock.  On every rising edge of the baud clock, sample
// the input.
// Then at the appropriate bit times shift rx into the receive shift register.

module rx (
    input reset,
    input clear,
    input clk,
    input rx,
    input [15:0] baud_count,
    input clear_flag,
    output reg flag,
    output reg [0:7] char0
);  //  bit 7 is the LSB and was received first

  `include "../parameters.v"
  
localparam idle = 0,
    start = 1,
    bit0 = 2,
    bit1 = 3,
    bit2 = 4,
    bit3 = 5,
    bit4 = 6, 
    bit5 = 7, 
    bit6 = 8, 
    bit7 = 9, 
    stop_bit = 10;

  reg [ 3:0] state;
  reg [15:0] counter;
  reg [ 0:7] char1;  // receive shift register


  always @(posedge clk) begin
    if ((reset == 1'b1) | (clear == 1)) begin
      char1 <= 8'o377;
      char0 <= 8'o377;
      counter <= 16;  // high speed looking for a start edge; 
      flag <= 0;
      state <= idle;
    end else if (clear_flag == 1) flag <= 0;
    else if (counter > 0) counter <= counter - 1;
    else  // counter reached zero
    begin
      state   <= state + 1;
      case (state)
        idle: begin
          if (rx == 0) begin
            state   <= start;
            counter <= baud_count / 2; 
	        // this gets us to the center of the start bit
          end else begin
            counter <= 16;  //from above probably need to be a different number
            state   <= idle;
          end
        end
        start: counter <= baud_count ;  
        bit0, bit1, bit2, bit3, bit4, bit5, bit6: begin
          counter <= baud_count;
          char1   <= {rx, char1[0:6]};
        end
        bit7: begin
          counter <= baud_count;
          char0   <= {rx, char1[0:6]};
        end

        // if all speeds are nominal we should be at 9.5 baud out of 10
	    // we can tolerate maximum of 5 % difference
        stop_bit: begin  // rx should be one here
          flag  <= 1;
          state <= idle;
          counter <= 16; // set the counter so we go to idle before a baud
          // idle will spin with rx being high
	      char1 <= 8'o377;
        end
        default: ;
      endcase
    end
  end
endmodule
