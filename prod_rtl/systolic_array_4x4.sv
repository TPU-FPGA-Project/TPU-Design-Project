`timescale 1ns/1ps

// Pure 4x4 PE mesh. Boundary skewing and tile control live outside this module.
module systolic_array_4x4 (
    input  logic                       clk,
    input  logic                       rst_n,
    input  logic                       clear,

    input  logic signed [7:0]          a_left       [0:3],
    input  logic signed [7:0]          b_top        [0:3],
    input  logic                       a_valid_left [0:3],
    input  logic                       b_valid_top  [0:3],

    output logic signed [31:0]         acc          [0:3][0:3]
);

    // A has four rows and five boundaries: external left boundary, then one
    // registered output after each of the four PEs.
    logic signed [7:0] a_bus [0:3][0:4];
    logic              a_v   [0:3][0:4];

    // B has five row boundaries and four columns.
    logic signed [7:0] b_bus [0:4][0:3];
    logic              b_v   [0:4][0:3];

    genvar r, c;
    generate
        for (r = 0; r < 4; r++) begin : GEN_A_BOUNDARY
            assign a_bus[r][0] = a_left[r];
            assign a_v[r][0]   = a_valid_left[r];
        end

        for (c = 0; c < 4; c++) begin : GEN_B_BOUNDARY
            assign b_bus[0][c] = b_top[c];
            assign b_v[0][c]   = b_valid_top[c];
        end

        for (r = 0; r < 4; r++) begin : GEN_ROW
            for (c = 0; c < 4; c++) begin : GEN_COL
                pe u_pe (
                    .clk         (clk),
                    .rst_n       (rst_n),
                    .clear       (clear),
                    .a_in        (a_bus[r][c]),
                    .b_in        (b_bus[r][c]),
                    .a_valid_in  (a_v[r][c]),
                    .b_valid_in  (b_v[r][c]),
                    .a_out       (a_bus[r][c+1]),
                    .b_out       (b_bus[r+1][c]),
                    .a_valid_out (a_v[r][c+1]),
                    .b_valid_out (b_v[r+1][c]),
                    .acc_out     (acc[r][c])
                );
            end
        end
    endgenerate

endmodule
