module ram (din, addr, write_en, clk, dout);// 8196 x 12 + 2048 x 12
// this is NOT portable
    localparam data_width = 12;
    input [14:0] addr;
    input [data_width-1:0] din;
    input write_en, clk;
    output reg [data_width-1:0] dout;
    // the following line defines 10k words, there is probably a formula that
    // could be used but this seems cleaerer.  I would have prefered to have
    // the 2048 segement on field 7 in the high half, this puts it in field 2
    // in the lower half.  After several trys at making it do that I gave up,
    // it would make the 8 K in block ram and then the rest in logic! 
    // which would not fit..

    reg [data_width-1:0] mem [15'o23777:0];
    
`ifndef SIM
        initial begin
           $readmemh("focal_loader.hex",mem,0,4095);
        end
`endif

	always @(posedge clk)
    if (write_en == 1)    begin
	    if (addr < 15'o24000) mem[addr[13:0]] <= din;
    end
    else
    if (addr < 15'o24000) dout <= mem[addr[13:0]];
    else dout <= 12'o0;
endmodule
