

module scan_matrix (
    input clk,
    input reset,
    input [0:11] A,
    input [0:2] EMA,
    input [0:11] ds,
    output [0:2] LR,
    output [0:10] LC,
    output [0:5] SR,
    output [0:11] sr,
	output [2:0] dsel,
    output reg single_step,
    halt, sw,
    output reg addr_load,
    extd_addr,
    clear,
    cont,
    exam,
    dep,
    input [0:4] SC
);

  reg [14:0] counter;
  reg [ 1:0] Lrow;
  reg [ 2:0] Srow;
  reg [0:5] dsel1;

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
          LC   <= {EMA[2:0], A[0:6], dsel1[0:1]};
        end
        1: begin
          LC   <= {A[7:11], ds[0:4], dsel1[2:3]};
          Lrow <= 2'd2;
        end
        2: begin
          LC   <= {ds[5:11], single_step, halt, dsel1[4:5]};
          Lrow <= 2'd0;
        end
        default: Lrow <= 2'b00;
      endcase
      case (Srow)
        0: begin
        end
        1: begin
        end
        2: begin
        end
        3: begin
        end
        4: begin
        end
        default: Srow <= 3'b000;
      endcase
    end
  end



endmodule

