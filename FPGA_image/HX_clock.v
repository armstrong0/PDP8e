module HX_clock (
    input reset,
    input clk,
    input fp_trigger,
    output reg oneKHz,
    output reg sd_reset,
    output reg fp_cont,
    output wire [9:0] SlowDev,
    output wire [9:0] FastDev,
    output reg [9:0] cntr,
    output wire [15:0] baud_count  // enough bits to get down to 1200 baud
    // with 73.5 MHz clock
    // we send the constant rather than generate a clock because RX needs part rate clocks
);

  `include "../FPGA_image/clock_frequency.v"
  `include "../timing.v"


  localparam tx_term_count = $rtoi(clock_frequency / baud_rate);
  assign baud_count = tx_term_count;

  localparam oneK_cnt = $rtoi(clock_frequency / 2000.0);
  reg [$clog2(oneK_cnt):0] oneK_cntr;


  localparam slow_dev = $rtoi(clock_frequency / (slow_spi * 2));
  assign SlowDev = slow_dev;
  localparam fast_dev = $rtoi(clock_frequency / (fast_spi * 2));
  assign FastDev = fast_dev;
  reg [9:0] fp_cntr;
  reg [9:0] sd_cntr;

  always @(posedge clk) begin
    if (reset) begin
      oneK_cntr <= 0;
      oneKHz <= 0;
      fp_cntr <= 0;
      sd_reset <= 1;
      sd_cntr <= 0;
      fp_cont <= 0;
    end else begin
      oneK_cntr <= oneK_cntr - 1;
      if (oneK_cntr == 0) begin
        oneKHz = ~oneKHz;
        oneK_cntr <= oneK_cnt;
        if (oneKHz == 1) // all 1 kHz processing goes here
	begin
          if (sd_reset == 1) begin
            sd_cntr <= sd_cntr + 1;
            if (sd_cntr == sd_delay) sd_reset <= 0;
          end
          if ((fp_trigger == 1) || fp_cntr != 0) begin
            fp_cntr <= fp_cntr + 1;
            if (fp_cntr == sw_dbnc) begin
              fp_cont <= 1;
            end
            if (fp_cont == 1) begin
              fp_cntr <= 0;
              fp_cont <= 0;
            end
          end


        end
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
