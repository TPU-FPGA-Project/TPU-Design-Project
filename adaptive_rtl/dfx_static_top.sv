`timescale 1ns/1ps

// ============================================================================
// Adaptive Precision TPU - DFX Static Shell
//
// This module represents the STATIC side of the first DFX prototype.
//
// The instance named "u_tpu_rp" is intended to become the Vivado
// Reconfigurable Partition (RP).
//
// Initial configuration:
//      RM 00 -> INT8 / 8x8 systolic core
//
// Later DFX configurations will replace ONLY u_tpu_rp with:
//
//      RM 01 -> INT16 / 4x4 systolic core
//      RM 10 -> INT32 / 2x2 systolic core
//
// Everything outside u_tpu_rp belongs to the static design.
// ============================================================================

module dfx_static_top (

    // ------------------------------------------------------------------------
    // Clock / reset
    // ------------------------------------------------------------------------

    input  logic clk,
    input  logic rst_n,


    // ------------------------------------------------------------------------
    // Common operand-loading interface
    // ------------------------------------------------------------------------

    input  logic load_a,
    input  logic load_b,

    input  logic [2:0] load_row,
    input  logic [2:0] load_col,

    input  logic signed [31:0] load_data,


    // ------------------------------------------------------------------------
    // Command interface
    // ------------------------------------------------------------------------

    input  logic start,


    // ------------------------------------------------------------------------
    // Status
    // ------------------------------------------------------------------------

    output wire busy,
    output wire done,


    // ------------------------------------------------------------------------
    // Common result stream
    // ------------------------------------------------------------------------

    output wire result_valid,

    output wire [5:0] result_index,

    output wire [2:0] result_row,
    output wire [2:0] result_col,

    output wire signed [64:0] result_data,


    // ------------------------------------------------------------------------
    // Current RM identification
    // ------------------------------------------------------------------------

    output wire [1:0] rm_id
);


    // ========================================================================
    // RECONFIGURABLE PARTITION INSTANCE
    //
    // IMPORTANT:
    //
    // Do NOT rename this instance.
    //
    // Vivado will mark this hierarchical cell as the Reconfigurable Partition.
    //
    // The INT8 RM is used as the initial implementation only.
    // During DFX this hardware will be physically replaced by the INT16
    // or INT32 RM while the surrounding static design remains unchanged.
    // ========================================================================

    rm_int8_8x8 u_tpu_rp (

        .clk            (clk),
        .rst_n          (rst_n),

        .load_a         (load_a),
        .load_b         (load_b),

        .load_row       (load_row),
        .load_col       (load_col),

        .load_data      (load_data),

        .start          (start),

        .busy           (busy),
        .done           (done),

        .result_valid   (result_valid),

        .result_index   (result_index),
        .result_row     (result_row),
        .result_col     (result_col),

        .result_data    (result_data),

        .rm_id          (rm_id)
    );


endmodule