`include "../st7735/st7735.v"
`include "../delay-counter/delay-counter.v"
`timescale 1 ns / 10 ps

module oled_tb ();

    localparam DURATION = 70000;

   
    reg clk = 1;
    wire cs = 1;
    wire mosi = 1;
    wire dc = 1;
    wire lcd_clk = 1;
    wire reset = 1;

    
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
