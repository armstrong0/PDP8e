# Create a base clock for the PLL input clock
create_clock -name clk100 -period 10 [get_ports clk100]
# Create the PLL Output clocks automatically
derive_pll_clocks
