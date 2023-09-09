module front_panel (input clk,
    input reset,
    input [4:0] state,
    input clear,
    input extd_addr,
    input addr_load,
    input dep,
    input exam,
    input cont,
    input sing_step,
    input halt,
    output reg sw_active,
    output triggerd,cleard , extd_addrd , addr_loadd , depd , examd, contd
);

`include "../parameters.v"
    wire cont_c;
    reg [6:0] switchd;
    reg [5:0] switchl;
    reg [2:0] trig_state;

    reg [dbnce_nu_bits:0] trig_cnt;  // the highest order bit is always dbnce_nu_bits !
    reg trigger1;

    assign { triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd } = switchd;

    localparam reg Latch = 3'b110,
          Wait  = 3'b000,
          Trig1 = 3'b001,
          Trig2 = 3'b010,
          Trig3 = 3'b011,
          Delay = 3'b100,
          Reenable = 3'b101;


    assign cont_c = (cont & sing_step );

    always @(posedge clk)
    begin
        if (reset)
        begin
            trig_state <= Latch;
            switchd <= 7'b0000000;
            switchl <= 6'b000000;
            trig_cnt <= 0;
            sw_active <= 1'b0;
        end
        else
        begin
            case (trig_state)
                Latch:
                begin
                    switchl <= switchl |
                     {clear, extd_addr, addr_load, dep, exam, cont };// latch inputs
                    if (switchl == 6'b000000)
                        trig_state <= Latch;
                    else
                    begin
                        trig_state <= Wait;
                        trigger1 <= 1'b1;
                    end
                end
                Wait: if ((((state == H0) || (state == HW)) & (trigger1 == 1)) |
                        ((state == F0) & cont_c) |
                        ((state == D0) & cont_c) |
                        ((state == E0) & cont_c))
                begin
                    trig_state <= Trig1 ;
                    switchd <= {trigger1,switchl};
                    switchl <= 6'b000000;
                end
                Trig1: begin
                    trig_state <= Trig2;
                    switchd <= switchd;
                end
                Trig2: begin
                    trig_state <= Trig3;
                    switchd <= switchd;
                end
                Trig3: begin
                    trig_state <= Delay;
                    switchd <= switchd;

                end
                Delay: if (trig_cnt[dbnce_nu_bits] == 1)
                begin
                    trig_state <= Reenable;
                    sw_active <= 1'b0;
                end
                else
                begin
                    trig_state <= Delay;
                    sw_active <= 1'b1;
                    switchd <= 7'b0000000;
                end

                Reenable: trig_state <= Latch;
                default: trig_state <= Latch;

            endcase
            if (trig_state == Trig1)
                trig_cnt <=0;
            else  trig_cnt <= trig_cnt + 1;
        end
    end


endmodule

