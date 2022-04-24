
`include "../clock-divider/clock-divider.v"

module ButtonCounter (
    output [7:0] LED,
    output LED_STAT,
    input wire [1:0] BUTTON,
    input CLK

);

    localparam STATE_HIGH = 3'b001;
    localparam STATE_LOW = 3'b010;
    localparam STATE_PRESSED = 3'b011;
    localparam STATE_WAIT = 3'b100;


    wire reset;
    wire button_count;
    wire clock_divider_out;
    wire button_debouncer;
    reg [7:0] data;
    reg [7:0] data_click;
    reg [2:0] state = STATE_HIGH;

    assign reset = ~BUTTON[0];
    assign button_count = ~BUTTON[1];
    assign LED = ~(data + data_click);

    always @(posedge clock_divider_out, posedge reset) begin
        if (reset) begin
            data <= 8'b0;
        end else if (state == STATE_PRESSED) begin

            data <= 0;
        end else begin
            data <= data + 1;
        end

    end

    always @(posedge CLK, posedge reset) begin
        if (reset) begin
            data_click <= 0;
            state <= STATE_HIGH;
        end else begin
            case (state)
                STATE_HIGH: begin
                    if (button_count == 1'b0) begin
                        state <= STATE_LOW;
                    end
                end
                STATE_LOW: begin
                    if (button_count == 1'b1) begin
                        state <= STATE_WAIT;
                    end
                end

                STATE_WAIT: begin
                    if (button_debouncer) begin
                        if (button_count == 1'b1) begin
                            state <= STATE_PRESSED;

                        end else begin
                            state <= STATE_HIGH;

                        end
                    end
                end

                STATE_PRESSED: begin
                    data_click <= data_click + 1;

                    state <= STATE_HIGH;
                end
            endcase

        end
    end

    ClockDivider #(
        .CLOCK_SPEED_MHZ(12),
        .MS(1000)
    ) _clock_divider (
        .out(clock_divider_out),
        .CLK(CLK)
    );

    ClockDivider #(
        .CLOCK_SPEED_MHZ(12),
        .MS(1000)
    ) _blinker (
        .out(LED_STAT),
        .CLK(CLK)
    );

    ClockDivider #(
        .CLOCK_SPEED_MHZ(12),
        .MS(30)
    ) _button_debouncer (
        .out(button_debouncer),
        .CLK(CLK)
    );

endmodule
