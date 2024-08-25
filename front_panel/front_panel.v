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
    input dsel_sw,
    output reg sw_active,   
    output triggerd,cleard, extd_addrd, addr_loadd, depd, examd, contd, dseld,
    output reg [5:0] dsel
);

`include "../parameters.v"
`ifndef SIM
    parameter integer dbnce_nu_bits = $clog2(clock_frequency) - 1;
`else
    parameter integer dbnce_nu_bits = 4;
`endif



    wire cont_c;
    reg [7:0] switchd;
    reg [6:0] switchl;
    reg [2:0] trig_state;
    //reg dseld;

    reg [dbnce_nu_bits:0] trig_cnt;  // the highest order bit is always dbnce_nu_bits !
    reg trigger1;

    assign {triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd,dseld } = switchd;

    parameter
      LATCH = 3'b000,
      WAIT  = 3'b001,
      TRIG1 = 3'b010,
      TRIG2 = 3'b011,
      TRIG3 = 3'b100,
      DELAY = 3'b101,
      REENABLE = 3'b110;

// This set of notes is to record in short form efforts to get this working
// again!  One of the last yosys ugrades seem to make the logic optimizer work
// better.  There was a noticable decrease in resoures and an increase in the
// allowable clock frequency.  However it also optimizes out logic, notably
// some of the counter in the tx module and here it appears that the state
// machine below completely dissappears, hence the switiches don't work.
// This can be seen in the synth log, as a counter going to [0:0] ie one bit
// instead of what it should be OR eliminating switches (6 in the case of this
// module)
//
// // I think the real problem was my improper usage of $clog2

// don't really care what state the main state machine is in, as every processed
// switch press is validated for the proper state elsewhere
    always @(posedge clk)
    begin
        if (reset)
        begin
            trig_state <= LATCH;
            switchd <= 8'b0000000;
            switchl <= 7'b000000;
            trig_cnt <= 0;
            sw_active <= 1'b0;
            dsel <= 6'b100000;
        end
        else
        begin
            case (trig_state)
                LATCH:
                begin
                    switchl <= switchl |
                    {clear, extd_addr, addr_load, dep, exam, cont, dsel_sw };// latch inputs
                    if (switchl == 6'b000000)
                        trig_state <= LATCH;
                    else
                    begin
                        trig_state <= WAIT;
                    end
                end
                WAIT:
                begin
                    trig_state <= TRIG1 ;
                    switchd <= {1'b1,switchl};
                    switchl <= 6'b000000;
                end
                TRIG1: begin
                    trig_state <= TRIG2;
                    switchd <= switchd;
                    trig_cnt <=0;
                end
                TRIG2: begin
                    trig_state <= TRIG3;
                    switchd <= switchd;
                    if (dseld == 1) dsel <= {dsel[0] ,dsel[5:1]};  // rotate the display select 
                end
                TRIG3: begin
                    trig_state <= DELAY;
                    switchd <= switchd;
                end
                DELAY: if (trig_cnt[dbnce_nu_bits] == 1)
                begin
                    trig_state <= REENABLE;
                    sw_active <= 1'b0;
                end
                else
                begin
                    trig_cnt <= trig_cnt + 1;
                    trig_state <= DELAY;
                    sw_active <= 1'b1;
                    switchd <= 7'b0000000;
                end

                REENABLE: trig_state <= LATCH;
                default: trig_state <= LATCH;

            endcase
        end
    end


endmodule

