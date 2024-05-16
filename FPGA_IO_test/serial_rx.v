

module serial_rx (
    input  reset,
    input  clk100,
    input  rx,
    output [11:0] rx_char_out
);

`include "HX_clock.v"
  localparam baud_rate = 9600;
  localparam term_count = $rtoi(clock_frequency/baud_rate);
  localparam term_nu_bits = $clog2(term_count);


  // this section implements a simple serial receive interface.
  // it uses the term count from transmit
  reg [11:0] rx_char, rx_temp;
  reg [2:0] bit_cnt;
  reg [term_nu_bits-1:0] rx_counter;
  reg [2:0] rx_state;
  assign rx_char_out = rx_char; 
  
  always @(posedge clk100) begin
  if (reset == 1) 
  begin
    rx_counter <= 0;
    bit_cnt  <= 0;
    rx_state <= 0;
    rx_char  <= 0;
    rx_temp  <= 0;
  end
  else  case (rx_state)
      0: // idle state
      begin
        if (rx == 1) rx_state <= 0;
        else begin
          rx_counter <= 'd32;
          rx_state <= 1;
         // rx_char <= 'o0;
        end
      end

      1: begin  // verify start bit 400 to 500 nanoseconds
        if (rx == 1)  //  false start
          rx_state <= 0;
        else begin
          rx_counter <= rx_counter - 1;
          if (rx_counter == 0) begin
            rx_counter <= (term_count >> 1);
            rx_state   <= 2;
          end
        end
      end
      2:  // start bit
      begin
        rx_counter <= rx_counter - 1;
        if (rx_counter == 0) begin
          if (rx == 0) begin
            rx_state   <= 3;
            rx_counter <= term_count;
          end else begin
            rx_state <= 0;  // false start bit start over
            rx_char[11] <= 1;
          end
        end

      end
      3: // bit 0
   begin
        rx_counter <= rx_counter - 1;
        if (rx_counter == 0)
        begin
          if (bit_cnt == 'd7) rx_state <= 4;
          else rx_counter <= term_count;
          rx_temp <= {rx,rx_temp[7:1]};
          bit_cnt <= bit_cnt + 1;
        end
      end
      4:// stop bit
   begin
        rx_counter <= rx_counter - 1;
        if (rx_counter == 0) begin
          rx_counter <= (term_count >> 1);
          rx_char <= rx_temp;
          rx_state <= 5;
          if (rx == 0) rx_char[10] <= 'o1;

        end
      end
      5:  // return to idle
      rx_state <= 0;
      default: rx_state <= 0;

    endcase

  end

endmodule

