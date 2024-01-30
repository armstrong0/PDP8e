/* verilator lint_off LITENDIAN */

`include "../serial/rx.v"
`include "../serial/tx.v"


module serial_top(
    input clk,
    input reset,
    input [0:11] instruction,
    input [4:0] state,
    input [0:11] ac,
    input rx,
    input clear,
    input UF,
    output reg [0:11] serial_bus,  //from the point of view of the CPU
    output tx,
    /* verilator lint_off SYMRSVDWORD */
    output reg interrupt,
    /* verilator lint_on SYMRSVDWORD */
    output reg skip);

    wire rx_flag;
    wire tx_flag;
    wire flag;
    wire [0:7] rx_serial_bus;
    reg load_tx;
    reg clear_tx;
    reg clear_rx;
    reg set_tx;
    reg sint_ena;

    always @(posedge clk)
    begin
        if (rx_flag == 1) serial_bus <= {4'b0000,rx_serial_bus};
		else serial_bus <= 12'o0;
    end


`include "../parameters.v"
    tx TX(.clk100 (clk),
        .reset (reset),
        .clear (clear),
        .char (ac),
        .load (load_tx),
        .clear_flag (clear_tx),
        .set_flag (set_tx),
        .tx (tx),
        .flag (tx_flag)
    );


    rx rx1(.reset (reset),
        .clear (clear),
        .clk (clk),
        .rx (rx),
        .flag (rx_flag),
        .clear_flag (clear_rx),
        .char0 (rx_serial_bus));

    assign flag = rx_flag | tx_flag;
    always @(posedge clk) begin

        if ((flag == 1) && (sint_ena ==1)) interrupt <= 1;
        else interrupt <= 0;
        if (state == F1)
        begin
            skip <= 0;
            case (instruction)
                12'o6031: if ((rx_flag == 1)&&(UF == 1'b0)) skip <= 1;
                12'o6041: if ((flag == 1) && (UF == 1'b0))  skip <= 1;
                12'o6045: if ((flag & sint_ena) && (UF == 1'b0)) skip <= 1;
                default:;
            endcase
        end
    end



    always @(posedge clk)
    begin
        if ((reset ==1) | (clear))
        begin
            clear_tx <= 0;
            set_tx <= 0;
            sint_ena <= 1;
            clear_rx <= 0;
        end

        if (state == F0)
        begin
            load_tx <= 0;
            clear_tx <= 0;
            clear_rx <= 0;
            set_tx <= 0;
        end
        if (state == F1)
            case (instruction)
                12'o6030: if(UF == 1'b0) clear_rx <= 1;//KCF Clear Keyboard flag
                12'o6031:;// KSF Skip if Keyboard Flag = 1
                12'o6032:if (UF == 1'b0) clear_rx <= 1;//KCC Clear AC,keyboard flag
                12'o6034:;//KRS Read Keyboard buffer 'ors' the buffer int the AC
                12'o6035: if (UF == 1'b0) sint_ena <= ac[11];
                //KIE AC11 to Keyboard interupt enable
                12'o6036: if (UF == 1'b0) clear_rx <= 1;
                // KRB Clear AC read buffer, clear flags
                12'o6040: if (UF == 1'b0) set_tx <= 1;  // SPF Set printer flag
                12'o6041:;//TSF Skip if printer flag = 1 or keyboard flag = 1
                12'o6042: if (UF == 1'b0) clear_tx <= 1;//TCF clear printer flag
                12'o6044: if (UF == 1'b0) load_tx <= 1;//TCP Load buffer, print
                12'o6045:;// SPI Skip if printer interrupt = 1
                12'o6046: // TLS Load buffer, print and clear the printer flag
                if (UF == 1'b0)
                begin
                    load_tx <= 1;
                    clear_tx <= 1;
                end
                12'o6007: //CAF
                if (UF == 1'b0)
                begin
                    clear_tx <= 1;
                    clear_rx <= 1;
                    sint_ena <= 1;
                end
                default:;
            endcase
    end
endmodule

