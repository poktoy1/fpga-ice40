module DelayCounter #(
    parameter CLOCK_SPEED_MHZ = 12,
    parameter US_DELAY = 1000
) (
    output reg out,
    input wire CLK,
    input start
);
    localparam HALF_CLOCK_SPEED = CLOCK_SPEED_MHZ / 2;
    localparam SEC = US_DELAY;
    reg [$clog2(CLOCK_SPEED_MHZ):0] counter = 0;
    reg [$clog2(SEC):0] sec = 0;

    always @(posedge CLK, start) begin

        if (start) begin
            if (counter == HALF_CLOCK_SPEED) begin
                counter <= 0;
                sec <= sec + 1;
            end else if (sec == SEC) begin
                sec <= 0;
                out <= 1'b1;
            end else begin
                counter <= counter + 1;
                out <= 1'b0;
            end
        end else begin
            counter <= 0;
            sec <= 0;
            out <= 1'b0;
        end


    end



endmodule
