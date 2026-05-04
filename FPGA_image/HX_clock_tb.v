`timescale 1 ns / 1 ps

module HX_clock_tb;

  reg  reset;
  reg  clk;

  reg  spi_high_clock;

  wire oneKHz;
  wire rx_baud_clock;
  wire spi_clock;
  wire [15:0] baud_count;

  parameter real clock_frequency = 73500000;

  localparam real clock_period = 1/clock_frequency*1e9;
  
  always begin      
    #(clock_period / 2) clk <= 1;
    #(clock_period / 2) clk <= 0;
  end

  HX_clock UUT (
      .clk(clk),
      .reset(reset),
      .spi_high_clk(spi_high_clk),
      .oneKHz(oneKHz),
      .baud_count(baud_count),
      .spi_clk(spi_clk)
  );

initial begin
  $dumpfile("clocks.vcd");
  $dumpvars(0,UUT);
  $display("clock period:",clock_period," nanoseconds");
  
  #1 reset <= 0;
  #20 reset <=1;
  #40 reset <=0;

  #3000000 $finish;

end

endmodule
