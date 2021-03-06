/* verilator lint_off LITENDIAN */

module D_mux(
    input clk,
    input reset,
    input [0:5] dsel,
    input [4:0] state,
    input [3:11] state1,
    input [0:11] status,
    input [0:11] rac,
    input [0:11] mb,
    input [0:11] rmq,
    input [0:11] io_bus,
    output reg [0:11] dout,
    output reg run_led);

    reg FS,DS,ES;

    always @* begin
        if(state[3:2] == 2'b00) FS = 1;  else FS = 0;
        if(state[3:2] == 2'b01) DS = 1;  else DS = 0;
        if(state[3:2] == 2'b10) ES = 1;  else ES = 0;
        if(state[3:2] == 2'b11)
            run_led = 0;
        else
            run_led = 1;
    end

    always @(posedge clk) begin

// state (F D E IR0 IR1 IR2 MD_Dir DATA_CONT SW PAUSE BRK_PROG BRK
// status (link, gt int_bus NO_int ION UM IF0 IF1 IF2 DF0 DF1 DF2)
// ac mb mq bus
        if (dsel[5] == 1)
            dout <= {FS,DS,ES,state1};
        else if (dsel[4] == 1)
            dout <= status;
        else if (dsel[3] == 1)
            dout <= rac;
        else if (dsel[2] == 1)
            dout <= mb ;
        else if (dsel[1] == 1)
            dout <= rmq;
        else if (dsel[0] == 1)
            dout <= io_bus;
        else
            dout <= 12'b000000000000;
    end
endmodule


