`timescale 1ns/1ps

module systolic_array #(
    parameter int N          = 4,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32
)(
    input logic clk,
    input logic rst_n,
    input logic clear,

    // Left boundary: one A input for every row
    input logic signed [DATA_WIDTH-1:0] a_left [0:N-1],

    // Top boundary: one B input for every column
    input logic signed [DATA_WIDTH-1:0] b_top [0:N-1],

    input logic a_valid_left [0:N-1],
    input logic b_valid_top  [0:N-1],

    // One accumulator per PE
    output wire [N*N*ACC_WIDTH-1:0] acc_flat
);

    // ------------------------------------------------------------
    // Horizontal A interconnect
    //
    // N rows
    // N+1 boundaries per row
    // ------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0]
        a_bus [0:N-1][0:N];

    logic
        a_valid_bus [0:N-1][0:N];


    // ------------------------------------------------------------
    // Vertical B interconnect
    //
    // N+1 row boundaries
    // N columns
    // ------------------------------------------------------------

    logic signed [DATA_WIDTH-1:0]
        b_bus [0:N][0:N-1];

    logic
        b_valid_bus [0:N][0:N-1];


    genvar r;
    genvar c;

    generate

        // --------------------------------------------------------
        // Connect external A inputs to left edge
        // --------------------------------------------------------

        for (r = 0; r < N; r = r + 1) begin : GEN_A_BOUNDARY

            assign a_bus[r][0] =
                a_left[r];

            assign a_valid_bus[r][0] =
                a_valid_left[r];

        end


        // --------------------------------------------------------
        // Connect external B inputs to top edge
        // --------------------------------------------------------

        for (c = 0; c < N; c = c + 1) begin : GEN_B_BOUNDARY

            assign b_bus[0][c] =
                b_top[c];

            assign b_valid_bus[0][c] =
                b_valid_top[c];

        end


        // --------------------------------------------------------
        // Generate N × N processing elements
        // --------------------------------------------------------

        for (r = 0; r < N; r = r + 1) begin : GEN_ROW

            for (c = 0; c < N; c = c + 1) begin : GEN_COL

                logic signed [ACC_WIDTH-1:0] pe_acc;

                systolic_pe #(
                    .DATA_WIDTH(DATA_WIDTH),
                    .ACC_WIDTH (ACC_WIDTH)
                ) u_pe (
                    .clk            (clk),
                    .rst_n          (rst_n),
                    .clear          (clear),

                    .a_in           (a_bus[r][c]),
                    .b_in           (b_bus[r][c]),

                    .a_valid_in     (a_valid_bus[r][c]),
                    .b_valid_in     (b_valid_bus[r][c]),

                    .a_out          (a_bus[r][c+1]),
                    .b_out          (b_bus[r+1][c]),

                    .a_valid_out    (a_valid_bus[r][c+1]),
                    .b_valid_out    (b_valid_bus[r+1][c]),

                    .acc_out        (pe_acc)
                );

                assign acc_flat[
                    ((r*N + c) * ACC_WIDTH) +: ACC_WIDTH
                ] = pe_acc;

            end

        end

    endgenerate

endmodule