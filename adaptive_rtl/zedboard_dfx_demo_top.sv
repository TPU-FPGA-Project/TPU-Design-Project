`timescale 1ns/1ps

// ============================================================================
// Adaptive Precision TPU
// ZedBoard manual-DFX hardware demonstration
//
// SW0 HIGH:
//      Hold static controller and RP in reset.
//      Use this while loading a partial bitstream.
//
// SW0 LOW:
//      Release reset.
//      Static controller automatically loads the test operands.
//
// BTNU:
//      Start the currently loaded accelerator.
//
// BTNC:
//      Manual reset.
//
// LEDs:
//      LD7 = PASS
//      LD6 = FAIL
//      LD5 = accelerator BUSY
//      LD4 = controller READY
//      LD3 = computation DONE (latched)
//      LD2 = DFX isolate/reset active
//      LD1:LD0 = RM ID
//
// RM ID:
//      00 = INT8  / 8x8
//      01 = INT16 / 4x4
//      10 = INT32 / 2x2
// ============================================================================

module zedboard_dfx_demo_top (

    input  logic clk_100mhz,

    input  logic btn_reset,
    input  logic btn_start,

    input  logic sw_isolate,

    output logic [7:0] led
);


    // ========================================================================
    // Reset / manual DFX isolation
    //
    // Assertion is asynchronous.
    // Release is synchronized to the 100 MHz PL clock.
    //
    // Before partial reconfiguration:
    //
    //      SW0 = 1
    //
    // After reconfiguration:
    //
    //      SW0 = 0
    //
    // This keeps the static controller quiet while the RP is being changed.
    // ========================================================================

    wire async_reset;

    assign async_reset =
        btn_reset | sw_isolate;


    logic [1:0] reset_pipe;

    always_ff @(posedge clk_100mhz or posedge async_reset) begin

        if (async_reset)

            reset_pipe <=
                2'b11;

        else

            reset_pipe <=
                {
                    reset_pipe[0],
                    1'b0
                };

    end


    wire rst_n;

    assign rst_n =
        ~reset_pipe[1];


    // ========================================================================
    // Fixed DFX interface
    // ========================================================================

    logic core_load_a;
    logic core_load_b;

    logic [2:0] core_load_row;
    logic [2:0] core_load_col;

    logic signed [31:0]
        core_load_data;

    logic core_start;


    (* mark_debug = "true" *)
    logic core_busy;

    (* mark_debug = "true" *)
    logic core_done;

    (* mark_debug = "true" *)
    logic core_result_valid;

    (* mark_debug = "true" *)
    logic [5:0]
        core_result_index;

    (* mark_debug = "true" *)
    logic [2:0]
        core_result_row;

    (* mark_debug = "true" *)
    logic [2:0]
        core_result_col;

    (* mark_debug = "true" *)
    logic signed [64:0]
        core_result_data;

    (* mark_debug = "true" *)
    logic [1:0]
        core_rm_id;


    // ========================================================================
    // Static verification status
    // ========================================================================

    logic demo_ready;

    (* mark_debug = "true" *)
    logic pass_latched;

    (* mark_debug = "true" *)
    logic fail_latched;

    (* mark_debug = "true" *)
    logic done_latched;

    (* mark_debug = "true" *)
    logic signed [64:0]
        captured_c00;

    logic [6:0]
        result_seen_count;


    // ========================================================================
    // STATIC CONTROLLER
    //
    // This logic remains physically unchanged during DFX.
    // ========================================================================

    dfx_demo_controller u_demo_controller (

        .clk                (clk_100mhz),
        .rst_n              (rst_n),

        .btn_start          (btn_start),

        .rm_id              (core_rm_id),

        .core_busy          (core_busy),
        .core_done          (core_done),

        .core_result_valid  (core_result_valid),
        .core_result_index  (core_result_index),
        .core_result_data   (core_result_data),

        .core_load_a        (core_load_a),
        .core_load_b        (core_load_b),

        .core_load_row      (core_load_row),
        .core_load_col      (core_load_col),

        .core_load_data     (core_load_data),

        .core_start         (core_start),

        .ready              (demo_ready),

        .pass_latched       (pass_latched),
        .fail_latched       (fail_latched),
        .done_latched       (done_latched),

        .captured_c00       (captured_c00),
        .result_seen_count  (result_seen_count)
    );


    // ========================================================================
    // RECONFIGURABLE PARTITION
    //
    // KEEP INSTANCE NAME:
    //
    //      u_tpu_rp
    //
    // Initial RM = INT8 / 8x8.
    //
    // Vivado DFX substitutes:
    //
    //      rm_int16_4x4
    //      rm_int32_2x2
    //
    // into THIS EXACT INSTANCE.
    // ========================================================================

    rm_int8_8x8 u_tpu_rp (

        .clk            (clk_100mhz),
        .rst_n          (rst_n),

        .load_a         (core_load_a),
        .load_b         (core_load_b),

        .load_row       (core_load_row),
        .load_col       (core_load_col),

        .load_data      (core_load_data),

        .start          (core_start),

        .busy           (core_busy),
        .done           (core_done),

        .result_valid   (core_result_valid),

        .result_index   (core_result_index),
        .result_row     (core_result_row),
        .result_col     (core_result_col),

        .result_data    (core_result_data),

        .rm_id          (core_rm_id)
    );


    // ========================================================================
    // Human-readable LED status
    // ========================================================================

    always_comb begin

        led = 8'b0;

        // Main test result
        led[7] = pass_latched;
        led[6] = fail_latched;

        // Runtime state
        led[5] = core_busy;
        led[4] = demo_ready;
        led[3] = done_latched;

        // DFX safety switch
        led[2] = sw_isolate;

        // Do not display possibly unstable RP outputs
        // while the partition is being reconfigured.
        if (sw_isolate)

            led[1:0] =
                2'b11;

        else

            led[1:0] =
                core_rm_id;

    end


endmodule