`timescale 1 ns / 10 ps
`define CLK #5 clk <= 1;  #5 clk <= 0;
module ram_tb;

wire [0:11] dout;
reg clk;
reg reset;
reg we;
reg [0:12] addr;
reg [0:11] din;



   ram UUT(.clk (clk),
          .din (din),
	  .write_en (we),
	  .addr (addr),
	  .dout (dout));

initial begin
  $dumpfile("ram_results.vcd");
  $dumpvars(0,clk,reset,we,addr,din,dout);
  reset <=1;
  addr <= 13'o00000;
  clk   <= 0;
  we <= 0;
`CLK
din <= 12'o7777;
we <=1;
`CLK
addr <= 13'o10000;
din <= 12'o5252;
we <=1;
`CLK
addr <= 13'o17777;
din <= 12'o2525;
we <= 1;
`CLK 
we <=0;

addr <= 13'o00000;
`CLK 
addr <= 13'o10000;
`CLK
addr <= 13'o17777;
`CLK
din <= dout + 12'o0001;
we <= 1;
`CLK 
we <= 0;
`CLK 
`CLK
`CLK
`CLK 
`CLK 
`CLK
`CLK
`CLK 
`CLK 
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK
`CLK

end

endmodule

