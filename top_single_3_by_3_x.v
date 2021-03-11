module top_single_3_by_3_x 
(
	measurement_value_in_0_0,
	measurement_valid_in_0_0,
	match_value_out_0_0,
	measurement_value_in_0_1,
	measurement_valid_in_0_1,
	match_value_out_0_1,
	measurement_value_in_0_2,
	measurement_valid_in_0_2,
	match_value_out_0_2,
	measurement_value_in_1_0,
	measurement_valid_in_1_0,
	match_value_out_1_0,
	measurement_value_in_1_1,
	measurement_valid_in_1_1,
	match_value_out_1_1,
	measurement_value_in_1_2,
	measurement_valid_in_1_2,
	match_value_out_1_2,
	start_offer,
	stop_offer
);

// This is 3 by 2 grid of x stabilizers

`include "parameters.v"

input measurement_value_in_0_0;
input measurement_valid_in_0_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_0;
input measurement_value_in_0_1;
input measurement_valid_in_0_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_1;
input measurement_value_in_0_2;
input measurement_valid_in_0_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_2;
input measurement_value_in_1_0;
input measurement_valid_in_1_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_0;
input measurement_value_in_1_1;
input measurement_valid_in_1_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_1;
input measurement_value_in_1_2;
input measurement_valid_in_1_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_2;
input start_offer;
input stop_offer;

wire [MSG_WIDTH -1 : 0] north_south_value_0_0_1_0;
wire north_south_valid_0_0_1_0;
wire north_south_ready_0_0_1_0;
wire [MSG_WIDTH -1 : 0] south_north_value_0_0_1_0;
wire south_north_valid_0_0_1_0;
wire south_north_ready_0_0_1_0;
wire [MSG_WIDTH -1 : 0] north_south_value_0_1_1_1;
wire north_south_valid_0_1_1_1;
wire north_south_ready_0_1_1_1;
wire [MSG_WIDTH -1 : 0] south_north_value_0_1_1_1;
wire south_north_valid_0_1_1_1;
wire south_north_ready_0_1_1_1;
wire [MSG_WIDTH -1 : 0] north_south_value_0_2_1_2;
wire north_south_valid_0_2_1_2;
wire north_south_ready_0_2_1_2;
wire [MSG_WIDTH -1 : 0] south_north_value_0_2_1_2;
wire south_north_valid_0_2_1_2;
wire south_north_ready_0_2_1_2;
wire [MSG_WIDTH -1 : 0] east_west_value_0_0_1_0;
wire east_west_valid_0_0_0_1;
wire east_west_ready_0_0_0_1;
wire [MSG_WIDTH -1 : 0] west_east_value_0_0_0_1;
wire west_east_valid_0_0_0_1;
wire west_east_ready_0_0_0_1;
wire [MSG_WIDTH -1 : 0] east_west_value_0_1_1_1;
wire east_west_valid_0_1_0_2;
wire east_west_ready_0_1_0_2;
wire [MSG_WIDTH -1 : 0] west_east_value_0_1_0_2;
wire west_east_valid_0_1_0_2;
wire west_east_ready_0_1_0_2;
wire [MSG_WIDTH -1 : 0] east_west_value_1_0_2_0;
wire east_west_valid_1_0_1_1;
wire east_west_ready_1_0_1_1;
wire [MSG_WIDTH -1 : 0] west_east_value_1_0_1_1;
wire west_east_valid_1_0_1_1;
wire west_east_ready_1_0_1_1;
wire [MSG_WIDTH -1 : 0] east_west_value_1_1_2_1;
wire east_west_valid_1_1_1_2;
wire east_west_ready_1_1_1_2;
wire [MSG_WIDTH -1 : 0] west_east_value_1_1_1_2;
wire west_east_valid_1_1_1_2;
wire west_east_ready_1_1_1_2;
wire ready_open_north_0_0;
wire [MSG_WIDTH -1 : 0] value_open_north_0_0;
wire valid_open_north_0_0;
wire ready_open_south_1_0;
wire [MSG_WIDTH -1 : 0] value_open_south_1_0;
wire valid_open_south_1_0;
wire ready_open_north_0_1;
wire [MSG_WIDTH -1 : 0] value_open_north_0_1;
wire valid_open_north_0_1;
wire ready_open_south_1_1;
wire [MSG_WIDTH -1 : 0] value_open_south_1_1;
wire valid_open_south_1_1;
wire ready_open_north_0_2;
wire [MSG_WIDTH -1 : 0] value_open_north_0_2;
wire valid_open_north_0_2;
wire ready_open_south_1_2;
wire [MSG_WIDTH -1 : 0] value_open_south_1_2;
wire valid_open_south_1_2;
wire ready_open_west_0_0;
wire [MSG_WIDTH -1 : 0] value_open_west_0_0;
wire valid_open_west_0_0;
wire ready_open_east_0_2;
wire [MSG_WIDTH -1 : 0] value_open_east_0_2;
wire valid_open_east_0_2;
wire ready_open_west_1_0;
wire [MSG_WIDTH -1 : 0] value_open_west_1_0;
wire valid_open_west_1_0;
wire ready_open_east_1_2;
wire [MSG_WIDTH -1 : 0] value_open_east_1_2;
wire valid_open_east_1_2;

pe unit_0_0 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_0),
	.measurement_valid_in(measurement_valid_in_0_0),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_0),
	.mailbox_east_value_in(east_west_value_0_0_0_1),
	.mailbox_east_valid_in(east_west_valid_0_0_0_1),
	.mailbox_east_ready_out(east_west_ready_0_0_0_1),
	.mailbox_south_value_in(south_north_value_0_0_1_0),
	.mailbox_south_valid_in(south_north_valid_0_0_1_0),
	.mailbox_south_ready_out(south_north_ready_0_0_1_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_0_0),
	.outqueue_north_value_out(value_open_north_0_0),
	.outqueue_north_valid_out(valid_open_north_0_0),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(west_east_value_0_0_0_1),
	.outqueue_east_valid_out(west_east_valid_0_0_0_1),
	.outqueue_east_ready_in(west_east_ready_0_0_0_1),
	.outqueue_south_value_out(north_south_value_0_0_1_0),
	.outqueue_south_valid_out(north_south_valid_0_0_1_0),
	.outqueue_south_ready_in(north_south_ready_0_0_1_0),
	.outqueue_west_value_out(value_open_west_0_0),
	.outqueue_west_valid_out(valid_open_west_0_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_0_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(0),
	.BOUNDARY_COST(stop_offer),
);

pe unit_0_1 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_1),
	.measurement_valid_in(measurement_valid_in_0_1),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_1),
	.mailbox_east_value_in(east_west_value_0_1_0_2),
	.mailbox_east_valid_in(east_west_valid_0_1_0_2),
	.mailbox_east_ready_out(east_west_ready_0_1_0_2),
	.mailbox_south_value_in(south_north_value_0_1_1_1),
	.mailbox_south_valid_in(south_north_valid_0_1_1_1),
	.mailbox_south_ready_out(south_north_ready_0_1_1_1),
	.mailbox_west_value_in(west_east_value_0_0_0_1),
	.mailbox_west_valid_in(west_east_valid_0_0_0_1),
	.mailbox_west_ready_out(west_east_ready_0_0_0_1),
	.outqueue_north_value_out(value_open_north_0_1),
	.outqueue_north_valid_out(valid_open_north_0_1),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(west_east_value_0_1_0_2),
	.outqueue_east_valid_out(west_east_valid_0_1_0_2),
	.outqueue_east_ready_in(west_east_ready_0_1_0_2),
	.outqueue_south_value_out(north_south_value_0_1_1_1),
	.outqueue_south_valid_out(north_south_valid_0_1_1_1),
	.outqueue_south_ready_in(north_south_ready_0_1_1_1),
	.outqueue_west_value_out(east_west_value_0_0_0_1),
	.outqueue_west_valid_out(east_west_valid_0_0_0_1),
	.outqueue_west_ready_in(east_west_ready_0_0_0_1),
	.match_value_out(match_value_out_0_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(1),
	.BOUNDARY_COST(stop_offer),
);

pe unit_0_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_2),
	.measurement_valid_in(measurement_valid_in_0_2),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_2),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_0_2),
	.mailbox_south_value_in(south_north_value_0_2_1_2),
	.mailbox_south_valid_in(south_north_valid_0_2_1_2),
	.mailbox_south_ready_out(south_north_ready_0_2_1_2),
	.mailbox_west_value_in(west_east_value_0_1_0_2),
	.mailbox_west_valid_in(west_east_valid_0_1_0_2),
	.mailbox_west_ready_out(west_east_ready_0_1_0_2),
	.outqueue_north_value_out(value_open_north_0_2),
	.outqueue_north_valid_out(valid_open_north_0_2),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(value_open_east_0_2),
	.outqueue_east_valid_out(valid_open_east_0_2),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(north_south_value_0_2_1_2),
	.outqueue_south_valid_out(north_south_valid_0_2_1_2),
	.outqueue_south_ready_in(north_south_ready_0_2_1_2),
	.outqueue_west_value_out(east_west_value_0_1_0_2),
	.outqueue_west_valid_out(east_west_valid_0_1_0_2),
	.outqueue_west_ready_in(east_west_ready_0_1_0_2),
	.match_value_out(match_value_out_0_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(2),
	.BOUNDARY_COST(stop_offer),
);

pe unit_1_0 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_0),
	.measurement_valid_in(measurement_valid_in_1_0),
	.mailbox_north_value_in(north_south_value_0_0_1_0),
	.mailbox_north_valid_in(north_south_valid_0_0_1_0),
	.mailbox_north_ready_out(north_south_ready_0_0_1_0),
	.mailbox_east_value_in(east_west_value_1_0_1_1),
	.mailbox_east_valid_in(east_west_valid_1_0_1_1),
	.mailbox_east_ready_out(east_west_ready_1_0_1_1),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_1_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_1_0),
	.outqueue_north_value_out(south_north_value_0_0_1_0),
	.outqueue_north_valid_out(south_north_valid_0_0_1_0),
	.outqueue_north_ready_in(south_north_ready_0_0_1_0),
	.outqueue_east_value_out(west_east_value_1_0_1_1),
	.outqueue_east_valid_out(west_east_valid_1_0_1_1),
	.outqueue_east_ready_in(west_east_ready_1_0_1_1),
	.outqueue_south_value_out(value_open_south_1_0),
	.outqueue_south_valid_out(valid_open_south_1_0),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(value_open_west_1_0),
	.outqueue_west_valid_out(valid_open_west_1_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_1_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(0),
	.BOUNDARY_COST(stop_offer),
);

pe unit_1_1 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_1),
	.measurement_valid_in(measurement_valid_in_1_1),
	.mailbox_north_value_in(north_south_value_0_1_1_1),
	.mailbox_north_valid_in(north_south_valid_0_1_1_1),
	.mailbox_north_ready_out(north_south_ready_0_1_1_1),
	.mailbox_east_value_in(east_west_value_1_1_1_2),
	.mailbox_east_valid_in(east_west_valid_1_1_1_2),
	.mailbox_east_ready_out(east_west_ready_1_1_1_2),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_1_1),
	.mailbox_west_value_in(west_east_value_1_0_1_1),
	.mailbox_west_valid_in(west_east_valid_1_0_1_1),
	.mailbox_west_ready_out(west_east_ready_1_0_1_1),
	.outqueue_north_value_out(south_north_value_0_1_1_1),
	.outqueue_north_valid_out(south_north_valid_0_1_1_1),
	.outqueue_north_ready_in(south_north_ready_0_1_1_1),
	.outqueue_east_value_out(west_east_value_1_1_1_2),
	.outqueue_east_valid_out(west_east_valid_1_1_1_2),
	.outqueue_east_ready_in(west_east_ready_1_1_1_2),
	.outqueue_south_value_out(value_open_south_1_1),
	.outqueue_south_valid_out(valid_open_south_1_1),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_1_0_1_1),
	.outqueue_west_valid_out(east_west_valid_1_0_1_1),
	.outqueue_west_ready_in(east_west_ready_1_0_1_1),
	.match_value_out(match_value_out_1_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(1),
	.BOUNDARY_COST(stop_offer),
);

pe unit_1_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_2),
	.measurement_valid_in(measurement_valid_in_1_2),
	.mailbox_north_value_in(north_south_value_0_2_1_2),
	.mailbox_north_valid_in(north_south_valid_0_2_1_2),
	.mailbox_north_ready_out(north_south_ready_0_2_1_2),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_1_2),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_1_2),
	.mailbox_west_value_in(west_east_value_1_1_1_2),
	.mailbox_west_valid_in(west_east_valid_1_1_1_2),
	.mailbox_west_ready_out(west_east_ready_1_1_1_2),
	.outqueue_north_value_out(south_north_value_0_2_1_2),
	.outqueue_north_valid_out(south_north_valid_0_2_1_2),
	.outqueue_north_ready_in(south_north_ready_0_2_1_2),
	.outqueue_east_value_out(value_open_east_1_2),
	.outqueue_east_valid_out(valid_open_east_1_2),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(value_open_south_1_2),
	.outqueue_south_valid_out(valid_open_south_1_2),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_1_1_1_2),
	.outqueue_west_valid_out(east_west_valid_1_1_1_2),
	.outqueue_west_ready_in(east_west_ready_1_1_1_2),
	.match_value_out(match_value_out_1_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(2),
	.BOUNDARY_COST(stop_offer),
);

endmodule