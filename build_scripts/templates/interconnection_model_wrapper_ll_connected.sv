interonncetion_model #(
    .WIDTH(INTERCONNECT_PHYSICAL_WIDTH),
    .LATENCY(/*$$INTERCONNECTION_LATENCY*/),
    .CHANNELS(/*$$NUM_CHILDREN*/)
) u_interconnection_model_/*$$INTERCONNECT_ID*/(
    .clk(clk),
    .reset(reset),


    .upstream_fifo_out_data(final_fifo_in_data_leaf_/*$$WEST_ID*/[3*INTERCONNECT_PHYSICAL_WIDTH - 1 : 2*INTERCONNECT_PHYSICAL_WIDTH]),
    .upstream_fifo_out_valid(final_fifo_in_valid_leaf_/*$$WEST_ID*/[2]),
    .upstream_fifo_out_ready(final_fifo_in_ready_leaf_/*$$WEST_ID*/[2]),
    .upstream_fifo_in_data(final_fifo_out_data_leaf_/*$$WEST_ID*/[3*INTERCONNECT_PHYSICAL_WIDTH - 1 : 2*INTERCONNECT_PHYSICAL_WIDTH]),
    .upstream_fifo_in_valid(final_fifo_out_valid_leaf_/*$$WEST_ID*/[2]),
    .upstream_fifo_in_ready(final_fifo_out_ready_leaf_/*$$WEST_ID*/[2]),

    .downstream_fifo_out_data(final_fifo_in_data_leaf_/*$$EAST_ID*/[2*INTERCONNECT_PHYSICAL_WIDTH - 1 : INTERCONNECT_PHYSICAL_WIDTH]),
    .downstream_fifo_out_valid(final_fifo_in_valid_leaf_/*$$EAST_ID*/[1]),
    .downstream_fifo_out_ready(final_fifo_in_ready_leaf_/*$$EAST_ID*/[1]),
    .downstream_fifo_in_data(final_fifo_out_data_leaf_/*$$EAST_ID*/[2*INTERCONNECT_PHYSICAL_WIDTH - 1 : INTERCONNECT_PHYSICAL_WIDTH]),
    .downstream_fifo_in_valid(final_fifo_out_valid_leaf_/*$$EAST_ID*/[1]),
    .downstream_fifo_in_ready(final_fifo_out_ready_leaf_/*$$EAST_ID*/[1]),

    .upstream_has_message_flying(),
    .upstream_has_odd_clusters(),

    .downstream_has_message_flying(),
    .downstream_has_odd_clusters()
);

