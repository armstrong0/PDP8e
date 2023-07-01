/* verilator lint_off ASCRANGE */

module scan_matrix (
    input clk,
    input reset,
    input [0:11] A,
    input [0:2] EMA,
    input [0:11] ds,
    output reg [0:2] LR,
    output reg [0:12] LC,
    output reg [0:4] SR,
    output reg [0:11] sr,
    output reg [2:0] dsel,
    output reg single_step,
    halt, sw,
    output reg addr_load,
    extd_addr,
    clear,
    cont,
    exam,
    dep,
    input [0:3] SC
);

  reg [14:0] counter;
  reg [ 1:0] Lrow;
  reg [ 2:0] Srow;
  reg [0:5] dsel1;

  // three signals single_step, halt and sw have to be developed in this
  // module.  In an original PDP8e they are essentailly toggle switches, Here
  // we are emulating that with push button switches.  So we have to detect
  // presses, toggle the state of the signal and hold off making changes for
  // some period of time.  Basically the same as the circuitry in
  // front_panel.v
  //
  // Additionally the 12 sr switches need the same treatment

  always @(posedge clk) begin
    if (reset == 1'b1) begin
      counter <= 15'd0;
      Lrow <= 2'b00;
      Srow <= 3'b000;

    end else counter <= counter + 15'd1;
    if (counter == 15'd0) begin
      
      case (Lrow)
        0: begin
          Lrow <= 2'd1;
          LC   <= {EMA[0:2], A[0:6], dsel1[0:1]};
        end
        1: begin
          LC   <= {A[7:11], ds[0:4], dsel1[2:3]};
          Lrow <= 2'd2;
        end
        2: begin
          LC   <= {ds[5:11], single_step, halt,sw, dsel1[4:5]};
          Lrow <= 2'd0;
        end
        default: Lrow <= 2'b00;
      endcase
      case (Srow)
        0: begin
	   SR <= 6'b100000;
	   sr[0:3] <= SC;
	   Srow <= 3'b001;
        end
        1: begin
	   SR <= 6'b010000;
	   sr[4:7] <= SC;
	   Srow <= 3'b010;
        end
        2: begin
	   SR <= 6'b001000;
	   sr[8:11] <= SC; 
	   Srow <= 3'b011;
        end
        3: begin
	   SR <= 6'b000100;
	   {single_step,halt,sw,dep} <= SC; //need separate signals for inout and processed output
	   Srow <= 3'b100;
        end
        4: begin
	   SR <= 6'b000010;
	   {dep,exam} <= SC[0];
	   Srow <= 3'b101;
        end
        5: begin
	   SR <= 6'b000001;
	   {addr_load,extd_addr,clear,cont} <= SC;
	   Srow <= 3'b000;
        end
        default: Srow <= 3'b000;
      endcase
    end
  end



endmodule

