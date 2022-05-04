

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
    localparam CONFIG_C1 = 8'b00000101;
    localparam CONFIG_C2 = 8'b00000110;
    localparam CONFIG_C3 = 8'b00000111;
    localparam CONFIG_C4 = 8'b00001000;
    localparam CONFIG_C5 = 8'b00001001;
    localparam CONFIG_E0 = 8'b00001010;
    localparam CONFIG_E1 = 8'b00001011;
    localparam CONFIG_FC = 8'b00001100;
    localparam CONFIG_3A = 8'b00001101;
    localparam CONFIG_36 = 8'b00001110;
    localparam CONFIG_21 = 8'b00001111;
    localparam CONFIG_29 = 8'b00010000;
    localparam CONFIG_2A = 8'b00010001;
    localparam CONFIG_2B = 8'b00010010;
    localparam CONFIG_2C = 8'b00010011;
    localparam CONFIG_DONE = 8'b00010100;

    localparam ENABLE = 1'b1;
    localparam DISABLE = 1'b0;

    wire lcd_delay_out;
    reg [7:0] data = 8'h00;
    reg [3:0] data_count = 0;

    reg [$clog2(17):0] next_data_count;
    reg [$clog2(17):0] next_data_count_max = 0;

    reg delay_status = DISABLE;
    reg [7:0] oled_state = STATE_IDLE;
    reg init_done = DISABLE;
    reg init_write_config = DISABLE;

    reg [7:0] config_b1[0:3];
    reg [7:0] config_b2[0:3];
    reg [7:0] config_b3[0:6];
    reg [7:0] config_b4[0:1];
    reg [7:0] config_c0[0:3];
    reg [7:0] config_c1[0:1];
    reg [7:0] config_c2[0:2];
    reg [7:0] config_c3[0:2];
    reg [7:0] config_c4[0:2];
    reg [7:0] config_c5[0:1];
    reg [7:0] config_e0[0:16];
    reg [7:0] config_e1[0:16];
    reg [7:0] config_fc[0:1];
    reg [7:0] config_3a[0:1];
    reg [7:0] config_36[0:1];
    reg [7:0] config_2a[0:4];
    reg [7:0] config_2b[0:4];
    reg [7:0] config_cnt = CONFIG_B1;

    integer i;

    initial begin
        RESET = DISABLE;
        $readmemh("b1_config.dat", config_b1);
        $readmemh("b2_config.dat", config_b2);
        $readmemh("b3_config.dat", config_b3);
        $readmemh("b4_config.dat", config_b4);
        $readmemh("c0_config.dat", config_c0);
        $readmemh("c1_config.dat", config_c1);
        $readmemh("c2_config.dat", config_c2);
        $readmemh("c3_config.dat", config_c3);
        $readmemh("c4_config.dat", config_c4);
        $readmemh("c5_config.dat", config_c5);
        $readmemh("e0_config.dat", config_e0);
        $readmemh("e1_config.dat", config_e1);
        $readmemh("fc_config.dat", config_fc);
        $readmemh("3a_config.dat", config_3a);
        $readmemh("36_config.dat", config_36);
        $readmemh("2a_config.dat", config_2a);
        $readmemh("2b_config.dat", config_2b);

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
        if (data_count) begin
            LCD_CLK <= ~SYSTEM_CLK;
        end else begin
            LCD_CLK <= ENABLE;
        end
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
                    next_data_count <= 0;
                    next_data_count_max <= 1;
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

                end else begin
                    write_bus(data, data_count);
                end


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
                        next_data_count_max <= 4;
                        data <= config_b1[next_data_count];

                    end
                    CONFIG_B2: begin
                        next_data_count_max <= 4;
                        data <= config_b2[next_data_count];

                    end
                    CONFIG_B3: begin
                        next_data_count_max <= 7;
                        data <= config_b3[next_data_count];

                    end
                    CONFIG_B4: begin
                        next_data_count_max <= 2;
                        data <= config_b4[next_data_count];
                    end
                    CONFIG_C0: begin
                        next_data_count_max <= 4;
                        data <= config_c0[next_data_count];
                    end
                    CONFIG_C1: begin
                        next_data_count_max <= 2;
                        data <= config_c1[next_data_count];
                    end
                    CONFIG_C2: begin
                        next_data_count_max <= 3;
                        data <= config_c2[next_data_count];
                    end
                    CONFIG_C3: begin
                        next_data_count_max <= 3;
                        data <= config_c3[next_data_count];
                    end
                    CONFIG_C4: begin
                        next_data_count_max <= 3;
                        data <= config_c4[next_data_count];
                    end
                    CONFIG_C5: begin
                        next_data_count_max <= 2;
                        data <= config_c5[next_data_count];
                    end
                    CONFIG_E0: begin
                        next_data_count_max <= 17;
                        data <= config_e0[next_data_count];
                    end
                    CONFIG_E1: begin
                        next_data_count_max <= 17;
                        data <= config_e1[next_data_count];
                    end
                    CONFIG_FC: begin
                        next_data_count_max <= 2;
                        data <= config_fc[next_data_count];
                    end
                    CONFIG_3A: begin
                        next_data_count_max <= 2;
                        data <= config_3a[next_data_count];
                    end
                    CONFIG_36: begin
                        next_data_count_max <= 2;
                        data <= config_36[next_data_count];
                    end
                    CONFIG_21: begin
                        next_data_count_max <= 1;
                        data <= 8'h21;
                    end
                    CONFIG_29: begin
                        next_data_count_max <= 1;
                        data <= 8'h29;
                    end
                    CONFIG_2A: begin
                        next_data_count_max <= 5;
                        data <= config_2a[next_data_count];
                    end
                    CONFIG_2B: begin
                        next_data_count_max <= 5;
                        data <= config_2b[next_data_count];
                    end
                    CONFIG_2C: begin
                        next_data_count_max <= 1;
                        data <= 8'h2C;
                    end


                endcase

                if (config_cnt >= CONFIG_DONE) begin
                    oled_state <= STATE_WRITE_CONFIGURATIONS_DONE;
                end else begin
                    oled_state <= STATE_BITBANG_BUS;
                end



            end

            STATE_BITBANG_BUS: begin

                if (next_data_count >= next_data_count_max) begin
                    next_data_count <= 0;
                    next_data_count_max <= 0;
                    data <= 0;
                    data_count <= 0;
                    if (config_cnt >= CONFIG_DONE) begin
                        oled_state <= STATE_WRITE_CONFIGURATIONS_DONE;
                    end else begin
                        config_cnt <= config_cnt + 1;
                        oled_state <= STATE_WRITE_CONFIGURATIONS;
                    end
                end else if (next_data_count == 0) begin
                    $display("data:%02h,next_data_count:%02h,max:%02h", data, next_data_count,
                             next_data_count_max);
                    next_data_count <= next_data_count + 1;
                    oled_state <= STATE_PREPARE_WRITE_REG;
                end else begin
                    $display("data:%02h,next_data_count:%02h,max:%02h", data, next_data_count,
                             next_data_count_max);
                    next_data_count <= next_data_count + 1;
                    oled_state <= STATE_PREPARE_WRITE_DATA;
                end
            end

            STATE_WRITE_CONFIGURATIONS_DONE: begin
                init_write_config <= DISABLE;
                DC <= ENABLE;
                CS <= ENABLE;

            end


        endcase
    end


endmodule
