`include "../st7735/st7735.v"
`include "../clock-divider/clock-divider.v"
`timescale 100 ns / 10 ps

module oled_tb ();

    localparam DURATION = 10000;

   
    reg clk = 0;
    wire cs;
    wire mosi;
    wire dc;
    wire lcd_clk;
    wire reset;

    wire lcd_delay_out = 0;

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


    ClockDivider #(
        .CLOCK_SPEED_MHZ(12),
        .NS_DELAY(10)
    ) _lcd_delay (
        .CLK(clk),
        .out(lcd_delay_out)
    );


    initial begin
        $dumpfile("oled_tb.vcd");
        $dumpvars(0, oled_tb);

        #(DURATION)
        $display("Finish");
        $finish;
    end


endmodule
