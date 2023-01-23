wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots_/*$$ID*/;

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
    // .final_fifo_out_data(downstream_fifo_in_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_PHYSICAL_WIDTH  - 1: /*$$CHILD_ID*/ *INTERCONNECT_PHYSICAL_WIDTH]),
    // .final_fifo_out_valid(downstream_fifo_in_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    // .final_fifo_out_ready(downstream_fifo_in_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    // .final_fifo_in_data(downstream_fifo_out_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_PHYSICAL_WIDTH - 1: /*$$CHILD_ID*/ *INTERCONNECT_PHYSICAL_WIDTH]),
    // .final_fifo_in_valid(downstream_fifo_out_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    // .final_fifo_in_ready(downstream_fifo_out_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .has_message_flying(downstream_has_message_flying_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .has_odd_clusters(downstream_has_odd_clusters_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .state_signal(downstream_state_signal_d_/*$$PARENT*/)
);


generate
    for (k2=0; k2 < MEASUREMENT_ROUNDS; k2=k2+1) begin: assign_k_/*$$ID*/
        for (i2=/*$$X_START*/; i2 <= /*$$X_END*/; i2=i2+1) begin: assign_i_/*$$ID*/
            for (j2=0; j2 < CODE_DISTANCE_Z; j2=j2+1) begin: assign_j_/*$$ID*/
                assign `root(i2, j2, k2) = roots_/*$$ID*/[ADDRESS_WIDTH*`INDEX(i2, j2, k2) +: ADDRESS_WIDTH];
            end
        end
    end
endgenerate

