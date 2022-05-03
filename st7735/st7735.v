

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
    localparam STATE_PREPARE_WRITE_DATA = 8'b00000100;
    localparam STATE_WRITE_BUS = 8'b00000101;
    localparam STATE_DELAY_120MS = 8'b00000110;
    localparam STATE_WRITE_CONFIGURATIONS = 8'b00000111;
    localparam STATE_BITBANG_BUS = 8'b00001000;
    localparam STATE_WRITE_CONFIGURATIONS_DONE = 8'b00001001;

    localparam CONFIG_B1 = 8'b00000000;
    localparam CONFIG_B2 = 8'b00000001;
    localparam CONFIG_B3 = 8'b00000010;
    localparam CONFIG_B4 = 8'b00000011;
    localparam CONFIG_C0 = 8'b00000100;
    localparam CONFIG_DONE = 8'b00000101;

    localparam ENABLE = 1'b1;
    localparam DISABLE = 1'b0;

    wire lcd_delay_outs;
    reg [7:0] data = 8'h00;
    reg [3:0] data_count = 0;

    reg [3:0] next_data_count = 0;
    reg [3:0] next_data_count_max = 0;

    reg delay_status = DISABLE;
    reg [7:0] oled_state = STATE_IDLE;
    reg init_done = DISABLE;
    reg init_write_config = DISABLE;

    reg [7:0] config_b1[3:0];
    reg [7:0] config_b2[3:0];
    reg [7:0] config_b3[6:0];
    reg [7:0] config_b4[1:0];
    reg [7:0] config_c0[3:0];
    reg [7:0] config_cnt = CONFIG_B1;

    integer i;

    initial begin
        RESET = DISABLE;
        $readmemh("b1_config.dat", config_b1);
        $readmemh("b2_config.dat", config_b2);
        $readmemh("b3_config.dat", config_b3);
        $readmemh("b4_config.dat", config_b4);
        $readmemh("c0_config.dat", config_c0);
    end


    task write_bus(inout [7:0] spi_data, inout [3:0] count);

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
        LCD_CLK <= data_count[0];
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
                    data <= 8'h11;
                    oled_state <= STATE_PREPARE_WRITE_REG;
                end else begin
                    RESET <= ENABLE;
                end
            end

            STATE_PREPARE_WRITE_REG: begin

                DC <= DISABLE;
                CS <= DISABLE;
                oled_state <= STATE_WRITE_BUS;
            end

            STATE_PREPARE_WRITE_DATA: begin
                DC <= ENABLE;
                CS <= DISABLE;
                oled_state <= STATE_WRITE_BUS;
            end

            STATE_WRITE_BUS: begin
                if (data_count >= MAX) begin
                    DC <= ENABLE;
                    CS <= ENABLE;
                    data_count <= 0;
                    data <= 0;
                    if (init_write_config) begin
                        oled_state <= STATE_WRITE_CONFIGURATIONS;
                    end else begin
                        oled_state <= STATE_DELAY_120MS;
                    end

                end
                write_bus(data, data_count);
            end
            STATE_DELAY_120MS: begin

                delay_status <= ENABLE;
                if (lcd_delay_out) begin

                    delay_status <= DISABLE;
                    oled_state   <= STATE_WRITE_CONFIGURATIONS;
                end

            end

            STATE_WRITE_CONFIGURATIONS: begin
                init_write_config <= ENABLE;
                case (config_cnt)
                    CONFIG_B1: begin
                        next_data_count_max <= 3;
                        data <= config_b1[next_data_count];

                    end
                    CONFIG_B2: begin
                        next_data_count_max <= 3;
                        data <= config_b2[next_data_count];

                    end
                    CONFIG_B3: begin
                        next_data_count_max <= 6;
                        data <= config_b3[next_data_count];

                    end
                    CONFIG_B4: begin
                        next_data_count_max <= 1;
                        data <= config_b4[next_data_count];
                    end
                    CONFIG_C0: begin
                        next_data_count_max <= 3;
                        data <= config_c0[next_data_count];
                    end


                endcase
                oled_state <= STATE_BITBANG_BUS;

            end

            STATE_BITBANG_BUS: begin

                if (next_data_count >= next_data_count_max) begin
                    next_data_count <= 0;
                    data <= 0;
                    data_count <= 0;
                    if (config_cnt >= CONFIG_DONE) begin
                        oled_state <= STATE_WRITE_CONFIGURATIONS_DONE;
                    end else begin
                        config_cnt <= config_cnt + 1;
                        oled_state <= STATE_PREPARE_WRITE_REG;
                    end
                end else if (next_data_count == 0) begin

                    next_data_count <= next_data_count + 1;
                    oled_state <= STATE_PREPARE_WRITE_REG;
                end else begin

                    next_data_count <= next_data_count + 1;
                    oled_state <= STATE_PREPARE_WRITE_DATA;
                end

                $display("data:%02h,next_data_count:%02h,max:%02h", data, next_data_count,
                         next_data_count_max);


            end

            STATE_WRITE_CONFIGURATIONS_DONE: begin

            end


        endcase
    end


endmodule
