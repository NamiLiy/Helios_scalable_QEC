/// This module combines the stage controller with planar code grid.
/// Use this for the main test bench

module standard_planar_code_3d_no_fast_channel_with_stage_controller_left #(
    CODE_DISTANCE = 5
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
    final_fifo_in_ready

);

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + ADDRESS_WIDTH;
localparam FIFO_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);

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

output [FINAL_FIFO_WIDTH - 1 :0] final_fifo_out_data;
output final_fifo_out_valid;
output final_fifo_out_ready;
output [FINAL_FIFO_WIDTH - 1 :0] final_fifo_in_data;
output final_fifo_in_valid;
output final_fifo_in_ready;

wire [PU_COUNT-1:0] is_odd_cardinalities;
wire [PU_COUNT-1:0] is_touching_boundaries;
wire has_message_flying;
wire [STAGE_WIDTH-1:0] stage;
wire [PU_COUNT-1:0] is_odd_clusters;
reg has_odd_clusters;

always@(posedge clk) begin
    has_odd_clusters <= |is_odd_clusters;
end

wire [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
wire [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
wire sc_fifo_out_valid;
wire sc_fifo_out_ready;
wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
wire sc_fifo_in_valid;
wire sc_fifo_in_ready;

standard_planar_code_3d_no_fast_channel_left #(.CODE_DISTANCE(CODE_DISTANCE)) decoder_left (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .is_odd_cardinalities(is_odd_cardinalities),
    .is_touching_boundaries(is_touching_boundaries),
    .roots(roots),
    .has_message_flying(has_message_flying),
    .master_fifo_out_data_vector(master_fifo_out_data_vector),
    .master_fifo_out_valid_vector(master_fifo_out_valid_vector),
    .master_fifo_out_ready_vector(master_fifo_out_ready_vector),
    .master_fifo_in_data_vector(master_fifo_in_data_vector),
    .master_fifo_in_valid_vector(master_fifo_in_valid_vector),
    .master_fifo_in_ready_vector(master_fifo_in_ready_vector)
);

decoder_stage_controller_left #(
    .CODE_DISTANCE(CODE_DISTANCE), 
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller_left (
    .clk(clk),
    .reset(reset),
    .has_message_flying(has_message_flying),
    .has_odd_clusters(has_odd_clusters),
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

final_arbitration_unit u_final_arbitration_unit_left (
    .master_fifo_out_data(master_fifo_out_data_vector),
    .master_fifo_out_valid(master_fifo_out_valid_vector),
    .master_fifo_out_ready(master_fifo_out_ready_vector),
    .master_fifo_in_data(master_fifo_in_data_vector),
    .master_fifo_in_valid(master_fifo_in_valid_vector),
    .master_fifo_in_ready(master_fifo_in_ready_vector)
    .sc_fifo_out_data(sc_fifo_out_data),
    .sc_fifo_out_valid(sc_fifo_out_valid),
    .sc_fifo_out_ready(sc_fifo_out_ready),
    .sc_fifo_in_data(sc_fifo_in_data),
    .sc_fifo_in_valid(sc_fifo_in_valid),
    .sc_fifo_in_ready(sc_fifo_in_ready)
    .final_fifo_out_data(final_fifo_out_data),
    .final_fifo_out_valid(final_fifo_out_valid),
    .final_fifo_out_ready(final_fifo_out_ready),
    .final_fifo_in_data(final_fifo_in_data),
    .final_fifo_in_valid(final_fifo_in_valid),
    .final_fifo_in_ready(final_fifo_in_ready)
    
);

endmodule

module standard_planar_code_3d_no_fast_channel_with_stage_controller_right #(
    CODE_DISTANCE = 5
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
    final_fifo_in_ready

);

localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;
localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + ADDRESS_WIDTH;
localparam FIFO_COUNT = CODE_DISTANCE * (CODE_DISTANCE - 1);

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

output [FINAL_FIFO_WIDTH - 1 :0] final_fifo_out_data;
output final_fifo_out_valid;
output final_fifo_out_ready;
output [FINAL_FIFO_WIDTH - 1 :0] final_fifo_in_data;
output final_fifo_in_valid;
output final_fifo_in_ready;

wire [PU_COUNT-1:0] is_odd_cardinalities;
wire [PU_COUNT-1:0] is_touching_boundaries;
wire has_message_flying;
wire [STAGE_WIDTH-1:0] stage;
wire [PU_COUNT-1:0] is_odd_clusters;
reg has_odd_clusters;

always@(posedge clk) begin
    has_odd_clusters <= |is_odd_clusters;
end

wire [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
wire [MASTER_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
wire [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
wire sc_fifo_out_valid;
wire sc_fifo_out_ready;
wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
wire sc_fifo_in_valid;
wire sc_fifo_in_ready;

standard_planar_code_3d_no_fast_channel_right #(.CODE_DISTANCE(CODE_DISTANCE)) decoder_right (
    .clk(clk),
    .reset(reset),
    .stage(stage),
    .is_error_syndromes(is_error_syndromes),
    .is_odd_clusters(is_odd_clusters),
    .is_odd_cardinalities(is_odd_cardinalities),
    .is_touching_boundaries(is_touching_boundaries),
    .roots(roots),
    .has_message_flying(has_message_flying),
    .master_fifo_out_data_vector(master_fifo_out_data_vector),
    .master_fifo_out_valid_vector(master_fifo_out_valid_vector),
    .master_fifo_out_ready_vector(master_fifo_out_ready_vector),
    .master_fifo_in_data_vector(master_fifo_in_data_vector),
    .master_fifo_in_valid_vector(master_fifo_in_valid_vector),
    .master_fifo_in_ready_vector(master_fifo_in_ready_vector)
);

decoder_stage_controller_right #(
    .CODE_DISTANCE(CODE_DISTANCE), 
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller_right (
    .clk(clk),
    .reset(reset),
    .has_message_flying(has_message_flying),
    .has_odd_clusters(has_odd_clusters),
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

final_arbitration_unit u_final_arbitration_unit_right (
    .master_fifo_out_data(master_fifo_out_data_vector),
    .master_fifo_out_valid(master_fifo_out_valid_vector),
    .master_fifo_out_ready(master_fifo_out_ready_vector),
    .master_fifo_in_data(master_fifo_in_data_vector),
    .master_fifo_in_valid(master_fifo_in_valid_vector),
    .master_fifo_in_ready(master_fifo_in_ready_vector)
    .sc_fifo_out_data(sc_fifo_out_data),
    .sc_fifo_out_valid(sc_fifo_out_valid),
    .sc_fifo_out_ready(sc_fifo_out_ready),
    .sc_fifo_in_data(sc_fifo_in_data),
    .sc_fifo_in_valid(sc_fifo_in_valid),
    .sc_fifo_in_ready(sc_fifo_in_ready)
    .final_fifo_out_data(final_fifo_out_data),
    .final_fifo_out_valid(final_fifo_out_valid),
    .final_fifo_out_ready(final_fifo_out_ready),
    .final_fifo_in_data(final_fifo_in_data),
    .final_fifo_in_valid(final_fifo_in_valid),
    .final_fifo_in_ready(final_fifo_in_ready)
    
);

endmodule