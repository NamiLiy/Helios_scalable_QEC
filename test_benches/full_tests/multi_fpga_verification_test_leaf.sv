`timescale 1ns / 10ps

// Output file format
// Each line is 32 bit. Cordinates are entered as two 16 bit entries in a single line
// Test ID
// root_of_0,0
// root_of_0,1
// .....
// Test ID
// root_of_0,0
// root_of_0,1
// .......

module verification_bench_leaf#(
    parameter CODE_DISTANCE = 5,
    parameter NUM_FPGAS = 2,
    parameter ROUTER_DELAY = 18,
    parameter FPGA_ID = 1,
    parameter NUM_CONTEXTS = 1,
    parameter LOGICAL_QUBITS_PER_DIM = 1
)(
    input clk,
    input reset,

    input [63:0] parent_rx_data,
    input parent_rx_valid,
    output parent_rx_ready,

    output [63:0] parent_tx_data,
    output parent_tx_valid,
    input parent_tx_ready,

    output [63 : 0] grid_1_out_data,
    output grid_1_out_valid,
    input grid_1_out_ready,

    input [63 : 0] grid_1_in_data,
    input grid_1_in_valid,
    output grid_1_in_ready,

    output [63 : 0] grid_2_out_data,
    output grid_2_out_valid,
    input grid_2_out_ready,

    input [63 : 0] grid_2_in_data,
    input grid_2_in_valid,
    output grid_2_in_ready
 );

`include "../../parameters/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam ACTUAL_D = CODE_DISTANCE;
localparam FULL_LOGICAL_QUBITS_PER_DIM = LOGICAL_QUBITS_PER_DIM;

localparam GRID_X_EXTRA = (FPGA_ID < 3) ? ((((ACTUAL_D + 1)>>2)<<1) + 1) : 0;
localparam GRID_Z_EXTRA = (FPGA_ID % 2 == 1) ? ((ACTUAL_D + 3)>>2) : 0;
localparam GRID_X_NORMAL = FULL_LOGICAL_QUBITS_PER_DIM * (ACTUAL_D + 1);
localparam GRID_Z_NORMAL = (FULL_LOGICAL_QUBITS_PER_DIM * (ACTUAL_D - 1) >> 1) + (FULL_LOGICAL_QUBITS_PER_DIM >> 1);
localparam GRID_WIDTH_X = GRID_X_NORMAL + GRID_X_EXTRA;
localparam GRID_WIDTH_Z = (GRID_Z_NORMAL + GRID_Z_EXTRA);
localparam GRID_WIDTH_U = ACTUAL_D; // Laksheen
// Nami : I have no idea why the below code is not working. It is essential to run context switching
// localparam PHYSICAL_GRID_WIDTH_U = ((GRID_WIDTH_U % NUM_CONTEXTS == 0) ? 
//                                    ($floor(GRID_WIDTH_U / NUM_CONTEXTS)) : 
//                                    ($floor(GRID_WIDTH_U / NUM_CONTEXTS) + 1));
localparam PHYSICAL_GRID_WIDTH_U = GRID_WIDTH_U;
localparam MAX_WEIGHT = 2;


`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = PHYSICAL_GRID_WIDTH_U * NUM_CONTEXTS;

localparam CODE_DISTANCE_X = GRID_WIDTH_X;
localparam CODE_DISTANCE_Z = GRID_WIDTH_Z;
localparam CODE_DISTANCE_U = GRID_WIDTH_U;


localparam PU_COUNT_ACROSS_CONTEXT = CODE_DISTANCE_X * CODE_DISTANCE_Z * PHYSICAL_GRID_WIDTH_U * NUM_CONTEXTS;

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH;

localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam HOR_ERROR_COUNT = ACTUAL_D*ACTUAL_D*FULL_LOGICAL_QUBITS_PER_DIM*FULL_LOGICAL_QUBITS_PER_DIM;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_X_NORMAL*GRID_Z_NORMAL; // This has some extra PEs in short rows. That has to be discarded
localparam CORRECTION_COUNT_PER_ROUND = HOR_ERROR_COUNT + UD_ERROR_COUNT_PER_ROUND;


wire [(ADDRESS_WIDTH * PU_COUNT_ACROSS_CONTEXT)-1:0] roots;

`define BYTES_PER_ROUND ((CODE_DISTANCE_X * CODE_DISTANCE_Z  + 7) >> 3)
`define ALIGNED_PU_PER_ROUND (`BYTES_PER_ROUND << 3)

