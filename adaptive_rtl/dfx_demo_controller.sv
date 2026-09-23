`timescale 1ns/1ps

module dfx_demo_controller (
    input  logic clk,
    input  logic rst_n,

    // Physical start button. Synchronised internally.
    input  logic btn_start,

    // ============================================================
    // Information coming FROM the current RM
    // ============================================================

    input  logic [1:0] rm_id,

    input  logic core_busy,
    input  logic core_done,

    input  logic core_result_valid,
    input  logic [5:0] core_result_index,
    input  logic signed [64:0] core_result_data,

    // ============================================================
    // Commands going TO the current RM
    // ============================================================

    output logic core_load_a,
    output logic core_load_b,

    output logic [2:0] core_load_row,
    output logic [2:0] core_load_col,

    output logic signed [31:0] core_load_data,

    output logic core_start,

    // ============================================================
    // Static demo status
    // ============================================================

    output logic ready,

    output logic pass_latched,
    output logic fail_latched,
    output logic done_latched,

    output logic signed [64:0] captured_c00,
    output logic [6:0] result_seen_count
);


    // ============================================================
    // Synchronize + edge-detect the pushbutton
    // ============================================================

    logic start_meta;
    logic start_sync;
    logic start_delay;
    logic start_pulse;

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            start_meta  <= 1'b0;
            start_sync  <= 1'b0;
            start_delay <= 1'b0;

        end
        else begin

            start_meta  <= btn_start;
            start_sync  <= start_meta;
            start_delay <= start_sync;

        end

    end

    assign start_pulse =
        start_sync && !start_delay;


    // ============================================================
    // Fixed hardware tests
    //
    // Only A[0][0] and B[0][0] are non-zero.
    //
    // Everything else remains zero after reset.
    //
    // RM 00:
    //      INT8 / 8x8
    //      7 * -3 = -21
    //
    // RM 01:
    //      INT16 / 4x4
    //      1000 * -700 = -700000
    //
    // RM 10:
    //      INT32 / 2x2
    //      70000 * 70000 = 4,900,000,000
    // ============================================================

    function automatic logic signed [31:0]
        demo_a00(input logic [1:0] id);

        case (id)

            2'b00:
                demo_a00 = 32'sd7;

            2'b01:
                demo_a00 = 32'sd1000;

            2'b10:
                demo_a00 = 32'sd70000;

            default:
                demo_a00 = 32'sd0;

        endcase

    endfunction


    function automatic logic signed [31:0]
        demo_b00(input logic [1:0] id);

        case (id)

            2'b00:
                demo_b00 = -32'sd3;

            2'b01:
                demo_b00 = -32'sd700;

            2'b10:
                demo_b00 = 32'sd70000;

            default:
                demo_b00 = 32'sd0;

        endcase

    endfunction


    function automatic logic signed [64:0]
        expected_result(
            input logic [1:0] id,
            input logic [5:0] index
        );

        begin

            if (index != 6'd0) begin

                expected_result = 65'sd0;

            end
            else begin

                case (id)

                    2'b00:
                        expected_result = -65'sd21;

                    2'b01:
                        expected_result = -65'sd700000;

                    2'b10:
                        expected_result = 65'sd4900000000;

                    default:
                        expected_result = 65'sd0;

                endcase

            end

        end

    endfunction


    function automatic logic [6:0]
        expected_result_count(input logic [1:0] id);

        case (id)

            2'b00:
                expected_result_count = 7'd64;

            2'b01:
                expected_result_count = 7'd16;

            2'b10:
                expected_result_count = 7'd4;

            default:
                expected_result_count = 7'd0;

        endcase

    endfunction


    // ============================================================
    // Static demo state machine
    // ============================================================

    typedef enum logic [1:0] {
        DEMO_LOAD_A,
        DEMO_LOAD_B,
        DEMO_READY,
        DEMO_WAIT
    } demo_state_t;

    demo_state_t demo_state;


    assign ready =
        (demo_state == DEMO_READY);


    // ============================================================
    // Drive the common DFX interface
    // ============================================================

    always_comb begin

        core_load_a = 1'b0;
        core_load_b = 1'b0;

        core_load_row = 3'd0;
        core_load_col = 3'd0;

        core_load_data = 32'sd0;

        core_start = 1'b0;


        case (demo_state)

            DEMO_LOAD_A: begin

                core_load_a =
                    1'b1;

                core_load_data =
                    demo_a00(rm_id);

            end


            DEMO_LOAD_B: begin

                core_load_b =
                    1'b1;

                core_load_data =
                    demo_b00(rm_id);

            end


            DEMO_READY: begin

                if (rm_id != 2'b11)
                    core_start = start_pulse;

            end


            default: begin
            end

        endcase

    end


    // ============================================================
    // Controller / verification logic
    // ============================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            demo_state <= DEMO_LOAD_A;

            pass_latched <= 1'b0;
            fail_latched <= 1'b0;
            done_latched <= 1'b0;

            captured_c00 <= '0;

            result_seen_count <= 7'd0;

        end
        else begin

            case (demo_state)

                // ------------------------------------------------
                // First clock after reset:
                // write A[0][0]
                // ------------------------------------------------

                DEMO_LOAD_A: begin

                    demo_state <=
                        DEMO_LOAD_B;

                end


                // ------------------------------------------------
                // Second clock:
                // write B[0][0]
                // ------------------------------------------------

                DEMO_LOAD_B: begin

                    demo_state <=
                        DEMO_READY;

                end


                // ------------------------------------------------
                // Wait for BTNU
                // ------------------------------------------------

                DEMO_READY: begin

                    if (start_pulse) begin

                        pass_latched <= 1'b0;
                        fail_latched <= 1'b0;
                        done_latched <= 1'b0;

                        captured_c00 <= '0;

                        result_seen_count <=
                            7'd0;


                        if (rm_id == 2'b11) begin

                            fail_latched <= 1'b1;
                            done_latched <= 1'b1;

                        end
                        else begin

                            demo_state <=
                                DEMO_WAIT;

                        end

                    end

                end


                // ------------------------------------------------
                // Verify complete result stream
                // ------------------------------------------------

                DEMO_WAIT: begin

                    if (core_result_valid) begin

                        result_seen_count <=
                            result_seen_count + 1'b1;


                        if (core_result_index == 6'd0)

                            captured_c00 <=
                                $signed(core_result_data);


                        if (
                            $signed(core_result_data)
                            !==
                            expected_result(
                                rm_id,
                                core_result_index
                            )
                        ) begin

                            fail_latched <=
                                1'b1;

                        end

                    end


                    // core_done occurs after the final
                    // result_valid cycle.
                    if (core_done) begin

                        done_latched <=
                            1'b1;


                        if (
                            !fail_latched
                            &&
                            result_seen_count
                            ==
                            expected_result_count(rm_id)
                        ) begin

                            pass_latched <=
                                1'b1;

                        end
                        else begin

                            pass_latched <=
                                1'b0;

                            fail_latched <=
                                1'b1;

                        end


                        demo_state <=
                            DEMO_READY;

                    end

                end


                default: begin

                    demo_state <=
                        DEMO_LOAD_A;

                end

            endcase

        end

    end


endmodule