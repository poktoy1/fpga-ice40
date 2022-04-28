

module ST7735 #(
    parameter CLOCK_SPEED_MHZ = 12
) (
    input  wire SYSTEM_CLK,
    output reg  CS,
    output reg  MOSI,
    output reg  DC,
    output reg  LCD_CLK,
    output reg  RESET
);

    localparam STATE_DELAY_IDLE = 2'b00;
    localparam STATE_DELAY_START = 2'b01;
    localparam STATE_DELAY_STOP = 2'b10;

    localparam STATE_IDLE = 3'b000;
    localparam STATE_INIT = 3'b001;
    localparam STATE_WRITE_REG = 3'b010;


    wire lcd_delay_out = 1'b0;

    reg enable_delay = 1'b0;
    reg [1:0] delay_state = STATE_DELAY_IDLE;
    reg [2:0] oled_state = STATE_IDLE;

    ClockDivider #(
        .CLOCK_SPEED_MHZ(CLOCK_SPEED_MHZ),
        .NS_DELAY(2)
    ) _lcd_delay (
        .CLK(SYSTEM_CLK),
        .out(lcd_delay_out)
    );

    always @(posedge SYSTEM_CLK) begin
        case (oled_state)
            STATE_IDLE: begin
                oled_state   <= STATE_INIT;
                enable_delay <= 1'b1;
            end

        endcase
    end

    always @(posedge lcd_delay_out) begin
        if (enable_delay) begin
            delay_state <= STATE_DELAY_START;
            enable_delay <= 1'b0;
        end else begin
            case (delay_state)
                STATE_DELAY_START: begin
                    delay_state <= STATE_DELAY_STOP;
                end
                STATE_DELAY_STOP: begin
                    delay_state <= STATE_DELAY_IDLE;
                end
                default: begin
                    delay_state <= STATE_DELAY_IDLE;
                    
                end
            endcase
        end

    end



endmodule
