module Helios_single_FPGA_wrapper #(
    parameter CODE_DISTANCE_X = 11,
    parameter CODE_DISTANCE_Z = 10,
    parameter WEIGHT_X = 2,
    parameter WEIGHT_Z = 2,
    parameter WEIGHT_M = 2 // Weight up down
) (
    clk,
    reset,
    new_round_start,
    measurements,
    roots,
    correction,
    result_valid,
    iteration_counter,
    cycle_counter,
    global_stage,

    bram_we,
    bram_en,
    bram_addr,
    bram_di,
    bram_dout,

    input_line,
    output_line
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIM_BIT_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_BIT_WIDTH * 3;

localparam NS_ERROR_COUNT = (CODE_DISTANCE_X-1) * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam EW_ERROR_COUNT = CODE_DISTANCE_X * (CODE_DISTANCE_Z+1) * MEASUREMENT_ROUNDS;
localparam UD_ERROR_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam CORRECTION_COUNT = NS_ERROR_COUNT + EW_ERROR_COUNT + UD_ERROR_COUNT;

input clk;
input reset;
output new_round_start;
output [PU_COUNT-1:0] measurements;
output result_valid;
output [7:0] iteration_counter;
output [31:0] cycle_counter;
output [STAGE_WIDTH-1:0] global_stage;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output [CORRECTION_COUNT - 1 : 0] correction;

output [3:0] bram_we;
output bram_en;
output [31:0]bram_addr;
output [31:0] bram_di;
input [31:0] bram_dout;

input [15:0] input_line;
output [1:0] output_line;

// instantiate
Helios_single_FPGA #(
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
    .global_stage(global_stage)
);

reg [15:0] reg_input_line_1;
reg [1:0] reg_output_line_1;
always@(posedge clk) begin
       reg_input_line_1 <= input_line;
       if(reg_input_line_1 < CORRECTION_COUNT) begin
            reg_output_line_1[0] <= correction[reg_input_line_1];
       end
       if(reg_input_line_1 < PU_COUNT) begin
            reg_output_line_1[1] <= measurements[reg_input_line_1];
       end
end
assign output_line = reg_output_line_1;

arm_communicator #(.reset_threshold(32'hb0), .number_of_runs(32'd1000)) ac(
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .result_valid(result_valid),
    .downstream_busy(0),
    .total_test_case_counter(test_case),
    .duration(cycle_counter),
    .we(bram_we),
    .en(bram_en),
    .addr(bram_addr),
    .di(bram_di),
    .dout(bram_dout)
);

reg [10:0] counter;
always@(posedge clk) begin
    if(reset) begin
        counter <= 0;
    end else begin
        if(global_stage == STAGE_MEASUREMENT_LOADING) begin
            counter <= 1;
            // is_odd_syndrome <= is_odd_syndrome_wire;
        end else begin
            if(counter > 0 && counter < 4) begin
                counter <= counter + 1;
            end else begin
                counter <= 0;
            end
        end
    end
end

wire update_errors;
assign update_errors = counter == 4 ? 1 : 0;


rand_gen_top #(.CODE_DISTANCE_X(CODE_DISTANCE_X), .CODE_DISTANCE_Z(CODE_DISTANCE_Z)) rgt(
    .next(update_errors),
    .measurement_values(measurements),
    .clk(clk),
    .reset(reset),
    .is_odd_syndrome()
);

endmodule