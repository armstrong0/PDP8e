module D_mux_tb;

reg [0:5] dsel;
reg [0:11] state;
reg [0:11] state;
reg [0:11] state;
reg [0:11] state;
reg [0:11] state;
reg [0:11] state;
wire [0:11] dout;

D_mux UUT (
        .dsel (dsel),
	.

	 initial
    begin
        $dumpfile("test.vcd");
        $dumpvars(0,dsel,aco,l,lo);
        ac <= 12'b000111001101;
        dsel <= 6'b000000;
        #1
        dsel <= 6'b000001;
        #1
        dsel <= 6'b000010;
        #1
        dsel <= 6'b000100;
        #1
        dsel <= 6'b001000;
        #1
        dsel <= 6'b010000;
        #1
        dsel <= 6'b100000;
        #1
        #1
        #1
        #1
        #1
        #1
        #1
    end
endmodule

