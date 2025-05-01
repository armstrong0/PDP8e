`include "../state_machine/state_machine.v"
`timescale 1 ns / 10 ps

module front_panel_st_tb;

    reg clk,reset;
    reg clear, extd_addr,addr_load,dep,exam,cont;
    reg dsel_sw;
    reg halt;
    reg sing_step;
    reg [0:11] instruction;
    wire contd;
    wire cleard , extd_addrd , addr_loadd , depd , examd;
    wire trigger;

    wire [4:0] state;
    wire [0:2] trig_stateo;
    wire [0:4] count;
`include "../parameters.v"

    front_panel UUT(.clk (clk),
        .clear (clear),
        .cont (cont),
        .extd_addr (extd_addr),
        .addr_load (addr_load),
        .dep (dep),
        .exam (exam),
        .dsel_sw (dsel_sw),

        .cleard (cleard),
        .extd_addrd (extd_addrd),
        .addr_loadd (addr_loadd) ,
        .depd (depd),
        .examd (examd),
        .contd (contd),
        .reset (reset),
        .state (state),
        .triggerd (trigger));

    state_machine sm1(.clk (clk),
        .reset (reset),
        .state (state),
        .halt (halt),
        .single_step (sing_step),
        .cont (contd),
        .trigger (trigger),
        .instruction (instruction));


    initial begin

        $dumpfile("front_st.vcd");
        $dumpvars(0,UUT);

        clk = 0;
        forever
            #10  clk = ~clk;
    end

    initial begin
        clear <= 0;
        extd_addr  <= 0;
        addr_load  <= 0;
        dsel_sw <= 0;
        dep  <= 0;
        exam <= 0;
        sing_step <= 0;
        cont <= 0;
        halt <= 1;
        instruction <= { JMS,9'o402};
        #15 reset <= 1;
        #25 reset <= 0;
        #20 addr_load <= 1;
        #60 addr_load <= 0;
        #500 clear <= 1;
        #100 clear <= 0;
        #300 extd_addr <= 1;
        #40 extd_addr <= 0;
        #450 exam <= 1;
        #45 exam <= 0;
        #333 dep <= 1;
        #100 dep <= 0;

        #200 cont <= 1;
        #20 cont <=0;
        #440 sing_step <= 1;
        #50 halt <= 0;
        #55 cont <= 1;
        #80 cont <= 0;
        #500 cont <= 1;
        #50 cont <= 0;
        #500 cont <= 1;
        #50 cont <= 0;
        #50 instruction <= 12'o7000;
        #500 cont <= 1;
        #50 cont <= 0;
        #50 instruction <= 12'o5400;
        #300 cont <= 1;
        #50 cont <= 0;
        #888 cont <= 1;
        #50 cont <= 0;
        #320 sing_step <= 0;
        #400 halt <= 1;
        #150 cont <=1;
        #40 cont <= 0;
        #500 $finish;
    end


endmodule

