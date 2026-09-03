`timescale 1ns/1ps

module tb_pe;

    logic clk;
    logic rst_n;
    logic clear;

    logic signed [7:0] a_in;
    logic signed [7:0] b_in;
    logic              a_valid_in;
    logic              b_valid_in;

    logic signed [7:0]  a_out;
    logic signed [7:0]  b_out;
    logic               a_valid_out;
    logic               b_valid_out;
    logic signed [31:0] acc_out;

    // Instantiate the PE being tested
    pe dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .clear       (clear),

        .a_in        (a_in),
        .b_in        (b_in),
        .a_valid_in  (a_valid_in),
        .b_valid_in  (b_valid_in),

        .a_out       (a_out),
        .b_out       (b_out),
        .a_valid_out (a_valid_out),
        .b_valid_out (b_valid_out),
        .acc_out     (acc_out)
    );

    // 100 MHz clock:
    // period = 10 ns
    // frequency = 1 / 10 ns = 100 MHz
    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // Apply one A/B pair before the next rising edge
    task automatic drive_pair(
        input logic signed [7:0] a,
        input logic signed [7:0] b,
        input logic              valid
    );
        begin
            @(negedge clk);

            a_in      = a;
            b_in      = b;
            a_valid_in = valid;
            b_valid_in = valid;
        end
    endtask

    initial begin
        // Initial values
        rst_n      = 1'b0;
        clear      = 1'b0;
        a_in       = '0;
        b_in       = '0;
        a_valid_in = 1'b0;
        b_valid_in = 1'b0;

        // Keep reset active for three rising clock edges
        repeat (3) @(posedge clk);

        // Release reset away from a rising edge
        @(negedge clk);
        rst_n = 1'b1;

        /*
         * Send four products:
         *
         *  2 × 5  = 10
         *  3 × 2  =  6
         * -1 × 6  = -6
         *  4 × 3  = 12
         *
         * Expected sum = 10 + 6 - 6 + 12 = 22
         */

        drive_pair( 2, 5, 1'b1);
        drive_pair( 3, 2, 1'b1);
        drive_pair(-1, 6, 1'b1);
        drive_pair( 4, 3, 1'b1);

        // Stop sending valid data and drain the MAC pipeline
        drive_pair(0, 0, 1'b0);
        drive_pair(0, 0, 1'b0);
        
        // The second drive_pair returns at a falling edge.
        // Wait for the following rising edge, where the final
        // registered product is added to the accumulator.
        @(posedge clk);
        #1;

        if (acc_out !== 32'sd22) begin
            $fatal(1,
                "PE TEST FAILED: expected 22, received %0d",
                $signed(acc_out)
            );
        end
        else begin
            $display(
                "PE MAC TEST PASSED: accumulator = %0d",
                $signed(acc_out)
            );
        end 

        // Test the tile-clear input
        @(negedge clk);
        clear = 1'b1;

        @(negedge clk);
        clear = 1'b0;

        #1;

        if (acc_out !== 32'sd0) begin
            $error("CLEAR TEST FAILED: expected 0, received %0d",
                   $signed(acc_out));
        end
        else begin
            $display("PE CLEAR TEST PASSED");
        end

        $display("ALL PE TESTS PASSED");
        $finish;
    end

endmodule