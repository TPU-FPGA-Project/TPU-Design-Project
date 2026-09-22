`timescale 1ns/1ps

module int32_2x2_tb;

    localparam int N = 2;

    logic clk;
    logic rst_n;

    logic load_a;
    logic load_b;

    logic [0:0] load_row;
    logic [0:0] load_col;

    logic signed [31:0] load_data;

    logic start;

    logic busy;
    logic done;

    logic result_valid;

    logic [1:0] result_index;
    logic [0:0] result_row;
    logic [0:0] result_col;

    logic signed [64:0] result_data;


    // ============================================================
    // TEST MATRICES
    // ============================================================

    logic signed [31:0] A [0:N-1][0:N-1];
    logic signed [31:0] B [0:N-1][0:N-1];

    longint signed expected [0:N-1][0:N-1];
    longint signed observed [0:N-1][0:N-1];


    // ============================================================
    // DUT
    // ============================================================

    systolic_core #(
        .N(2),
        .DATA_WIDTH(32),
        .ACC_WIDTH(65)
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
    // GTKWave DEBUG ALIASES
    // ============================================================

    wire signed [31:0] dbg_a_left_0 = dut.a_left[0];
    wire signed [31:0] dbg_a_left_1 = dut.a_left[1];

    wire signed [31:0] dbg_b_top_0 = dut.b_top[0];
    wire signed [31:0] dbg_b_top_1 = dut.b_top[1];

    wire signed [64:0] dbg_acc_00 =
        dut.u_array.GEN_ROW[0].GEN_COL[0].u_pe.accumulator;

    wire signed [64:0] dbg_acc_01 =
        dut.u_array.GEN_ROW[0].GEN_COL[1].u_pe.accumulator;

    wire signed [64:0] dbg_acc_10 =
        dut.u_array.GEN_ROW[1].GEN_COL[0].u_pe.accumulator;

    wire signed [64:0] dbg_acc_11 =
        dut.u_array.GEN_ROW[1].GEN_COL[1].u_pe.accumulator;


    // ============================================================
    // CLOCK — 100 MHz
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // 32x32 -> 64 BIT GOLDEN MULTIPLY
    //
    // Using longint intermediates deliberately avoids accidentally
    // truncating the reference calculation to 32 bits.
    // ============================================================

    function automatic longint signed mul32(
        input logic signed [31:0] x,
        input logic signed [31:0] y
    );

        longint signed lx;
        longint signed ly;

        begin
            lx = x;
            ly = y;

            mul32 = lx * ly;
        end

    endfunction


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
    // LOAD TASKS
    // ============================================================

    task automatic write_a(
        input integer r,
        input integer c,
        input longint signed value
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
        input longint signed value
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

        $dumpfile("int32_2x2.vcd");
        $dumpvars(0, int32_2x2_tb);


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
        // MATRIX A
        //
        // All significant values exceed signed INT16 range.
        // ========================================================

        A[0][0] =   70000;
        A[0][1] = -100000;

        A[1][0] =  200000;
        A[1][1] = -350000;


        // ========================================================
        // MATRIX B
        // ========================================================

        B[0][0] =  50000;
        B[0][1] = -60000;

        B[1][0] = -90000;
        B[1][1] = 120000;


        // ========================================================
        // INITIALIZE GOLDEN / OBSERVED
        // ========================================================

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                expected[r][c] = 0;
                observed[r][c] = 0;

            end

        end


        // ========================================================
        // SOFTWARE GOLDEN MODEL
        //
        // C = A x B
        // ========================================================

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                for (int k = 0; k < N; k = k + 1) begin

                    expected[r][c] =
                        expected[r][c]
                        +
                        mul32(
                            A[r][k],
                            B[k][c]
                        );

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
        // LOAD MATRIX A
        // ========================================================

        $display("");
        $display("Loading INT32 matrix A...");

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

        $display("Loading INT32 matrix B...");

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
        // LOADER CHECK
        // ========================================================

        $display("");
        $display("===========================================");
        $display("INT32 LOADER CHECK");
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
            "A[1][0] = %0d",
            $signed(dut.a_mem[1][0])
        );

        $display(
            "A[1][1] = %0d",
            $signed(dut.a_mem[1][1])
        );

        $display(
            "B[0][0] = %0d",
            $signed(dut.b_mem[0][0])
        );

        $display(
            "B[1][1] = %0d",
            $signed(dut.b_mem[1][1])
        );


        // ========================================================
        // START
        // ========================================================

        $display("");
        $display(
            "Starting INT32 2x2 systolic multiplication..."
        );

        start = 1'b1;

        @(negedge clk);

        start = 1'b0;


        // ========================================================
        // WAIT
        // ========================================================

        wait(done);

        @(negedge clk);


        // ========================================================
        // FINAL ACCUMULATOR DEBUG
        // ========================================================

        $display("");
        $display("===========================================");
        $display("FINAL ACCUMULATORS");
        $display("===========================================");

        $display(
            "PE00 = %0d",
            $signed(dbg_acc_00)
        );

        $display(
            "PE01 = %0d",
            $signed(dbg_acc_01)
        );

        $display(
            "PE10 = %0d",
            $signed(dbg_acc_10)
        );

        $display(
            "PE11 = %0d",
            $signed(dbg_acc_11)
        );


        // ========================================================
        // EXPECTED RESULT
        // ========================================================

        $display("");
        $display("EXPECTED RESULT:");
        $display("-------------------------------------------");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                $write(
                    "%16d ",
                    expected[r][c]
                );

            end

            $display("");

        end

        $display("-------------------------------------------");


        // ========================================================
        // RTL RESULT
        // ========================================================

        $display("");
        $display("RTL RESULT:");
        $display("-------------------------------------------");

        for (int r = 0; r < N; r = r + 1) begin

            for (int c = 0; c < N; c = c + 1) begin

                $write(
                    "%16d ",
                    observed[r][c]
                );

            end

            $display("");

        end

        $display("-------------------------------------------");


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
        $display("2x2 INT32 MATRIX MULTIPLICATION PASSED");
        $display("4 PEs successfully computed C = A x B");
        $display("===========================================");
        $display("");

        $finish;

    end

endmodule