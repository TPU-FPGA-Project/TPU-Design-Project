`timescale 1ns/1ps

module systolic_core #(
    parameter int N          = 4,
    parameter int DATA_WIDTH = 8,
    parameter int ACC_WIDTH  = 32,

    parameter int INDEX_WIDTH =
        (N <= 1) ? 1 : $clog2(N),

    parameter int RESULT_INDEX_WIDTH =
        (N*N <= 1) ? 1 : $clog2(N*N)
)(
    input logic clk,
    input logic rst_n,

    // ------------------------------------------------------------
    // Matrix loading interface
    // ------------------------------------------------------------

    input logic load_a,
    input logic load_b,

    input logic [INDEX_WIDTH-1:0] load_row,
    input logic [INDEX_WIDTH-1:0] load_col,

    input logic signed [DATA_WIDTH-1:0] load_data,

    // Start computation
    input logic start,

    // ------------------------------------------------------------
    // Status
    // ------------------------------------------------------------

    output logic busy,
    output logic done,

    // ------------------------------------------------------------
    // Result stream
    // ------------------------------------------------------------

    output logic result_valid,

    output logic [RESULT_INDEX_WIDTH-1:0]
        result_index,

    output logic [INDEX_WIDTH-1:0]
        result_row,

    output logic [INDEX_WIDTH-1:0]
        result_col,

    output logic signed [ACC_WIDTH-1:0]
        result_data
);

    // ============================================================
    // Derived constants
    // ============================================================

    localparam int COMPUTE_CYCLES = 3 * N;

    localparam int CYCLE_WIDTH =
        (COMPUTE_CYCLES <= 1)
            ? 1
            : $clog2(COMPUTE_CYCLES);


    // ============================================================
    // State machine
    // ============================================================

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_CLEAR,
        ST_COMPUTE,
        ST_CAPTURE,
        ST_READOUT,
        ST_DONE
    } state_t;

    state_t state;


    // ============================================================
    // Local matrix memories
    // ============================================================

    logic signed [DATA_WIDTH-1:0]
        a_mem [0:N-1][0:N-1];

    logic signed [DATA_WIDTH-1:0]
        b_mem [0:N-1][0:N-1];


    // ============================================================
    // Systolic-array boundaries
    // ============================================================

    logic signed [DATA_WIDTH-1:0]
        a_left [0:N-1];

    logic signed [DATA_WIDTH-1:0]
        b_top [0:N-1];

    logic
        a_valid_left [0:N-1];

    logic
        b_valid_top [0:N-1];


    // ============================================================
    // PE accumulators
    // ============================================================

    wire [N*N*ACC_WIDTH-1:0] acc_flat;


    // ============================================================
    // Result snapshot buffer
    // ============================================================

    logic signed [ACC_WIDTH-1:0]
        result_buffer [0:N*N-1];


    logic [CYCLE_WIDTH-1:0]
        cycle_count;

    logic [RESULT_INDEX_WIDTH-1:0]
        read_index;

    logic clear_array;


    // ============================================================
    // Load matrices while idle
    // ============================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            for (int r = 0; r < N; r = r + 1)
                for (int c = 0; c < N; c = c + 1) begin
                    a_mem[r][c] <= '0;
                    b_mem[r][c] <= '0;
                end

        end
        else if (state == ST_IDLE) begin

            if (load_a)
                a_mem[load_row][load_col]
                    <= load_data;

            if (load_b)
                b_mem[load_row][load_col]
                    <= load_data;

        end

    end


    // ============================================================
    // Main controller
    // ============================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            state       <= ST_IDLE;
            cycle_count <= '0;
            read_index  <= '0;

        end
        else begin

            case (state)

                // ------------------------------------------------
                ST_IDLE: begin

                    cycle_count <= '0;
                    read_index  <= '0;

                    if (start)
                        state <= ST_CLEAR;

                end


                // ------------------------------------------------
                ST_CLEAR: begin

                    cycle_count <= '0;
                    state       <= ST_COMPUTE;

                end


                // ------------------------------------------------
                ST_COMPUTE: begin

                    if (cycle_count ==
                        COMPUTE_CYCLES - 1) begin

                        cycle_count <= '0;
                        state <= ST_CAPTURE;

                    end
                    else begin

                        cycle_count <=
                            cycle_count + 1'b1;

                    end

                end


                // ------------------------------------------------
                ST_CAPTURE: begin

                    read_index <= '0;
                    state <= ST_READOUT;

                end


                // ------------------------------------------------
                ST_READOUT: begin

                    if (read_index == N*N - 1) begin

                        read_index <= '0;
                        state <= ST_DONE;

                    end
                    else begin

                        read_index <=
                            read_index + 1'b1;

                    end

                end


                // ------------------------------------------------
                ST_DONE: begin

                    state <= ST_IDLE;

                end


                default:
                    state <= ST_IDLE;

            endcase

        end

    end


    // ============================================================
    // Array clear pulse
    // ============================================================

    assign clear_array =
        (state == ST_CLEAR);


    // ============================================================
    // Generate skewed A streams
    //
    // Row r begins r cycles late:
    //
    // row 0 : A00 A01 A02 ...
    // row 1 :  -  A10 A11 ...
    // row 2 :  -   -  A20 ...
    //
    // ============================================================

    always_comb begin

        for (int r = 0; r < N; r = r + 1) begin

            a_left[r]       = '0;
            a_valid_left[r] = 1'b0;

            if (
                state == ST_COMPUTE &&
                cycle_count >= r &&
                cycle_count < r + N
            ) begin

                a_left[r] =
                    a_mem[r][cycle_count - r];

                a_valid_left[r] =
                    1'b1;

            end

        end

    end


    // ============================================================
    // Generate skewed B streams
    //
    // Column c begins c cycles late:
    //
    // col 0 : B00 B10 B20 ...
    // col 1 :  -  B01 B11 ...
    // col 2 :  -   -  B02 ...
    //
    // ============================================================

    always_comb begin

        for (int c = 0; c < N; c = c + 1) begin

            b_top[c]       = '0;
            b_valid_top[c] = 1'b0;

            if (
                state == ST_COMPUTE &&
                cycle_count >= c &&
                cycle_count < c + N
            ) begin

                b_top[c] =
                    b_mem[cycle_count - c][c];

                b_valid_top[c] =
                    1'b1;

            end

        end

    end


    // ============================================================
    // Generic N × N systolic array
    // ============================================================

    systolic_array #(
        .N          (N),
        .DATA_WIDTH (DATA_WIDTH),
        .ACC_WIDTH  (ACC_WIDTH)
    ) u_array (
        .clk          (clk),
        .rst_n        (rst_n),
        .clear        (clear_array),

        .a_left       (a_left),
        .b_top        (b_top),

        .a_valid_left (a_valid_left),
        .b_valid_top  (b_valid_top),

        .acc_flat          (acc_flat)
    );


    // ============================================================
    // Snapshot entire result matrix
    // ============================================================

    always_ff @(posedge clk) begin

        if (!rst_n) begin

            for (int i = 0; i < N*N; i = i + 1)
                result_buffer[i] <= '0;

        end
        else if (state == ST_CAPTURE) begin

            for (int r = 0; r < N; r = r + 1)
                for (int c = 0; c < N; c = c + 1)

                    result_buffer[r*N + c]
                        <= $signed(
                            acc_flat[
                                ((r*N + c) * ACC_WIDTH)
                                +: ACC_WIDTH
                            ]
                        );

        end

    end


    // ============================================================
    // Output/status
    // ============================================================

    assign busy =
        (state != ST_IDLE) &&
        (state != ST_DONE);

    assign done =
        (state == ST_DONE);

    assign result_valid =
        (state == ST_READOUT);

    assign result_index =
        read_index;

    assign result_row =
        read_index / N;

    assign result_col =
        read_index % N;

    assign result_data =
        result_buffer[read_index];

endmodule