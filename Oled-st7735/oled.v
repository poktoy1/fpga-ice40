
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
    reg [4:0] red;
    reg [5:0] green;
    reg [4:0] blue;
    reg write_en;
    wire blink;
    reg [$clog2(3):0] color_state;
    reg [15:0] color_x = 0;
    reg [15:0] color_y = 0;
    reg [15:0] color_x_end = WIDTH;
    reg [15:0] color_y_end = HEIGHT;

    localparam STATE_BLUE = 0;
    localparam STATE_GREEN = 1;
    localparam STATE_RED = 2;
    localparam STATE_SQUARE = 3;
    localparam HEIGHT = 120;
    localparam WIDTH = 160;

    assign blink = LED_STAT;
    // assign is_lcd_ready = LED_STAT;

    initial begin
        red = 0;
        green = 0;
        blue = 0;
        write_en = 1'b0;
        color_state = 1'b0;
    end

    always @(posedge SYSTEM_CLK) begin
        color_pixel <= {red, green, blue};
    end

    ST7735 #(
        .WIDTH (WIDTH),
        .HEIGHT(HEIGHT)
    ) _st7735 (
        .SYSTEM_CLK(SYSTEM_CLK),
        .color_pixel(color_pixel),
        .COLOR_X(color_x),
        .COLOR_Y(color_y),
        .COLOR_X_END(color_x_end),
        .COLOR_Y_END(color_y_end),
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
        .US_DELAY(500000)
    ) _blinker (
        .out(blink),
        .CLK(SYSTEM_CLK)
    );

    always @(posedge LCD_CLK) begin
        // write_en <= (is_lcd_ready && (is_busy == 0));
        if (is_lcd_ready) begin
            write_en <= 1;
        end
    end


    always @(negedge is_busy) begin

        case (color_state)

            STATE_BLUE: begin
                blue <= blue + 1;
                if (blue == 5'b11111) begin
                    blue <= 0;
                    color_state <= STATE_GREEN;
                end
            end

            STATE_GREEN: begin
                green <= green + 1;
                if (green == 6'b111111) begin
                    green <= 0;
                    color_state <= STATE_RED;
                end
            end

            STATE_RED: begin
                red <= red + 1;
                if (red == 5'b11111) begin
                    red <= 0;
                    color_x <= 100;
                    color_y <= 50;
                    color_x_end <= 150;
                    color_y_end <= 100;
                    color_state <= STATE_SQUARE;

                end
            end

            STATE_SQUARE: begin
                if (red < 5'b11111) begin
                    red <= red + 1;
                end
                if (green < 6'b111111) begin
                    green <= green + 1;
                end
                if (blue < 5'b11111) begin
                    blue <= blue + 1;
                end

                if (color_pixel == 16'hffff) begin
                    red <= 0;
                    green <= 0;
                    blue <= 0;
                    color_state <= STATE_BLUE;
                end


            end

        endcase


    end


endmodule
