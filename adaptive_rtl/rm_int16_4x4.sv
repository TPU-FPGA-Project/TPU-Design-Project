`timescale 1ns/1ps

module rm_int16_4x4 (
    input  logic clk,
    input  logic rst_n,

    input  logic load_a,
    input  logic load_b,

    input  logic [2:0] load_row,
    input  logic [2:0] load_col,

    input  logic signed [31:0] load_data,

    input  logic start,

    output wire busy,
    output wire done,

    output wire result_valid,

    output wire [5:0] result_index,
    output wire [2:0] result_row,
    output wire [2:0] result_col,

    output wire signed [64:0] result_data,

    output wire [1:0] rm_id
);

    dfx_rm_adapter #(
        .N          (4),
        .DATA_WIDTH (16),
        .ACC_WIDTH  (48),
        .RM_ID      (2'b01)
    ) u_adapter (
        .clk(clk),
        .rst_n(rst_n),

        .load_a(load_a),
        .load_b(load_b),

        .load_row(load_row),
        .load_col(load_col),
        .load_data(load_data),

        .start(start),

        .busy(busy),
        .done(done),

        .result_valid(result_valid),

        .result_index(result_index),
        .result_row(result_row),
        .result_col(result_col),

        .result_data(result_data),

        .rm_id(rm_id)
    );

endmodule