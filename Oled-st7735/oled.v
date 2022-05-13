
`include "../st7735/st7735.v"
`include "../delay-counter/delay-counter.v"
`include "../clock-divider/clock-divider.v"

module Oled (
    input  SYSTEM_CLK,
    output LED_STAT,
    output CS,
    output MOSI,
    output DC,
    output LCD_CLK,
    output RESET
);

    wire is_lcd_ready;
    reg [15:0] color = 16'h16F9;

    ST7735 _st7735 (
        .SYSTEM_CLK(SYSTEM_CLK),
        .color(color),
        .LCD_READY(is_lcd_ready),
        .CS(CS),
        .MOSI(MOSI),
        .DC(DC),
        .LCD_CLK(LCD_CLK),
        .RESET(RESET)
    );

    ClockDivider #(
        .CLOCK_SPEED_MHZ(12),
        .US_DELAY(1000000)
    ) _blinker (
        .out(LED_STAT),
        .CLK(SYSTEM_CLK)
    );

    always @(posedge SYSTEM_CLK) begin
        if (is_lcd_ready) begin
        end
    end


endmodule
