`timescale 1ns/1ps

// Complete reusable 4x4 tile engine.
//
// The host writes A and B one signed byte at a time while busy=0, pulses start,
// and receives sixteen signed 32-bit results in row-major order.
module systolic_core_4x4 (
    input  logic                       clk,
    input  logic                       rst_n,

    input  logic                       load_a,
    input  logic                       load_b,
    input  logic [1:0]                 load_row,
    input  logic [1:0]                 load_col,
    input  logic signed [7:0]          load_data,
    input  logic                       start,

    output logic                       busy,
    output logic                       done,
    output logic                       result_valid,
    output logic [3:0]                 result_index,
    output logic [1:0]                 result_row,
    output logic [1:0]                 result_col,
    output logic signed [31:0]         result_data
);

    typedef enum logic [2:0] {
        ST_IDLE,
        ST_CLEAR,
        ST_COMPUTE,
        ST_CAPTURE,
        ST_READOUT,
        ST_DONE
    } state_t;

    state_t state;

    logic signed [7:0]  a_mem [0:3][0:3];
    logic signed [7:0]  b_mem [0:3][0:3];

    logic signed [7:0]  a_left [0:3];
    logic signed [7:0]  b_top  [0:3];
    logic               a_valid_left [0:3];
    logic               b_valid_top  [0:3];

    logic signed [31:0] acc [0:3][0:3];
    logic signed [31:0] result_buffer [0:15];

    logic [3:0] cycle_count;
    logic [3:0] read_index;
    logic       clear_array;

    // Matrix-loading registers. Loading is intentionally blocked while busy.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < 4; i = i + 1) begin
                for (int j = 0; j < 4; j = j + 1) begin
                    a_mem[i][j] <= '0;
                    b_mem[i][j] <= '0;
                end
            end
        end else if (state == ST_IDLE) begin
            if (load_a)
                a_mem[load_row][load_col] <= load_data;
            if (load_b)
                b_mem[load_row][load_col] <= load_data;
        end
    end

    // Controller. Twelve COMPUTE edges are required:
    // 0..9 moves the final k=3 pair to PE[3][3], 10 registers its product,
    // and 11 performs its final accumulation. Capture happens on the next edge.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            state       <= ST_IDLE;
            cycle_count <= '0;
            read_index  <= '0;
        end else begin
            case (state)
                ST_IDLE: begin
                    cycle_count <= '0;
                    read_index  <= '0;
                    if (start)
                        state <= ST_CLEAR;
                end

                ST_CLEAR: begin
                    cycle_count <= '0;
                    state       <= ST_COMPUTE;
                end

                ST_COMPUTE: begin
                    if (cycle_count == 4'd11) begin
                        cycle_count <= '0;
                        state       <= ST_CAPTURE;
                    end else begin
                        cycle_count <= cycle_count + 1'b1;
                    end
                end

                ST_CAPTURE: begin
                    read_index <= '0;
                    state      <= ST_READOUT;
                end

                ST_READOUT: begin
                    if (read_index == 4'd15) begin
                        read_index <= '0;
                        state      <= ST_DONE;
                    end else begin
                        read_index <= read_index + 1'b1;
                    end
                end

                ST_DONE: state <= ST_IDLE;
                default: state <= ST_IDLE;
            endcase
        end
    end

    assign clear_array = (state == ST_CLEAR);

    // Boundary skew generator. Invalid positions carry zero and valid=0.
    always_comb begin
        for (int r = 0; r < 4; r++) begin
            a_left[r]       = '0;
            a_valid_left[r] = 1'b0;

            if ((state == ST_COMPUTE) &&
                (cycle_count >= r) && (cycle_count < r + 4)) begin
                a_left[r]       = a_mem[r][cycle_count-r];
                a_valid_left[r] = 1'b1;
            end
        end

        for (int c = 0; c < 4; c++) begin
            b_top[c]       = '0;
            b_valid_top[c] = 1'b0;

            if ((state == ST_COMPUTE) &&
                (cycle_count >= c) && (cycle_count < c + 4)) begin
                b_top[c]       = b_mem[cycle_count-c][c];
                b_valid_top[c] = 1'b1;
            end
        end
    end

    systolic_array_4x4 u_array (
        .clk          (clk),
        .rst_n        (rst_n),
        .clear        (clear_array),
        .a_left       (a_left),
        .b_top        (b_top),
        .a_valid_left (a_valid_left),
        .b_valid_top  (b_valid_top),
        .acc          (acc)
    );

    // Snapshot all 16 local accumulators after the pipeline is completely
    // drained. This lets later versions clear/start another tile while a narrow
    // output port drains the saved tile.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            for (int i = 0; i < 16; i = i + 1)
                result_buffer[i] <= '0;
        end else if (state == ST_CAPTURE) begin
            for (int i = 0; i < 4; i = i + 1)
                for (int j = 0; j < 4; j = j + 1)
                    result_buffer[i*4+j] <= acc[i][j];
        end
    end

    assign busy         = (state != ST_IDLE) && (state != ST_DONE);
    assign done         = (state == ST_DONE);
    assign result_valid = (state == ST_READOUT);
    assign result_index = read_index;
    assign result_row   = read_index[3:2];
    assign result_col   = read_index[1:0];
    assign result_data  = result_buffer[read_index];

endmodule
