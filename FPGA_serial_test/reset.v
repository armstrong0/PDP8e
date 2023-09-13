module reset(input clk,input lock,output resetn);
wire clk, resetn;
reg [3:0] PLL_LOCKED_BUF;


always @(posedge clk)
    PLL_LOCKED_BUF <= {PLL_LOCKED_BUF, PLL_LOCKED};

assign resetn = PLL_LOCKED_BUF[3];

endmodule

