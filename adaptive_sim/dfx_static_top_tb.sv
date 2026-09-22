`timescale 1ns/1ps

module dfx_static_top_tb;

    logic clk;
    logic rst_n;

    logic load_a;
    logic load_b;

    logic [2:0] load_row;
    logic [2:0] load_col;

    logic signed [31:0] load_data;

    logic start;

    wire busy;
    wire done;

    wire result_valid;

    wire [5:0] result_index;
    wire [2:0] result_row;
    wire [2:0] result_col;

    wire signed [64:0] result_data;

    wire [1:0] rm_id;


    // ========================================================================
    // DUT
    // ========================================================================

    dfx_static_top dut (

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

        .result_data(result_data),

        .rm_id(rm_id)
    );


    // ========================================================================
    // Clock
    // ========================================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    // ========================================================================
    // Capture C00
    // ========================================================================

    longint signed captured_c00;

    always @(negedge clk) begin

        if (result_valid && result_index == 0)
            captured_c00 = $signed(result_data);

    end


    // ========================================================================
    // Main test
    // ========================================================================

    initial begin

        $dumpfile("dfx_static_top.vcd");
        $dumpvars(0, dfx_static_top_tb);

        rst_n = 1'b0;

        load_a = 1'b0;
        load_b = 1'b0;

        load_row  = 3'd0;
        load_col  = 3'd0;
        load_data = 32'sd0;

        start = 1'b0;

        captured_c00 = 0;


        // --------------------------------------------------------------------
        // Reset
        // --------------------------------------------------------------------

        repeat (3)
            @(posedge clk);

        @(negedge clk);

        rst_n = 1'b1;


        // --------------------------------------------------------------------
        // Verify initial RM identity
        // --------------------------------------------------------------------

        if (rm_id !== 2'b00)
            $fatal(
                1,
                "STATIC TOP RM ID FAILURE: expected 00 got %b",
                rm_id
            );


        // --------------------------------------------------------------------
        // Load A[0][0] = 7
        // --------------------------------------------------------------------

        @(negedge clk);

        load_row  = 3'd0;
        load_col  = 3'd0;

        load_data = 32'sd7;

        load_a = 1'b1;
        load_b = 1'b0;


        // --------------------------------------------------------------------
        // Load B[0][0] = -3
        // --------------------------------------------------------------------

        @(negedge clk);

        load_data = -32'sd3;

        load_a = 1'b0;
        load_b = 1'b1;


        // Stop loading

        @(negedge clk);

        load_a = 1'b0;
        load_b = 1'b0;


        // --------------------------------------------------------------------
        // Start
        // --------------------------------------------------------------------

        start = 1'b1;

        @(negedge clk);

        start = 1'b0;


        // --------------------------------------------------------------------
        // Wait for completion
        // --------------------------------------------------------------------

        wait(done);

        @(negedge clk);


        // --------------------------------------------------------------------
        // Verify
        //
        // C00 = 7 * -3 = -21
        // --------------------------------------------------------------------

        if (captured_c00 !== -21) begin

            $fatal(
                1,
                "STATIC TOP COMPUTE FAILURE: expected -21 got %0d",
                captured_c00
            );

        end


        $display("");
        $display("==============================================");
        $display("DFX STATIC SHELL TEST PASSED");
        $display("==============================================");
        $display("");
        $display("Initial RM    : INT8 / 8x8");
        $display("RM ID         : %b", rm_id);
        $display("Result C[0][0]: %0d", captured_c00);
        $display("");
        $display("u_tpu_rp interface operational.");
        $display("Static shell ready for Vivado DFX.");
        $display("==============================================");
        $display("");

        $finish;

    end

endmodule