reg [`ALIGNED_PU_PER_ROUND * PHYSICAL_GRID_WIDTH_U * NUM_CONTEXTS - 1:0] measurements;

`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define PADDED_INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * `ALIGNED_PU_PER_ROUND)
`define measurements(i, j, k) measurements[`PADDED_INDEX(i, j, k)]
// `define is_odd_cluster(i, j, k) decoder.is_odd_clusters[`INDEX(i, j, k)]
`define root(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: ADDRESS_WIDTH]
`define root_x(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k)+Z_BIT_WIDTH +: X_BIT_WIDTH]
`define root_z(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: Z_BIT_WIDTH]
`define root_u(i, j, k) decoder.roots[ADDRESS_WIDTH*`INDEX(i, j, k)+X_BIT_WIDTH+Z_BIT_WIDTH +: U_BIT_WIDTH]



reg [31:0] input_data;
reg input_valid;
wire input_ready;
wire [31:0] output_data;
wire output_valid;
reg output_ready;

wire [31:0] input_data_fifo;
wire input_valid_fifo;
wire input_ready_fifo;
wire [31:0] output_data_fifo;
wire output_valid_fifo;
wire output_ready_fifo;


// instantiate
Helios_single_FPGA #(
    .FULL_LOGICAL_QUBITS_PER_DIM(FULL_LOGICAL_QUBITS_PER_DIM),
    .MAX_WEIGHT(MAX_WEIGHT),
    .NUM_CONTEXTS(NUM_CONTEXTS),
    .NUM_FPGAS(NUM_FPGAS),
    .ROUTER_DELAY_COUNTER(ROUTER_DELAY),
    .FPGA_ID(FPGA_ID),
    .ACTUAL_D(CODE_DISTANCE)
 ) decoder (
    .clk(clk),
    .reset(reset),
    .input_data(input_data_fifo),
    .input_valid(input_valid_fifo),
    .input_ready(input_ready_fifo),
    .output_data(output_data_fifo),
    .output_valid(output_valid_fifo),
    .output_ready(output_ready_fifo),

    .parent_rx_data(parent_rx_data),
    .parent_rx_valid(parent_rx_valid),
    .parent_rx_ready(parent_rx_ready),
    .parent_tx_data(parent_tx_data),
    .parent_tx_valid(parent_tx_valid),
    .parent_tx_ready(parent_tx_ready),

    .grid_1_out_data(grid_1_out_data),
    .grid_1_out_valid(grid_1_out_valid),
    .grid_1_out_ready(grid_1_out_ready),

    .grid_2_out_data(grid_2_out_data),
    .grid_2_out_valid(grid_2_out_valid),
    .grid_2_out_ready(grid_2_out_ready),

    .grid_1_in_data(grid_1_in_data),
    .grid_1_in_valid(grid_1_in_valid),
    .grid_1_in_ready(grid_1_in_ready),

    .grid_2_in_data(grid_2_in_data),
    .grid_2_in_valid(grid_2_in_valid),
    .grid_2_in_ready(grid_2_in_ready)
    //.roots(roots)
);

// FIFO
fifo_wrapper #(
    .WIDTH(32),
    .DEPTH(128)
) input_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .input_valid(input_valid),
    .input_ready(input_ready),
    .output_data(input_data_fifo),
    .output_valid(input_valid_fifo),
    .output_ready(input_ready_fifo)
);

fifo_wrapper #(
    .WIDTH(32),
    .DEPTH(128)
) output_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(output_data_fifo),
    .input_valid(output_valid_fifo),
    .input_ready(output_ready_fifo),
    .output_data(output_data),
    .output_valid(output_valid),
    .output_ready(output_ready)
);

