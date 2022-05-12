interonncetion_model_wrapper #(
    .WIDTH(WIDTH),
    .LATENCY(LATENCY)
) u_interconnection_model_/*$$ID*/(
    .clk(clk),
    .reset(reset),


    .upstream_fifo_out_data(downstream_fifo_in_data_/*$$ID*/),
    .upstream_fifo_out_valid(downstream_fifo_in_valid_/*$$ID*/),
    .upstream_fifo_out_ready(downstream_fifo_in_ready_/*$$ID*/),
    .upstream_fifo_in_data(downstream_fifo_out_data_/*$$ID*/),
    .upstream_fifo_in_valid(downstream_fifo_out_valid_/*$$ID*/]),
    .upstream_fifo_in_ready(downstream_fifo_out_ready_/*$$ID*/),

    .downstream_fifo_out_data(downstream_fifo_out_data_d_/*$$ID*/),
    .downstream_fifo_out_valid(downstream_fifo_out_valid_d_/*$$ID*/),
    .downstream_fifo_out_ready(downstream_fifo_out_ready_d_/*$$ID*/),
    .downstream_fifo_in_data(downstream_fifo_in_data_d_/*$$ID*/),
    .downstream_fifo_in_valid(downstream_fifo_in_valid_d_/*$$ID*/),
    .downstream_fifo_in_ready(downstream_fifo_in_ready_d_/*$$ID*/),

    .upstream_has_message_flying(downstream_has_message_flying_d_/*$$ID*/),
    .upstream_has_odd_clusters(downstream_has_odd_cluster_d_/*$$ID*/),

    .downstream_has_message_flying(downstream_has_message_flying_/*$$ID*/),
    .downstream_has_odd_clusters(downstream_has_odd_clusters_/*$$ID*/)
);