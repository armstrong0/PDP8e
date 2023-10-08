module serial_tx(
    input reset,
	input clk100,
	output tx,
	output [7:0] tx_char_out);
    localparam baud_rate = 9600;
    localparam term_count = $rtoi(clock_frequency / baud_rate);
    localparam term_nu_bits = $clog2(term_count);

assign tx_char_out = tx_char;
    reg [term_nu_bits-1:0] counter;
    reg [3:0] stat;
    reg [7:0] tx_char;
    reg [7:0] tx_char1;
	reg tx;
    reg [6:0] column;
always @(posedge clk100)
    begin
        if (reset == 1) begin
            counter <= term_count;
            column <= 0;
            tx_char1 <= 'h20;
        end
        else
        if (counter == 0)
        begin
            case (stat)
                0: tx <= 0;
                1: tx <= tx_char[0];
                2: tx <= tx_char[1];
                3: tx <= tx_char[2];
                4: tx <= tx_char[3];
                5: tx <= tx_char[4];
                6: tx <= tx_char[5];
                7: tx <= tx_char[6];
                8: tx <= 1 ; //tx_char[7];
                9: begin
                    column <= column + 1;
                    if (column == 'd80)
                    begin
                        tx_char <= 'h0a;
                    end
                    else if (column == 'd81)
                    begin
                        tx_char <= 'h0d;
                    end
                    else
                    begin
                        tx_char <= tx_char1;
                        tx_char1 <= tx_char1 +1;
                    end
                end
                10:begin
                    if (tx_char1 == 'h7f) tx_char1 = 'h20;
                    if (column == 'd82)  column <= 0;
                end
                default: stat <= 0;
            endcase
            stat <= stat +1;
            counter <= term_count;
        end
        else counter <= counter - 1;
    end
endmodule
