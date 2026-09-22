`timescale 1ns/1ps

module pe_tb;

    logic clk;
    logic rst_n;
    logic clear;

    // ------------------------------------------------------------
    // INT8 PE signals
    // ------------------------------------------------------------
    logic signed [7:0]  a8, b8;
    logic               a8_valid, b8_valid;
    logic signed [7:0]  a8_out, b8_out;
    logic               a8_valid_out, b8_valid_out;
    logic signed [31:0] acc8;

    // ------------------------------------------------------------
    // INT16 PE signals
    // ------------------------------------------------------------
    logic signed [15:0] a16, b16;
    logic               a16_valid, b16_valid;
    logic signed [15:0] a16_out, b16_out;
    logic               a16_valid_out, b16_valid_out;
    logic signed [47:0] acc16;

    // ------------------------------------------------------------
    // INT32 PE signals
    // ------------------------------------------------------------
    logic signed [31:0] a32, b32;
    logic               a32_valid, b32_valid;
    logic signed [31:0] a32_out, b32_out;
    logic               a32_valid_out, b32_valid_out;
    logic signed [64:0] acc32;

    // ============================================================
    // DUT 1 : INT8
    // ============================================================

    systolic_pe #(
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) pe_int8 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .a_in(a8),
        .b_in(b8),
        .a_valid_in(a8_valid),
        .b_valid_in(b8_valid),

        .a_out(a8_out),
        .b_out(b8_out),
        .a_valid_out(a8_valid_out),
        .b_valid_out(b8_valid_out),

        .acc_out(acc8)
    );

    // ============================================================
    // DUT 2 : INT16
    // ============================================================

    systolic_pe #(
        .DATA_WIDTH(16),
        .ACC_WIDTH(48)
    ) pe_int16 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .a_in(a16),
        .b_in(b16),
        .a_valid_in(a16_valid),
        .b_valid_in(b16_valid),

        .a_out(a16_out),
        .b_out(b16_out),
        .a_valid_out(a16_valid_out),
        .b_valid_out(b16_valid_out),

        .acc_out(acc16)
    );

    // ============================================================
    // DUT 3 : INT32
    // ============================================================

    systolic_pe #(
        .DATA_WIDTH(32),
        .ACC_WIDTH(65)
    ) pe_int32 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .a_in(a32),
        .b_in(b32),
        .a_valid_in(a32_valid),
        .b_valid_in(b32_valid),

        .a_out(a32_out),
        .b_out(b32_out),
        .a_valid_out(a32_valid_out),
        .b_valid_out(b32_valid_out),

        .acc_out(acc32)
    );


    // ============================================================
    // 100 MHz clock
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Drive all three PEs at once
    // ============================================================

    task automatic drive_inputs(
        input integer signed a8_value,
        input integer signed b8_value,

        input integer signed a16_value,
        input integer signed b16_value,

        input longint signed a32_value,
        input longint signed b32_value,

        input logic valid
    );
        begin
            @(negedge clk);

            a8  = a8_value;
            b8  = b8_value;

            a16 = a16_value;
            b16 = b16_value;

            a32 = a32_value;
            b32 = b32_value;

            a8_valid  = valid;
            b8_valid  = valid;

            a16_valid = valid;
            b16_valid = valid;

            a32_valid = valid;
            b32_valid = valid;
        end
    endtask


    // ============================================================
    // Clear all PEs
    // ============================================================

    task automatic clear_pes;
        begin
            @(negedge clk);
            clear = 1'b1;

            @(negedge clk);
            clear = 1'b0;

            #1;
        end
    endtask


    // ============================================================
    // Test sequence
    // ============================================================

    initial begin

        // Optional waveform output
        $dumpfile("pe_param.vcd");
        $dumpvars(0, pe_tb);

        // Defaults
        rst_n = 1'b0;
        clear = 1'b0;

        a8 = '0;
        b8 = '0;
        a16 = '0;
        b16 = '0;
        a32 = '0;
        b32 = '0;

        a8_valid  = 1'b0;
        b8_valid  = 1'b0;
        a16_valid = 1'b0;
        b16_valid = 1'b0;
        a32_valid = 1'b0;
        b32_valid = 1'b0;


        // ========================================================
        // RESET
        // ========================================================

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst_n = 1'b1;


        // ========================================================
        // TEST 1
        //
        // Same arithmetic on every precision.
        //
        // 2*5 + 3*2 + (-1)*6 + 4*3
        //
        // = 10 + 6 - 6 + 12
        // = 22
        // ========================================================

        $display("");
        $display("==========================================");
        $display("TEST 1: COMMON ARITHMETIC TEST");
        $display("==========================================");

        drive_inputs( 2, 5,   2, 5,   2, 5, 1'b1);
        drive_inputs( 3, 2,   3, 2,   3, 2, 1'b1);
        drive_inputs(-1, 6,  -1, 6,  -1, 6, 1'b1);
        drive_inputs( 4, 3,   4, 3,   4, 3, 1'b1);

        // Drain the 3-stage PE pipeline
        drive_inputs(0, 0, 0, 0, 0, 0, 1'b0);
        drive_inputs(0, 0, 0, 0, 0, 0, 1'b0);

        repeat (2) @(posedge clk);
        #1;

        if (acc8 !== 32'sd22)
            $fatal(1, "INT8 FAILED: expected 22, got %0d",
                   $signed(acc8));

        if (acc16 !== 48'sd22)
            $fatal(1, "INT16 FAILED: expected 22, got %0d",
                   $signed(acc16));

        if (acc32 !== 65'sd22)
            $fatal(1, "INT32 FAILED: expected 22, got %0d",
                   $signed(acc32));

        $display("INT8  PE PASS : %0d", $signed(acc8));
        $display("INT16 PE PASS : %0d", $signed(acc16));
        $display("INT32 PE PASS : %0d", $signed(acc32));


        // ========================================================
        // CLEAR
        // ========================================================

        clear_pes();

        if (acc8 !== 0 || acc16 !== 0 || acc32 !== 0)
            $fatal(1, "CLEAR TEST FAILED");

        $display("");
        $display("CLEAR TEST PASS");


        // ========================================================
        // TEST 2
        //
        // Precision-specific values.
        //
        // These prove that the wider PEs genuinely support values
        // unavailable to the narrower PEs.
        // ========================================================

        $display("");
        $display("==========================================");
        $display("TEST 2: WIDTH-SPECIFIC ARITHMETIC");
        $display("==========================================");

        /*
         * INT8:
         *
         * 100*2 + (-50)*3
         * = 200 - 150
         * = 50
         *
         *
         * INT16:
         *
         * 1000*20 + (-300)*4
         * = 20000 - 1200
         * = 18800
         *
         *
         * INT32:
         *
         * 70000*70000 + (-100000)*10000
         *
         * = 4,900,000,000
         * - 1,000,000,000
         *
         * = 3,900,000,000
         */

        drive_inputs(
             100,      2,
            1000,     20,
           70000,  70000,
            1'b1
        );

        drive_inputs(
             -50,      3,
            -300,      4,
         -100000,  10000,
            1'b1
        );

        drive_inputs(0, 0, 0, 0, 0, 0, 1'b0);
        drive_inputs(0, 0, 0, 0, 0, 0, 1'b0);

        repeat (2) @(posedge clk);
        #1;


        // INT8 expected = 50
        if ($signed(acc8) !== 32'sd50)
            $fatal(1,
                "INT8 WIDTH TEST FAILED: expected 50, got %0d",
                $signed(acc8)
            );


        // INT16 expected = 18800
        if ($signed(acc16) !== 48'sd18800)
            $fatal(1,
                "INT16 WIDTH TEST FAILED: expected 18800, got %0d",
                $signed(acc16)
            );


        // INT32 expected = 3,900,000,000
        if ($signed(acc32) !== 65'sd3900000000)
            $fatal(1,
                "INT32 WIDTH TEST FAILED: expected 3900000000, got %0d",
                $signed(acc32)
            );


        $display(
            "INT8  WIDTH TEST PASS : %0d",
            $signed(acc8)
        );

        $display(
            "INT16 WIDTH TEST PASS : %0d",
            $signed(acc16)
        );

        $display(
            "INT32 WIDTH TEST PASS : %0d",
            $signed(acc32)
        );


        // ========================================================

        $display("");
        $display("==========================================");
        $display("ALL PARAMETERIZED PE TESTS PASSED");
        $display("==========================================");
        $display("");

        $finish;

    end

endmodule