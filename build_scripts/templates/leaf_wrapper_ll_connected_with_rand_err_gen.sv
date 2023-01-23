wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots_/*$$ID*/;

wire [INTERCONNECT_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_out_data_leaf_/*$$ID*/;
wire [FPGA_NEIGHBORS : 0] final_fifo_out_valid_leaf_/*$$ID*/;
wire [FPGA_NEIGHBORS : 0] final_fifo_out_ready_leaf_/*$$ID*/;
wire [INTERCONNECT_PHYSICAL_WIDTH*(FPGA_NEIGHBORS + 1) - 1 :0] final_fifo_in_data_leaf_/*$$ID*/;
wire [FPGA_NEIGHBORS : 0] final_fifo_in_valid_leaf_/*$$ID*/;
wire [FPGA_NEIGHBORS : 0] final_fifo_in_ready_leaf_/*$$ID*/;


assign downstream_fifo_in_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_PHYSICAL_WIDTH  - 1: /*$$CHILD_ID*/ *INTERCONNECT_PHYSICAL_WIDTH] = final_fifo_out_data_leaf_/*$$ID*/[INTERCONNECT_PHYSICAL_WIDTH - 1 : 0];
assign downstream_fifo_in_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/] = final_fifo_out_valid_leaf_/*$$ID*/[0];
assign final_fifo_out_ready_leaf_/*$$ID*/[0] = downstream_fifo_in_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/];
assign final_fifo_in_data_leaf_/*$$ID*/[INTERCONNECT_PHYSICAL_WIDTH - 1 : 0] = downstream_fifo_out_data_d_/*$$PARENT*/[(/*$$CHILD_ID*/ + 1)*INTERCONNECT_PHYSICAL_WIDTH - 1: /*$$CHILD_ID*/ *INTERCONNECT_PHYSICAL_WIDTH];
assign final_fifo_in_valid_leaf_/*$$ID*/[0] = downstream_fifo_out_valid_d_/*$$PARENT*/[/*$$CHILD_ID*/];
assign downstream_fifo_out_ready_d_/*$$PARENT*/[/*$$CHILD_ID*/] = final_fifo_in_ready_leaf_/*$$ID*/[0];


// instantiate
top_module_for_leaf_with_rand_err_gen_/*$$ID*/ #(
    .CODE_DISTANCE_X(CODE_DISTANCE_X),
    .CODE_DISTANCE_Z(CODE_DISTANCE_Z),
    .WEIGHT_X(WEIGHT_X),
    .WEIGHT_Z(WEIGHT_Z),
    .WEIGHT_UD(WEIGHT_UD)
) u_leaf_/*$$ID*/ (
    .clk(clk),
    .reset(reset),
    .new_round_start(),
    .roots(roots_/*$$ID*/),
    .result_valid(),
    .iteration_counter(),
    .cycle_counter(),
    .deadlock(),
    .final_cardinality(),
    .final_fifo_out_data(final_fifo_out_data_leaf_/*$$ID*/),
    .final_fifo_out_valid(final_fifo_out_valid_leaf_/*$$ID*/),
    .final_fifo_out_ready(final_fifo_out_ready_leaf_/*$$ID*/),
    .final_fifo_in_data(final_fifo_in_data_leaf_/*$$ID*/),
    .final_fifo_in_valid(final_fifo_in_valid_leaf_/*$$ID*/),
    .final_fifo_in_ready(final_fifo_in_ready_leaf_/*$$ID*/),
    .has_message_flying(downstream_has_message_flying_d_/*$$PARENT*/[/*$$CHILD_ID*/]),
    .has_odd_clusters(downstream_has_odd_clusters_d_/*$$PARENT*/[/*$$CHILD_ID*/])
);

