module front_panel (
    input clk,
    input reset,
    input [4:0] state,
    input clear,
    input extd_addr,
    input addr_load,
    input dep,
    input exam,
    input cont,
    input dsel_sw,
    input fp_cont,
    input disk_rdy,
    input [0:11] sr,
    input sw,
    output reg sw_active,
    output reg swr,
    output reg triggerd,
    output reg fp_trigger,
    output reg cleard,
    extd_addrd,
    addr_loadd,
    depd,
    examd,
    contd,
    dseld,
    output reg [0:11] rsr,
    output reg [2:0] dsel

);





  wire cont_c;
  reg [6:0] switchl;
  reg [3:0] trig_state;
  reg [9:0] cntr;
  reg trigger1;
`ifdef AS_RK8E
`define AS
`endif

`ifdef AS_CSD
`define AS
`endif

`ifdef AS
  // autostart control
  reg AutoStart;
  reg [13:0] AS_data[0:10];  // 2 bits for op, 12 bits opernd
  // 00 load, 01 extn addr, 10 dep, 11 cont 
  reg [3:0] data_idx;
`endif

  initial begin  // RK8e
`ifdef AS_RK8E
    AS_data[0] = 14'o00030;  // Load
    AS_data[1] = 14'o26743;  // Dep
    AS_data[2] = 14'o25031;
    AS_data[3] = 14'o00030;
    AS_data[4] = 14'o30000;  //cont
`elsif AS_CSD
    //CSD
    AS_data[0] <= 14'o00025;  //    Load
    AS_data[1] <= 14'o26031;  //    Dep
    AS_data[2] <= 14'o25025;
    AS_data[3] <= 14'o26036;
    AS_data[4] <= 14'o27012;
    AS_data[5] <= 14'o27010;
    AS_data[6] <= 14'o23001;
    AS_data[7] <= 14'o22032;
    AS_data[8] <= 14'o25025;
    AS_data[9] <= 14'o00025;  //    Load
    AS_data[10] = 14'o30000;  //    cont
`endif

  end
  parameter reg [3:0]  //integer
  LATCH = 4'b000,
      WAIT  = 4'b001,
      TRIG1 = 4'b010,
      TRIG2 = 4'b011,
      TRIG3 = 4'b100,
      DELAY = 4'b101,
      REENABLE = 4'b110,
      TRIG4 = 4'b0111,
      AS0 = 4'b1000,
      AS1 = 4'b1001,
      AS2 = 4'b1010,
      AS3 = 4'b1011,
      AS4 = 4'b1100,
      AS5 = 4'b1101,
      AS6 = 4'b1110,
      AS7 = 4'b1111;


  // don't really care what state the main state machine is in,
  // as every processed
  // switch press is validated for the proper state elsewhere
  always @(posedge clk) begin
    if (reset) begin
      {triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd, dseld} <= 8'b0;
      switchl <= 7'b0000000;
      sw_active <= 1'b0;
      dsel <= 3'b000;
      fp_trigger <= 0;
      rsr <= 0;
`ifdef AS
      // need to test here to see if we need to autostart
      if (sw == 1) begin
        trig_state <= AS0;
        swr <= 0;  // inhibit sw for addr load from rsr
      end else trig_state <= LATCH;
      data_idx <= 0;
`else
      trig_state <= LATCH;
`endif
    end else begin
      case (trig_state)
        LATCH: begin
          rsr <= sr;
          swr <= sw;  // pass sw through so that ma can check and load the bus
          switchl <= switchl | {clear, extd_addr, addr_load, dep, exam, cont, dsel_sw};
          // latch inputs
          if (switchl == 7'b0000000) trig_state <= LATCH;
          else begin
            trig_state <= WAIT;
          end

        end
        WAIT: begin
          trig_state <= TRIG1;
          {triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd, dseld} <= {1'b1, switchl};
          switchl <= 7'b0000000;
        end
        TRIG1: begin
          trig_state <= TRIG2;
          // switchd <= switchd;
        end
        TRIG2: begin
          trig_state <= TRIG3;
          fp_trigger <= 1;
          if (dseld == 1) begin
            if (dsel == 5) dsel <= 0;
            else dsel <= dsel + 1;
          end
        end
        TRIG3: begin
          trig_state <= DELAY;
          sw_active  <= 1'b1;
        end
        DELAY:
        if (fp_cont == 1) begin
          trig_state <= REENABLE;
          fp_trigger <= 0;
          sw_active <= 1'b0;
          {triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd, dseld} <= 8'b0;
        end else begin
          trig_state <= DELAY;
          {triggerd, cleard, extd_addrd, addr_loadd, depd, examd, contd, dseld} <= 8'b0;
        end

        REENABLE: begin
          trig_state <= LATCH;
          fp_trigger <= 0;
        end
        default: trig_state <= LATCH;
`ifdef AS	
        AS0:
`ifdef AS_RK8E
        begin
          if (disk_rdy == 1) trig_state <= AS1;
	  else if (sw == 0 ) trig_state <= LATCH; // allows an escape when disk is not functioning
	  else trig_state <= AS0;
        end
`else
        trig_state <= AS1;  // CSD case we dont have to wait for disk_rdy
`endif
        AS1: begin
          trig_state <= AS2;
          rsr <= AS_data[data_idx][11:0];
          case (AS_data[data_idx][13:12])
            0: addr_loadd <= 1;
            1: extd_addrd <= 1;
            2: depd <= 1;
            3: contd <= 1;
            default: ;
          endcase
        end
        AS2: trig_state <= AS3;
        AS3: trig_state <= AS4;
        AS4: trig_state <= AS5;
        AS5: begin
          trig_state <= AS6;
          addr_loadd <= 0;
          extd_addrd <= 0;
          depd <= 0;
          contd <= 0;
        end
        AS6: begin
          if (AS_data[data_idx][13:12] == 2'b11) trig_state <= AS7;// cont pressed finish loader
          else trig_state <= AS1;
          data_idx <= data_idx + 1;
        end
        AS7: trig_state <= LATCH;
`endif
      endcase
    end
  end
endmodule

// for auto start
// add parameter to compile in auto start
// add a parameter to have the code for CSD loaded
// else load the RK8e boot code
// for RK8e we must wait for the disk_rdy  to assert
// set up arrays for the code and a variable to access them
// 
//  expand the state machine to handle states to load
// state machine assesses the array, sets 12 bits to the sr and 
// uses one of the other four bits to activate the control siganls
// addr_load, extd_addr_load, dep, cont.
// when cont inue is asserted the auto start portion of the state
// machine exits and the normal functions work as normal
// duplicate the state machine for normal for use with autostart, 
// howevery it does not use the fp_trigger, fp_cont signals



