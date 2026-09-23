`timescale 1ns/1ps

module dfx_demo_controller_tb;

    logic clk;
    logic rst_n;
    logic btn_start;


    // ============================================================
    // INT8 signals
    // ============================================================

    logic l_a8;
    logic l_b8;

    logic [2:0] row8;
    logic [2:0] col8;

    logic signed [31:0] data8;

    logic start8;

    wire busy8;
    wire done8;
    wire valid8;

    wire [5:0] index8;
    wire [2:0] rr8;
    wire [2:0] rc8;

    wire signed [64:0] result8;
    wire [1:0] id8;

    wire ready8;
    wire pass8;
    wire fail8;
    wire done_l8;

    wire signed [64:0] c008;
    wire [6:0] count8;


    // ============================================================
    // INT16 signals
    // ============================================================

    logic l_a16;
    logic l_b16;

    logic [2:0] row16;
    logic [2:0] col16;

    logic signed [31:0] data16;

    logic start16;

    wire busy16;
    wire done16;
    wire valid16;

    wire [5:0] index16;
    wire [2:0] rr16;
    wire [2:0] rc16;

    wire signed [64:0] result16;
    wire [1:0] id16;

    wire ready16;
    wire pass16;
    wire fail16;
    wire done_l16;

    wire signed [64:0] c0016;
    wire [6:0] count16;


    // ============================================================
    // INT32 signals
    // ============================================================

    logic l_a32;
    logic l_b32;

    logic [2:0] row32;
    logic [2:0] col32;

    logic signed [31:0] data32;

    logic start32;

    wire busy32;
    wire done32;
    wire valid32;

    wire [5:0] index32;
    wire [2:0] rr32;
    wire [2:0] rc32;

    wire signed [64:0] result32;
    wire [1:0] id32;

    wire ready32;
    wire pass32;
    wire fail32;
    wire done_l32;

    wire signed [64:0] c0032;
    wire [6:0] count32;


    // ============================================================
    // Clock
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5
            clk = ~clk;

    end


    // ============================================================
    // INT8 controller
    // ============================================================

    dfx_demo_controller ctrl8 (

        .clk(clk),
        .rst_n(rst_n),

        .btn_start(btn_start),

        .rm_id(id8),

        .core_busy(busy8),
        .core_done(done8),

        .core_result_valid(valid8),
        .core_result_index(index8),
        .core_result_data(result8),

        .core_load_a(l_a8),
        .core_load_b(l_b8),

        .core_load_row(row8),
        .core_load_col(col8),

        .core_load_data(data8),

        .core_start(start8),

        .ready(ready8),

        .pass_latched(pass8),
        .fail_latched(fail8),
        .done_latched(done_l8),

        .captured_c00(c008),
        .result_seen_count(count8)
    );


    rm_int8_8x8 rm8 (

        .clk(clk),
        .rst_n(rst_n),

        .load_a(l_a8),
        .load_b(l_b8),

        .load_row(row8),
        .load_col(col8),

        .load_data(data8),

        .start(start8),

        .busy(busy8),
        .done(done8),

        .result_valid(valid8),

        .result_index(index8),
        .result_row(rr8),
        .result_col(rc8),

        .result_data(result8),

        .rm_id(id8)
    );


    // ============================================================
    // INT16 controller
    // ============================================================

    dfx_demo_controller ctrl16 (

        .clk(clk),
        .rst_n(rst_n),

        .btn_start(btn_start),

        .rm_id(id16),

        .core_busy(busy16),
        .core_done(done16),

        .core_result_valid(valid16),
        .core_result_index(index16),
        .core_result_data(result16),

        .core_load_a(l_a16),
        .core_load_b(l_b16),

        .core_load_row(row16),
        .core_load_col(col16),

        .core_load_data(data16),

        .core_start(start16),

        .ready(ready16),

        .pass_latched(pass16),
        .fail_latched(fail16),
        .done_latched(done_l16),

        .captured_c00(c0016),
        .result_seen_count(count16)
    );


    rm_int16_4x4 rm16 (

        .clk(clk),
        .rst_n(rst_n),

        .load_a(l_a16),
        .load_b(l_b16),

        .load_row(row16),
        .load_col(col16),

        .load_data(data16),

        .start(start16),

        .busy(busy16),
        .done(done16),

        .result_valid(valid16),

        .result_index(index16),
        .result_row(rr16),
        .result_col(rc16),

        .result_data(result16),

        .rm_id(id16)
    );


    // ============================================================
    // INT32 controller
    // ============================================================

    dfx_demo_controller ctrl32 (

        .clk(clk),
        .rst_n(rst_n),

        .btn_start(btn_start),

        .rm_id(id32),

        .core_busy(busy32),
        .core_done(done32),

        .core_result_valid(valid32),
        .core_result_index(index32),
        .core_result_data(result32),

        .core_load_a(l_a32),
        .core_load_b(l_b32),

        .core_load_row(row32),
        .core_load_col(col32),

        .core_load_data(data32),

        .core_start(start32),

        .ready(ready32),

        .pass_latched(pass32),
        .fail_latched(fail32),
        .done_latched(done_l32),

        .captured_c00(c0032),
        .result_seen_count(count32)
    );


    rm_int32_2x2 rm32 (

        .clk(clk),
        .rst_n(rst_n),

        .load_a(l_a32),
        .load_b(l_b32),

        .load_row(row32),
        .load_col(col32),

        .load_data(data32),

        .start(start32),

        .busy(busy32),
        .done(done32),

        .result_valid(valid32),

        .result_index(index32),
        .result_row(rr32),
        .result_col(rc32),

        .result_data(result32),

        .rm_id(id32)
    );


    // ============================================================
    // Test
    // ============================================================

    initial begin

        $dumpfile(
            "dfx_demo_controller.vcd"
        );

        $dumpvars(
            0,
            dfx_demo_controller_tb
        );


        rst_n = 1'b0;
        btn_start = 1'b0;


        repeat (5)
            @(posedge clk);


        @(negedge clk);

        rst_n = 1'b1;


        // All controllers automatically load A00/B00.

        wait (
            ready8
            &&
            ready16
            &&
            ready32
        );


        $display("");
        $display("All three demo controllers READY.");


        // Push BTNU equivalent.

        @(negedge clk);

        btn_start = 1'b1;


        repeat (4)
            @(negedge clk);


        btn_start = 1'b0;


        // Wait for all three complete result streams.

        wait (
            done_l8
            &&
            done_l16
            &&
            done_l32
        );


        @(negedge clk);


        $display("");
        $display("==============================================");
        $display("DFX ZEDBOARD DEMO CONTROLLER RESULTS");
        $display("==============================================");

        $display(
            "INT8  RM=%b C00=%0d count=%0d PASS=%0d FAIL=%0d",
            id8,
            $signed(c008),
            count8,
            pass8,
            fail8
        );

        $display(
            "INT16 RM=%b C00=%0d count=%0d PASS=%0d FAIL=%0d",
            id16,
            $signed(c0016),
            count16,
            pass16,
            fail16
        );

        $display(
            "INT32 RM=%b C00=%0d count=%0d PASS=%0d FAIL=%0d",
            id32,
            $signed(c0032),
            count32,
            pass32,
            fail32
        );


        if (
            !pass8
            ||
            fail8
            ||
            c008 !== -65'sd21
            ||
            count8 !== 7'd64
        )
            $fatal(
                1,
                "INT8 hardware-demo controller failed"
            );


        if (
            !pass16
            ||
            fail16
            ||
            c0016 !== -65'sd700000
            ||
            count16 !== 7'd16
        )
            $fatal(
                1,
                "INT16 hardware-demo controller failed"
            );


        if (
            !pass32
            ||
            fail32
            ||
            c0032 !== 65'sd4900000000
            ||
            count32 !== 7'd4
        )
            $fatal(
                1,
                "INT32 hardware-demo controller failed"
            );


        $display("");
        $display("==============================================");
        $display("ALL THREE HARDWARE DEMO MODES PASSED");
        $display("==============================================");
        $display("INT8  / 8x8  : PASS");
        $display("INT16 / 4x4  : PASS");
        $display("INT32 / 2x2  : PASS");
        $display("");
        $display("Static controller is ready for ZedBoard DFX.");
        $display("==============================================");
        $display("");

        $finish;

    end

endmodule