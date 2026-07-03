`timescale 1ns / 1ps
/**
* @file counter_tb.sv
* @brief Test bench for the updown_counter module.
* @details This test bench verifies the functionality of the updown_counter module by simulating various scenarios.
* The present test bench includes basic setup and a few test cases to validate the counter's behavior.
* 1. Load value into the counter and check if it matches.
* 2. Count up and check if the count matches the expected value.
* 3. Count down and check if the count matches the expected value.
* 4. Disable the counter and check if the count remains unchanged.
*
* You need to add the following test cases:
* 5. Reset the counter during operation and check if it resets to zero.
* 6. Check the counter's behavior when the load signal is asserted while counting.
* 7. Check the counter's behavior when the enable signal is deasserted while counting.
*
* You also need to add a clock generation block to simulate the clock signal.
*/

module counter_tb();
    logic clk;
    logic rst_n;
    logic load;
    logic up_down;
    logic enable;
    logic [3:0] d_in;
    logic [3:0] count;
    logic test_passed;

    // Clock generation: 10ns period (rising edges at 5, 15, 25, ...)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Instance of student's module
    updown_counter dut(
        .clk(clk),
        .rst_n(rst_n),
        .load(load),
        .up_down(up_down),
        .enable(enable),
        .d_in(d_in),
        .count(count)
    );

    initial begin
        test_passed = 1'b1;

        // Reset
        rst_n = 0;
        load = 0;
        up_down = 1;
        enable = 0;
        d_in = 4'h0;
        #20;
        rst_n = 1;

        // Test Case 1: Load value
        d_in = 4'h7;
        load = 1;
        #10;
        load = 0;
        if (count !== 4'h7) begin
            $display("Test 1 Failed: Load operation");
            test_passed = 1'b0;
        end

        // Test Case 2: Count up
        enable = 1;
        up_down = 1;
        #40;  // 4 clock cycles
        if (count !== 4'hB) begin
            $display("Test 2 Failed: Count up operation");
            test_passed = 1'b0;
        end

        // Test Case 3: Count down
        up_down = 0;
        #30;  // 3 clock cycles
        if (count !== 4'h8) begin
            $display("Test 3 Failed: Count down operation");
            test_passed = 1'b0;
        end

        // Test Case 4: Disabled counter should not change
        enable = 0;
        #20;
        if (count !== 4'h8) begin
            $display("Test 4 Failed: Disabled counter changed");
            test_passed = 1'b0;
        end

        // Test Case 5: Reset during operation
        // Count up for a couple of cycles, then assert reset and confirm it clears.
        enable = 1;
        up_down = 1;
        #20;            // 2 clock cycles: 8 -> 9 -> A
        rst_n = 0;      // Asynchronous reset asserted mid-operation
        #10;
        if (count !== 4'h0) begin
            $display("Test 5 Failed: Reset during operation");
            test_passed = 1'b0;
        end
        rst_n = 1;      // Release reset

        // Test Case 6: Load while counting
        // With enable high, asserting load should override counting and load d_in.
        enable = 1;
        up_down = 1;
        d_in = 4'h5;
        load = 1;
        #10;            // 1 clock cycle
        load = 0;
        if (count !== 4'h5) begin
            $display("Test 6 Failed: Load while counting");
            test_passed = 1'b0;
        end

        // Test Case 7: Disable while counting
        // Deassert enable; the counter must hold its value across several clocks.
        enable = 0;
        #20;            // 2 clock cycles, value should not change
        if (count !== 4'h5) begin
            $display("Test 7 Failed: Disable while counting");
            test_passed = 1'b0;
        end

        // Final check
        if (test_passed) begin
            $display("All tests passed!");
        end else begin
            $display("Some tests failed.");
        end

        $finish(0);
    end
endmodule
