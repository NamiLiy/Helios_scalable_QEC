wire [/*$$NUM_CHILDREN*/*INTERCONNECT_WIDTH - 1 : 0] downstream_fifo_in_data_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_valid_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_ready_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/*INTERCONNECT_WIDTH - 1 : 0] downstream_fifo_out_data_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_valid_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_ready_/*$$ID*/;

wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_message_flying_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_odd_clusters_/*$$ID*/;

wire [/*$$NUM_CHILDREN*/*INTERCONNECT_WIDTH - 1 : 0] downstream_fifo_in_data_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_valid_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_in_ready_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/*INTERCONNECT_WIDTH - 1 : 0] downstream_fifo_out_data_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_valid_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_fifo_out_ready_d_/*$$ID*/;

wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_message_flying_d_/*$$ID*/;
wire [/*$$NUM_CHILDREN*/ - 1 : 0] downstream_has_odd_clusters_d_/*$$ID*/;

top_module_hub_/*$$ID*/ #(
    .CODE_DISTANCE_X(/*$$CODE_DISTANCE_X*/),
    .CODE_DISTANCE_Z(/*$$CODE_DISTANCE_Z*/)
    .WEIGHT_X(WEIGHT_X)
    .WEIGHT_Z(WEIGHT_Z)
    .WEIGHT_UD(WEIGHT_UD)
) u_hub_/*$$ID*/ (
    .clk(clk),
    .reset(reset),

    // Temporary ports for debug
    // .new_round_start(new_round_start),
    // .is_error_syndromes(is_error_syndromes),
    // .roots(roots),
    // .result_valid(result_valid),
    // .iteration_counter(iteration_counter),
    // .cycle_counter(cycle_counter),
    // .deadlock(deadlock),
    // .final_cardinality(final_cardinality)


    .upstream_fifo_out_data(downstream_fifo_in_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_WIDTH : /*$$CHILD_ID*/ *INTERCONNECT_WIDTH]),
    .upstream_fifo_out_valid(downstream_fifo_in_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .upstream_fifo_out_ready(downstream_fifo_in_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .upstream_fifo_in_data(downstream_fifo_out_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_WIDTH : /*$$CHILD_ID*/ *INTERCONNECT_WIDTH]),
    .upstream_fifo_in_valid(downstream_fifo_out_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .upstream_fifo_in_ready(downstream_fifo_out_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/]),

    .downstream_fifo_out_data(downstream_fifo_out_data_/*$$ID*/),
    .downstream_fifo_out_valid(downstream_fifo_out_valid_/*$$ID*/),
    .downstream_fifo_out_ready(downstream_fifo_out_ready_/*$$ID*/),
    .downstream_fifo_in_data(downstream_fifo_in_data_/*$$ID*/),
    .downstream_fifo_in_valid(downstream_fifo_in_valid_/*$$ID*/),
    .downstream_fifo_in_ready(downstream_fifo_in_ready_/*$$ID*/),

    .upstream_has_message_flying(downstream_has_message_flying_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .upstream_has_odd_clusters(downstream_has_odd_cluster_d_/*$$PARENT*/[/*$$CHILD_ID*/]),

    .downstream_has_message_flying(downstream_has_message_flying_/*$$ID*/),
    .downstream_has_odd_clusters(downstream_has_odd_clusters_/*$$ID*/)
);



