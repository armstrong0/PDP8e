`timescale 1 ns / 10 ps
module front_panel_tb;

    reg clk,reset;
    reg halt;
    reg clear, extd_addr,addr_load,dep,exam,sing_step,cont;
    wire contd;
    wire cleard , extd_addrd , addr_loadd , depd , examd;

    wire [0:11] dout;
    reg [0:11] status,ac, mq, mb,io_bus,sr;
    reg [4:0] state;
    reg [3:11] state1;
    reg dsel_sw;
    reg run_ff;
    wire sw_active;
    wire [2:0] dsel;
    wire [0:4] dsel_led;
    wire run_led;

    wire [0:2] trig_stateo;
    wire [0:4] count;
`include "../parameters.v"

    front_panel FP(.clk (clk),
        .clear (clear),
        .extd_addr (extd_addr),
        .addr_load (addr_load),
        .dep (dep),
        .exam (exam),
        .dsel_sw (dsel_sw),
        .cont (cont),
        .sr (sr),
        .rsr (rsr),
        .cleard (cleard),
        .extd_addrd (extd_addrd),
        .addr_loadd (addr_loadd) ,
        .depd (depd),
        .examd (examd),
        .contd (contd),

        .dsel (dsel),
        .sw_active (sw_active),
        .reset (reset),
        .state (state));

    D_mux DM ( .clk (clk),
        .reset (reset),
        .dsel (dsel),
        .state (state),
        .state1 (state1),
        .status (status),
        .ac (ac),
        .mb (mb),
        .mq (mq),
        .io_bus (io_bus),
        .sw_active (sw_active),
        .dout (dout),
        .dsel_led (dsel_led),
        .run_ff (run_ff),
        .run_led (run_led));


    initial begin

        $dumpfile("front_panel.vcd");
        $dumpvars(0,FP,DM);
        clk = 0;
        forever
            #10  clk = ~clk;
    end

    initial begin
        clear <= 0;
        run_ff <= 0;
        halt <= 0;
        dsel_sw <= 0;
        ac =12'o1111;
        mq <= 12'o2222;
        mb <= 12'o3333;
        io_bus <= 12'o5555;
        // state <= 5'b10101;
        status <= 12'o6666;
        state1 = 9'b111111111;
        extd_addr  <= 0;
        addr_load  <= 0;
        dep  <= 0;
        exam <= 0;
        sing_step <= 0;
        cont <= 0;
        sing_step <= 0;
        state <= F0;

        #10 dsel_sw <= 0;

        #15 reset <= 1;
        #40 reset <= 0;
        #24 clear <= 1;
        #100 clear <= 0;
        #40 cont <= 1;
        #40 cont <=0;
        #500 extd_addr <= 1;
        #80 extd_addr <= 0;
        #500 addr_load <= 1;
        #50 addr_load <= 0;

        #1500 exam <= 1;
        #1 sr <= 12'o2525;
        #40 exam <= 0;
        #50 exam <= 1;
        #40 exam <= 0;
        #500 dep <= 1;
        #40 dep <= 0;
        sing_step <= 1;
        #500 cont <= 1;
        #50 cont <= 0;
        sing_step <= 0;
        #50 halt <= 1;

        #500 cont <= 1;
        #50 cont <= 0;
        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;

        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;
        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;
        #10 run_ff <= 1;
        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;
        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;
        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;
        #500 dsel_sw <= 1;
        #50 dsel_sw <=0;

        #2500 $finish;
    end


endmodule

