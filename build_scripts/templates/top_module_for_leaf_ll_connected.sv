/// This module combines the stage controller with planar code grid.
/// Use this for the main test bench

module top_module_for_leaf_/*$$ID*/ #(
    parameter CODE_DISTANCE_X = 3,
    parameter CODE_DISTANCE_Z = 2,
    parameter WEIGHT_X = 1,
    parameter WEIGHT_Z = 1,
    parameter WEIGHT_UD = 1 // Weight up down
) (
    clk,
    reset,
    new_round_start,
    is_error_syndromes,
    roots,
    result_valid,
    iteration_counter,
    cycle_counter,
    deadlock,
    final_cardinality,

    final_fifo_out_data,
    final_fifo_out_valid,
    final_fifo_out_ready,
    final_fifo_in_data,
    final_fifo_in_valid,
    final_fifo_in_ready,

    has_message_flying,
    has_odd_clusters
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;
//localparam FIFO_COUNT = MEASUREMENT_ROUNDS * (CODE_DISTANCE_Z);
localparam EDGE_COUNT = /*$$EDGE_COUNT*/;
localparam FIFO_COUNT = /*$$EDGE_COUNT*/ * MEASUREMENT_ROUNDS;
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT+1);
localparam HUB_FIFO_WIDTH = /*$$HUB_FIFO_WIDTH*/;
localparam HUB_FIFO_PHYSICAL_WIDTH = /*$$HUB_FIFO_PHYSICAL_WIDTH*/;

localparam X_START = /*$$X_START*/;
localparam X_END = /*$$X_END*/;
localparam PU_INST = (X_END - X_START + 1); // GENERATE THIS
localparam MY_ID = /*$$ID*/;
// localparam TOP_FPGA_ID = /*$$ID*/ - 1;
// localparam BOTTOM_FPGA_ID = /*$$ID*/ + 1;
localparam FPGAID_WIDTH = /*$$FPGAID_WIDTH*/;
localparam FIFO_IDWIDTH = /*$$FIFO_IDWIDTH*/;
localparam MESSAGE_FLYING_DELAY = /*$$MESSAGE_FLYING_DELAY*/;

localparam FPGA_NEIGHBORS = /*$$LL_NEIGHBORS*/;

input clk;
input reset;
input new_round_start;
input [PU_COUNT-1:0] is_error_syndromes;
output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
output reg result_valid;
output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
output [31:0] cycle_counter;
output deadlock;
output final_cardinality;

output has_message_flying;
output reg has_odd_clusters;

