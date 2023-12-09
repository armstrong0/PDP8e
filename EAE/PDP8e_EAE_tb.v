`define SIM
`timescale 1 ns / 10 ps
`define pulse(arg) #1 ``arg <=1 ; #140 ``arg <= 0

`define pulse1(arg) #1 ``arg <=1 ; #1400 ``arg <= 0


module PDP8e_tb;
  reg clk100;
  reg clk;
  reg pll_locked;
  reg reset;
  reg rx;
  reg [0:11] sr;
  reg [0:5] dsel;
  reg dep;
  reg sw;
  reg single_step;
  reg halt;
  reg exam;
  reg cont;
  reg extd_addr;
  reg addr_load;
  reg clear;
  reg [0:14] address;
  reg [0:23] acmq;
  wire led1;
  wire led2;
  wire runn;
  wire [0:14] An;
  wire [0:11] dsn;
  wire tx;
  wire tclk;

  `include "../parameters.v"
  `include "../FPGA_image/HX_clock.v"

  localparam clock_period = 1e9 / clock_frequency;

  always begin  // clock _period comes from parameters.v
    #(clock_period / 2) clk100 <= 1;
    #(clock_period / 2) clk100 <= 0;
  end

  always begin  // assumes about a 12 MHz clock
    #42 clk <= 1;
    #42 clk <= 0;
  end
  always @* begin
    address <= ~An;
    acmq <= {UUT.AC.ac, UUT.AC.mq};
  end

  always @(posedge clk100) begin
    rx <= tx;
  end
  parameter test_sel = 2;


  PDP8e UUT (
      .clk(clk),
      .runn(runn),
      .led1(led1),
      .led2(led2),
      .An(An),
      .dsn(dsn),
      .tx(tx),
      .clk100(clk100),
      .pll_locked(pll_locked),
      .reset(reset),
      .rx(rx),
      .sr(sr),
      .dsel(dsel),
      .dep(dep),
      .sw(sw),
      .single_stepn(~single_step),
      .haltn(~halt),
      .examn(~exam),
      .contn(~cont),
      .extd_addrn(~extd_addr),
      .addr_loadn(~addr_load),
      .clearn(~clear)
  );



  always @(posedge clk) begin

    if ((UUT.instruction == 12'b1111??????10) && (UUT.state == H0)) begin
      case (test_sel)
        1: ;
        //11: if ($time < 5000)
        //begin
        //    `pulse(cont);  //it would appear that a case with just pulse does not work
        //end
        //else $finish;
        12: begin
          #1000 $finish;
        end
        default:
        if ($time > 5000) begin
          $display("Stopped %d because of a Halt", $time);
          $display("Address:%o", address);
          #1000 $finish;
        end
      endcase
    end
  end

  always @(posedge clk) begin
    case (test_sel)
      1:
      case (address)
        15'o05276: begin
          $display("Passed Instruction Set Part 1");
          #99 $finish;
        end
        15'o00147: $display("starting SZA Test 1");
        15'o00157: $display("starting SZA Test 2");
        15'o00166: $display("starting SZA Test 3");
        15'o00201: $display("starting SZA Test 4");
        15'o00210: $display("starting SZA Test 5");
        15'o00217: $display("starting SZA Test 6");
        15'o00226: $display("starting SZA Test 7");
        15'o00235: $display("starting SZA Test 8");
        15'o00244: $display("starting SZA Test 9");
        15'o00253: $display("starting SZA Test 10");
        15'o00262: $display("starting SZA Test 11");
        15'o00271: $display("starting SZA Test 12");
        15'o00300: $display("starting SZA Test 13");
        15'o00307: $display("starting SPA Test 1");
        15'o00313: $display("starting SPA Test 2");
        15'o00320: $display("starting SMA Test 1");
        15'o00325: $display("starting SMA Test 2");
        default:   ;
      endcase

      1.1:
      if (address == 15'o05701)  // test 1
            begin
        $display("Passed Instruction Set Part 1.1");
        #99 $finish;
      end
      2:
      if (address == 15'o03736)  // test 1
            begin
        $display("Passed Instruction Set Part 2 one pass");
        #99 $finish;
      end

      2.1: ;
      3:
      if (address == 15'o01653) begin
        $display("%c", UUT.ac[4:11]);
        #99 $finish;
      end

      4:
      if (address == 15'o03551) begin
        $display("completed one pass of JMS JMP");
        #1000 $finish;
      end

      5:
      if (address == 15'o07443) begin
        $display("completed one pass of Random TAD");
        #1000 $finish;
      end
      6:
      if (address == 15'o00326) begin
        $display("completed one pass of Random AND");
        #1000 $finish;
      end

      7:
      if (address == 15'o07602) begin
        $display("Printing Random ISZ");
        #1000 $finish;
      end


      8:
      if (address == 15'o00302) begin
        $display("Printing one bell Random DCA");
        #1000 $finish;
      end


      9: ;
      10: ;
      11:
      case (address)
        15'o00337: $display("Starting Test 1");
        15'o00600: $display("Starting Test 2");
        15'o00656: $display("Starting Test 3");
        15'o02271: $display("Starting Test 4");
        15'o02367: $display("Finished Test 5");
        15'o02047: $display("Starting Test 6");
        15'o04000: $display("Starting Test 7");
        15'o02400: $display("Starting Test 8");
        15'o02452: $display("Starting Test 9");
        15'o01050: $display("Starting Test 10");
        15'o01400: $display("Starting Test 11");
        15'o01432: $display("Starting Test 12");
        15'o01600: $display("Starting Test 13");
        15'o02200: $display("Starting Test 14");
        15'o02600: $display("Starting Test 15");
        15'o03200: $display("Starting Test 15 Part 2");
        15'o03400: $display("Starting Test 15 Part 3");

        15'o03502: $display("Starting Test 16");
        15'o01565: $display("Finished complete tests!");
      endcase
      12: ;
      13:
      case (address)
        //15'o01602: $display("Address 1602");
        //15'o00115:begin
        //      $display("found address 00115");
        //      $displayo("instruction  ",UUT.instruction);
        //  end
        //15'o06007: #1000 $finish;
        default: ;
      endcase
      default: ;
    endcase

  end



  initial begin
    #1 $display("clock frequency %f", (clock_frequency));
    #1 $display("baud rate %f ", (baud_rate));
    #1 $display("clock period %f", (clock_period));
    // #1 $display("baud_period %f",(baud_period)) ;
    #1 $display("cycle time %f nanoseconds", (6 * clock_period));


    #1 sr <= 12'o0200;  // normal start address
    case (test_sel)
      1: begin
        $dumpfile("instruction_test_pt1.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0AB.hex", UUT.MA.ram.mem, 0, 4095);
      end
      1.1: begin
        $dumpfile("instruction_test_pt1.1.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/dhkaf-a.hex", UUT.MA.ram.mem, 0, 4095);
      end
      2: begin
        $dumpfile("instruction_test_pt2.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0BB.hex", UUT.MA.ram.mem, 0, 4095);
      end

      2.1: begin
        $dumpfile("instruction_test_pt2.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/dhkag-a.hex", UUT.MA.ram.mem, 0, 4095);
      end
      3: begin
        $dumpfile("Adder_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0CC.hex", UUT.MA.ram.mem, 0, 4095);
        sr <= 12'o2416;
      end
      4: begin
        $dumpfile("JMP_JMS_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0IB.hex", UUT.MA.ram.mem, 0, 4095);
      end
      5: begin
        $dumpfile("TAD_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0EB.hex", UUT.MA.ram.mem, 0, 4095);
        sr <= 12'o0400;
      end
      6: begin
        $dumpfile("AND_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0DB.hex", UUT.MA.ram.mem, 0, 4095);
        sr <= 12'o3400;
      end

      7: begin
        $dumpfile("ISZ_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0FC.hex", UUT.MA.ram.mem, 0, 4095);
      end

      8: begin
        $dumpfile("DCA_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0GC.hex", UUT.MA.ram.mem, 0, 4095);
        sr <= 12'o0004;
      end
      9: begin
        $dumpfile("RJMP_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0HC.hex", UUT.MA.ram.mem, 0, 4095);
        sr <= 12'o0004;
      end
      10: begin
        $dumpfile("RJMP_JMS_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/D0JB.hex", UUT.MA.ram.mem, 0, 4095);
        sr <= 12'o0004;
      end

      11: begin
        $dumpfile("extended_memory.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/dhmca.hex", UUT.MA.ram.mem, 0, 8191);
        $dumpvars(0, UUT);
      end

      12: begin
        $dumpfile("Serial_test.vcd");
        $dumpvars(0, UUT);
        $readmemh("Diagnostics/d2ab.hex", UUT.MA.ram.mem, 0, 8191);
      end
      13: begin
        $dumpfile("EAE_Test1.vcd");
        $readmemh("d0lb.hex", UUT.MA.ram.mem, 0, 8191);
        $dumpvars(0, UUT);
      end

      14: begin
        $dumpfile("SHL_Test1.vcd");
        $readmemh("t14.hex", UUT.MA.ram.mem, 0, 8191);
        $dumpvars(0, UUT);
      end

    endcase
    #0 halt <= 1;
    #1 reset <= 1;
    #1 clear <= 0;
    //#(clock_period*10) reset <=0;
    #1 single_step <= 0;
    #1 sw <= 0;
    #1 exam <= 0;
    #1 cont <= 0;
    #1 extd_addr <= 0;
    #1 addr_load <= 0;
    #1 dep <= 0;
    #1 dsel <= 6'b001000;
    #1 sr <= 12'o0200;
    #1 pll_locked <= 0;
    #1 rx <= 1;  // marking state
    #100 pll_locked <= 1;
    #10 halt <= 0;
    #100 reset <= 0;

    case (test_sel)
      1: begin
        `pulse(addr_load);
        #500 `pulse(cont);
        sr <= 12'o7777;
        #500 `pulse(cont);
        $display("Starting");
        #520000000 $finish;
      end

      1.1: begin
        `pulse(addr_load);
        #500 `pulse(cont);
        sr <= 12'o7777;
        #500 `pulse(cont);
        sr <= 12'o7777;
        #520000000 $finish;
      end
      2: begin
        `pulse(addr_load);
        #(clock_period * 50) `pulse(cont);
        //#5000 $finish ;
        #500000000 $finish;
      end

      2.1: begin
        `pulse(addr_load);
        #(clock_period * 50) `pulse(cont);
        `pulse(cont);
        #17800000 $finish;
      end
      3: begin
        `pulse(addr_load);
        #(clock_period * 50) `pulse(cont);
        sr <= 12'o2416;
        `pulse(cont);
        #1000000000 $finish;
      end
      4: begin
        `pulse(addr_load);
        sr <= 12'o2416;
        #(clock_period * 50) `pulse(cont);

        `pulse(cont);
        #90000000 $finish;
      end
      5: begin
        `pulse(addr_load);
        #(clock_period * 50) `pulse(cont);
        sr <= 12'o0000;
        `pulse(cont);
        #500000000 $finish;
      end
      6: begin
        `pulse(addr_load);
        #(clock_period * 50) `pulse(cont);
        sr <= 12'o2400;
        `pulse(cont);
        #800000000 $finish;
      end
      7: begin
        `pulse(addr_load);
        #(clock_period * 50) `pulse(cont);
        sr <= 12'o2000;
        `pulse(cont);
        #500000000 $finish;  // 1/2 second limit
      end
      8: begin
        `pulse(addr_load);
        sr <= 12'o2000;
        #(clock_period * 50) `pulse(cont);
        `pulse(cont);
        #500000000 $finish;
      end
      9: begin
        `pulse(addr_load);
        sr <= 12'o0004;
        #(clock_period * 50) `pulse(cont);
        `pulse(cont);
        #150000000 $finish;
      end
      10: begin
        `pulse(addr_load);
        sr <= 12'o0004;
        #(clock_period * 50) `pulse(cont);
        `pulse(cont);
        #150000000 $finish;
      end
      11: begin
        sr <= 12'o2200;  //test 14
        #1000;
        `pulse(addr_load);
        sr <= 12'o0001;  // simulation has 8k, reads 0000 for
        // non-exsistant memory
        #1000 `pulse(cont);
        // #1000  `pulse(cont);
        #5000000 $finish;
      end
      12: begin
        #100 $display("in test 12");
        ;
        sr <= 12'o0020;
        #5000 `pulse1(addr_load);
        sr <= 12'o0002;
        #5000 `pulse1(dep);
        sr <= 12'o0304;
        #5000 `pulse1(dep);
        sr <= 12'o1200;
        #5000 `pulse1(dep);
        sr <= 12'o0200;
        #5000 `pulse1(addr_load);
        sr <= 12'o0001;  //prog1
        #5000 `pulse1(cont);
        #890000 `pulse1(cont);
        #5000 sr <= 12'o6006;  //do one routine sr 6:11 has number
        //wait(UUT.state == H0);
        #100000;
        $finish;
      end
      13: begin
        sr <= 12'o5000;  // shl0
        //sr <= 12'o1600;  // shl1
        //sr <= 12'o1652;  // lsr0
        //sr <= 12'o2000;  // lsr1
        //sr <= 12'o2052;  // asr0
        //sr <= 12'o2200;  // asr1
        //sr <= 12'o3600;  // nmi
        //sr <= 12'o4200;  // nmi1
        //sr <= 12'o4400;  // nmi2
        #200 `pulse(addr_load);
        sr <= 12'o4002;  // no printout stop on error, test a only
        #400 `pulse(cont);
        #1000 $finish;
        //#7000000 $finish;

      end
      14: begin

        //sr <= 12'o5000;
        #1000 sr <= 12'o0200;
        #1000 `pulse(addr_load);
        #1000 `pulse(cont);
        #28000 $finish;
      end

      default: ;
    endcase

  end

endmodule
