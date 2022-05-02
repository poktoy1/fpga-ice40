

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


    localparam MAX = 7;
    localparam STATE_IDLE = 8'b0000000;
    localparam STATE_INIT = 8'b00000001;
    localparam STATE_TRICKLE_RESET = 8'b00000010;
    localparam STATE_PREPARE_WRITE_REG = 8'b00000011;
    localparam STATE_WRITE_REG = 8'b00000100;
    localparam STATE_DELAY_120MS = 8'b00000101;
    localparam STATE_WRITE_CONFIGURATIONS = 8'b00000110;

    localparam ENABLE = 1'b1;
    localparam DISABLE = 1'b0;

    wire lcd_delay_outs;
    reg [7:0] data;
    reg [3:0] data_count = 0;

    reg delay_status = DISABLE;
    reg [7:0] oled_state = STATE_IDLE;
    reg init_done = DISABLE;

    initial begin
        RESET = DISABLE;
    end


    task Write_reg(inout [7:0] spi_data, inout [3:0] count);

        begin
            spi_data = {spi_data[6:0], spi_data[7]};
            count = count + 1;
        end

    endtask

    DelayCounter #(
        .CLOCK_SPEED_MHZ(CLOCK_SPEED_MHZ),
        .US_DELAY(2)
    ) _lcd_delay (
        .CLK  (SYSTEM_CLK),
        .out  (lcd_delay_out),
        .start(delay_status)
    );

    always @(*) begin
        MOSI <= data[7];
    end

    always @(posedge SYSTEM_CLK) begin


        case (oled_state)
            STATE_IDLE: begin
                if (init_done == DISABLE) begin
                    oled_state <= STATE_INIT;
                end

            end
            STATE_INIT: begin
                delay_status <= ENABLE;
                oled_state   <= STATE_TRICKLE_RESET;
            end

            STATE_TRICKLE_RESET: begin

                if (lcd_delay_out) begin
                    RESET <= DISABLE;
                    delay_status <= DISABLE;
                    oled_state <= STATE_PREPARE_WRITE_REG;
                end else begin
                    RESET <= ENABLE;
                end
            end

            STATE_PREPARE_WRITE_REG: begin
                data <= 8'h81;
                DC <= DISABLE;
                CS <= DISABLE;
                oled_state <= STATE_WRITE_REG;
            end

            STATE_WRITE_REG: begin
                if (data_count >= MAX) begin
                    DC <= ENABLE;
                    CS <= ENABLE;
                    if (init_done == DISABLE) begin
                        oled_state <= STATE_DELAY_120MS;
                    end

                end
                Write_reg(data, data_count);
            end
            STATE_DELAY_120MS: begin

                delay_status <= ENABLE;
                if (lcd_delay_out) begin

                    delay_status <= DISABLE;
                    oled_state   <= STATE_WRITE_CONFIGURATIONS;
                end

            end

            STATE_WRITE_CONFIGURATIONS: begin

            end


        endcase
    end


endmodule