output [HUB_FIFO_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_out_data;
output [FPGA_NEIGHBORS : 0] final_fifo_out_valid;
input [FPGA_NEIGHBORS : 0] final_fifo_out_ready;
input [HUB_FIFO_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_in_data;
input [FPGA_NEIGHBORS : 0] final_fifo_in_valid;
output [FPGA_NEIGHBORS : 0] final_fifo_in_ready;

wire [HUB_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
wire [HUB_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

wire [HUB_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
wire sc_fifo_out_valid;
wire sc_fifo_out_ready;
wire [HUB_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
wire sc_fifo_in_valid;
wire sc_fifo_in_ready;

wire [PU_COUNT -1:0] is_odd_cardinalities;
wire [PU_COUNT -1:0] is_touching_boundaries;
reg [MESSAGE_FLYING_DELAY-1:0]has_message_flying_reg;
wire [STAGE_WIDTH-1:0] stage;
wire [PU_COUNT -1:0] is_odd_clusters;
// wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] left_roots;
wire has_message_flying_grid;
wire has_message_flying_interconnect;

assign has_message_flying = |has_message_flying_reg;

always@(posedge clk) begin
    if (reset) begin
        has_message_flying_reg <= 32'b0;
    end else begin
        has_message_flying_reg[0] <= has_message_flying_grid | has_message_flying_interconnect;
        has_message_flying_reg[MESSAGE_FLYING_DELAY-1:1] <= has_message_flying_reg[MESSAGE_FLYING_DELAY-2:0];
    end
end

always@(posedge clk) begin
    has_odd_clusters <= |is_odd_clusters;
end

standard_planar_code_3d_no_fast_channel_/*$$ID*/ #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_UD(WEIGHT_UD)
) decoder (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .is_odd_cardinalities(is_odd_cardinalities),
    .is_touching_boundaries(is_touching_boundaries),
    .roots(roots),
    .has_message_flying(has_message_flying_grid),
    .master_fifo_out_data_vector(master_fifo_out_data_vector),
    .master_fifo_out_valid_vector(master_fifo_out_valid_vector),
    .master_fifo_out_ready_vector(master_fifo_out_ready_vector),
    .master_fifo_in_data_vector(master_fifo_in_data_vector),
    .master_fifo_in_valid_vector(master_fifo_in_valid_vector),
    .master_fifo_in_ready_vector(master_fifo_in_ready_vector)
);

decoder_stage_controller_dummy_/*$$ID*/ #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller (
    .clk(clk),
    .reset(reset),
    .is_touching_boundaries(is_touching_boundaries),
    .is_odd_cardinalities(is_odd_cardinalities),
    .roots(roots),
    .new_round_start(new_round_start),
    .stage(stage),
    .result_valid(result_valid),
    .iteration_counter(iteration_counter),
    .cycle_counter(cycle_counter),
    .deadlock(deadlock),
    .final_cardinality(final_cardinality),
    .sc_fifo_out_data(sc_fifo_out_data),
    .sc_fifo_out_valid(sc_fifo_out_valid),
    .sc_fifo_out_ready(sc_fifo_out_ready),
    .sc_fifo_in_data(sc_fifo_in_data),
    .sc_fifo_in_valid(sc_fifo_in_valid),
    .sc_fifo_in_ready(sc_fifo_in_ready)
);

localparam logic [FPGAID_WIDTH - 1:0] fpga_neighbor_array[FPGA_NEIGHBORS] = {/*$$LL_NEIGHBOR_IDS*/};

wire [FPGAID_WIDTH*FPGA_NEIGHBORS - 1:0] fpga_neighbor_array_packed;

genvar i;

generate
    for(i=0;i<FPGA_NEIGHBORS;i=i+1) begin: packing_n_list
        assign fpga_neighbor_array_packed[(i+1)*FPGAID_WIDTH - 1 : i*FPGAID_WIDTH] = fpga_neighbor_array[i];
    end
endgenerate

final_arbitration_ll_connected_unit #(
    .FPGAID_WIDTH(FPGAID_WIDTH),
    .HUB_FIFO_WIDTH(HUB_FIFO_WIDTH),
    .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH),
    .FIFO_IDWIDTH(FIFO_IDWIDTH),
    .FIFO_COUNT(FIFO_COUNT),
    .FPGA_NEIGHBORS(FPGA_NEIGHBORS)
) u_final_arbitration_unit (
    .clk(clk),
    .reset(reset),
    .master_fifo_out_data_vector(master_fifo_out_data_vector),
    .master_fifo_out_valid_vector(master_fifo_out_valid_vector),
    .master_fifo_out_ready_vector(master_fifo_out_ready_vector),
    .master_fifo_in_data_vector(master_fifo_in_data_vector),
    .master_fifo_in_valid_vector(master_fifo_in_valid_vector),
    .master_fifo_in_ready_vector(master_fifo_in_ready_vector),
    .sc_fifo_out_data(sc_fifo_out_data),
    .sc_fifo_out_valid(sc_fifo_out_valid),
    .sc_fifo_out_ready(sc_fifo_out_ready),
    .sc_fifo_in_data(sc_fifo_in_data),
    .sc_fifo_in_valid(sc_fifo_in_valid),
    .sc_fifo_in_ready(sc_fifo_in_ready),
    .final_fifo_out_data(final_fifo_out_data),
    .final_fifo_out_valid(final_fifo_out_valid),
    .final_fifo_out_ready(final_fifo_out_ready),
    .final_fifo_in_data(final_fifo_in_data),
    .final_fifo_in_valid(final_fifo_in_valid),
    .final_fifo_in_ready(final_fifo_in_ready),
    .has_flying_messages(has_message_flying_interconnect),
    .fpga_neighbor_array(fpga_neighbor_array_packed)
);

// assign final_fifo_out_data[HUB_FIFO_WIDTH -1 :FINAL_FIFO_WIDTH] = 0;

endmodule