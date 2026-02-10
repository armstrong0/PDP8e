module ram (din, addr, write_en, clk, dout);// 8196 x 12 + 2048 x 12
    localparam data_width = 12;
    input [14:0] addr;
    input [data_width-1:0] din;
    input write_en, clk;
    output reg [data_width-1:0] dout;


`include "../parameters.v"
    // the following line defines the memory size.  A parameter from
    // parameters.v defines what to use. For the ic40hk8 we can have anything
    // up to 10 k.  10k words.  This is contigous memory. I would have 
    // prefered to have the 2048 segement on field 7 in the high half. 
    // this puts it in lower half of field 2. 
    // This was what I settled on after making several trys doing that.


    // two tests will not pass with partial fields so to make them pass change
    // the parameter MAX_address in parameters.v

        reg [data_width-1:0] mem [MAX_ADDRESS:0];
    
`ifndef SIM
        initial begin
           $readmemh("focal_loader.hex",mem,0,4095);
        end
`endif

	always @(posedge clk)
    if (write_en == 1)    begin
	    if (addr < MAX_ADDRESS+1) mem[addr[13:0]] <= din;
    end
    else
    if (addr < MAX_ADDRESS+1) dout <= mem[addr[13:0]];
    else dout <= 12'o0;
endmodule
