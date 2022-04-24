module ClockDivider #(
    parameter CLOCK_SPEED_MHZ = 12,
    parameter MS = 1000
) (
    output reg  out,
    input  wire CLK
);
    localparam HALF_CLOCK_SPEED = CLOCK_SPEED_MHZ / 2;
    localparam SEC = (MS * 1000) - 1;
    reg [$clog2(CLOCK_SPEED_MHZ):0] counter = 0;
    reg [$clog2(SEC):0] sec = 0;

    always @(posedge CLK) begin


        if (counter == HALF_CLOCK_SPEED) begin
            counter <= 0;
            sec <= sec + 1;
        end else if (sec == SEC) begin
            sec <= 0;
            out <= ~out;
        end else begin
            counter <= counter + 1;
        end
    end



endmodule
