`timescale 1 ns / 10 ps


module rx_tb;

reg clk;
reg reset;
reg Rx;
reg clear_flag;
reg clear;
wire flag;
wire [0:7] char;

reg [15:0] baud_count;

rx RX (.reset (reset),
.clear (clear),
.clk (clk),
.rx (Rx),
.baud_count (baud_count),
.clear_flag (clear_flag),
.flag (flag),
.char0 (char)
);

`include "../parameters.v"
//`include "../FPGA_image/clock_frequency.v"
initial begin
        clk <=0;
        forever
        begin
            #(clock_period/2) clk <= 1;
            #(clock_period/2) clk <= 0;
        end
    end
localparam baud_rate = 115200;
localparam real baud_period = 1.0/baud_rate*1e9;
localparam real slow_baud = 0.97 * baud_period;
localparam real fast_baud = 1.03 * baud_period;
localparam tx_term_count = $rtoi(clock_frequency/baud_rate);
localparam tx_term_nu_bits = $clog2(tx_term_count);
localparam tx_term_cnt = tx_term_count[tx_term_nu_bits-1:0]; 




initial begin 
  $dumpfile("rx.vcd");
  $dumpvars(0,RX);
  #10 baud_count <= tx_term_count;
  
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
#1 $display("fast baud rate %f ",(fast_baud)) ;
#1 $display("slow baud rate %f ",(slow_baud)) ;
#1 $display("baud_period %f",(baud_period)) ;

#1 $display("slow baud period %f",(slow_baud));
#100 Rx <= 1;
#1000 ;
#(baud_period) Rx <= 0; // start
#(baud_period) Rx <= 1; // bit 0
#(baud_period) Rx <= 0; // 1
#(baud_period) Rx <= 1; // 2
#(baud_period) Rx <= 0; // 3
#(baud_period) Rx <= 1; // 4
#(baud_period) Rx <= 1; // 5
#(baud_period) Rx <= 0; // 6
#(baud_period) Rx <= 1; // last bit of octal 265
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


#(fast_baud) Rx <= 0; // start
#(fast_baud) Rx <= 1; // bit 0
#(fast_baud) Rx <= 0; // 1
#(fast_baud) Rx <= 1; // 2
#(fast_baud) Rx <= 0; // 3
#(fast_baud) Rx <= 1; // 4
#(fast_baud) Rx <= 1; // 5
#(fast_baud) Rx <= 0; // 6
#(fast_baud) Rx <= 1; // last bit of octal 265
#(fast_baud) Rx <= 1; // stop bit
wait(flag == 1);
#20 clear_flag <= 1;
#20 clear_flag <= 0;

#(slow_baud) Rx <= 0; // start
#(slow_baud) Rx <= 1; // bit 0
#(slow_baud) Rx <= 0; // 1
#(slow_baud) Rx <= 1; // 2
#(slow_baud) Rx <= 0; // 3
#(slow_baud) Rx <= 1; // 4
#(slow_baud) Rx <= 1; // 5
#(slow_baud) Rx <= 0; // 6
#(slow_baud) Rx <= 1; // last bit of octal 265
#(slow_baud) Rx <= 1; // stop bit
wait(flag == 1);

#20 clear_flag <= 1;
#20 clear_flag <= 0;



#(2*slow_baud)  $finish; 
end

endmodule
