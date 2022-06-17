module parameters_tb;

`include "parameters.v"
initial begin
#1 $display("debounce %d ",dbnce_nu_bits);
//#1 $display("Tx term_cnt %d \n",tx_term_cnt);
#1 $display("Clock frequency ",clock_frequency);
#1 $display("Clock Period ",clock_period ) ;  
#1 $display("baud_rate ", baud_rate);    
#1 $display("baud period ",baud_period);
#1 $display("Tx Term Count ", tx_term_cnt);
#1 $display("Required number of bits:",$rtoi($clog2(tx_term_cnt)));

# 1000 $finish;
end

endmodule
