`timescale 1 ns / 10 ps

module serial_tb;

    wire tx;
    serial_top ST(
        .clk (clk),
        .reset (reset),
        .clear (clear),
        .instruction (instruction),
        .state (state),
        .ac (ac),
        .rx (rx),
        .serial_bus (input_bus),
        .tx (tx),
        .UF (UF),
        .interrupt (interrupt),
        .skip (skip));

    reg clk;
    reg reset;
    reg clear;
    reg [0:11] instruction;
    reg [4:0] state;
    reg [0:11] ac;
    reg UF;
    wire [0:11] input_bus;
    wire flag;
    wire interupt;
    wire skip;
    wire rx;  //loop tx to rx
    
    assign rx = tx;

`include "../parameters.v"
    initial begin
        clk <=0;
        forever
        begin
            #5 clk <= 1;
            #5 clk <= 0;
        end
    end

    initial begin
        if (reset == 1)
            state <= F0;
    end
    always @(posedge clk)
    begin
        case (state)
            F0: state <= FW;
            FW: state <= F1;
            F1: state <= F2;
            F2: state <= F3;
            F3: state <= F0;
            default: state <= F0;
        endcase
    end

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0,ST);


        reset <= 1;
        clear <= 0;
        UF <= 0;

        #400 reset <= 0;
        ac <= 12'o0001;

        #40 instruction <= 12'o6035; // KIE AC11 to Keyboard interupt enable
        #100 ac <= 12'o0252;
        #180 ;
        wait(state == F0);
        #20 instruction <= 12'o6040;
        wait(state == F0);
        #20 instruction <= 12'o6041;
        wait(state == F0);
        #20 instruction <= 12'o6044; // TCP Load buffer and print
        wait(state == F0);
        #20 instruction <= 12'o7000;
        wait(state == F0);
//instruction <= 12'o6030; // KCF Clear Keyboard flag
//instruction <= 12'o6031; // KSF Skip if Keyboard Flag = 1
//instruction <= 12'o6032; // KCC Clear AC keyboard flag and set reader to run
//instruction <= 12'o6034; // KRS Read Keyboard buffer 'ors' the buffer int the AC
//instruction <= 12'o6036; // KRB Clear AC read keyboard buffer clear keyboard flags
//instruction <= 12'o6040; // SPF Set printer flag
//instruction <= 12'o6041; // TSF Skip if printer of keyboard flag = 1
//instruction <= 12'o6042; // TCF clear printer flag
//instruction <= 12'o6044; // TCP Load buffer and print

//instruction <= 12'o6045; // SPI Skip if printer interrupt = 1
//instruction <= 12'o6046;
//#30 rx <= 0;
//#320 rx <= 1;
//#320 rx <= 0;
//#320 rx <= 1;
//#320 rx <= 0;
//#320 rx <= 1;
//#320 rx <= 0;
//#320 rx <= 1;
//#320 rx <= 0;
//#320 rx <= 1;
//#320 rx <= 1;
//#320 rx <= 1;


        #120000 $finish;
        //#1200000 $finish;

    end

endmodule

