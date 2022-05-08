

module ST7735 #(
    parameter CLOCK_SPEED_MHZ = 12,
    parameter DELAY_US = 100000,
    parameter WIDTH = 160,
    parameter HEIGHT = 80
) (
    input  wire SYSTEM_CLK,
    output reg  CS,
    output reg  MOSI,
    output reg  DC,
    output reg  LCD_CLK,
    output reg  RESET
);


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
    localparam STATE_INIT_FRAME = 8'b00001010;
    localparam STATE_WAITING_PIXEL = 8'b00001011;

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

    localparam HIGH = 1'b1;
    localparam LOW = 1'b0;

    wire lcd_delay_out;
    reg [7:0] data = 8'h00;
    reg [4:0] data_count = 7;

    reg [$clog2(17):0] next_data_count;
    reg [$clog2(17):0] next_data_count_max = 0;

    reg delay_status = LOW;
    reg [7:0] oled_state = STATE_IDLE;
    reg init_done = LOW;
    reg init_write_config = LOW;

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
    reg [7:0] config_set_address[0:6];
    reg [7:0] config_cnt = CONFIG_B1;

    reg [15:0] color = 16'h0f0f;
    reg [$clog2(WIDTH):0] color_x = 0;
    reg [$clog2(HEIGHT):0] color_y = 0;
    reg [19:0] current_pixel;

    integer i;

    initial begin
        CS = HIGH;
        MOSI = HIGH;
        DC = HIGH;
        LCD_CLK = HIGH;
        RESET = HIGH;
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

    DelayCounter #(
        .CLOCK_SPEED_MHZ(CLOCK_SPEED_MHZ),
        // .US_DELAY(120000)
        .US_DELAY(DELAY_US)
    ) _lcd_delay (
        .CLK  (SYSTEM_CLK),
        .out  (lcd_delay_out),
        .start(delay_status)
    );


    always @(posedge SYSTEM_CLK) begin

        LCD_CLK = ~LCD_CLK;


    end


    always @(posedge LCD_CLK) begin

        CS <= HIGH;
        data_count <= data_count - 1;

        case (oled_state)
            STATE_IDLE: begin
                if (init_done == LOW) begin
                    oled_state <= STATE_INIT;
                    delay_status <= HIGH;
                end

            end
            STATE_INIT: begin
                if (lcd_delay_out) begin
                    RESET <= HIGH;
                    // CS <= HIGH;
                    delay_status <= HIGH;
                    data <= 0;
                    next_data_count <= 0;
                    next_data_count_max <= 1;
                    data_count <= 7;
                    oled_state <= STATE_TRICKLE_RESET;
                end else begin
                    RESET <= LOW;
                    CS <= LOW;
                    data_count <= 7;
                end
                
            end

            STATE_TRICKLE_RESET: begin

                if (lcd_delay_out) begin
                    // RESET <= HIGH;
                    // CS <= HIGH;
                    delay_status <= LOW;
                    data <= 8'h11;
                    next_data_count <= 0;
                    next_data_count_max <= 1;
                    data_count <= 7;
                    oled_state <= STATE_PREPARE_WRITE_REG;
                end else begin
                    // RESET <= LOW;
                    CS <= LOW;
                    data_count <= 7;
                end
            end

            STATE_PREPARE_WRITE_REG: begin

                DC   <= LOW;
                CS   <= LOW;
                MOSI <= data[data_count];
                if (data_count == 0) begin
                    data_count <= 7;
                    data <= 0;

                    if (init_done) begin
                        oled_state <= STATE_INIT_FRAME;
                    end else if (init_write_config) begin
                        oled_state <= STATE_WRITE_CONFIGURATIONS;
                    end else begin
                        oled_state <= STATE_DELAY_120MS;
                    end


                end
            end

            STATE_PREPARE_WRITE_DATA: begin
                DC   <= HIGH;
                CS   <= LOW;
                // data_count <= 7;
                MOSI <= data[data_count];
                if (data_count == 0) begin
                    data_count <= 7;
                    data <= 0;

                    if (init_done) begin
                        oled_state <= STATE_INIT_FRAME;
                    end else if (init_write_config) begin
                        oled_state <= STATE_WRITE_CONFIGURATIONS;
                    end else begin
                        oled_state <= STATE_DELAY_120MS;
                    end


                end
            end

            STATE_DELAY_120MS: begin

                delay_status <= HIGH;
                if (lcd_delay_out) begin

                    delay_status <= LOW;
                    oled_state   <= STATE_WRITE_CONFIGURATIONS;
                end

            end

            STATE_WRITE_CONFIGURATIONS: begin
                init_write_config <= HIGH;
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
                    data_count <= 7;


                    if (init_done) begin
                        oled_state <= STATE_INIT_FRAME;
                    end else if (config_cnt >= CONFIG_DONE) begin
                        oled_state <= STATE_WRITE_CONFIGURATIONS_DONE;
                    end else begin
                        config_cnt <= config_cnt + 1;
                        oled_state <= STATE_WRITE_CONFIGURATIONS;
                    end

                end else if (next_data_count == 0) begin
                    // $display("data:%02h,next_data_count:%02h,max:%02h", data, next_data_count,
                    //  next_data_count_max);
                    data_count <= 7;
                    next_data_count <= next_data_count + 1;
                    oled_state <= STATE_PREPARE_WRITE_REG;
                end else begin
                    // $display("data:%02h,next_data_count:%02h,max:%02h", data, next_data_count,
                    //  next_data_count_max);
                    data_count <= 7;
                    next_data_count <= next_data_count + 1;
                    oled_state <= STATE_PREPARE_WRITE_DATA;
                end
            end

            STATE_WRITE_CONFIGURATIONS_DONE: begin
                init_write_config <= LOW;
                init_done <= HIGH;
                DC <= HIGH;
                CS <= HIGH;
                data <= 0;
                data_count <= 15;
                next_data_count <= 0;
                next_data_count_max <= 0;

                oled_state <= STATE_INIT_FRAME;
            end

            STATE_INIT_FRAME: begin
                DC   <= HIGH;
                CS   <= LOW;
                MOSI <= color[data_count];
                if (data_count == 0) begin
                    data_count <= 15;
                    current_pixel <= current_pixel + 1;
                    if (current_pixel == WIDTH * HEIGHT) begin
                        current_pixel <= 0;
                        oled_state <= STATE_WAITING_PIXEL;
                    end
                    // color_x <= color_x + 1;
                    // if (color_x >= WIDTH) begin
                    //     color_x <= 0;
                    //     color_y <= color_y + 1;
                    // end
                    // if (color_y >= HEIGHT) begin
                    //     color_x <= 0;
                    //     color_y <= 0;
                    //     oled_state <= STATE_WAITING_PIXEL;
                    // end
                end

            end

            STATE_WAITING_PIXEL: begin

            end

        endcase
    end


endmodule
