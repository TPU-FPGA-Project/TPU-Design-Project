`timescale 1ns/1ps

module int8_8x8_tb;

    localparam int N = 8;

    logic clk;
    logic rst_n;

    logic load_a;
    logic load_b;

    logic [2:0] load_row;
    logic [2:0] load_col;

    logic signed [7:0] load_data;

    logic start;

    logic busy;
    logic done;

    logic result_valid;

    logic [5:0] result_index;
    logic [2:0] result_row;
    logic [2:0] result_col;

    logic signed [31:0] result_data;


    // ============================================================
    // TEST MATRICES
    // ============================================================

    logic signed [7:0] A [0:N-1][0:N-1];
    logic signed [7:0] B [0:N-1][0:N-1];

    integer signed expected [0:N-1][0:N-1];
    integer signed observed [0:N-1][0:N-1];


    // ============================================================
    // DUT
    // ============================================================

    systolic_core #(
        .N(8),
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) dut (
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

        .result_data(result_data)
    );

    // ============================================================
    // GTKWave debug aliases
    // ============================================================

    wire signed [7:0] dbg_a_left_0;
    wire signed [7:0] dbg_a_left_1;
    wire signed [7:0] dbg_a_left_7;

    wire signed [7:0] dbg_b_top_0;
    wire signed [7:0] dbg_b_top_1;
    wire signed [7:0] dbg_b_top_7;

    wire dbg_a_valid_0;
    wire dbg_a_valid_1;
    wire dbg_a_valid_7;

    wire dbg_b_valid_0;
    wire dbg_b_valid_1;
    wire dbg_b_valid_7;

    assign dbg_a_left_0 = dut.a_left[0];
    assign dbg_a_left_1 = dut.a_left[1];
    assign dbg_a_left_7 = dut.a_left[7];

    assign dbg_b_top_0 = dut.b_top[0];
    assign dbg_b_top_1 = dut.b_top[1];
    assign dbg_b_top_7 = dut.b_top[7];

    assign dbg_a_valid_0 = dut.a_valid_left[0];
    assign dbg_a_valid_1 = dut.a_valid_left[1];
    assign dbg_a_valid_7 = dut.a_valid_left[7];

    assign dbg_b_valid_0 = dut.b_valid_top[0];
    assign dbg_b_valid_1 = dut.b_valid_top[1];
    assign dbg_b_valid_7 = dut.b_valid_top[7];

    wire signed [31:0] dbg_acc_00;
    wire signed [31:0] dbg_acc_11;
    wire signed [31:0] dbg_acc_33;
    wire signed [31:0] dbg_acc_77;

    assign dbg_acc_00 =
        dut.u_array.GEN_ROW[0].GEN_COL[0].u_pe.accumulator;

    assign dbg_acc_11 =
        dut.u_array.GEN_ROW[1].GEN_COL[1].u_pe.accumulator;

    assign dbg_acc_33 =
        dut.u_array.GEN_ROW[3].GEN_COL[3].u_pe.accumulator;

    assign dbg_acc_77 =
        dut.u_array.GEN_ROW[7].GEN_COL[7].u_pe.accumulator;

    // ============================================================
    // CLOCK
    // 100 MHz
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // RESULT CAPTURE
    // ============================================================

    always @(negedge clk) begin

        if (result_valid) begin

            $display(
                "READ idx=%0d row=%0d col=%0d data=%0d",
                result_index,
                result_row,
                result_col,
                $signed(result_data)
            );

            observed[result_row][result_col]
                = $signed(result_data);

        end

    end


    // ============================================================
    // PE00 DEBUG TRACE
    // ============================================================

    always @(posedge clk) begin

        #1;

        // ST_COMPUTE = enum value 2
        if (rst_n && dut.state == 3'd2) begin

            $display(
                "PE00 | cyc=%0d | a=%0d av=%b | b=%0d bv=%b | areg=%0d breg=%0d | prod=%0d pv=%b | acc=%0d | flat=%0d",
                dut.cycle_count,

                $signed(dut.a_left[0]),
                dut.a_valid_left[0],

                $signed(dut.b_top[0]),
                dut.b_valid_top[0],

                $signed(
                    dut.u_array
                       .GEN_ROW[0]
                       .GEN_COL[0]
                       .u_pe.a_reg
                ),

                $signed(
                    dut.u_array
                       .GEN_ROW[0]
                       .GEN_COL[0]
                       .u_pe.b_reg
                ),

                $signed(
                    dut.u_array
                       .GEN_ROW[0]
                       .GEN_COL[0]
                       .u_pe.product_reg
                ),

                dut.u_array
                   .GEN_ROW[0]
                   .GEN_COL[0]
                   .u_pe.product_valid_reg,

                $signed(
                    dut.u_array
                       .GEN_ROW[0]
                       .GEN_COL[0]
                       .u_pe.accumulator
                ),

                $signed(
                    dut.acc_flat[0 +: 32]
                )
            );

        end

    end


    // ============================================================
    // MATRIX WRITE TASKS
    // ============================================================

    task automatic write_a(
        input integer r,
        input integer c,
        input integer signed value
    );
        begin

            @(negedge clk);

            load_row  = r;
            load_col  = c;
            load_data = value;

            load_a = 1'b1;
            load_b = 1'b0;

        end
    endtask


    task automatic write_b(
        input integer r,
        input integer c,
        input integer signed value
    );
        begin

            @(negedge clk);

            load_row  = r;
            load_col  = c;
            load_data = value;

            load_a = 1'b0;
            load_b = 1'b1;

        end
    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Waveform
        // --------------------------------------------------------

        $dumpfile("int8_8x8.vcd");
        $dumpvars(0, int8_8x8_tb);


        // --------------------------------------------------------
        // Defaults
        // --------------------------------------------------------

        rst_n = 1'b0;

        load_a = 1'b0;
        load_b = 1'b0;

        load_row  = '0;
        load_col  = '0;
        load_data = '0;

        start = 1'b0;


        // ========================================================
        // GENERATE TEST MATRICES
        // ========================================================

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                /*
                 * Matrix A:
                 *
                 * A[r][c] = r - c
                 *
                 * Example row 0:
                 *
                 * 0 -1 -2 -3 -4 -5 -6 -7
                 */

                A[r][c] = r - c;


                /*
                 * Matrix B:
                 *
                 * diagonal     = 2
                 * off-diagonal = -1
                 */

                if (r == c)
                    B[r][c] = 2;
                else
                    B[r][c] = -1;


                expected[r][c] = 0;
                observed[r][c] = 0;

            end

        end


        // ========================================================
        // GOLDEN SOFTWARE MATRIX MULTIPLICATION
        // C = A x B
        // ========================================================

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                for (int k = 0; k < N; k = k + 1) begin

                    expected[r][c] =
                        expected[r][c]
                        +
                        $signed(A[r][k])
                        *
                        $signed(B[k][c]);

                end

            end

        end


        // ========================================================
        // RESET
        // ========================================================

        repeat (3)
            @(posedge clk);

        @(negedge clk);

        rst_n = 1'b1;


        @(posedge clk);
        #1;


        $display("");
        $display("===========================================");
        $display("RESET DEBUG");
        $display("===========================================");


        $display(
            "PE00 internal accumulator = %0d",
            $signed(
                dut.u_array
                   .GEN_ROW[0]
                   .GEN_COL[0]
                   .u_pe.accumulator
            )
        );


        $display(
            "PE00 flattened accumulator = %0d",
            $signed(
                dut.acc_flat[0 +: 32]
            )
        );


        // PE77 = index 63
        // bit offset = 63 * 32 = 2016

        $display(
            "PE77 flattened accumulator = %0d",
            $signed(
                dut.acc_flat[2016 +: 32]
            )
        );


        // ========================================================
        // LOAD MATRIX A
        // ========================================================

        $display("");
        $display("Loading A...");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                write_a(
                    r,
                    c,
                    A[r][c]
                );

            end

        end


        // ========================================================
        // LOAD MATRIX B
        // ========================================================

        $display("Loading B...");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                write_b(
                    r,
                    c,
                    B[r][c]
                );

            end

        end


        // Stop loading

        @(negedge clk);

        load_a = 1'b0;
        load_b = 1'b0;


        // ========================================================
        // LOADER SANITY CHECK
        // ========================================================

        $display("");
        $display("===========================================");
        $display("LOADER DEBUG");
        $display("===========================================");

        $display(
            "A[0][0] = %0d",
            $signed(dut.a_mem[0][0])
        );

        $display(
            "A[0][1] = %0d",
            $signed(dut.a_mem[0][1])
        );

        $display(
            "A[0][7] = %0d",
            $signed(dut.a_mem[0][7])
        );

        $display(
            "B[0][0] = %0d",
            $signed(dut.b_mem[0][0])
        );

        $display(
            "B[1][0] = %0d",
            $signed(dut.b_mem[1][0])
        );

        $display(
            "B[7][0] = %0d",
            $signed(dut.b_mem[7][0])
        );


        // ========================================================
        // START
        // ========================================================

        $display("");
        $display(
            "Starting 8x8 systolic multiplication..."
        );

        start = 1'b1;

        @(negedge clk);

        start = 1'b0;


        // ========================================================
        // WAIT FOR COMPLETION
        // ========================================================

        wait(done);

        // Allow final output sampling to settle
        @(negedge clk);


        // ========================================================
        // FINAL INTERNAL DEBUG
        // ========================================================

        $display("");
        $display("===========================================");
        $display("FINAL INTERNAL STATE");
        $display("===========================================");


        $display(
            "PE00 internal accumulator = %0d",
            $signed(
                dut.u_array
                   .GEN_ROW[0]
                   .GEN_COL[0]
                   .u_pe.accumulator
            )
        );


        $display(
            "PE00 flat accumulator = %0d",
            $signed(
                dut.acc_flat[0 +: 32]
            )
        );


        $display(
            "PE77 internal accumulator = %0d",
            $signed(
                dut.u_array
                   .GEN_ROW[7]
                   .GEN_COL[7]
                   .u_pe.accumulator
            )
        );


        $display(
            "PE77 flat accumulator = %0d",
            $signed(
                dut.acc_flat[2016 +: 32]
            )
        );


        $display(
            "result_buffer[0] = %0d",
            $signed(
                dut.result_buffer[0]
            )
        );


        $display(
            "result_buffer[63] = %0d",
            $signed(
                dut.result_buffer[63]
            )
        );


        // ========================================================
        // PRINT EXPECTED RESULT
        // ========================================================

        $display("");
        $display("EXPECTED RESULT:");
        $display("-----------------------------------------");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                $write(
                    "%6d ",
                    expected[r][c]
                );

            end

            $display("");

        end

        $display("-----------------------------------------");


        // ========================================================
        // PRINT RTL RESULT
        // ========================================================

        $display("");
        $display("RTL RESULT:");
        $display("-----------------------------------------");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                $write(
                    "%6d ",
                    observed[r][c]
                );

            end

            $display("");

        end

        $display("-----------------------------------------");


        // ========================================================
        // VERIFY
        // ========================================================

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                if (
                    observed[r][c]
                    !==
                    expected[r][c]
                ) begin

                    $fatal(
                        1,
                        "FAIL C[%0d][%0d]: expected %0d got %0d",
                        r,
                        c,
                        expected[r][c],
                        observed[r][c]
                    );

                end

            end

        end


        // ========================================================
        // SUCCESS
        // ========================================================

        $display("");
        $display("===========================================");
        $display("8x8 INT8 MATRIX MULTIPLICATION PASSED");
        $display("64 PEs successfully computed C = A x B");
        $display("===========================================");
        $display("");

        $finish;

    end

endmodule