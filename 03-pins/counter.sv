module counter (
    input logic clkpulse,       // Clock input (button)
    input logic rst,            // Active high reset (button)
    input logic up_down,        // Direction from SW0: 1 = up, 0 = down
    output logic [3:0] led      // 4-bit counter output
);

    always @(posedge clkpulse or posedge rst) begin
        if (rst) begin
            led <= 4'b0000;          // Reset counter to 0
        end else if (up_down) begin
            led <= led + 1;          // SW0 = 1: count up   (0, 1, 2, ...)
        end else begin
            led <= led - 1;          // SW0 = 0: count down (0, 15, 14, ...)
        end
    end

endmodule
