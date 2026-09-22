`timescale 1ns/1ps

module array_compile_tb;

    logic clk;
    logic rst_n;
    logic clear;

    // ============================================================
    // INT8 / 8x8
    // ============================================================

    logic signed [7:0] a8 [0:7];
    logic signed [7:0] b8 [0:7];

    logic a8_valid [0:7];
    logic b8_valid [0:7];

    logic signed [31:0] acc8 [0:7][0:7];


    // ============================================================
    // INT16 / 4x4
    // ============================================================

    logic signed [15:0] a16 [0:3];
    logic signed [15:0] b16 [0:3];

    logic a16_valid [0:3];
    logic b16_valid [0:3];

    logic signed [47:0] acc16 [0:3][0:3];


    // ============================================================
    // INT32 / 2x2
    // ============================================================

    logic signed [31:0] a32 [0:1];
    logic signed [31:0] b32 [0:1];

    logic a32_valid [0:1];
    logic b32_valid [0:1];

    logic signed [64:0] acc32 [0:1][0:1];


    // ============================================================
    // 8x8 INT8 array
    // ============================================================

    systolic_array #(
        .N(8),
        .DATA_WIDTH(8),
        .ACC_WIDTH(32)
    ) array_int8 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .a_left(a8),
        .b_top(b8),

        .a_valid_left(a8_valid),
        .b_valid_top(b8_valid),

        .acc(acc8)
    );


    // ============================================================
    // 4x4 INT16 array
    // ============================================================

    systolic_array #(
        .N(4),
        .DATA_WIDTH(16),
        .ACC_WIDTH(48)
    ) array_int16 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .a_left(a16),
        .b_top(b16),

        .a_valid_left(a16_valid),
        .b_valid_top(b16_valid),

        .acc(acc16)
    );


    // ============================================================
    // 2x2 INT32 array
    // ============================================================

    systolic_array #(
        .N(2),
        .DATA_WIDTH(32),
        .ACC_WIDTH(65)
    ) array_int32 (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),

        .a_left(a32),
        .b_top(b32),

        .a_valid_left(a32_valid),
        .b_valid_top(b32_valid),

        .acc(acc32)
    );


    // ============================================================
    // Clock
    // ============================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ============================================================
    // Simple elaboration test
    // ============================================================

    initial begin

        rst_n = 1'b0;
        clear = 1'b0;

        for (int i = 0; i < 8; i = i + 1) begin
            a8[i] = '0;
            b8[i] = '0;
            a8_valid[i] = 1'b0;
            b8_valid[i] = 1'b0;
        end

        for (int i = 0; i < 4; i = i + 1) begin
            a16[i] = '0;
            b16[i] = '0;
            a16_valid[i] = 1'b0;
            b16_valid[i] = 1'b0;
        end

        for (int i = 0; i < 2; i = i + 1) begin
            a32[i] = '0;
            b32[i] = '0;
            a32_valid[i] = 1'b0;
            b32_valid[i] = 1'b0;
        end

        repeat (3) @(posedge clk);

        @(negedge clk);
        rst_n = 1'b1;

        repeat (3) @(posedge clk);

        $display("");
        $display("===========================================");
        $display("GENERIC ARRAY ELABORATION PASSED");
        $display("INT8  : 8x8 = 64 PEs");
        $display("INT16 : 4x4 = 16 PEs");
        $display("INT32 : 2x2 = 4 PEs");
        $display("===========================================");
        $display("");

        $finish;

    end

endmodule
