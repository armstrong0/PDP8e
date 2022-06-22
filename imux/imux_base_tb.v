module imux_base_tb;
    reg clk;
    reg reset;
    reg mskip,iskip,sskip;
    wire eskip;


    reg [0:11] instruction;
    reg [0:11] serial_bus,mem_reg_bus;
    wire [0:11] in_bus,display_bus;
    reg [4:0] state;

imux IM(
.clk (clk),
.reset (clk),
.state (state),
.instruction (instruction),
.mem_reg_bus (mem_reg_bus),
.serial_data_bus (serial_bus),
.iskip (iskip),
.sskip (sskip),
.mskip (mskip),
.skip (eskip),
.in_bus (in_bus),
.bus_display (display_bus)); 



    initial begin
        #5 clk <= 1;
	forever begin
        #5 clk <= ~clk;
	end
    end



    initial begin
        $dumpfile("imux_base.vcd");
        $dumpvars(0,clk,reset,state,instruction,iskip,sskip,mskip,eskip,mem_reg_bus,serial_bus,in_bus,display_bus);
        reset <= 1;
        iskip <=0;
        mskip <=0;
        sskip <=0;
        #50 reset <= 0;
	// most of the module being test is combinatorial, no real need for
	// clock or state.  However once we get to bus display we need clock
	// and state
	#5 instruction <= 12'o6000;
	iskip <= 1;
	#20 iskip <=0;
	#5 mskip <= 1;
	#5 sskip <=1;
	#5 instruction <= 12'o6007;
	#20 iskip <=1;
	#5 mskip <= 0;
	#5 sskip <=0;
	//#5 iskip <= 0;
	#5 instruction <= 12'o6037;
        #10 instruction <= 12'o6047;
	#10 sskip <= 1;
	#5 instruction <= 12'o6030;
	#10 mem_reg_bus <= 12'o6363;
	#10 serial_bus <= 12'o7070;
	#5 instruction <= 12'o6000;
	#5 instruction <= 12'o6037;
        #5 instruction <= 12'o6224;



	#1000 ;
        $finish;
    end
endmodule

