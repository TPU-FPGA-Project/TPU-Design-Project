`timescale 1ns/1ps

module int16_4x4_tb;

    localparam int N = 4;

    logic clk;
    logic rst_n;

    logic load_a;
    logic load_b;

    logic [1:0] load_row;
    logic [1:0] load_col;

    logic signed [15:0] load_data;

    logic start;

    logic busy;
    logic done;

    logic result_valid;

    logic [3:0] result_index;
    logic [1:0] result_row;
    logic [1:0] result_col;

    logic signed [47:0] result_data;


    // ============================================================
    // TEST MATRICES
    // ============================================================

    logic signed [15:0] A [0:N-1][0:N-1];
    logic signed [15:0] B [0:N-1][0:N-1];

    longint signed expected [0:N-1][0:N-1];
    longint signed observed [0:N-1][0:N-1];


    // ============================================================
    // DUT
    // ============================================================

    systolic_core #(
        .N(4),
        .DATA_WIDTH(16),
        .ACC_WIDTH(48)
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
    // GTKWave aliases
    // ============================================================

    wire signed [15:0] dbg_a_left_0 = dut.a_left[0];
    wire signed [15:0] dbg_a_left_1 = dut.a_left[1];
    wire signed [15:0] dbg_a_left_3 = dut.a_left[3];

    wire signed [15:0] dbg_b_top_0 = dut.b_top[0];
    wire signed [15:0] dbg_b_top_1 = dut.b_top[1];
    wire signed [15:0] dbg_b_top_3 = dut.b_top[3];

    wire signed [47:0] dbg_acc_00 =
        dut.u_array.GEN_ROW[0].GEN_COL[0].u_pe.accumulator;

    wire signed [47:0] dbg_acc_11 =
        dut.u_array.GEN_ROW[1].GEN_COL[1].u_pe.accumulator;

    wire signed [47:0] dbg_acc_22 =
        dut.u_array.GEN_ROW[2].GEN_COL[2].u_pe.accumulator;

    wire signed [47:0] dbg_acc_33 =
        dut.u_array.GEN_ROW[3].GEN_COL[3].u_pe.accumulator;


    // ============================================================
    // CLOCK
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
    // MATRIX LOAD TASKS
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

        $dumpfile("int16_4x4.vcd");
        $dumpvars(0, int16_4x4_tb);


        rst_n = 1'b0;

        load_a = 1'b0;
        load_b = 1'b0;

        load_row  = '0;
        load_col  = '0;
        load_data = '0;

        start = 1'b0;


        // ========================================================
        // MATRIX A
        //
        // Values intentionally exceed INT8 range.
        // ========================================================

        A[0][0] =  1000;
        A[0][1] =  -250;
        A[0][2] =   700;
        A[0][3] =   100;

        A[1][0] =  -400;
        A[1][1] =  1200;
        A[1][2] =   300;
        A[1][3] =  -600;

        A[2][0] =   500;
        A[2][1] =   800;
        A[2][2] = -1100;
        A[2][3] =   200;

        A[3][0] =  -900;
        A[3][1] =   350;
        A[3][2] =   450;
        A[3][3] =  1300;


        // ========================================================
        // MATRIX B
        // ========================================================

        B[0][0] =   300;
        B[0][1] =  -700;
        B[0][2] =   500;
        B[0][3] =  1000;

        B[1][0] =   200;
        B[1][1] =   400;
        B[1][2] =  -300;
        B[1][3] =   800;

        B[2][0] =  -600;
        B[2][1] =   900;
        B[2][2] =  1100;
        B[2][3] =  -200;

        B[3][0] =   750;
        B[3][1] =  -500;
        B[3][2] =   250;
        B[3][3] =   600;


        // ========================================================
        // INITIALIZE EXPECTED / OBSERVED
        // ========================================================

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                expected[r][c] = 0;
                observed[r][c] = 0;

            end

        end


        // ========================================================
        // SOFTWARE GOLDEN MODEL
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


        // ========================================================
        // LOAD A
        // ========================================================

        $display("");
        $display("Loading INT16 matrix A...");

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
        // LOAD B
        // ========================================================

        $display("Loading INT16 matrix B...");

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
        // LOADER SANITY
        // ========================================================

        $display("");
        $display("===========================================");
        $display("INT16 LOADER CHECK");
        $display("===========================================");

        $display(
            "A[0][0] = %0d",
            $signed(dut.a_mem[0][0])
        );

        $display(
            "A[3][3] = %0d",
            $signed(dut.a_mem[3][3])
        );

        $display(
            "B[0][1] = %0d",
            $signed(dut.b_mem[0][1])
        );

        $display(
            "B[2][2] = %0d",
            $signed(dut.b_mem[2][2])
        );


        // ========================================================
        // START
        // ========================================================

        $display("");
        $display(
            "Starting INT16 4x4 systolic multiplication..."
        );

        start = 1'b1;

        @(negedge clk);

        start = 1'b0;


        // ========================================================
        // WAIT FOR COMPLETION
        // ========================================================

        wait(done);

        @(negedge clk);


        // ========================================================
        // PRINT EXPECTED
        // ========================================================

        $display("");
        $display("EXPECTED RESULT:");
        $display("-----------------------------------------------");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                $write(
                    "%12d ",
                    expected[r][c]
                );

            end

            $display("");

        end

        $display("-----------------------------------------------");


        // ========================================================
        // PRINT RTL
        // ========================================================

        $display("");
        $display("RTL RESULT:");
        $display("-----------------------------------------------");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                $write(
                    "%12d ",
                    observed[r][c]
                );

            end

            $display("");

        end

        $display("-----------------------------------------------");


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
        $display("4x4 INT16 MATRIX MULTIPLICATION PASSED");
        $display("16 PEs successfully computed C = A x B");
        $display("===========================================");
        $display("");

        $finish;

    end

endmodule