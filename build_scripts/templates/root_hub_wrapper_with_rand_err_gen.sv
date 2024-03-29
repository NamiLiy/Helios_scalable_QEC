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

module bench_multi_fpga;

`include "../../parameters/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE_X = /*$$CODE_DISTANCE_X*/;
localparam CODE_DISTANCE_Z = /*$$CODE_DISTANCE_Z*/;
localparam WEIGHT_X = 1;
localparam WEIGHT_Z = 1;
localparam WEIGHT_UD = 1; // Weight up down
localparam CODE_DISTANCE = CODE_DISTANCE_X;


`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;
localparam FIFO_COUNT = MEASUREMENT_ROUNDS * (CODE_DISTANCE_Z);
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT+1);

localparam INTERCONNECT_PHYSICAL_WIDTH = /*$$HUB_FIFO_PHYSICAL_WIDTH*/;
localparam FPGA_NEIGHBORS = /*$$DIRECT_CONNECTED_NEIGHBORS*/;

reg clk;
reg reset;
wire new_round_start;

reg [PU_COUNT-1:0] is_error_syndromes;
wire [31:0] cycle_counter;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
reg deadlock;

wire [PU_COUNT-1:0] is_touching_boundaries;
wire [PU_COUNT-1:0] is_odd_cardinalities;

`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define is_error_syndrome(i, j, k) is_error_syndromes[`INDEX(i, j, k)]
`define is_odd_cluster(i, j, k) decoder.is_odd_clusters[`INDEX(i, j, k)]
`define root(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: ADDRESS_WIDTH]
`define root_x(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k)+PER_DIMENSION_WIDTH +: PER_DIMENSION_WIDTH]
`define root_y(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: PER_DIMENSION_WIDTH]
`define root_z(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k)+(2*PER_DIMENSION_WIDTH) +: PER_DIMENSION_WIDTH]
`define PU(i, j, k) decoder.decoder.pu_k[k].pu_i[i].pu_j[j].u_processing_unit


// wire [/*$$NUM_CHILDREN*/*INTERCONNECT_PHYSICAL_WIDTH - 1 : 0] downstream_fifo_in_data_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_valid_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_ready_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/*INTERCONNECT_PHYSICAL_WIDTH - 1 : 0] downstream_fifo_out_data_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_valid_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_ready_/*$$ID*/;

wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_message_flying_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_odd_clusters_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/*2 - 1 : 0] downstream_state_signal_/*$$ID*/;

// wire [/*$$NUM_CHILDREN*/*INTERCONNECT_PHYSICAL_WIDTH - 1 : 0] downstream_fifo_in_data_d_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_valid_d_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_ready_d_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/*INTERCONNECT_PHYSICAL_WIDTH - 1 : 0] downstream_fifo_out_data_d_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_valid_d_/*$$ID*/;
// wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_ready_d_/*$$ID*/;

wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_message_flying_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_odd_clusters_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/*2 - 1 : 0] downstream_state_signal_d_/*$$ID*/;

genvar i2,j2,k2;

function [ADDRESS_WIDTH-1:0] make_address;
input [PER_DIMENSION_WIDTH-1:0] i;
input [PER_DIMENSION_WIDTH-1:0] j;
input [PER_DIMENSION_WIDTH-1:0] k;
begin
    make_address = { k, i, j };
end
endfunction

always #5 clk = ~clk;  // flip every 5ns, that is 100MHz clock

reg valid_delayed = 0;
integer i;
integer j;
integer k;
integer file, input_file;
reg open = 1;
reg input_open = 1;
reg eof = 0;
reg input_eof = 0;
reg [31:0] read_value, input_read_value;
wire [31:0] test_case;
reg [PER_DIMENSION_WIDTH-1 : 0] expected_x, expected_y, expected_z;
reg test_fail;
reg processing = 0;
reg [31:0] syndrome_count;
reg [31:0] pass_count = 0;
reg [31:0] fail_count = 0;
reg [31:0] total_count;
wire other_modules_busy_to_ac;

// Output verification logic
always @(posedge clk) begin
    if (!valid_delayed && result_valid) begin
        processing = 0;
        if (deadlock) begin
            $display("%t\tTest case %d hit a deadlock", $time, test_case);
            test_fail = 1;
        end
        $display("%t\tTest case %d pass %d cycles %d iterations", $time, test_case, cycle_counter, iteration_counter);
        pass_count = pass_count + 1;
    end
    if (input_eof == 1)begin
        total_count = pass_count + fail_count;
        $display("%t\t Done:", $time);
        $display("Total : %d",total_count);
        $display("Passed : %d",pass_count);
        $display("Failed : %d",fail_count);
        $finish;
    end
end

always@(posedge clk) begin
    valid_delayed <= result_valid;
end

initial begin
    clk = 1'b1;
    reset = 1'b1;
    // deadlock = 1'b0;
    #107;
    reset = 1'b0;
end



root_hub_/*$$ID*/ #(
    .CODE_DISTANCE_X(/*$$CODE_DISTANCE_X*/),
    .CODE_DISTANCE_Z(/*$$CODE_DISTANCE_Z*/),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_UD(WEIGHT_UD)
) u_hub_/*$$ID*/ (
    .clk(clk),
    .reset(reset),

    // Temporary ports for debug
    .new_round_start(new_round_start),
    // .is_error_syndromes(is_error_syndromes),
    // .roots(roots),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(final_cardinality),

    // Following three ports are for single FPGA debug only and should not be used in the multi-FPGA design
    .is_touching_boundaries(is_touching_boundaries),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),


    // .upstream_fifo_out_data(),
    // .upstream_fifo_out_valid(),
    // .upstream_fifo_out_ready(1'b1),
    // .upstream_fifo_in_data(),
    // .upstream_fifo_in_valid(1'b0),
    // .upstream_fifo_in_ready(),

    // .downstream_fifo_out_data(downstream_fifo_out_data_/*$$ID*/),
    // .downstream_fifo_out_valid(downstream_fifo_out_valid_/*$$ID*/),
    // .downstream_fifo_out_ready(downstream_fifo_out_ready_/*$$ID*/),
    // .downstream_fifo_in_data(downstream_fifo_in_data_/*$$ID*/),
    // .downstream_fifo_in_valid(downstream_fifo_in_valid_/*$$ID*/),
    // .downstream_fifo_in_ready(downstream_fifo_in_ready_/*$$ID*/),

    .upstream_has_message_flying(other_modules_busy_to_ac),
    // .upstream_has_odd_clusters(),

    .downstream_has_message_flying(downstream_has_message_flying_/*$$ID*/),
    .downstream_has_odd_clusters(downstream_has_odd_clusters_/*$$ID*/),
    .downstream_state_signal(downstream_state_signal_/*$$ID*/)
);

arm_communicator #(.reset_threshold(32'd100), .number_of_runs(32'd100)) ac(
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .result_valid(result_valid),
    .total_test_case_counter(test_case),
    .downstream_busy(other_modules_busy_to_ac)
);


