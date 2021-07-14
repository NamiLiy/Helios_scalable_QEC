`timescale 1ns / 10ps

module bench_decoder;

`include "../sources_1/new/parameters.sv"
`define assert(condition, reason) if(!(condition)) begin $display(reason); $finish(1); end

localparam CODE_DISTANCE = 3;
localparam PU_COUNT = CODE_DISTANCE * CODE_DISTANCE * (CODE_DISTANCE - 1);
localparam PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations
localparam UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH;  // [old_root, updated_root]
localparam MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1;

reg clk;
reg reset;
reg new_round_start = 0;

reg left_has_message_flying;
reg left_has_odd_clusters;
reg [PU_COUNT-1:0] left_is_touching_boundaries;
reg [PU_COUNT-1:0] left_is_odd_cardinalities;
reg [(ADDRESS_WIDTH * PU_COUNT)-1:0] left_roots;
wire [STAGE_WIDTH-1:0] left_stage;
wire left_result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] left_iteration_counter;
wire [31:0] left_cycle_counter;
wire left_deadlock;
wire left_final_cardinality;
wire [MASTER_FIFO_WIDTH-1:0] left_sc_fifo_out_data;
wire left_sc_fifo_out_valid;
wire left_sc_fifo_out_ready;
wire has_message_flying_otherside;
wire has_odd_clusters_otherside;
wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] net_roots_out;

reg right_has_message_flying;
reg right_has_odd_clusters;
reg [PU_COUNT-1:0] right_is_touching_boundaries;
reg [PU_COUNT-1:0] right_is_odd_cardinalities;
reg [(ADDRESS_WIDTH * PU_COUNT)-1:0] right_roots;
wire [STAGE_WIDTH-1:0] right_stage;
wire right_result_valid;
wire [ITERATION_COUNTER_WIDTH-1:0] right_iteration_counter;
wire [31:0] right_cycle_counter;
wire right_deadlock;
wire right_final_cardinality;
wire [MASTER_FIFO_WIDTH-1:0] right_sc_fifo_out_data;
wire right_sc_fifo_out_valid;
wire right_sc_fifo_out_ready;

decoder_stage_controller_left  #(
    .CODE_DISTANCE(CODE_DISTANCE), 
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller_left (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .has_message_flying(left_has_message_flying),
    .has_odd_clusters(left_has_odd_clusters),
    .is_touching_boundaries(left_is_touching_boundaries),
    .is_odd_cardinalities(left_is_odd_cardinalities),
    .roots(left_roots),
    .stage(left_stage),
    .result_valid(left_result_valid),
    .iteration_counter(left_iteration_counter),
    .cycle_counter(left_cycle_counter),
    .deadlock(left_deadlock),
    .final_cardinality(left_final_cardinality),
    .sc_fifo_out_data(left_sc_fifo_out_data),
    .sc_fifo_out_valid(left_sc_fifo_out_valid),
    .sc_fifo_out_ready(left_sc_fifo_out_ready),
    .sc_fifo_in_data(right_sc_fifo_out_data),
    .sc_fifo_in_valid(right_sc_fifo_out_valid),
    .sc_fifo_in_ready(right_sc_fifo_out_ready),
    .has_message_flying_otherside(has_message_flying_otherside),
    .has_odd_clusters_otherside(has_odd_clusters_otherside),
    .net_roots_out(net_roots_out)
);

decoder_stage_controller_right #(
    .CODE_DISTANCE(CODE_DISTANCE), 
    .ITERATION_COUNTER_WIDTH(ITERATION_COUNTER_WIDTH)
) u_decoder_stage_controller_right (
    .clk(clk),
    .reset(reset),
    .new_round_start(new_round_start),
    .has_message_flying(right_has_message_flying),
    .has_odd_clusters(right_has_odd_clusters),
    .is_touching_boundaries(right_is_touching_boundaries),
    .is_odd_cardinalities(right_is_odd_cardinalities),
    .roots(right_roots),
    .stage(right_stage),
    .result_valid(right_result_valid),
    .iteration_counter(right_iteration_counter),
    .cycle_counter(right_cycle_counter),
    .deadlock(right_deadlock),
    .final_cardinality(right_final_cardinality),
    .sc_fifo_out_data(right_sc_fifo_out_data),
    .sc_fifo_out_valid(right_sc_fifo_out_valid),
    .sc_fifo_out_ready(right_sc_fifo_out_ready),
    .sc_fifo_in_data(left_sc_fifo_out_data),
    .sc_fifo_in_valid(left_sc_fifo_out_valid),
    .sc_fifo_in_ready(left_sc_fifo_out_ready),
    .has_message_flying_otherside(has_message_flying_otherside),
    .has_odd_clusters_otherside(has_odd_clusters_otherside)
);

integer i;
always #5 clk = ~clk;

initial begin
    clk = 1'b1;
    reset = 1'b1;
    new_round_start <= 0;

    left_has_message_flying = 0;
    left_has_odd_clusters = 0;
    left_is_touching_boundaries = 0;
    left_is_odd_cardinalities = 0;

    right_has_message_flying = 0;
    right_has_odd_clusters = 0;
    right_is_touching_boundaries = 0;
    right_is_odd_cardinalities = 0;
    left_roots = 0;
    right_roots = 0;
    for(i = 0; i < 12; i = i + 1) begin
        left_roots[ADDRESS_WIDTH*i+:ADDRESS_WIDTH] = i;    
    end
    for(i = 0; i < 6; i = i + 1) begin
        right_roots[ADDRESS_WIDTH*i+:ADDRESS_WIDTH] = i+12;    
    end
    #107;
    reset = 1'b0;
    #100;
    new_round_start = 1;
    #10;
    new_round_start = 0;
    #1000;
    `assert(left_result_valid == 1, "result_valid should be 1");
end
endmodule
