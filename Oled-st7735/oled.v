
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
    wire is_busy;
    reg [15:0] color_pixel;
    reg write_en;
    wire blink;

    // assign blink = LED_STAT;


    initial begin
        color_pixel = 16'hff00;
        write_en = 1'b0;
    end

    ST7735 _st7735 (
        .SYSTEM_CLK(SYSTEM_CLK),
        .color_pixel(color_pixel),
        .WRITE_EN(write_en),
        .IS_BUSY(is_busy),
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
        .out(blink),
        .CLK(SYSTEM_CLK)
    );

    always @(posedge LCD_CLK) begin
        write_en <= (is_lcd_ready && (is_busy == 0));
    end


    always @(posedge LCD_CLK) begin
        if (is_busy  == 1'b0) begin
            color_pixel <= color_pixel + 1;
            if (color_pixel >= 16'hffff) begin
                color_pixel <= 0;
                LED_STAT <= ~LED_STAT;
            end
        end

    end


endmodule
