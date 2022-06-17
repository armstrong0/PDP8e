
module mem_init_test();
wire [0:11] m_out;
reg clk;
reg reset;
integer k;

mem_inc mem( .clk (clk),
             .reset (reset),
	     .mem_plus (m_out));
	     


initial
begin
$readmemh("maindec-8i-d0ba-pb.hex",mem.ram1.mem,0,4095);
$dumpfile("mem_test.vcd");
$dumpvars(0,clk,reset,m_out);

#5 reset <= 1;
clk <= 0;
#5 clk <=1;
#5 clk <= 0;
#50 reset <= 0;
clk <= 0;
for (k = 0; k < 30; k =  k + 1)
begin 
# 5 $display("%h",m_out);
#5 clk <= 0; #5 clk <= 1;

end
end
endmodule

