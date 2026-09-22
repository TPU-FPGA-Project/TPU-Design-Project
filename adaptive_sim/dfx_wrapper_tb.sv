`timescale 1ns/1ps

module dfx_wrapper_tb;

    logic clk;
    logic rst_n;


    // ============================================================
    // INT8 RM COMMON INTERFACE
    // ============================================================

    logic load_a8;
    logic load_b8;
    logic [2:0] row8;
    logic [2:0] col8;
    logic signed [31:0] data8;
    logic start8;

    wire busy8;
    wire done8;
    wire valid8;

    wire [5:0] index8;
    wire [2:0] result_row8;
    wire [2:0] result_col8;

    wire signed [64:0] result_data8;
    wire [1:0] rm_id8;


    // ============================================================
    // INT16 RM COMMON INTERFACE
    // ============================================================

    logic load_a16;
    logic load_b16;
    logic [2:0] row16;
    logic [2:0] col16;
    logic signed [31:0] data16;
    logic start16;

    wire busy16;
    wire done16;
    wire valid16;

    wire [5:0] index16;
    wire [2:0] result_row16;
    wire [2:0] result_col16;

    wire signed [64:0] result_data16;
    wire [1:0] rm_id16;


    // ============================================================
    // INT32 RM COMMON INTERFACE
    // ============================================================

    logic load_a32;
    logic load_b32;
    logic [2:0] row32;
    logic [2:0] col32;
    logic signed [31:0] data32;
    logic start32;

    wire busy32;
    wire done32;
    wire valid32;

    wire [5:0] index32;
    wire [2:0] result_row32;
    wire [2:0] result_col32;

    wire signed [64:0] result_data32;
    wire [1:0] rm_id32;


    // ============================================================
    // CAPTURED RESULTS
    // ============================================================

    longint signed int8_c00;
    longint signed int16_c00;
    longint signed int32_c00;

    longint signed int16_c33;

    logic [5:0] last_index8;
    logic [5:0] last_index16;
    logic [5:0] last_index32;

    logic [2:0] last_row8;
    logic [2:0] last_row16;
    logic [2:0] last_row32;

    logic [2:0] last_col8;
    logic [2:0] last_col16;
    logic [2:0] last_col32;


    // ============================================================
    // DUTS
    // ============================================================

    rm_int8_8x8 dut8 (
        .clk(clk),
        .rst_n(rst_n),

        .load_a(load_a8),
        .load_b(load_b8),

        .load_row(row8),
        .load_col(col8),
        .load_data(data8),

        .start(start8),

        .busy(busy8),
        .done(done8),

        .result_valid(valid8),

        .result_index(index8),
        .result_row(result_row8),
        .result_col(result_col8),

        .result_data(result_data8),

        .rm_id(rm_id8)
    );


    rm_int16_4x4 dut16 (
        .clk(clk),
        .rst_n(rst_n),

        .load_a(load_a16),
        .load_b(load_b16),

        .load_row(row16),
        .load_col(col16),
        .load_data(data16),

        .start(start16),

        .busy(busy16),
        .done(done16),

        .result_valid(valid16),

        .result_index(index16),
        .result_row(result_row16),
        .result_col(result_col16),

        .result_data(result_data16),

        .rm_id(rm_id16)
    );


    rm_int32_2x2 dut32 (
        .clk(clk),
        .rst_n(rst_n),

        .load_a(load_a32),
        .load_b(load_b32),

        .load_row(row32),
        .load_col(col32),
        .load_data(data32),

        .start(start32),

        .busy(busy32),
        .done(done32),

        .result_valid(valid32),

        .result_index(index32),
        .result_row(result_row32),
        .result_col(result_col32),

        .result_data(result_data32),

        .rm_id(rm_id32)
    );


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

        if (valid8) begin

            last_index8 = index8;
            last_row8   = result_row8;
            last_col8   = result_col8;

            if (index8 == 0)
                int8_c00 = $signed(result_data8);

        end


        if (valid16) begin

            last_index16 = index16;
            last_row16   = result_row16;
            last_col16   = result_col16;

            if (index16 == 0)
                int16_c00 = $signed(result_data16);

            if (index16 == 15)
                int16_c33 = $signed(result_data16);

        end


        if (valid32) begin

            last_index32 = index32;
            last_row32   = result_row32;
            last_col32   = result_col32;

            if (index32 == 0)
                int32_c00 = $signed(result_data32);

        end

    end


    // ============================================================
    // COMMON WRITE HELPERS
    // ============================================================

    task automatic write8(
        input logic is_a,
        input integer r,
        input integer c,
        input integer signed value
    );
        begin

            @(negedge clk);

            row8  = r;
            col8  = c;
            data8 = value;

            load_a8 = is_a;
            load_b8 = !is_a;

        end
    endtask


    task automatic write16(
        input logic is_a,
        input integer r,
        input integer c,
        input integer signed value
    );
        begin

            @(negedge clk);

            row16  = r;
            col16  = c;
            data16 = value;

            load_a16 = is_a;
            load_b16 = !is_a;

        end
    endtask


    task automatic write32(
        input logic is_a,
        input integer r,
        input integer c,
        input longint signed value
    );
        begin

            @(negedge clk);

            row32  = r;
            col32  = c;
            data32 = value;

            load_a32 = is_a;
            load_b32 = !is_a;

        end
    endtask


    // ============================================================
    // TEST
    // ============================================================

    initial begin

        $dumpfile("dfx_wrapper.vcd");
        $dumpvars(0, dfx_wrapper_tb);


        // --------------------------------------------------------
        // Defaults
        // --------------------------------------------------------

        rst_n = 1'b0;

        load_a8 = 0;
        load_b8 = 0;
        row8 = 0;
        col8 = 0;
        data8 = 0;
        start8 = 0;

        load_a16 = 0;
        load_b16 = 0;
        row16 = 0;
        col16 = 0;
        data16 = 0;
        start16 = 0;

        load_a32 = 0;
        load_b32 = 0;
        row32 = 0;
        col32 = 0;
        data32 = 0;
        start32 = 0;


        int8_c00  = 0;
        int16_c00 = 0;
        int16_c33 = 0;
        int32_c00 = 0;

        last_index8  = 0;
        last_index16 = 0;
        last_index32 = 0;

        last_row8  = 0;
        last_row16 = 0;
        last_row32 = 0;

        last_col8  = 0;
        last_col16 = 0;
        last_col32 = 0;


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        repeat (3)
            @(posedge clk);

        @(negedge clk);

        rst_n = 1'b1;


        // ========================================================
        // CHECK RM IDENTITIES
        // ========================================================

        $display("");
        $display("===========================================");
        $display("DFX RM ID CHECK");
        $display("===========================================");

        $display("INT8  RM ID = %b", rm_id8);
        $display("INT16 RM ID = %b", rm_id16);
        $display("INT32 RM ID = %b", rm_id32);


        if (rm_id8 !== 2'b00)
            $fatal(1, "INT8 RM ID incorrect");

        if (rm_id16 !== 2'b01)
            $fatal(1, "INT16 RM ID incorrect");

        if (rm_id32 !== 2'b10)
            $fatal(1, "INT32 RM ID incorrect");


        // ========================================================
        // TEST INT8 / 8x8
        //
        // Only A00 and B00 are non-zero.
        //
        // C00 = 7 * (-3) = -21
        // ========================================================

        $display("");
        $display("Testing common interface: INT8 / 8x8");

        write8(1'b1, 0, 0,  7);
        write8(1'b0, 0, 0, -3);

        @(negedge clk);

        load_a8 = 0;
        load_b8 = 0;

        start8 = 1;

        @(negedge clk);

        start8 = 0;

        wait(done8);

        @(negedge clk);


        if (int8_c00 !== -21)
            $fatal(
                1,
                "INT8 wrapper failed: expected -21 got %0d",
                int8_c00
            );


        if (
            last_index8 !== 6'd63 ||
            last_row8   !== 3'd7  ||
            last_col8   !== 3'd7
        )
            $fatal(
                1,
                "INT8 result indexing failed"
            );


        $display(
            "INT8 wrapper PASS: C00 = %0d",
            int8_c00
        );


        // ========================================================
        // TEST INT16 / 4x4
        //
        // C00 = 1000 * (-700)
        //     = -700000
        //
        // Also attempt illegal [7][7] writes.
        //
        // If the wrapper incorrectly truncates addresses,
        // those writes would alias to [3][3].
        // ========================================================

        $display("");
        $display("Testing common interface: INT16 / 4x4");

        write16(1'b1, 0, 0,  1000);
        write16(1'b0, 0, 0,  -700);


        // Invalid addresses — MUST be ignored

        write16(1'b1, 7, 7, 1234);
        write16(1'b0, 7, 7,    2);


        @(negedge clk);

        load_a16 = 0;
        load_b16 = 0;

        start16 = 1;

        @(negedge clk);

        start16 = 0;

        wait(done16);

        @(negedge clk);


        if (int16_c00 !== -700000)
            $fatal(
                1,
                "INT16 wrapper failed: expected -700000 got %0d",
                int16_c00
            );


        if (int16_c33 !== 0)
            $fatal(
                1,
                "INT16 address guard failed: C33=%0d",
                int16_c33
            );


        if (
            last_index16 !== 6'd15 ||
            last_row16   !== 3'd3  ||
            last_col16   !== 3'd3
        )
            $fatal(
                1,
                "INT16 result indexing failed"
            );


        $display(
            "INT16 wrapper PASS: C00 = %0d",
            int16_c00
        );

        $display(
            "INT16 invalid-address guard PASS"
        );


        // ========================================================
        // TEST INT32 / 2x2
        //
        // C00 =
        //
        // 70000 * 70000
        //
        // = 4,900,000,000
        //
        // This exceeds signed INT32.
        // ========================================================

        $display("");
        $display("Testing common interface: INT32 / 2x2");

        write32(1'b1, 0, 0, 70000);
        write32(1'b0, 0, 0, 70000);


        @(negedge clk);

        load_a32 = 0;
        load_b32 = 0;

        start32 = 1;

        @(negedge clk);

        start32 = 0;

        wait(done32);

        @(negedge clk);


        if (int32_c00 !== 64'sd4900000000)
            $fatal(
                1,
                "INT32 wrapper failed: expected 4900000000 got %0d",
                int32_c00
            );


        if (
            last_index32 !== 6'd3 ||
            last_row32   !== 3'd1 ||
            last_col32   !== 3'd1
        )
            $fatal(
                1,
                "INT32 result indexing failed"
            );


        $display(
            "INT32 wrapper PASS: C00 = %0d",
            int32_c00
        );


        // ========================================================
        // SUCCESS
        // ========================================================

        $display("");
        $display("===========================================");
        $display("ALL COMMON DFX WRAPPER TESTS PASSED");
        $display("===========================================");
        $display("");
        $display("RM 00 : INT8  / 8x8  PASS");
        $display("RM 01 : INT16 / 4x4  PASS");
        $display("RM 10 : INT32 / 2x2  PASS");
        $display("");
        $display("All three modules expose:");
        $display("  32-bit common operand input");
        $display("  65-bit common result output");
        $display("  3-bit common row/column addressing");
        $display("  6-bit common result indexing");
        $display("");
        $display("DFX interface contract verified.");
        $display("===========================================");
        $display("");

        $finish;

    end

endmodule