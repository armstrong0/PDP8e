module up_spram (
    input clk,
    input wr,
    input  [14:0] addr,
    input  [15:0] wdata,
    output [15:0] rdata
);

wire cs_0, cs_1;
wire [15:0] rdata_0, rdata_1;

assign cs_0 = !addr[14];
assign cs_1 = addr[14];
assign rdata = addr[14] ? rdata_1 : rdata_0;
//assign wen[3:0] = {wr,wr,wr,wr};


SB_SPRAM256KA ram00
  (
    .ADDRESS(addr[13:0]),
    .DATAIN(wdata[15:0]),
    .MASKWREN({1'b1 ,1'b1,1'b1, 1'b1}),
    .WREN(wr),
    .CHIPSELECT(cs_0),
    .CLOCK(clk),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(rdata_0[15:0])
  );


SB_SPRAM256KA ram10
  (
    .ADDRESS(addr[13:0]),
    .DATAIN(wdata[15:0]),
    .MASKWREN({1'b1 ,1'b1,1'b1, 1'b1}),
    .WREN(wr),
    .CHIPSELECT(cs_1),
    .CLOCK(clk),
    .STANDBY(1'b0),
    .SLEEP(1'b0),
    .POWEROFF(1'b1),
    .DATAOUT(rdata_1[15:0])
  );


endmodule
