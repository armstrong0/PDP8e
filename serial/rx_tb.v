`timescale 1 ns / 10 ps


module rx_tb;

reg clk;
reg reset;
reg Rx;
reg clear_flag;
reg clear;
wire flag;
wire [0:7] char;

rx RX (.reset (reset),
.clear (clear),
.clk (clk),
.rx (Rx),
.clear_flag (clear_flag),
.flag (flag),
.char0 (char)
);

`include "../parameters.v"

initial begin
        clk <=0;
        forever
        begin
            #(clock_period/2) clk <= 1;
            #(clock_period/2) clk <= 0;
        end
    end

localparam real baud_period = 1.0/baud_rate*1e9;
localparam real slow_baud = 0.97 * baud_period;
localparam full_baud = $rtoi(clock_frequency/(baud_rate));
localparam rx_term_nu_bits = $clog2(full_baud);
localparam seven_sixteenth = $rtoi(clock_frequency/(baud_rate)*7/16);
localparam one_sixteenth = $rtoi(clock_frequency /(baud_rate)/16);


initial begin 
  $dumpfile("rx.vcd");
  $dumpvars(0,RX);

#30 Rx <= 1;
#10 clear_flag <= 1;
#10 clear <= 1;
#1 reset <= 1;
#100 reset <= 0;
#100 clear_flag <= 0;
#20 clear <= 0;
#1 $display("clock frequency %f",(clock_frequency)) ;
#1 $display("clock period %f",(clock_period)) ;
#1 $display("baud rate %f ",(baud_rate)) ;
#1 $display("baud_period %f",(baud_period)) ;
#1 $display("nu counter bits %f",rx_term_nu_bits);
#1 $display(" 1    baud count %f",full_baud);
#1 $display(" 7/16 baud count %f",seven_sixteenth);
#1 $display(" 1/16 baud count %f",one_sixteenth);

//#1 $display(" 1/16 rx count %f",$rtoi(clock_frequency/(baud_rate*16)));
#1 $display("slow baud period %f",(slow_baud));

#(baud_period) Rx <= 0; // start
#(baud_period) Rx <= 0; // bit 0
#(baud_period) Rx <= 0; // 1
#(baud_period) Rx <= 0; // 2
#(baud_period) Rx <= 0; // 3
#(baud_period) Rx <= 0; // 4
#(baud_period) Rx <= 0; // 5
#(baud_period) Rx <= 0; // 6
#(baud_period) Rx <= 1; // last bit of octal 200
#(baud_period) Rx <= 1; // stop bit
wait(flag == 1);
#20 clear_flag <= 1;
#20 clear_flag <= 0;
#(baud_period) Rx <= 0; // start
#(baud_period) Rx <= 0; // 0
#(baud_period) Rx <= 0; // 1 
#(baud_period) Rx <= 0; // 2 
#(baud_period) Rx <= 0; // 3
#(baud_period) Rx <= 0; // 4
#(baud_period) Rx <= 0; // 5
#(baud_period) Rx <= 1; // 6
#(baud_period) Rx <= 1; // last bit of 300 octal
#(baud_period) Rx <= 1; //stop
wait(flag == 1);
#20 clear_flag <= 1;
#20 clear_flag <= 0;
#(slow_baud) Rx <= 1;
#(slow_baud) Rx <= 0; // a slow tx by about 3 %;
#(slow_baud) Rx <= 1; // 0
#(slow_baud) Rx <= 1; // 1
#(slow_baud) Rx <= 1; // 2
#(slow_baud) Rx <= 1; // 3
#(slow_baud) Rx <= 0; // 4
#(slow_baud) Rx <= 0; // 5 
#(slow_baud) Rx <= 0; // 6
#(slow_baud) Rx <= 0; // 7 last bit of 0x0f  o017
#(slow_baud) Rx <= 1; // stop
#(slow_baud) Rx <= 1;
#(slow_baud) Rx <= 1;
wait(flag == 1);
#20 clear_flag <= 1;
#20 clear_flag <= 0;
#1000 $finish; 
end

endmodule
