

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



    localparam STATE_IDLE = 3'b000;
    localparam STATE_INIT = 3'b001;
    localparam STATE_TRICKLE_RESET = 3'b010;
    localparam STATE_WRITE_REG = 3'b011;
    localparam STATE_WRITE_REG_DONE = 3'b100;
    // localparam STATE_SHIFT_DATA = 3'b101;
    // localparam STATE_SHIFT_DATA_DONE = 3'b110;
    localparam ENABLE = 1'b1;
    localparam DISABLE = 1'b0;

    wire lcd_delay_out = 1'b0;
    reg [7:0] data;
    reg [2:0] data_count = 0;

    reg reset_delay = DISABLE;
    reg delay_status = DISABLE;
    reg delay_count = DISABLE;
    reg [2:0] oled_state = STATE_IDLE;
    reg init_done = DISABLE;

    initial begin
        RESET = DISABLE;
    end


    task Write_reg(inout [7:0] spi_data, inout [2:0] count, output mosi);


        localparam MAX = 7;

        begin

            count = count + 1;
            spi_data = {spi_data[6:0], spi_data[7]};
            mosi = spi_data[7];

        end

    endtask

    ClockDivider #(
        .CLOCK_SPEED_MHZ(CLOCK_SPEED_MHZ),
        .US_DELAY(2)
    ) _lcd_delay (
        .CLK(SYSTEM_CLK),
        .out(lcd_delay_out)
    );

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
                RESET <= ENABLE;
                if (delay_count >= 1) begin
                    RESET <= DISABLE;
                    delay_status <= DISABLE;
                    data <= 8'h11;
                    oled_state <= STATE_WRITE_REG;
                end
            end

            STATE_WRITE_REG: begin
                if (data_count >= 7) begin
                    oled_state <= STATE_WRITE_REG_DONE;
                end
                Write_reg(data, data_count, MOSI);

            end
            STATE_WRITE_REG_DONE: begin

                
            end


        endcase
    end

    always @(posedge lcd_delay_out, posedge reset_delay) begin
        if (reset_delay == ENABLE) begin
            delay_count <= 0;
        end else begin
            if (delay_status == ENABLE) begin
                delay_count <= delay_count + 1;
            end else begin
                delay_count <= 0;
            end
        end

    end



endmodule