reg valid_delayed = 0;
integer i;
integer j;
integer k;
integer context_k;
integer output_file_2, input_file;
reg open = 1;
reg input_open = 1;
reg eof = 0;
reg input_eof = 0;
reg [31:0] read_value, test_case, input_read_value, input_test_case;
reg [X_BIT_WIDTH-1 : 0] expected_x;
reg [Z_BIT_WIDTH-1 : 0] expected_z;
reg [U_BIT_WIDTH-1 : 0] expected_u;
reg test_fail;
reg processing = 0;
reg [31:0] syndrome_count;
reg [31:0] pass_count = 0;
reg [31:0] fail_count = 0;
reg [31:0] total_count;

reg [2:0] loading_state;

reg new_round_start;
reg [31:0] cycle_counter;
reg [31:0] iteration_counter;
reg [31:0] message_counter;

reg full_test_completed;
reg data_loading_complete;
reg test_case_id_loaded;

always @(posedge clk) begin
    if(reset) begin
        loading_state <= 3'b0;
        message_counter <= 0;
    end else begin
        case(loading_state)
            3'b0: begin // reset
                loading_state <= 3'b1;
            end
            3'b1: begin // data loading stage
                if(data_loading_complete == 1) begin
                    loading_state <= 3'b10;
                end
            end
            3'b10: begin // data reading stage
                if(output_valid == 1) begin
                    if (message_counter == 0) begin
                        cycle_counter <= output_data[15:0];
                        iteration_counter <= output_data[23:16];
                    end
                    if (output_data == 32'hffffffff) begin
                        loading_state <= 3'b1;
                        message_counter <= 0;
                    end else begin
                        message_counter <= message_counter + 1;
                    end
                end
            end
            default: begin
                loading_state <= 3'b0;
            end
        endcase
    end
end

always@(*) begin
    if(loading_state == 3'b1) begin
        input_valid = 1;
        input_data = input_read_value;
    end else begin
        input_valid = 0;
        input_data = 0;
    end
end

always @(*) begin
    if (loading_state == 3'b10) begin
        output_ready = 1;
    end else begin
        output_ready = 0;
    end
end

string input_filename, output_filename;

// Input loading logic
always @(negedge clk) begin
    if(reset) begin
        test_case_id_loaded = 0;
        data_loading_complete = 0;
    end else if(loading_state == 3'b0 || loading_state == 3'b10) begin
        test_case_id_loaded = 0;
        data_loading_complete = 0;
    end else if (loading_state == 3'b1 && full_test_completed == 0) begin
        if(input_open == 1) begin
            input_filename = $sformatf("/home/helios/Helios_scalable_QEC/test_benches/test_data/input_data_%0d_%0d.txt", CODE_DISTANCE, FPGA_ID);
            input_file = $fopen(input_filename, "r");
            input_open = 0;
        end
        if (test_case_id_loaded ==0 && input_eof == 0)begin 
            $fscanf (input_file, "%h\n", input_test_case);
            input_eof = $feof(input_file);
            test_case_id_loaded = 1;
            if (input_eof == 0)begin 
                syndrome_count = 0;
            end
        end
        if(input_eof == 0) begin
            $fscanf (input_file, "%h\n", input_read_value);
            if (input_read_value == 32'hffffffff) begin
                data_loading_complete = 1;
                test_case_id_loaded = 0;
            end else begin
                syndrome_count = syndrome_count + 1;
            end
        end
    end
end


// Output verification logic
always @(posedge clk) begin
    if (decoder.controller.global_stage_d == STAGE_PEELING && full_test_completed == 0) begin // When we move to peeling we are doen with clustering
//       $display("%t\tTest case %d pass %d cycles %d iterations %d syndromes", $time, test_case, cycle_counter, iteration_counter, syndrome_count);
       if(open == 1) begin
            output_filename = $sformatf("/home/helios/Helios_scalable_QEC/test_benches/test_data/output_data_%0d_%0d.txt", CODE_DISTANCE, FPGA_ID);
            output_file_2 = $fopen(output_filename, "r");
            open = 0;
        end
        if (eof == 0)begin 
            if(decoder.controller.current_context == 0) begin
                $fscanf (output_file_2, "%h\n", test_case);
                //$display("%t\tTest case %d", $time, test_case);
                test_fail = 0;
            end
        end
        for (k=0 ;k <PHYSICAL_GRID_WIDTH_U; k++) begin
            for (i=0 ;i <CODE_DISTANCE_X; i++) begin
                for (j=0 ;j <CODE_DISTANCE_Z; j++) begin
                    if (eof == 0)begin 
                        $fscanf (output_file_2, "%h\n", read_value);
                        //$display("%t\t Read Value %h", $time, read_value);
                        if(Z_BIT_WIDTH>0) begin
                            expected_z = read_value[Z_BIT_WIDTH - 1:0];
                        end else begin
                            expected_z = 0;
                        end
                        expected_x = read_value[X_BIT_WIDTH - 1 + 8 :8];
                        expected_u = read_value[U_BIT_WIDTH - 1 + 16 :16];
                        
                        // context_k = k;
                        // These logic are for multi context verification
                        if(decoder.controller.current_context % 2 == 1) begin
                            context_k = decoder.controller.current_context*PHYSICAL_GRID_WIDTH_U + PHYSICAL_GRID_WIDTH_U - k - 1;
                        end else begin
                            context_k = decoder.controller.current_context*PHYSICAL_GRID_WIDTH_U  + k;
                        end
//                        if(decoder.controller.current_context == NUM_CONTEXTS - 1 && expected_u == 0 && expected_x==0 && expected_z==0) begin //hack for d=7,11
//                            continue;
                        //end else begin
                            if(Z_BIT_WIDTH>0) begin
                                if (expected_u != `root_u(i, j, k) || expected_x != `root_x(i, j, k) || expected_z != `root_z(i, j, k)) begin
                                    $display("%t\t Root(%0d,%0d,%0d) = (%0d,%0d,%0d) : Expected (%0d,%0d,%0d) : TC %d : ID %d" , $time, context_k, i ,j, `root_u(i, j, k), `root_x(i, j, k), `root_z(i, j, k), expected_u, expected_x, expected_z, test_case, FPGA_ID);
                                    test_fail = 1;
                                end
                            end else begin
                                // This logic has to be modified to multi FPGA
                                if (expected_u != `root_u(i, j, k) || expected_x != `root_x(i, j, k)) begin
                                    $display("%t\t Root(%0d,%0d,%0d) = (%0d,%0d,%0d) : Expected (%0d,%0d,%0d) : TC %d : ID %d" , $time, context_k, i ,j, `root_u(i, j, k), `root_x(i, j, k), 0, expected_u, expected_x, expected_z, test_case, FPGA_ID);
                                    test_fail = 1;
                                end
                            end
                        //end
                    end
                end
            end
        end
        eof = $feof(output_file_2);
    end
    if (message_counter == 1 && output_valid == 1 && full_test_completed == 0) begin // Cycle counter and iteration counter is recevied
        if (!test_fail) begin
            $display("%t\tID  = %d Test case  = %d, %d pass %d cycles %d first round %d syndromes", $time, FPGA_ID, test_case, pass_count, cycle_counter, iteration_counter, syndrome_count);
            pass_count = pass_count + 1;
        end else begin
            $display("%t\tID  = %d Test case  = %d, %d fail %d cycles %d iterations %d syndromes", $time, FPGA_ID, test_case, fail_count, cycle_counter, iteration_counter, syndrome_count);
            fail_count = fail_count + 1;
            // $finish;
        end
    end
    if (reset) begin
        full_test_completed = 0;
    end else if (input_eof == 1 && full_test_completed == 0)begin
        total_count = pass_count + fail_count;
        $display("%t\t Done:", $time);
        $display("Total : %d",total_count);
        $display("Passed : %d",pass_count);
        $display("Failed : %d",fail_count);
        full_test_completed = 1;
        $finish;
    end
end




endmodule
