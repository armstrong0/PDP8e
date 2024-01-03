/* verilator lint_off LITENDIAN */


module serial_top(
    input clk,
    input reset,
    input [0:11] instruction,
    input [4:0] state,
    input clear,
    input UF,
    /* verilator lint_off SYMRSVDWORD */
    output reg interrupt,
    /* verilator lint_on SYMRSVDWORD */
    output reg skip);

    reg flag;
    reg clk_int_ena;
    // need a register to do counting 


 //   6131 Enable Clock interupt (CLEI) does not affect flag 
 //   6132 Disable Clock Intrerrupt (CLED)
 //   6133 skip on a clock flag and clear the flag (CLSK)


    always @(posedge clk) begin

        if ((flag == 1) && (clk_int_ena ==1)) interrupt <= 1;
        else interrupt <= 0;
        if ((state == F1) && (UF ==0))
        begin
            skip <= 0;
            case (instruction)
                12'o6131: if ((flag == 1)&&(UF == 1'b0)) skip <= 1;//CLSK
                default:;
            endcase
        end
    end



    always @(posedge clk)
    begin
        if ((reset ==1) | (clear))
        begin
            clk_int_ena <= 1;
            
        end

        if (state == F0)
            clear_tx <= 0;
            clear_rx <= 0;
            set_tx <= 0;
        end
        if ((state == F1) && (UF == 0))
            case (instruction)
                12'o6031: clk_int_ena <= 1; // 6131 CLEI
                12'o6032: clk_int_ena <= 0; // 6132 CLED
                12'o6007: //CAF
                if (UF == 1'b0)
                begin
                    clk_int_ena <= 1;
                end
                default:;
            endcase
    end
endmodule

