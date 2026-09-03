`timescale 1ns/1ps

// ZedBoard hardware demonstration wrapper.
//
// After programming:
//   1. Press BTNC once to reset and load the fixed matrices.
//   2. Press BTNU once to start.
//   3. LED7=PASS, LED6=FAIL, LED5=BUSY, LED4=READY/DONE.
//   4. SW3:SW0 selects one of the sixteen saved results; LED3:LED0 shows
//      its low nibble. Use the ILA instructions for complete 32-bit results.
module zedboard_demo_top (
    input  logic       clk_100mhz,
    input  logic       btn_reset,
    input  logic       btn_start,
    input  logic [3:0] sw,
    output logic [7:0] led
);

    // Asynchronous assertion, synchronous deassertion of the local reset.
    logic [1:0] reset_pipe;
    logic       rst_n;

    always_ff @(posedge clk_100mhz or posedge btn_reset) begin
        if (btn_reset)
            reset_pipe <= 2'b11;
        else
            reset_pipe <= {reset_pipe[0], 1'b0};
    end

    assign rst_n = ~reset_pipe[1];

    // Synchronize and edge-detect the start pushbutton. One press creates one
    // single-cycle pulse even though the button remains high for many clocks.
    logic start_meta;
    logic start_sync;
    logic start_delay;
    logic start_pulse;

    always_ff @(posedge clk_100mhz) begin
        if (!rst_n) begin
            start_meta  <= 1'b0;
            start_sync  <= 1'b0;
            start_delay <= 1'b0;
        end else begin
            start_meta  <= btn_start;
            start_sync  <= start_meta;
            start_delay <= start_sync;
        end
    end

    assign start_pulse = start_sync && !start_delay;

    typedef enum logic [1:0] {
        DEMO_LOAD_A,
        DEMO_LOAD_B,
        DEMO_READY,
        DEMO_WAIT
    } demo_state_t;

    demo_state_t demo_state;
    logic [3:0] load_index;

    logic              core_load_a;
    logic              core_load_b;
    logic [1:0]        core_load_row;
    logic [1:0]        core_load_col;
    logic signed [7:0] core_load_data;
    logic              core_start;

    (* mark_debug = "true" *) logic              core_busy;
    (* mark_debug = "true" *) logic              core_done;
    (* mark_debug = "true" *) logic              core_result_valid;
    (* mark_debug = "true" *) logic [3:0]        core_result_index;
    (* mark_debug = "true" *) logic signed [31:0] core_result_data;

    logic signed [31:0] observed [0:15];
    logic pass_latched;
    logic fail_latched;
    logic done_latched;

    // A =
    // [ 1  2  3  4 ]
    // [ 5  6  7  8 ]
    // [-1  2 -3  4 ]
    // [ 2  0  1 -2 ]
    function automatic logic signed [7:0] demo_a(input logic [3:0] idx);
        case (idx)
            4'd0:  demo_a =  8'sd1;
            4'd1:  demo_a =  8'sd2;
            4'd2:  demo_a =  8'sd3;
            4'd3:  demo_a =  8'sd4;
            4'd4:  demo_a =  8'sd5;
            4'd5:  demo_a =  8'sd6;
            4'd6:  demo_a =  8'sd7;
            4'd7:  demo_a =  8'sd8;
            4'd8:  demo_a = -8'sd1;
            4'd9:  demo_a =  8'sd2;
            4'd10: demo_a = -8'sd3;
            4'd11: demo_a =  8'sd4;
            4'd12: demo_a =  8'sd2;
            4'd13: demo_a =  8'sd0;
            4'd14: demo_a =  8'sd1;
            default: demo_a = -8'sd2;
        endcase
    endfunction

    // B =
    // [ 1  0  2 -1 ]
    // [ 3  1  0  2 ]
    // [ 0 -2  1  3 ]
    // [ 2  4 -1  0 ]
    function automatic logic signed [7:0] demo_b(input logic [3:0] idx);
        case (idx)
            4'd0:  demo_b =  8'sd1;
            4'd1:  demo_b =  8'sd0;
            4'd2:  demo_b =  8'sd2;
            4'd3:  demo_b = -8'sd1;
            4'd4:  demo_b =  8'sd3;
            4'd5:  demo_b =  8'sd1;
            4'd6:  demo_b =  8'sd0;
            4'd7:  demo_b =  8'sd2;
            4'd8:  demo_b =  8'sd0;
            4'd9:  demo_b = -8'sd2;
            4'd10: demo_b =  8'sd1;
            4'd11: demo_b =  8'sd3;
            4'd12: demo_b =  8'sd2;
            4'd13: demo_b =  8'sd4;
            4'd14: demo_b = -8'sd1;
            default: demo_b = 8'sd0;
        endcase
    endfunction

    // Expected C = A x B in row-major order.
    function automatic logic signed [31:0] expected_c(input logic [3:0] idx);
        case (idx)
            4'd0:  expected_c = 32'sd15;
            4'd1:  expected_c = 32'sd12;
            4'd2:  expected_c = 32'sd1;
            4'd3:  expected_c = 32'sd12;
            4'd4:  expected_c = 32'sd39;
            4'd5:  expected_c = 32'sd24;
            4'd6:  expected_c = 32'sd9;
            4'd7:  expected_c = 32'sd28;
            4'd8:  expected_c = 32'sd13;
            4'd9:  expected_c = 32'sd24;
            4'd10: expected_c = -32'sd9;
            4'd11: expected_c = -32'sd4;
            4'd12: expected_c = -32'sd2;
            4'd13: expected_c = -32'sd10;
            4'd14: expected_c = 32'sd7;
            default: expected_c = 32'sd1;
        endcase
    endfunction

    always_comb begin
        core_load_a    = 1'b0;
        core_load_b    = 1'b0;
        core_load_row  = load_index[3:2];
        core_load_col  = load_index[1:0];
        core_load_data = '0;
        core_start     = 1'b0;

        case (demo_state)
            DEMO_LOAD_A: begin
                core_load_a    = 1'b1;
                core_load_data = demo_a(load_index);
            end
            DEMO_LOAD_B: begin
                core_load_b    = 1'b1;
                core_load_data = demo_b(load_index);
            end
            DEMO_READY: core_start = start_pulse;
            default: ;
        endcase
    end

    always_ff @(posedge clk_100mhz) begin
        if (!rst_n) begin
            demo_state   <= DEMO_LOAD_A;
            load_index   <= '0;
            pass_latched <= 1'b0;
            fail_latched <= 1'b0;
            done_latched <= 1'b0;

            for (int n = 0; n < 16; n++)
                observed[n] <= '0;
        end else begin
            case (demo_state)
                DEMO_LOAD_A: begin
                    if (load_index == 4'd15) begin
                        load_index <= '0;
                        demo_state <= DEMO_LOAD_B;
                    end else begin
                        load_index <= load_index + 1'b1;
                    end
                end

                DEMO_LOAD_B: begin
                    if (load_index == 4'd15) begin
                        load_index <= '0;
                        demo_state <= DEMO_READY;
                    end else begin
                        load_index <= load_index + 1'b1;
                    end
                end

                DEMO_READY: begin
                    if (start_pulse) begin
                        pass_latched <= 1'b0;
                        fail_latched <= 1'b0;
                        done_latched <= 1'b0;
                        demo_state   <= DEMO_WAIT;
                    end
                end

                DEMO_WAIT: begin
                    if (core_result_valid) begin
                        observed[core_result_index] <= core_result_data;
                        if (core_result_data != expected_c(core_result_index))
                            fail_latched <= 1'b1;
                    end

                    if (core_done) begin
                        done_latched <= 1'b1;
                        pass_latched <= !fail_latched;
                        demo_state   <= DEMO_READY;
                    end
                end
                default: demo_state <= DEMO_LOAD_A;
            endcase
        end
    end

    systolic_core_4x4 u_core (
        .clk          (clk_100mhz),
        .rst_n        (rst_n),
        .load_a       (core_load_a),
        .load_b       (core_load_b),
        .load_row     (core_load_row),
        .load_col     (core_load_col),
        .load_data    (core_load_data),
        .start        (core_start),
        .busy         (core_busy),
        .done         (core_done),
        .result_valid (core_result_valid),
        .result_index (core_result_index),
        .result_row   (),
        .result_col   (),
        .result_data  (core_result_data)
    );

    // Human-readable status. LED4 also means the result selector is ready.
    always_comb begin
        led      = '0;
        led[3:0] = observed[sw][3:0];
        led[4]   = done_latched || (demo_state == DEMO_READY);
        led[5]   = core_busy;
        led[6]   = fail_latched;
        led[7]   = pass_latched;
    end

endmodule
