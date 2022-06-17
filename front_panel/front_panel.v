module front_panel (input clk,
    input reset,
    input [3:0] state,
    input clear,
    input extd_addr,
    input addr_load,
    input dep,
    input exam,
    input cont,
    input sing_step,
    input halt,
    output triggerd,cleard , extd_addrd , addr_loadd , depd , examd, contd
	);

`include "../parameters.v"
    reg cont_c;
    reg [0:6] switchd;
    reg [0:2] trig_state;

    reg [0:dbnce_nu_bits] trig_cnt;  // the highest order bit is always bit 0 !
    reg trigger1;
    assign { triggerd,cleard , extd_addrd , addr_loadd , depd , examd, contd } = switchd;

    localparam Wait = 3'b000,
          Trig1 = 3'b001,
          Trig2 = 3'b010,
     	  Trig3 = 3'b011,
          Delay = 3'b100,
          Reenable = 3'b101;

    always @*
    begin
        trigger1 = (trig_state == Wait)&&
        ( clear | extd_addr | addr_load | dep | exam | cont );
        cont_c = (cont & (sing_step | halt));
    end

    always @(posedge clk) 
    begin
        if (reset)
        begin
            trig_state <= Wait;
            switchd <= 7'b0000000;
            trig_cnt <= 0;
        end
        else
        begin
            case (trig_state)
                Wait: if (((state == H0) & (trigger1 == 1)) |
                        ((state == F0) & cont_c) |
                        ((state == D0) & cont_c) |
                        ((state == E0) & cont_c))
                begin
                    trig_state <= Trig1 ;
                    switchd <= {1'b1,clear ,extd_addr ,addr_load , dep ,exam, cont };
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
                Delay: if (trig_cnt[0] == 1)
                begin
                    trig_state <= Reenable;
                end
                else
                begin
                    trig_state <= Delay;
		            switchd <= 7'b0000000;
                end

                Reenable: trig_state <= Wait;
				default: trig_state <= Wait;

            endcase
            if (trig_state == Trig1)
                trig_cnt <=0;
            else  trig_cnt <= trig_cnt + 1;
        end
    end


endmodule

