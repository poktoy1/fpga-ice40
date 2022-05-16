

module ST7735 #(
    parameter CLOCK_SPEED_MHZ = 12,
    parameter DELAY_US = 120000,
    parameter WIDTH = 160,
    parameter HEIGHT = 120
) (
    input wire SYSTEM_CLK,
    input wire [15:0] color_pixel,
    input wire WRITE_EN,
    input [$clog2(WIDTH):0] COLOR_X,
    input [$clog2(HEIGHT):0] COLOR_Y,
    output wire IS_BUSY,
    output wire LCD_READY,
    output reg CS,
    output reg MOSI,
    output reg DC,
    output reg LCD_CLK,
    output reg RESET
);


    localparam STATE_IDLE = 0;
    localparam STATE_INIT = 1;
    localparam STATE_TRICKLE_RESET = 2;
    localparam STATE_11_REG = 3;
    localparam STATE_DELAY_120MS = 4;
    localparam STATE_WRITE_CONFIGURATIONS = 5;
    localparam STATE_WRITE_CONFIGURATIONS_DONE = 6;
    localparam STATE_INIT_FRAME = 7;
    localparam STATE_WAIT_FOR_DATA = 8;

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
    localparam MAX_BYTE = 7;
    localparam [7:0] reg_11 = 8'h11;

    wire lcd_delay_out;
    reg [4:0] data_count;

    reg [$clog2(17):0] next_data_count;

    reg delay_status = LOW;
    reg [7:0] oled_state = STATE_IDLE;
    reg init_done = LOW;

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
    reg [7:0] config_21 = 8'h21;
    reg [7:0] config_29 = 8'h29;
    reg [7:0] config_2c = 8'h2c;
    reg [7:0] config_set_address[0:6];
    reg [7:0] config_cnt = CONFIG_B1;

    reg [$clog2(WIDTH):0] color_x = 0;
    reg [$clog2(HEIGHT):0] color_y = 0;
    reg init_frame_done = 0;
    reg is_busy = HIGH;

    assign LCD_READY = init_frame_done;
    assign IS_BUSY   = is_busy;
    
    
    initial begin
        CS = HIGH;
        MOSI = HIGH;
        DC = HIGH;
        LCD_CLK = HIGH;
        RESET = HIGH;
        data_count = MAX_BYTE;
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
        .US_DELAY(DELAY_US / 2)
    ) _lcd_delay (
        .CLK  (LCD_CLK),
        .out  (lcd_delay_out),
        .start(delay_status)
    );


    always @(posedge SYSTEM_CLK) begin

        LCD_CLK <= ~LCD_CLK;
        
    end


    always @(negedge LCD_CLK) begin

        CS <= HIGH;
        DC <= LOW;
        RESET <= HIGH;
        data_count <= data_count - 1;

        case (oled_state)
            STATE_IDLE: begin
                if (init_done == LOW) begin
                    oled_state   <= STATE_INIT;
                    delay_status <= HIGH;
                end

            end
            STATE_INIT: begin
                if (lcd_delay_out) begin

                    delay_status <= HIGH;
                    next_data_count <= 0;
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_TRICKLE_RESET;
                end else begin
                    RESET <= LOW;
                end

            end

            STATE_TRICKLE_RESET: begin

                if (lcd_delay_out) begin
                    delay_status <= LOW;
                    next_data_count <= 0;
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_11_REG;
                end
            end

            STATE_11_REG: begin
                CS   <= LOW;
                MOSI <= reg_11[data_count];
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_DELAY_120MS;

                end
            end

            STATE_DELAY_120MS: begin

                delay_status <= HIGH;
                if (lcd_delay_out) begin

                    delay_status <= LOW;
                    oled_state <= STATE_WRITE_CONFIGURATIONS;
                    data_count <= MAX_BYTE;
                    config_cnt <= CONFIG_B1;
                    next_data_count <= 0;
                end

            end

            STATE_WRITE_CONFIGURATIONS: begin

                case (config_cnt)
                    CONFIG_B1: begin
                        // next_data_count_max <= 4;
                        // data <= config_b1[next_data_count];
                        MOSI <= config_b1[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 3) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_B2;
                            end
                        end

                    end
                    CONFIG_B2: begin
                        MOSI <= config_b2[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 3) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_B3;
                            end
                        end

                    end
                    CONFIG_B3: begin
                        // next_data_count_max <= 7;
                        // data <= config_b3[next_data_count];
                        MOSI <= config_b3[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 6) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_B4;
                            end
                        end

                    end
                    CONFIG_B4: begin
                        // next_data_count_max <= 2;
                        // data <= config_b4[next_data_count];
                        MOSI <= config_b4[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 1) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_C0;
                            end
                        end
                    end
                    CONFIG_C0: begin
                        // next_data_count_max <= 4;
                        // data <= config_c0[next_data_count];
                        MOSI <= config_c0[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 3) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_C1;
                            end
                        end
                    end
                    CONFIG_C1: begin
                        // next_data_count_max <= 2;
                        // data <= config_c1[next_data_count];
                        MOSI <= config_c1[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 1) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_C2;
                            end
                        end
                    end
                    CONFIG_C2: begin
                        // next_data_count_max <= 3;
                        // data <= config_c2[next_data_count];
                        MOSI <= config_c2[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 2) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_C3;
                            end
                        end
                    end
                    CONFIG_C3: begin
                        // next_data_count_max <= 3;
                        // data <= config_c3[next_data_count];
                        MOSI <= config_c3[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 2) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_C4;
                            end
                        end
                    end
                    CONFIG_C4: begin
                        // next_data_count_max <= 3;
                        // data <= config_c4[next_data_count];
                        MOSI <= config_c4[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 2) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_C5;
                            end
                        end
                    end
                    CONFIG_C5: begin
                        // next_data_count_max <= 2;
                        // data <= config_c5[next_data_count];
                        MOSI <= config_c5[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 1) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_E0;
                            end
                        end
                    end
                    CONFIG_E0: begin
                        // next_data_count_max <= 17;
                        // data <= config_e0[next_data_count];
                        MOSI <= config_e0[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 16) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_E1;
                            end
                        end
                    end
                    CONFIG_E1: begin
                        // next_data_count_max <= 17;
                        // data <= config_e1[next_data_count];
                        MOSI <= config_e1[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 16) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_FC;
                            end
                        end
                    end
                    CONFIG_FC: begin
                        // next_data_count_max <= 2;
                        // data <= config_fc[next_data_count];
                        MOSI <= config_fc[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 1) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_3A;
                            end
                        end
                    end
                    CONFIG_3A: begin
                        // next_data_count_max <= 2;
                        // data <= config_3a[next_data_count];
                        MOSI <= config_3a[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 1) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_36;
                            end
                        end
                    end
                    CONFIG_36: begin
                        // next_data_count_max <= 2;
                        // data <= config_36[next_data_count];
                        MOSI <= config_36[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 1) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_21;
                            end
                        end
                    end
                    CONFIG_21: begin
                        // next_data_count_max <= 1;
                        // data <= 8'h21;
                        MOSI <= config_21[data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 0) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_29;
                            end
                        end

                    end
                    CONFIG_29: begin
                        // next_data_count_max <= 1;
                        // data <= 8'h29;
                        MOSI <= config_29[data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 0) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_2A;
                            end
                        end
                    end
                    CONFIG_2A: begin
                        // next_data_count_max <= 5;
                        // data <= config_2a[next_data_count];

                        MOSI <= config_2a[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 4) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_2B;
                            end
                        end
                    end
                    CONFIG_2B: begin
                        // next_data_count_max <= 5;
                        // data <= config_2b[next_data_count];
                        MOSI <= config_2b[next_data_count][data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 4) begin
                                next_data_count <= 0;
                                config_cnt <= CONFIG_2C;
                            end
                        end
                    end
                    CONFIG_2C: begin
                        // next_data_count_max <= 1;
                        // data <= 8'h2C;
                        MOSI <= config_2c[data_count];
                        CS   <= LOW;
                        if (next_data_count > 0) begin
                            DC <= HIGH;
                        end
                        if (data_count == 0) begin
                            data_count <= MAX_BYTE;
                            next_data_count <= next_data_count + 1;
                            if (next_data_count == 0) begin
                                next_data_count <= 0;
                                // config_cnt <= CONFIG_2A;
                                oled_state <= STATE_WRITE_CONFIGURATIONS_DONE;
                            end
                        end
                    end


                endcase

            end

            STATE_WRITE_CONFIGURATIONS_DONE: begin
                init_done <= HIGH;
                DC <= HIGH;
                CS <= HIGH;
                data_count <= 15;
                next_data_count <= 0;
                // color_x <= 0;
                // color_y <= 0;
                // if (init_frame_done) begin
                //     oled_state <= STATE_WAIT_FOR_DATA;
                // end else begin
                //     oled_state <= STATE_INIT_FRAME;
                // end
                oled_state <= STATE_INIT_FRAME;
            end

            STATE_INIT_FRAME: begin
                DC   <= HIGH;
                CS   <= LOW;
                MOSI <= color_pixel[data_count];

                if (data_count == 0) begin
                    data_count <= 15;

                    if (color_y < HEIGHT - 1) begin
                        color_x <= color_x + 1;
                        if (color_x > WIDTH - 1) begin
                            color_x <= 0;
                            color_y <= color_y + 1;
                        end
                    end else begin
                        color_x <= 0;
                        color_y <= 0;
                        // config_cnt <= CONFIG_2A;
                        init_frame_done <= HIGH;
                        is_busy <= LOW;
                        oled_state <= STATE_WAIT_FOR_DATA;
                    end
                end


            end

            STATE_WAIT_FOR_DATA: begin
                if (WRITE_EN == HIGH) begin

                    if (is_busy == LOW) begin
                        is_busy <= HIGH;
                        data_count <= MAX_BYTE;
                        next_data_count <= 0;
                        color_x <= COLOR_X;
                        color_y <= COLOR_Y;
                        config_cnt <= CONFIG_2A;
                        oled_state <= STATE_WRITE_CONFIGURATIONS;
                    end

                end
            end



        endcase
    end


endmodule
