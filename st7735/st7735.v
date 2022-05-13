

module ST7735 #(
    parameter CLOCK_SPEED_MHZ = 12,
    parameter DELAY_US = 8000000 / 6,
    parameter WIDTH = 160,
    parameter HEIGHT = 120
) (
    input  wire SYSTEM_CLK,
    output reg  CS,
    output reg  MOSI,
    output reg  DC,
    output reg  LCD_CLK,
    output reg  RESET
);


    localparam STATE_IDLE = 0;
    localparam STATE_INIT = 1;
    localparam STATE_DELAY_120MS = 2;
    localparam STATE_SPLOUT = 3;
    localparam STATE_WAITING_PIXEL = 4;
    localparam STATE_B4_REG = 5;
    localparam STATE_B4_PARAM1 = 6;
    localparam STATE_C0_REG = 7;
    localparam STATE_C0_PARAM0 = 8;
    localparam STATE_C0_PARAM1 = 9;
    localparam STATE_C0_PARAM2 = 10;
    localparam STATE_C3_REG = 11;
    localparam STATE_C3_PARAM0 = 12;
    localparam STATE_C3_PARAM1 = 13;
    localparam STATE_C4_REG = 14;
    localparam STATE_C4_PARAM0 = 15;
    localparam STATE_C4_PARAM1 = 16;
    localparam STATE_C5_REG = 17;
    localparam STATE_C5_PARAM0 = 18;
    localparam STATE_36_REG = 19;
    localparam STATE_36_PARAM0 = 20;
    localparam STATE_3A_REG = 21;
    localparam STATE_3A_PARAM0 = 22;
    localparam STATE_2A_REG = 23;
    localparam STATE_2A_PARAM0 = 24;
    localparam STATE_2A_PARAM1 = 25;
    localparam STATE_2A_PARAM2 = 26;
    localparam STATE_2A_PARAM3 = 27;
    localparam STATE_2B_REG = 28;
    localparam STATE_2B_PARAM0 = 29;
    localparam STATE_2B_PARAM1 = 30;
    localparam STATE_2B_PARAM2 = 31;
    localparam STATE_2B_PARAM3 = 32;
    localparam STATE_29_REG = 33;
    localparam STATE_2C_REG = 34;

    localparam HIGH = 1'b1;
    localparam LOW = 1'b0;
    localparam MAX_BYTE = 7;

    reg [7:0] data;
    reg [4:0] data_count;

    reg [7:0] oled_state;
    reg init_done;

    localparam [7:0] config_b4 = 8'hb4;
    localparam [7:0] config_b4_param = 8'h07;
    localparam [7:0] config_c0 = 8'hc0;
    localparam [7:0] config_c0_param0 = 8'h82;
    localparam [7:0] config_c0_param1 = 8'h02;
    localparam [7:0] config_c0_param2 = 8'h84;
    localparam [7:0] config_c3 = 8'hc3;
    localparam [7:0] config_c3_param0 = 8'h8a;
    localparam [7:0] config_c3_param1 = 8'h2e;
    localparam [7:0] config_c4 = 8'hc4;
    localparam [7:0] config_c4_param0 = 8'h8a;
    localparam [7:0] config_c4_param1 = 8'haa;
    localparam [7:0] config_c5 = 8'hc5;
    localparam [7:0] config_c5_param0 = 8'h0e;
    localparam [7:0] config_3a = 8'h3a;
    localparam [7:0] config_3a_param0 = 8'h05;
    localparam [7:0] config_36 = 8'h36;
    localparam [7:0] config_36_param0 = 8'ha8;
    localparam [7:0] config_2a = 8'h2a;
    localparam [7:0] config_2a_param0 = 8'h00;
    localparam [7:0] config_2a_param1 = 8'h00;
    localparam [7:0] config_2a_param2 = 8'h00;
    localparam [7:0] config_2a_param3 = 8'ha0;
    localparam [7:0] config_2b = 8'h2b;
    localparam [7:0] config_2b_param0 = 8'h00;
    localparam [7:0] config_2b_param1 = 8'h03;
    localparam [7:0] config_2b_param2 = 8'h00;
    localparam [7:0] config_2b_param3 = 8'h78;
    localparam [7:0] config_sw_reset = 8'h01;
    localparam [7:0] config_slpout = 8'h11;
    localparam [7:0] config_21 = 8'h21;
    localparam [7:0] config_29 = 8'h29;
    localparam [7:0] config_2c = 8'h2c;


    reg [15:0] color;    
    reg [19:0] current_pixel;
    reg [24:0] delay_counter;

    initial begin
        CS = HIGH;
        MOSI = HIGH;
        DC = HIGH;
        LCD_CLK = HIGH;
        RESET = HIGH;
        data_count = MAX_BYTE;
        delay_counter = 0;
        oled_state = STATE_IDLE;
        init_done <= LOW;
        color = ~(16'h16F9);

    end

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
                    oled_state <= STATE_INIT;
                end
            end
            STATE_INIT: begin
                delay_counter <= delay_counter + 1;
                if (delay_counter >= DELAY_US) begin
                    delay_counter <= 0;
                    data_count <= MAX_BYTE;

                    oled_state <= STATE_DELAY_120MS;
                end else begin
                    RESET <= LOW;
                end

            end

            STATE_DELAY_120MS: begin


                delay_counter <= delay_counter + 1;
                if (delay_counter >= DELAY_US) begin
                    delay_counter <= 0;
                    data_count <= MAX_BYTE;

                    oled_state <= STATE_SPLOUT;
                end
            end

            STATE_SPLOUT: begin
                MOSI <= config_slpout[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_B4_REG;
                end

            end

            STATE_B4_REG: begin
                MOSI <= config_b4[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_B4_PARAM1;
                end
            end

            STATE_B4_PARAM1: begin
                MOSI <= config_b4_param[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C0_REG;
                end
            end

            STATE_C0_REG: begin
                MOSI <= config_c0[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C0_PARAM0;
                end
            end

            STATE_C0_PARAM0: begin
                MOSI <= config_c0_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C0_PARAM1;
                end
            end

            STATE_C0_PARAM1: begin
                MOSI <= config_c0_param1[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C0_PARAM2;
                end
            end

            STATE_C0_PARAM2: begin
                MOSI <= config_c0_param2[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C3_REG;
                end
            end

            STATE_C3_REG: begin
                MOSI <= config_c3[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C3_PARAM0;
                end
            end

            STATE_C3_PARAM0: begin
                MOSI <= config_c3_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C3_PARAM1;
                end
            end

            STATE_C3_PARAM1: begin
                MOSI <= config_c3_param1[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C4_REG;
                end
            end

            STATE_C4_REG: begin
                MOSI <= config_c4[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C4_PARAM0;
                end
            end

            STATE_C4_PARAM0: begin
                MOSI <= config_c4_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C4_PARAM1;
                end
            end

            STATE_C4_PARAM1: begin
                MOSI <= config_c4_param1[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C5_REG;
                end
            end

            STATE_C5_REG: begin
                MOSI <= config_c5[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_C5_PARAM0;
                end
            end

            STATE_C5_PARAM0: begin
                MOSI <= config_c5_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_36_REG;
                end
            end

            STATE_36_REG: begin
                MOSI <= config_36[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_36_PARAM0;
                end
            end

            STATE_36_PARAM0: begin
                MOSI <= config_36_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_3A_REG;
                end
            end

            STATE_3A_REG: begin
                MOSI <= config_3a[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_3A_PARAM0;
                end
            end

            STATE_3A_PARAM0: begin
                MOSI <= config_3a_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2A_REG;
                end
            end

            STATE_2A_REG: begin
                MOSI <= config_2a[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2A_PARAM0;
                end
            end

            STATE_2A_PARAM0: begin
                MOSI <= config_2a_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2A_PARAM1;
                end
            end

            STATE_2A_PARAM1: begin
                MOSI <= config_2a_param1[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2A_PARAM2;
                end
            end

            STATE_2A_PARAM2: begin

                MOSI <= config_2a_param2[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2A_PARAM3;
                end

            end

            STATE_2A_PARAM3: begin
                MOSI <= config_2a_param3[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2B_REG;
                end
            end

            STATE_2B_REG: begin
                MOSI <= config_2b[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2B_PARAM0;
                end
            end

            STATE_2B_PARAM0: begin
                MOSI <= config_2b_param0[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2B_PARAM1;
                end
            end

            STATE_2B_PARAM1: begin
                MOSI <= config_2b_param1[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2B_PARAM2;
                end
            end

            STATE_2B_PARAM2: begin
                MOSI <= config_2b_param2[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2B_PARAM3;
                end
            end

            STATE_2B_PARAM3: begin
                MOSI <= config_2b_param3[data_count];
                CS   <= LOW;
                DC   <= HIGH;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_29_REG;
                end
            end

            STATE_29_REG: begin
                MOSI <= config_29[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= MAX_BYTE;
                    oled_state <= STATE_2C_REG;
                end
            end

            STATE_2C_REG: begin
                MOSI <= config_2c[data_count];
                CS   <= LOW;
                if (data_count == 0) begin
                    data_count <= 15;
                    oled_state <= STATE_WAITING_PIXEL;
                end
            end

            // STATE_INIT_FRAME: begin
            //     DC   <= HIGH;
            //     CS   <= LOW;
            //     MOSI <= color[data_count];
            //     if (data_count == 0) begin
            //         data_count <= 15;
            //         current_pixel <= current_pixel + 1;
            //         if (current_pixel == WIDTH * HEIGHT) begin
            //             current_pixel <= 0;
            //             // config_cnt <= CONFIG_2A;
            //             oled_state <= STATE_WRITE_CONFIGURATIONS;
            //         end

            //     end
            //     init_frame_done <= 1'b1;

            // end

            STATE_WAITING_PIXEL: begin
                DC   <= HIGH;
                CS   <= LOW;
                MOSI <= color[data_count];
                if (data_count == 0) begin
                    data_count <= 15;
                    current_pixel <= current_pixel + 1;
                    if (current_pixel == WIDTH * HEIGHT) begin
                        current_pixel <= 0;
                        init_done <= HIGH;
                        oled_state <= STATE_IDLE;
                    end

                end
            end

        endcase
    end


endmodule
