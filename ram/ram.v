module ram (din, addr, write_en, clk, dout);// 8196 x 12
`ifdef address_width13
	parameter addr_width = 13;
`else
    parameter addr_width = 15;
`endif	
	parameter data_width = 12;
	input [addr_width-1:0] addr;
	input [data_width-1:0] din;
	input write_en, clk;
	output reg [data_width-1:0] dout;
	reg [data_width-1:0] mem [(1<<addr_width)-1:0];
`ifndef SIM	
        initial begin
           //$readmemh("loader.hex",mem,0,4095);// both bin and rim loaders
           //$readmemh("utils.hex",mem,0,4095);// both bin and rim loaders
           //$readmemh("focal.hex",mem,0,4095);
           $readmemh("focal_loader.hex",mem,0,4095);
           //$readmemh("tit_interrupt.hex",mem,0,4095);
		   //$readmemh("../integrate3/Diagnostics/D0AB.hex", mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/dhkaf-a.hex", mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0BB.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/dhkag-a.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0CC.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0IB.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0EB.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0DB.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0FC.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0GC.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0HC.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/D0JB.hex",mem,0,4095);
           //$readmemh("../integrate3/Diagnostics/dhmca.hex",mem,0,8191);
           //$readmemh("../integrate3/Diagnostics/d2ab.hex",mem,0,4095);
		   //$readmemh("toggle-in-tests.hex",mem,0,4095);
        end
`endif	
    always @(posedge clk)
	begin
	if (write_en)
		mem[addr] <= din;
	end

	always @(posedge clk)
	begin
		dout <= mem[addr]; // Output register controlled by clock.
    end
endmodule
