`timescale 1 ns / 10 ps

module tx_tb;

    reg clk;
    reg reset;
    reg clear;
    wire tx;
    reg load;
    wire flag;
    reg [0:11] char;
    reg baud_clk;
    reg set_flag,clear_flag;

`include "../parameters.v"

    tx tx1(.clk100 (clk),
        .reset (reset),
        .clear (clear),
        .tx (tx),
        .load (load),
        .char (char),
        .clear_flag (clear_flag),
        .set_flag (set_flag),
        .flag (flag));

    initial begin

        clk <=0;
        char <= 12'o0000;
        forever
        begin
           #(clock_period/2) clk <= 1;
           #(clock_period/2) clk <= 0;
        end
    end

    initial begin
        $dumpfile("tx.vcd");
        $dumpvars(0,tx1);
        clear_flag <= 0;
        set_flag <= 0;
        reset <= 1;
        clear <= 0;
        load <= 0;
        #40 reset <= 0;
        #40 set_flag <= 1;
        #40 set_flag <= 0;
        #40 clear_flag <= 1;
        #40 clear_flag <= 0;
        #20 load <= 0;
        wait (tx1.flag == 1'b0); 
        #1000 char <= 12'o0110;
        #(2*clock_period) load <= 1;
        #(2*clock_period) load <= 0;
        wait (tx1.flag == 1'b1); 
        #78200 char <= 12'o0105;
        #20 load <= 1;
        #20 load <= 0;
        #98000  char <= 12'o0114;
        #20 load <= 1;
        #20 load <= 0;
        #150000 char <= 12'o0114;
        #20 load <= 1;
        #20 load <= 0;
        #93000 char <= 12'o0117;
        #20 load <= 1;
        #20 load <= 0;
        #150000 char <= 12'o0015;
        #20 load <= 1;
        #20 load <= 0;
        
        #150000 $finish;
    end

endmodule
