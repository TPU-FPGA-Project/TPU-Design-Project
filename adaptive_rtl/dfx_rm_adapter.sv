`timescale 1ns/1ps

module dfx_rm_adapter #(
    parameter int N          = 8,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32,
    parameter logic [1:0] RM_ID = 2'b00
)(
    input  logic clk,
    input  logic rst_n,

    // ============================================================
    // COMMON 32-BIT LOAD INTERFACE
    // ============================================================

    input  logic load_a,
    input  logic load_b,

    input  logic [2:0] load_row,
    input  logic [2:0] load_col,

    input  logic signed [31:0] load_data,

    input  logic start,


    // ============================================================
    // COMMON STATUS INTERFACE
    // ============================================================

    output wire busy,
    output wire done,


    // ============================================================
    // COMMON RESULT INTERFACE
    // ============================================================

    output wire result_valid,

    output wire [5:0] result_index,

    output wire [2:0] result_row,
    output wire [2:0] result_col,

    output wire signed [64:0] result_data,


    // ============================================================
    // IDENTIFIES CURRENT RECONFIGURABLE MODULE
    //
    // 00 = INT8  / 8x8
    // 01 = INT16 / 4x4
    // 10 = INT32 / 2x2
    // ============================================================

    output wire [1:0] rm_id
);


    // ============================================================
    // INTERNAL CORE WIDTHS
    // ============================================================

    localparam int INDEX_WIDTH =
        (N <= 1)
            ? 1
            : $clog2(N);

    localparam int RESULT_INDEX_WIDTH =
        (N*N <= 1)
            ? 1
            : $clog2(N*N);


    // ============================================================
    // ADDRESS VALIDATION
    //
    // This is important.
    //
    // For the 4x4 RM:
    // row/col 0..3 are legal.
    //
    // For the 2x2 RM:
    // row/col 0..1 are legal.
    //
    // We must NOT simply truncate the 3-bit address because
    // row 7 would otherwise alias to another valid location.
    // ============================================================

    wire address_valid;

    assign address_valid =
        (load_row < N) &&
        (load_col < N);


    // ============================================================
    // CORE-SPECIFIC INPUTS
    // ============================================================

    wire core_load_a;
    wire core_load_b;

    wire [INDEX_WIDTH-1:0] core_load_row;
    wire [INDEX_WIDTH-1:0] core_load_col;

    wire signed [DATA_WIDTH-1:0]
        core_load_data;


    assign core_load_a =
        load_a && address_valid;

    assign core_load_b =
        load_b && address_valid;


    assign core_load_row =
        load_row[INDEX_WIDTH-1:0];

    assign core_load_col =
        load_col[INDEX_WIDTH-1:0];


    // ------------------------------------------------------------
    // INT8  RM uses bits  7:0
    // INT16 RM uses bits 15:0
    // INT32 RM uses bits 31:0
    // ------------------------------------------------------------

    assign core_load_data =
        load_data[DATA_WIDTH-1:0];


    // ============================================================
    // CORE-SPECIFIC OUTPUTS
    // ============================================================

    wire core_busy;
    wire core_done;

    wire core_result_valid;

    wire [RESULT_INDEX_WIDTH-1:0]
        core_result_index;

    wire [INDEX_WIDTH-1:0]
        core_result_row;

    wire [INDEX_WIDTH-1:0]
        core_result_col;

    wire signed [ACC_WIDTH-1:0]
        core_result_data;


    // ============================================================
    // GENERIC SYSTOLIC CORE
    // ============================================================

    systolic_core #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH)
    ) u_core (
        .clk          (clk),
        .rst_n        (rst_n),

        .load_a       (core_load_a),
        .load_b       (core_load_b),

        .load_row     (core_load_row),
        .load_col     (core_load_col),

        .load_data    (core_load_data),

        .start        (start),

        .busy         (core_busy),
        .done         (core_done),

        .result_valid (core_result_valid),

        .result_index (core_result_index),
        .result_row   (core_result_row),
        .result_col   (core_result_col),

        .result_data  (core_result_data)
    );


    // ============================================================
    // COMMON STATUS OUTPUTS
    // ============================================================

    assign busy =
        core_busy;

    assign done =
        core_done;

    assign result_valid =
        core_result_valid;


    // ============================================================
    // ZERO-EXTEND ADDRESS/INDEX FIELDS
    // ============================================================

    assign result_index =
        core_result_index;

    assign result_row =
        core_result_row;

    assign result_col =
        core_result_col;


    // ============================================================
    // SIGN-EXTEND RESULT TO COMMON 65-BIT WIDTH
    // ============================================================

    generate

        if (ACC_WIDTH < 65) begin : GEN_RESULT_EXTENSION

            assign result_data =
                {
                    {(65-ACC_WIDTH){
                        core_result_data[ACC_WIDTH-1]
                    }},
                    core_result_data
                };

        end
        else begin : GEN_RESULT_DIRECT

            assign result_data =
                core_result_data;

        end

    endgenerate


    // ============================================================
    // RM IDENTIFICATION
    // ============================================================

    assign rm_id =
        RM_ID;


endmodule