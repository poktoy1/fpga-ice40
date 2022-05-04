
`include "../st7735/st7735.v"
`include "../delay-counter/delay-counter.v"

module Oled (
    input  SYSTEM_CLK,
    output CS,
    output MOSI,
    output DC,
    output LCD_CLK,
    output RESET
);


    ST7735 _st7735 (
        .SYSTEM_CLK(SYSTEM_CLK),
        .CS(CS),
        .MOSI(MOSI),
        .DC(DC),
        .LCD_CLK(LCD_CLK),
        .RESET(RESET)
    );

endmodule
