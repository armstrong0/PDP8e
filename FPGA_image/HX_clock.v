module HX_clock (
    input reset,
    input clk,
    output reg oneKHz,
    output wire [15:0] baud_count // enough bits to get down to 1200 baud
    // with 73.5 MHz clock
);

`include "../FPGA_image/clock_frequency.v"
`include "../rates.v"


  localparam tx_term_count = $rtoi(clock_frequency / baud_rate);
  assign baud_count = tx_term_count;

  localparam oneK_cnt = $rtoi(clock_frequency / 2000.0 );
  reg [$clog2(oneK_cnt):0] oneK_cntr;

 // localparam low_spi_cnt = $rtoi(clock_frequency / (slow_spi * 2));

//  reg [$clog2(low_spi_cnt):0] spi_cnt;
 // localparam high_spi_cnt = $rtoi(clock_frequency / (fast_spi * 2));


  always @(posedge clk) begin
    if (reset) begin
      oneK_cntr <= 0;
      oneKHz <= 0;
    end else begin
      oneK_cntr <= oneK_cntr - 1;
      if (oneK_cntr == 0) begin
        oneKHz = ~oneKHz;
        oneK_cntr <= oneK_cnt;
      end
    end
  end

 // always @(posedge clk) begin
 //   if (reset) begin
 //     spi_cnt <= 0;
 //     spi_clk <= 0;
 //   end else if (spi_cnt == 0) begin
 //     spi_clk <= ~spi_clk;
 //     if (spi_high_clk == 1) spi_cnt <= high_spi_cnt;
 //     else spi_cnt <= low_spi_cnt;
 //   end else spi_cnt <= spi_cnt - 1;
 //  end

endmodule
