`timescale 1 ns / 10 ps


module rx_tb;

reg clk;
reg reset;
reg rx;
reg clear_flag;
wire flag;
wire [0:7] char;
reg baud_clk;

`include "../parameters.v"

rx rx1(.reset (reset),
       .clk (clk),
       .rx (rx),
       .flag (flag),
       .clear_flag (clear_flag),
       .char0 (char));

localparam slow_baud = 0.97 * baud_period;
initial begin

clk <=0;
forever
   begin
     #(clock_period/2) clk <= 1;
     #(clock_period/2) clk <= 0;
   end
end


always @(posedge clk) begin
    if (baud_clk == 1) 
        #(baud_period/32) baud_clk <= 0;
    else 
        #(baud_period/32) baud_clk <= 1;
end


initial begin 
  $dumpfile("rx.vcd");
  $dumpvars(0,clk,reset,rx,flag,char,rx1.char1,rx1.state,rx1.counter,clear_flag);

#10 clear_flag <= 1;
reset <= 1;
#100 reset <= 0;
#100 clear_flag <= 0;
#30 rx <= 1;
#1 $display("clock frequency %f",(clock_frequency)) ;
#1 $display("baud rate %f ",(baud_rate)) ;
#1 $display("clock period %f",(clock_period)) ;
#1 $display("baud_period %f",(baud_period)) ;
#1 $display("slow baud period %f",(slow_baud));
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 1; // last bit of octal 200
#(baud_period) rx <= 1; // stop bit
#1 clear_flag <= 1;
#(clock_period *2) clear_flag <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 0;
#(baud_period) rx <= 1;
#(baud_period) rx <= 1; // last bit of 300 octal
#(baud_period) rx <= 1;
#1 clear_flag <= 1;
#(clock_period *2) clear_flag <= 0;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 0; // a slow tx by about 3 %;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 0;
#(slow_baud) rx <= 0;
#(slow_baud) rx <= 0;
#(slow_baud) rx <= 0;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 1;
#(slow_baud) rx <= 1;

#500 $finish; 
end

endmodule
