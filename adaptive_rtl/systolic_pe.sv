`timescale 1ns/1ps

module systolic_pe #(
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input logic clk,
    input logic rst_n,
    input logic clear,

    input logic signed [DATA_WIDTH-1:0] a_in,
    input logic signed [DATA_WIDTH-1:0] b_in,

    input logic a_valid_in,
    input logic b_valid_in,

    output logic signed [DATA_WIDTH-1:0] a_out,
    output logic signed [DATA_WIDTH-1:0] b_out,

    output logic a_valid_out,
    output logic b_valid_out,

    output logic signed [ACC_WIDTH-1:0] acc_out
);

    localparam int PRODUCT_WIDTH = 2 * DATA_WIDTH;

    logic signed [DATA_WIDTH-1:0] a_reg;
    logic signed [DATA_WIDTH-1:0] b_reg;

    logic signed [PRODUCT_WIDTH-1:0] product_reg;
    logic signed [ACC_WIDTH-1:0] accumulator;

    logic a_valid_reg;
    logic b_valid_reg;
    logic product_valid_reg;

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            a_reg             <= '0;
            b_reg             <= '0;
            product_reg       <= '0;
            accumulator       <= '0;

            a_valid_reg       <= 1'b0;
            b_valid_reg       <= 1'b0;
            product_valid_reg <= 1'b0;

        end
        else if (clear) begin

            a_reg             <= '0;
            b_reg             <= '0;
            product_reg       <= '0;
            accumulator       <= '0;

            a_valid_reg       <= 1'b0;
            b_valid_reg       <= 1'b0;
            product_valid_reg <= 1'b0;

        end
        else begin

            // Pipeline stage 1:
            // Capture and forward A/B.
            a_reg <= a_in;
            b_reg <= b_in;

            a_valid_reg <= a_valid_in;
            b_valid_reg <= b_valid_in;

            // Pipeline stage 2:
            // Signed multiplication.
            product_reg <=
                $signed(a_reg) * $signed(b_reg);

            product_valid_reg <=
                a_valid_reg && b_valid_reg;

            // Pipeline stage 3:
            // Output-stationary accumulation.
            if (product_valid_reg)
                accumulator <=
                    accumulator + $signed(product_reg);

        end

    end

    assign a_out = a_reg;
    assign b_out = b_reg;

    assign a_valid_out = a_valid_reg;
    assign b_valid_out = b_valid_reg;

    assign acc_out = accumulator;

endmodule