wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots_/*$$ID*/

// instantiate
top_module_for_leaf_/*$$ID*/ #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_UD(WEIGHT_UD)
) u_leaf_/*$$ID*/ (
    .clk(clk),
    .reset(reset),
    .new_round_start(),
    .is_error_syndromes(is_error_syndromes),
    .roots(roots_/*$$ID*/),
    .result_valid(),
    .iteration_counter(),
    .cycle_counter(),
    .deadlock(),
    .final_cardinality(),
    .final_fifo_out_data(downstream_fifo_in_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_WIDTH : /*$$CHILD_ID*/ *INTERCONNECT_WIDTH]),
    .final_fifo_out_valid(downstream_fifo_in_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .final_fifo_out_ready(downstream_fifo_in_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .final_fifo_in_data(downstream_fifo_out_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_WIDTH : /*$$CHILD_ID*/ *INTERCONNECT_WIDTH]),
    .final_fifo_in_valid(downstream_fifo_out_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .final_fifo_in_ready(downstream_fifo_out_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .has_message_flying_otherside(downstream_has_message_flying_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .has_odd_clusters_otherside(downstream_has_odd_cluster_d_/*$$PARENT*/[/*$$CHILD_ID*/])
);