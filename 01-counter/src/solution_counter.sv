/**
* updown_counter:
* A simple up/down counter with load functionality.
*
* Features:
* - 4-bit counter
* - Asynchronous reset
* - Load functionality: on load signal, the counter loads the input value
* - Up/Down counting: controlled by the up_down signal (1 for up, 0 for down)
* - Enable signal to control counting: when enabled, the counter counts; when disabled, it holds its value
*/
module updown_counter(
    input logic clk,       // Clock input
    input logic rst_n,     // Active-low reset
    input logic load,      // Load enable
    input logic up_down,   // Direction control (1 = up, 0 = down)
    input logic enable,    // Counter enable
    input logic [3:0] d_in,// Input data for loading
    output logic [3:0] count // Counter output
);

    // Sequential logic with asynchronous active-low reset.
    // Priority: reset > load > count (up/down) > hold.
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= 4'h0;          // Asynchronous reset to zero
        else if (load)
            count <= d_in;          // Load input value
        else if (enable)
            count <= up_down ? (count + 4'h1)   // Count up
                             : (count - 4'h1);  // Count down
        // else: hold current value (enable low)
    end

endmodule
