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

module latency_bench_single_FPGA;

`include "../../parameters/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 15;
localparam CODE_DISTANCE_X = CODE_DISTANCE;
localparam CODE_DISTANCE_Z = CODE_DISTANCE_X - 1;
localparam WEIGHT_X = 2;
localparam WEIGHT_Z = 2;
localparam WEIGHT_M = 2; // Weight up down


`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIM_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam NS_ERROR_COUNT = (CODE_DISTANCE_X-1) * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam EW_ERROR_COUNT = CODE_DISTANCE_X * (CODE_DISTANCE_Z+1) * MEASUREMENT_ROUNDS;
localparam UD_ERROR_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam CORRECTION_COUNT = NS_ERROR_COUNT + EW_ERROR_COUNT + UD_ERROR_COUNT;

reg clk;
reg reset;
wire new_round_start;

wire [PU_COUNT-1:0] measurements;
wire [31:0] cycle_counter;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
wire [CORRECTION_COUNT - 1 : 0] correction;

`define INDEX(i, j, k) (i * CODE_DISTANCE_Z + j + k * CODE_DISTANCE_Z*CODE_DISTANCE_X)
`define measurements(i, j, k) measurements[`INDEX(i, j, k)]
// `define is_odd_cluster(i, j, k) decoder.is_odd_clusters[`INDEX(i, j, k)]
`define root(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: ADDRESS_WIDTH]
`define root_x(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k)+PER_DIM_WIDTH +: PER_DIM_WIDTH]
`define root_y(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k) +: PER_DIM_WIDTH]
`define root_z(i, j, k) roots[ADDRESS_WIDTH*`INDEX(i, j, k)+(2*PER_DIM_WIDTH) +: PER_DIM_WIDTH]
`define PU(i, j, k) decoder.decoder.pu_k[k].pu_i[i].pu_j[j].u_processing_unit

wire result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;

// instantiate
Helios_single_FPGA_wrapper #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_M(WEIGHT_M)
 ) decoder (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .measurements(measurements),
    .roots(roots),
    .correction(correction),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .global_stage()
);

function [ADDRESS_WIDTH-1:0] make_address;
input [PER_DIM_WIDTH-1:0] i;
input [PER_DIM_WIDTH-1:0] j;
input [PER_DIM_WIDTH-1:0] k;
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
reg [31:0] read_value, test_case, input_read_value;
reg [PER_DIM_WIDTH-1 : 0] expected_x, expected_y, expected_z;
reg test_fail;
reg processing = 0;
reg [31:0] syndrome_count;
reg [31:0] pass_count = 0;
reg [31:0] fail_count = 0;
reg [31:0] total_count;
reg [63:0] overall_latency = 0;




// Output verification logic
always @(posedge clk) begin
    if (!valid_delayed && result_valid) begin
        test_case = test_case + 1;
        $display("%t\tTest case %d pass %d cycles %d iterations", $time, test_case, cycle_counter, iteration_counter);
        overall_latency = overall_latency + cycle_counter;
        if(test_case == 1000) begin
            $display("%t\t Total latency for %d test cases is %d ms", $time, test_case, overall_latency);
        end
    end
end

always@(posedge clk) begin
    valid_delayed <= result_valid;
end

initial begin
    clk = 1'b1;
    reset = 1'b1;
    test_case = 0;

    #107;
    reset = 1'b0;
    #100;


end


endmodule
