`include "../st7735/st7735.v"
`include "../delay-counter/delay-counter.v"
`timescale 1 ns / 10 ps

module oled_tb ();

    localparam DURATION = 10000;

   
    reg clk = 0;
    wire cs;
    wire mosi;
    wire dc;
    wire lcd_clk;
    wire reset;

    
    always begin
        #41.665
        clk = ~clk;
    end


    ST7735 _st7735_tb(
        .SYSTEM_CLK(clk),
        .CS(cs),
        .MOSI(mosi),
        .DC(dc),
        .LCD_CLK(lcd_clk),
        .RESET(reset)
    );


    initial begin
        $dumpfile("oled_tb.vcd");
        $dumpvars(2, oled_tb);

        #(DURATION)
        $display("Finish");
        $finish;
    end


endmodule
