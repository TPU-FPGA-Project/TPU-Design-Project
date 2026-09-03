`timescale 1ns/1ps

// One output-stationary processing element (PE).
//
// There is deliberately no separate register block between PEs.  a_reg and
// b_reg are both the input registers for this PE and the forwarding registers
// observed by the PE to the right/below.
module pe (
    input  logic                      clk,
    input  logic                      rst_n,
    input  logic                      clear,

    input  logic signed [7:0]         a_in,
    input  logic signed [7:0]         b_in,
    input  logic                      a_valid_in,
    input  logic                      b_valid_in,

    output logic signed [7:0]         a_out,
    output logic signed [7:0]         b_out,
    output logic                      a_valid_out,
    output logic                      b_valid_out,
    output logic signed [31:0]        acc_out
);

    logic signed [7:0]  a_reg;
    logic signed [7:0]  b_reg;
    logic signed [15:0] product_reg;
    logic signed [31:0] accumulator;

    logic a_valid_reg;
    logic b_valid_reg;
    logic product_valid_reg;

    // Synchronous reset is friendly to FPGA DSP/register inference.  clear is
    // pulsed at a tile boundary and also flushes the local validity pipeline.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            a_reg             <= '0;
            b_reg             <= '0;
            product_reg       <= '0;
            accumulator       <= '0;
            a_valid_reg       <= 1'b0;
            b_valid_reg       <= 1'b0;
            product_valid_reg <= 1'b0;
        end else if (clear) begin
            a_reg             <= '0;
            b_reg             <= '0;
            product_reg       <= '0;
            accumulator       <= '0;
            a_valid_reg       <= 1'b0;
            b_valid_reg       <= 1'b0;
            product_valid_reg <= 1'b0;
        end else begin
            // Stage 1: capture operands. These same registers forward the
            // previous operands one cell right/down every clock.
            a_reg       <= a_in;
            b_reg       <= b_in;
            a_valid_reg <= a_valid_in;
            b_valid_reg <= b_valid_in;

            // Stage 2: registered signed INT8 x INT8 multiplication.
            product_reg       <= $signed(a_reg) * $signed(b_reg);
            product_valid_reg <= a_valid_reg && b_valid_reg;

            // Stage 3: the partial sum remains inside this PE.
            if (product_valid_reg)
                accumulator <= accumulator
                             + $signed({{16{product_reg[15]}}, product_reg});
        end
    end

    assign a_out       = a_reg;
    assign b_out       = b_reg;
    assign a_valid_out = a_valid_reg;
    assign b_valid_out = b_valid_reg;
    assign acc_out     = accumulator;

endmodule
