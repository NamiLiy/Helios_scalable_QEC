module top_single_7_by_7_x 
(
	clk,
	reset,
	measurement_value_in_0_0,
	measurement_valid_in_0_0,
	match_value_out_0_0,
	measurement_0_0,
	measurement_value_in_0_1,
	measurement_valid_in_0_1,
	match_value_out_0_1,
	measurement_0_1,
	measurement_value_in_0_2,
	measurement_valid_in_0_2,
	match_value_out_0_2,
	measurement_0_2,
	measurement_value_in_0_3,
	measurement_valid_in_0_3,
	match_value_out_0_3,
	measurement_0_3,
	measurement_value_in_0_4,
	measurement_valid_in_0_4,
	match_value_out_0_4,
	measurement_0_4,
	measurement_value_in_0_5,
	measurement_valid_in_0_5,
	match_value_out_0_5,
	measurement_0_5,
	measurement_value_in_0_6,
	measurement_valid_in_0_6,
	match_value_out_0_6,
	measurement_0_6,
	measurement_value_in_1_0,
	measurement_valid_in_1_0,
	match_value_out_1_0,
	measurement_1_0,
	measurement_value_in_1_1,
	measurement_valid_in_1_1,
	match_value_out_1_1,
	measurement_1_1,
	measurement_value_in_1_2,
	measurement_valid_in_1_2,
	match_value_out_1_2,
	measurement_1_2,
	measurement_value_in_1_3,
	measurement_valid_in_1_3,
	match_value_out_1_3,
	measurement_1_3,
	measurement_value_in_1_4,
	measurement_valid_in_1_4,
	match_value_out_1_4,
	measurement_1_4,
	measurement_value_in_1_5,
	measurement_valid_in_1_5,
	match_value_out_1_5,
	measurement_1_5,
	measurement_value_in_1_6,
	measurement_valid_in_1_6,
	match_value_out_1_6,
	measurement_1_6,
	measurement_value_in_2_0,
	measurement_valid_in_2_0,
	match_value_out_2_0,
	measurement_2_0,
	measurement_value_in_2_1,
	measurement_valid_in_2_1,
	match_value_out_2_1,
	measurement_2_1,
	measurement_value_in_2_2,
	measurement_valid_in_2_2,
	match_value_out_2_2,
	measurement_2_2,
	measurement_value_in_2_3,
	measurement_valid_in_2_3,
	match_value_out_2_3,
	measurement_2_3,
	measurement_value_in_2_4,
	measurement_valid_in_2_4,
	match_value_out_2_4,
	measurement_2_4,
	measurement_value_in_2_5,
	measurement_valid_in_2_5,
	match_value_out_2_5,
	measurement_2_5,
	measurement_value_in_2_6,
	measurement_valid_in_2_6,
	match_value_out_2_6,
	measurement_2_6,
	measurement_value_in_3_0,
	measurement_valid_in_3_0,
	match_value_out_3_0,
	measurement_3_0,
	measurement_value_in_3_1,
	measurement_valid_in_3_1,
	match_value_out_3_1,
	measurement_3_1,
	measurement_value_in_3_2,
	measurement_valid_in_3_2,
	match_value_out_3_2,
	measurement_3_2,
	measurement_value_in_3_3,
	measurement_valid_in_3_3,
	match_value_out_3_3,
	measurement_3_3,
	measurement_value_in_3_4,
	measurement_valid_in_3_4,
	match_value_out_3_4,
	measurement_3_4,
	measurement_value_in_3_5,
	measurement_valid_in_3_5,
	match_value_out_3_5,
	measurement_3_5,
	measurement_value_in_3_6,
	measurement_valid_in_3_6,
	match_value_out_3_6,
	measurement_3_6,
	measurement_value_in_4_0,
	measurement_valid_in_4_0,
	match_value_out_4_0,
	measurement_4_0,
	measurement_value_in_4_1,
	measurement_valid_in_4_1,
	match_value_out_4_1,
	measurement_4_1,
	measurement_value_in_4_2,
	measurement_valid_in_4_2,
	match_value_out_4_2,
	measurement_4_2,
	measurement_value_in_4_3,
	measurement_valid_in_4_3,
	match_value_out_4_3,
	measurement_4_3,
	measurement_value_in_4_4,
	measurement_valid_in_4_4,
	match_value_out_4_4,
	measurement_4_4,
	measurement_value_in_4_5,
	measurement_valid_in_4_5,
	match_value_out_4_5,
	measurement_4_5,
	measurement_value_in_4_6,
	measurement_valid_in_4_6,
	match_value_out_4_6,
	measurement_4_6,
	measurement_value_in_5_0,
	measurement_valid_in_5_0,
	match_value_out_5_0,
	measurement_5_0,
	measurement_value_in_5_1,
	measurement_valid_in_5_1,
	match_value_out_5_1,
	measurement_5_1,
	measurement_value_in_5_2,
	measurement_valid_in_5_2,
	match_value_out_5_2,
	measurement_5_2,
	measurement_value_in_5_3,
	measurement_valid_in_5_3,
	match_value_out_5_3,
	measurement_5_3,
	measurement_value_in_5_4,
	measurement_valid_in_5_4,
	match_value_out_5_4,
	measurement_5_4,
	measurement_value_in_5_5,
	measurement_valid_in_5_5,
	match_value_out_5_5,
	measurement_5_5,
	measurement_value_in_5_6,
	measurement_valid_in_5_6,
	match_value_out_5_6,
	measurement_5_6,
	start_offer,
	stop_offer
);

// This is 7 by 6 grid of x stabilizers

`include "parameters.v"

input clk;
input reset;
input measurement_value_in_0_0;
input measurement_valid_in_0_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_0;
output measurement_0_0;
input measurement_value_in_0_1;
input measurement_valid_in_0_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_1;
output measurement_0_1;
input measurement_value_in_0_2;
input measurement_valid_in_0_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_2;
output measurement_0_2;
input measurement_value_in_0_3;
input measurement_valid_in_0_3;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_3;
output measurement_0_3;
input measurement_value_in_0_4;
input measurement_valid_in_0_4;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_4;
output measurement_0_4;
input measurement_value_in_0_5;
input measurement_valid_in_0_5;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_5;
output measurement_0_5;
input measurement_value_in_0_6;
input measurement_valid_in_0_6;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_0_6;
output measurement_0_6;
input measurement_value_in_1_0;
input measurement_valid_in_1_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_0;
output measurement_1_0;
input measurement_value_in_1_1;
input measurement_valid_in_1_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_1;
output measurement_1_1;
input measurement_value_in_1_2;
input measurement_valid_in_1_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_2;
output measurement_1_2;
input measurement_value_in_1_3;
input measurement_valid_in_1_3;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_3;
output measurement_1_3;
input measurement_value_in_1_4;
input measurement_valid_in_1_4;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_4;
output measurement_1_4;
input measurement_value_in_1_5;
input measurement_valid_in_1_5;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_5;
output measurement_1_5;
input measurement_value_in_1_6;
input measurement_valid_in_1_6;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_1_6;
output measurement_1_6;
input measurement_value_in_2_0;
input measurement_valid_in_2_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_0;
output measurement_2_0;
input measurement_value_in_2_1;
input measurement_valid_in_2_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_1;
output measurement_2_1;
input measurement_value_in_2_2;
input measurement_valid_in_2_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_2;
output measurement_2_2;
input measurement_value_in_2_3;
input measurement_valid_in_2_3;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_3;
output measurement_2_3;
input measurement_value_in_2_4;
input measurement_valid_in_2_4;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_4;
output measurement_2_4;
input measurement_value_in_2_5;
input measurement_valid_in_2_5;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_5;
output measurement_2_5;
input measurement_value_in_2_6;
input measurement_valid_in_2_6;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_2_6;
output measurement_2_6;
input measurement_value_in_3_0;
input measurement_valid_in_3_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_0;
output measurement_3_0;
input measurement_value_in_3_1;
input measurement_valid_in_3_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_1;
output measurement_3_1;
input measurement_value_in_3_2;
input measurement_valid_in_3_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_2;
output measurement_3_2;
input measurement_value_in_3_3;
input measurement_valid_in_3_3;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_3;
output measurement_3_3;
input measurement_value_in_3_4;
input measurement_valid_in_3_4;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_4;
output measurement_3_4;
input measurement_value_in_3_5;
input measurement_valid_in_3_5;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_5;
output measurement_3_5;
input measurement_value_in_3_6;
input measurement_valid_in_3_6;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_3_6;
output measurement_3_6;
input measurement_value_in_4_0;
input measurement_valid_in_4_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_0;
output measurement_4_0;
input measurement_value_in_4_1;
input measurement_valid_in_4_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_1;
output measurement_4_1;
input measurement_value_in_4_2;
input measurement_valid_in_4_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_2;
output measurement_4_2;
input measurement_value_in_4_3;
input measurement_valid_in_4_3;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_3;
output measurement_4_3;
input measurement_value_in_4_4;
input measurement_valid_in_4_4;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_4;
output measurement_4_4;
input measurement_value_in_4_5;
input measurement_valid_in_4_5;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_5;
output measurement_4_5;
input measurement_value_in_4_6;
input measurement_valid_in_4_6;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_4_6;
output measurement_4_6;
input measurement_value_in_5_0;
input measurement_valid_in_5_0;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_0;
output measurement_5_0;
input measurement_value_in_5_1;
input measurement_valid_in_5_1;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_1;
output measurement_5_1;
input measurement_value_in_5_2;
input measurement_valid_in_5_2;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_2;
output measurement_5_2;
input measurement_value_in_5_3;
input measurement_valid_in_5_3;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_3;
output measurement_5_3;
input measurement_value_in_5_4;
input measurement_valid_in_5_4;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_4;
output measurement_5_4;
input measurement_value_in_5_5;
input measurement_valid_in_5_5;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_5;
output measurement_5_5;
input measurement_value_in_5_6;
input measurement_valid_in_5_6;
output [MATCH_VALUE_WIDTH -1 : 0] match_value_out_5_6;
output measurement_5_6;
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
wire [MSG_WIDTH -1 : 0] north_south_value_0_3_1_3;
wire north_south_valid_0_3_1_3;
wire north_south_ready_0_3_1_3;
wire [MSG_WIDTH -1 : 0] south_north_value_0_3_1_3;
wire south_north_valid_0_3_1_3;
wire south_north_ready_0_3_1_3;
wire [MSG_WIDTH -1 : 0] north_south_value_0_4_1_4;
wire north_south_valid_0_4_1_4;
wire north_south_ready_0_4_1_4;
wire [MSG_WIDTH -1 : 0] south_north_value_0_4_1_4;
wire south_north_valid_0_4_1_4;
wire south_north_ready_0_4_1_4;
wire [MSG_WIDTH -1 : 0] north_south_value_0_5_1_5;
wire north_south_valid_0_5_1_5;
wire north_south_ready_0_5_1_5;
wire [MSG_WIDTH -1 : 0] south_north_value_0_5_1_5;
wire south_north_valid_0_5_1_5;
wire south_north_ready_0_5_1_5;
wire [MSG_WIDTH -1 : 0] north_south_value_0_6_1_6;
wire north_south_valid_0_6_1_6;
wire north_south_ready_0_6_1_6;
wire [MSG_WIDTH -1 : 0] south_north_value_0_6_1_6;
wire south_north_valid_0_6_1_6;
wire south_north_ready_0_6_1_6;
wire [MSG_WIDTH -1 : 0] north_south_value_1_0_2_0;
wire north_south_valid_1_0_2_0;
wire north_south_ready_1_0_2_0;
wire [MSG_WIDTH -1 : 0] south_north_value_1_0_2_0;
wire south_north_valid_1_0_2_0;
wire south_north_ready_1_0_2_0;
wire [MSG_WIDTH -1 : 0] north_south_value_1_1_2_1;
wire north_south_valid_1_1_2_1;
wire north_south_ready_1_1_2_1;
wire [MSG_WIDTH -1 : 0] south_north_value_1_1_2_1;
wire south_north_valid_1_1_2_1;
wire south_north_ready_1_1_2_1;
wire [MSG_WIDTH -1 : 0] north_south_value_1_2_2_2;
wire north_south_valid_1_2_2_2;
wire north_south_ready_1_2_2_2;
wire [MSG_WIDTH -1 : 0] south_north_value_1_2_2_2;
wire south_north_valid_1_2_2_2;
wire south_north_ready_1_2_2_2;
wire [MSG_WIDTH -1 : 0] north_south_value_1_3_2_3;
wire north_south_valid_1_3_2_3;
wire north_south_ready_1_3_2_3;
wire [MSG_WIDTH -1 : 0] south_north_value_1_3_2_3;
wire south_north_valid_1_3_2_3;
wire south_north_ready_1_3_2_3;
wire [MSG_WIDTH -1 : 0] north_south_value_1_4_2_4;
wire north_south_valid_1_4_2_4;
wire north_south_ready_1_4_2_4;
wire [MSG_WIDTH -1 : 0] south_north_value_1_4_2_4;
wire south_north_valid_1_4_2_4;
wire south_north_ready_1_4_2_4;
wire [MSG_WIDTH -1 : 0] north_south_value_1_5_2_5;
wire north_south_valid_1_5_2_5;
wire north_south_ready_1_5_2_5;
wire [MSG_WIDTH -1 : 0] south_north_value_1_5_2_5;
wire south_north_valid_1_5_2_5;
wire south_north_ready_1_5_2_5;
wire [MSG_WIDTH -1 : 0] north_south_value_1_6_2_6;
wire north_south_valid_1_6_2_6;
wire north_south_ready_1_6_2_6;
wire [MSG_WIDTH -1 : 0] south_north_value_1_6_2_6;
wire south_north_valid_1_6_2_6;
wire south_north_ready_1_6_2_6;
wire [MSG_WIDTH -1 : 0] north_south_value_2_0_3_0;
wire north_south_valid_2_0_3_0;
wire north_south_ready_2_0_3_0;
wire [MSG_WIDTH -1 : 0] south_north_value_2_0_3_0;
wire south_north_valid_2_0_3_0;
wire south_north_ready_2_0_3_0;
wire [MSG_WIDTH -1 : 0] north_south_value_2_1_3_1;
wire north_south_valid_2_1_3_1;
wire north_south_ready_2_1_3_1;
wire [MSG_WIDTH -1 : 0] south_north_value_2_1_3_1;
wire south_north_valid_2_1_3_1;
wire south_north_ready_2_1_3_1;
wire [MSG_WIDTH -1 : 0] north_south_value_2_2_3_2;
wire north_south_valid_2_2_3_2;
wire north_south_ready_2_2_3_2;
wire [MSG_WIDTH -1 : 0] south_north_value_2_2_3_2;
wire south_north_valid_2_2_3_2;
wire south_north_ready_2_2_3_2;
wire [MSG_WIDTH -1 : 0] north_south_value_2_3_3_3;
wire north_south_valid_2_3_3_3;
wire north_south_ready_2_3_3_3;
wire [MSG_WIDTH -1 : 0] south_north_value_2_3_3_3;
wire south_north_valid_2_3_3_3;
wire south_north_ready_2_3_3_3;
wire [MSG_WIDTH -1 : 0] north_south_value_2_4_3_4;
wire north_south_valid_2_4_3_4;
wire north_south_ready_2_4_3_4;
wire [MSG_WIDTH -1 : 0] south_north_value_2_4_3_4;
wire south_north_valid_2_4_3_4;
wire south_north_ready_2_4_3_4;
wire [MSG_WIDTH -1 : 0] north_south_value_2_5_3_5;
wire north_south_valid_2_5_3_5;
wire north_south_ready_2_5_3_5;
wire [MSG_WIDTH -1 : 0] south_north_value_2_5_3_5;
wire south_north_valid_2_5_3_5;
wire south_north_ready_2_5_3_5;
wire [MSG_WIDTH -1 : 0] north_south_value_2_6_3_6;
wire north_south_valid_2_6_3_6;
wire north_south_ready_2_6_3_6;
wire [MSG_WIDTH -1 : 0] south_north_value_2_6_3_6;
wire south_north_valid_2_6_3_6;
wire south_north_ready_2_6_3_6;
wire [MSG_WIDTH -1 : 0] north_south_value_3_0_4_0;
wire north_south_valid_3_0_4_0;
wire north_south_ready_3_0_4_0;
wire [MSG_WIDTH -1 : 0] south_north_value_3_0_4_0;
wire south_north_valid_3_0_4_0;
wire south_north_ready_3_0_4_0;
wire [MSG_WIDTH -1 : 0] north_south_value_3_1_4_1;
wire north_south_valid_3_1_4_1;
wire north_south_ready_3_1_4_1;
wire [MSG_WIDTH -1 : 0] south_north_value_3_1_4_1;
wire south_north_valid_3_1_4_1;
wire south_north_ready_3_1_4_1;
wire [MSG_WIDTH -1 : 0] north_south_value_3_2_4_2;
wire north_south_valid_3_2_4_2;
wire north_south_ready_3_2_4_2;
wire [MSG_WIDTH -1 : 0] south_north_value_3_2_4_2;
wire south_north_valid_3_2_4_2;
wire south_north_ready_3_2_4_2;
wire [MSG_WIDTH -1 : 0] north_south_value_3_3_4_3;
wire north_south_valid_3_3_4_3;
wire north_south_ready_3_3_4_3;
wire [MSG_WIDTH -1 : 0] south_north_value_3_3_4_3;
wire south_north_valid_3_3_4_3;
wire south_north_ready_3_3_4_3;
wire [MSG_WIDTH -1 : 0] north_south_value_3_4_4_4;
wire north_south_valid_3_4_4_4;
wire north_south_ready_3_4_4_4;
wire [MSG_WIDTH -1 : 0] south_north_value_3_4_4_4;
wire south_north_valid_3_4_4_4;
wire south_north_ready_3_4_4_4;
wire [MSG_WIDTH -1 : 0] north_south_value_3_5_4_5;
wire north_south_valid_3_5_4_5;
wire north_south_ready_3_5_4_5;
wire [MSG_WIDTH -1 : 0] south_north_value_3_5_4_5;
wire south_north_valid_3_5_4_5;
wire south_north_ready_3_5_4_5;
wire [MSG_WIDTH -1 : 0] north_south_value_3_6_4_6;
wire north_south_valid_3_6_4_6;
wire north_south_ready_3_6_4_6;
wire [MSG_WIDTH -1 : 0] south_north_value_3_6_4_6;
wire south_north_valid_3_6_4_6;
wire south_north_ready_3_6_4_6;
wire [MSG_WIDTH -1 : 0] north_south_value_4_0_5_0;
wire north_south_valid_4_0_5_0;
wire north_south_ready_4_0_5_0;
wire [MSG_WIDTH -1 : 0] south_north_value_4_0_5_0;
wire south_north_valid_4_0_5_0;
wire south_north_ready_4_0_5_0;
wire [MSG_WIDTH -1 : 0] north_south_value_4_1_5_1;
wire north_south_valid_4_1_5_1;
wire north_south_ready_4_1_5_1;
wire [MSG_WIDTH -1 : 0] south_north_value_4_1_5_1;
wire south_north_valid_4_1_5_1;
wire south_north_ready_4_1_5_1;
wire [MSG_WIDTH -1 : 0] north_south_value_4_2_5_2;
wire north_south_valid_4_2_5_2;
wire north_south_ready_4_2_5_2;
wire [MSG_WIDTH -1 : 0] south_north_value_4_2_5_2;
wire south_north_valid_4_2_5_2;
wire south_north_ready_4_2_5_2;
wire [MSG_WIDTH -1 : 0] north_south_value_4_3_5_3;
wire north_south_valid_4_3_5_3;
wire north_south_ready_4_3_5_3;
wire [MSG_WIDTH -1 : 0] south_north_value_4_3_5_3;
wire south_north_valid_4_3_5_3;
wire south_north_ready_4_3_5_3;
wire [MSG_WIDTH -1 : 0] north_south_value_4_4_5_4;
wire north_south_valid_4_4_5_4;
wire north_south_ready_4_4_5_4;
wire [MSG_WIDTH -1 : 0] south_north_value_4_4_5_4;
wire south_north_valid_4_4_5_4;
wire south_north_ready_4_4_5_4;
wire [MSG_WIDTH -1 : 0] north_south_value_4_5_5_5;
wire north_south_valid_4_5_5_5;
wire north_south_ready_4_5_5_5;
wire [MSG_WIDTH -1 : 0] south_north_value_4_5_5_5;
wire south_north_valid_4_5_5_5;
wire south_north_ready_4_5_5_5;
wire [MSG_WIDTH -1 : 0] north_south_value_4_6_5_6;
wire north_south_valid_4_6_5_6;
wire north_south_ready_4_6_5_6;
wire [MSG_WIDTH -1 : 0] south_north_value_4_6_5_6;
wire south_north_valid_4_6_5_6;
wire south_north_ready_4_6_5_6;
wire [MSG_WIDTH -1 : 0] east_west_value_0_0_0_1;
wire east_west_valid_0_0_0_1;
wire east_west_ready_0_0_0_1;
wire [MSG_WIDTH -1 : 0] west_east_value_0_0_0_1;
wire west_east_valid_0_0_0_1;
wire west_east_ready_0_0_0_1;
wire [MSG_WIDTH -1 : 0] east_west_value_0_1_0_2;
wire east_west_valid_0_1_0_2;
wire east_west_ready_0_1_0_2;
wire [MSG_WIDTH -1 : 0] west_east_value_0_1_0_2;
wire west_east_valid_0_1_0_2;
wire west_east_ready_0_1_0_2;
wire [MSG_WIDTH -1 : 0] east_west_value_0_2_0_3;
wire east_west_valid_0_2_0_3;
wire east_west_ready_0_2_0_3;
wire [MSG_WIDTH -1 : 0] west_east_value_0_2_0_3;
wire west_east_valid_0_2_0_3;
wire west_east_ready_0_2_0_3;
wire [MSG_WIDTH -1 : 0] east_west_value_0_3_0_4;
wire east_west_valid_0_3_0_4;
wire east_west_ready_0_3_0_4;
wire [MSG_WIDTH -1 : 0] west_east_value_0_3_0_4;
wire west_east_valid_0_3_0_4;
wire west_east_ready_0_3_0_4;
wire [MSG_WIDTH -1 : 0] east_west_value_0_4_0_5;
wire east_west_valid_0_4_0_5;
wire east_west_ready_0_4_0_5;
wire [MSG_WIDTH -1 : 0] west_east_value_0_4_0_5;
wire west_east_valid_0_4_0_5;
wire west_east_ready_0_4_0_5;
wire [MSG_WIDTH -1 : 0] east_west_value_0_5_0_6;
wire east_west_valid_0_5_0_6;
wire east_west_ready_0_5_0_6;
wire [MSG_WIDTH -1 : 0] west_east_value_0_5_0_6;
wire west_east_valid_0_5_0_6;
wire west_east_ready_0_5_0_6;
wire [MSG_WIDTH -1 : 0] east_west_value_1_0_1_1;
wire east_west_valid_1_0_1_1;
wire east_west_ready_1_0_1_1;
wire [MSG_WIDTH -1 : 0] west_east_value_1_0_1_1;
wire west_east_valid_1_0_1_1;
wire west_east_ready_1_0_1_1;
wire [MSG_WIDTH -1 : 0] east_west_value_1_1_1_2;
wire east_west_valid_1_1_1_2;
wire east_west_ready_1_1_1_2;
wire [MSG_WIDTH -1 : 0] west_east_value_1_1_1_2;
wire west_east_valid_1_1_1_2;
wire west_east_ready_1_1_1_2;
wire [MSG_WIDTH -1 : 0] east_west_value_1_2_1_3;
wire east_west_valid_1_2_1_3;
wire east_west_ready_1_2_1_3;
wire [MSG_WIDTH -1 : 0] west_east_value_1_2_1_3;
wire west_east_valid_1_2_1_3;
wire west_east_ready_1_2_1_3;
wire [MSG_WIDTH -1 : 0] east_west_value_1_3_1_4;
wire east_west_valid_1_3_1_4;
wire east_west_ready_1_3_1_4;
wire [MSG_WIDTH -1 : 0] west_east_value_1_3_1_4;
wire west_east_valid_1_3_1_4;
wire west_east_ready_1_3_1_4;
wire [MSG_WIDTH -1 : 0] east_west_value_1_4_1_5;
wire east_west_valid_1_4_1_5;
wire east_west_ready_1_4_1_5;
wire [MSG_WIDTH -1 : 0] west_east_value_1_4_1_5;
wire west_east_valid_1_4_1_5;
wire west_east_ready_1_4_1_5;
wire [MSG_WIDTH -1 : 0] east_west_value_1_5_1_6;
wire east_west_valid_1_5_1_6;
wire east_west_ready_1_5_1_6;
wire [MSG_WIDTH -1 : 0] west_east_value_1_5_1_6;
wire west_east_valid_1_5_1_6;
wire west_east_ready_1_5_1_6;
wire [MSG_WIDTH -1 : 0] east_west_value_2_0_2_1;
wire east_west_valid_2_0_2_1;
wire east_west_ready_2_0_2_1;
wire [MSG_WIDTH -1 : 0] west_east_value_2_0_2_1;
wire west_east_valid_2_0_2_1;
wire west_east_ready_2_0_2_1;
wire [MSG_WIDTH -1 : 0] east_west_value_2_1_2_2;
wire east_west_valid_2_1_2_2;
wire east_west_ready_2_1_2_2;
wire [MSG_WIDTH -1 : 0] west_east_value_2_1_2_2;
wire west_east_valid_2_1_2_2;
wire west_east_ready_2_1_2_2;
wire [MSG_WIDTH -1 : 0] east_west_value_2_2_2_3;
wire east_west_valid_2_2_2_3;
wire east_west_ready_2_2_2_3;
wire [MSG_WIDTH -1 : 0] west_east_value_2_2_2_3;
wire west_east_valid_2_2_2_3;
wire west_east_ready_2_2_2_3;
wire [MSG_WIDTH -1 : 0] east_west_value_2_3_2_4;
wire east_west_valid_2_3_2_4;
wire east_west_ready_2_3_2_4;
wire [MSG_WIDTH -1 : 0] west_east_value_2_3_2_4;
wire west_east_valid_2_3_2_4;
wire west_east_ready_2_3_2_4;
wire [MSG_WIDTH -1 : 0] east_west_value_2_4_2_5;
wire east_west_valid_2_4_2_5;
wire east_west_ready_2_4_2_5;
wire [MSG_WIDTH -1 : 0] west_east_value_2_4_2_5;
wire west_east_valid_2_4_2_5;
wire west_east_ready_2_4_2_5;
wire [MSG_WIDTH -1 : 0] east_west_value_2_5_2_6;
wire east_west_valid_2_5_2_6;
wire east_west_ready_2_5_2_6;
wire [MSG_WIDTH -1 : 0] west_east_value_2_5_2_6;
wire west_east_valid_2_5_2_6;
wire west_east_ready_2_5_2_6;
wire [MSG_WIDTH -1 : 0] east_west_value_3_0_3_1;
wire east_west_valid_3_0_3_1;
wire east_west_ready_3_0_3_1;
wire [MSG_WIDTH -1 : 0] west_east_value_3_0_3_1;
wire west_east_valid_3_0_3_1;
wire west_east_ready_3_0_3_1;
wire [MSG_WIDTH -1 : 0] east_west_value_3_1_3_2;
wire east_west_valid_3_1_3_2;
wire east_west_ready_3_1_3_2;
wire [MSG_WIDTH -1 : 0] west_east_value_3_1_3_2;
wire west_east_valid_3_1_3_2;
wire west_east_ready_3_1_3_2;
wire [MSG_WIDTH -1 : 0] east_west_value_3_2_3_3;
wire east_west_valid_3_2_3_3;
wire east_west_ready_3_2_3_3;
wire [MSG_WIDTH -1 : 0] west_east_value_3_2_3_3;
wire west_east_valid_3_2_3_3;
wire west_east_ready_3_2_3_3;
wire [MSG_WIDTH -1 : 0] east_west_value_3_3_3_4;
wire east_west_valid_3_3_3_4;
wire east_west_ready_3_3_3_4;
wire [MSG_WIDTH -1 : 0] west_east_value_3_3_3_4;
wire west_east_valid_3_3_3_4;
wire west_east_ready_3_3_3_4;
wire [MSG_WIDTH -1 : 0] east_west_value_3_4_3_5;
wire east_west_valid_3_4_3_5;
wire east_west_ready_3_4_3_5;
wire [MSG_WIDTH -1 : 0] west_east_value_3_4_3_5;
wire west_east_valid_3_4_3_5;
wire west_east_ready_3_4_3_5;
wire [MSG_WIDTH -1 : 0] east_west_value_3_5_3_6;
wire east_west_valid_3_5_3_6;
wire east_west_ready_3_5_3_6;
wire [MSG_WIDTH -1 : 0] west_east_value_3_5_3_6;
wire west_east_valid_3_5_3_6;
wire west_east_ready_3_5_3_6;
wire [MSG_WIDTH -1 : 0] east_west_value_4_0_4_1;
wire east_west_valid_4_0_4_1;
wire east_west_ready_4_0_4_1;
wire [MSG_WIDTH -1 : 0] west_east_value_4_0_4_1;
wire west_east_valid_4_0_4_1;
wire west_east_ready_4_0_4_1;
wire [MSG_WIDTH -1 : 0] east_west_value_4_1_4_2;
wire east_west_valid_4_1_4_2;
wire east_west_ready_4_1_4_2;
wire [MSG_WIDTH -1 : 0] west_east_value_4_1_4_2;
wire west_east_valid_4_1_4_2;
wire west_east_ready_4_1_4_2;
wire [MSG_WIDTH -1 : 0] east_west_value_4_2_4_3;
wire east_west_valid_4_2_4_3;
wire east_west_ready_4_2_4_3;
wire [MSG_WIDTH -1 : 0] west_east_value_4_2_4_3;
wire west_east_valid_4_2_4_3;
wire west_east_ready_4_2_4_3;
wire [MSG_WIDTH -1 : 0] east_west_value_4_3_4_4;
wire east_west_valid_4_3_4_4;
wire east_west_ready_4_3_4_4;
wire [MSG_WIDTH -1 : 0] west_east_value_4_3_4_4;
wire west_east_valid_4_3_4_4;
wire west_east_ready_4_3_4_4;
wire [MSG_WIDTH -1 : 0] east_west_value_4_4_4_5;
wire east_west_valid_4_4_4_5;
wire east_west_ready_4_4_4_5;
wire [MSG_WIDTH -1 : 0] west_east_value_4_4_4_5;
wire west_east_valid_4_4_4_5;
wire west_east_ready_4_4_4_5;
wire [MSG_WIDTH -1 : 0] east_west_value_4_5_4_6;
wire east_west_valid_4_5_4_6;
wire east_west_ready_4_5_4_6;
wire [MSG_WIDTH -1 : 0] west_east_value_4_5_4_6;
wire west_east_valid_4_5_4_6;
wire west_east_ready_4_5_4_6;
wire [MSG_WIDTH -1 : 0] east_west_value_5_0_5_1;
wire east_west_valid_5_0_5_1;
wire east_west_ready_5_0_5_1;
wire [MSG_WIDTH -1 : 0] west_east_value_5_0_5_1;
wire west_east_valid_5_0_5_1;
wire west_east_ready_5_0_5_1;
wire [MSG_WIDTH -1 : 0] east_west_value_5_1_5_2;
wire east_west_valid_5_1_5_2;
wire east_west_ready_5_1_5_2;
wire [MSG_WIDTH -1 : 0] west_east_value_5_1_5_2;
wire west_east_valid_5_1_5_2;
wire west_east_ready_5_1_5_2;
wire [MSG_WIDTH -1 : 0] east_west_value_5_2_5_3;
wire east_west_valid_5_2_5_3;
wire east_west_ready_5_2_5_3;
wire [MSG_WIDTH -1 : 0] west_east_value_5_2_5_3;
wire west_east_valid_5_2_5_3;
wire west_east_ready_5_2_5_3;
wire [MSG_WIDTH -1 : 0] east_west_value_5_3_5_4;
wire east_west_valid_5_3_5_4;
wire east_west_ready_5_3_5_4;
wire [MSG_WIDTH -1 : 0] west_east_value_5_3_5_4;
wire west_east_valid_5_3_5_4;
wire west_east_ready_5_3_5_4;
wire [MSG_WIDTH -1 : 0] east_west_value_5_4_5_5;
wire east_west_valid_5_4_5_5;
wire east_west_ready_5_4_5_5;
wire [MSG_WIDTH -1 : 0] west_east_value_5_4_5_5;
wire west_east_valid_5_4_5_5;
wire west_east_ready_5_4_5_5;
wire [MSG_WIDTH -1 : 0] east_west_value_5_5_5_6;
wire east_west_valid_5_5_5_6;
wire east_west_ready_5_5_5_6;
wire [MSG_WIDTH -1 : 0] west_east_value_5_5_5_6;
wire west_east_valid_5_5_5_6;
wire west_east_ready_5_5_5_6;
wire ready_open_north_0_0;
wire [MSG_WIDTH -1 : 0] value_open_north_0_0;
wire valid_open_north_0_0;
wire ready_open_south_5_0;
wire [MSG_WIDTH -1 : 0] value_open_south_5_0;
wire valid_open_south_5_0;
wire ready_open_north_0_1;
wire [MSG_WIDTH -1 : 0] value_open_north_0_1;
wire valid_open_north_0_1;
wire ready_open_south_5_1;
wire [MSG_WIDTH -1 : 0] value_open_south_5_1;
wire valid_open_south_5_1;
wire ready_open_north_0_2;
wire [MSG_WIDTH -1 : 0] value_open_north_0_2;
wire valid_open_north_0_2;
wire ready_open_south_5_2;
wire [MSG_WIDTH -1 : 0] value_open_south_5_2;
wire valid_open_south_5_2;
wire ready_open_north_0_3;
wire [MSG_WIDTH -1 : 0] value_open_north_0_3;
wire valid_open_north_0_3;
wire ready_open_south_5_3;
wire [MSG_WIDTH -1 : 0] value_open_south_5_3;
wire valid_open_south_5_3;
wire ready_open_north_0_4;
wire [MSG_WIDTH -1 : 0] value_open_north_0_4;
wire valid_open_north_0_4;
wire ready_open_south_5_4;
wire [MSG_WIDTH -1 : 0] value_open_south_5_4;
wire valid_open_south_5_4;
wire ready_open_north_0_5;
wire [MSG_WIDTH -1 : 0] value_open_north_0_5;
wire valid_open_north_0_5;
wire ready_open_south_5_5;
wire [MSG_WIDTH -1 : 0] value_open_south_5_5;
wire valid_open_south_5_5;
wire ready_open_north_0_6;
wire [MSG_WIDTH -1 : 0] value_open_north_0_6;
wire valid_open_north_0_6;
wire ready_open_south_5_6;
wire [MSG_WIDTH -1 : 0] value_open_south_5_6;
wire valid_open_south_5_6;
wire ready_open_west_0_0;
wire [MSG_WIDTH -1 : 0] value_open_west_0_0;
wire valid_open_west_0_0;
wire ready_open_east_0_6;
wire [MSG_WIDTH -1 : 0] value_open_east_0_6;
wire valid_open_east_0_6;
wire ready_open_west_1_0;
wire [MSG_WIDTH -1 : 0] value_open_west_1_0;
wire valid_open_west_1_0;
wire ready_open_east_1_6;
wire [MSG_WIDTH -1 : 0] value_open_east_1_6;
wire valid_open_east_1_6;
wire ready_open_west_2_0;
wire [MSG_WIDTH -1 : 0] value_open_west_2_0;
wire valid_open_west_2_0;
wire ready_open_east_2_6;
wire [MSG_WIDTH -1 : 0] value_open_east_2_6;
wire valid_open_east_2_6;
wire ready_open_west_3_0;
wire [MSG_WIDTH -1 : 0] value_open_west_3_0;
wire valid_open_west_3_0;
wire ready_open_east_3_6;
wire [MSG_WIDTH -1 : 0] value_open_east_3_6;
wire valid_open_east_3_6;
wire ready_open_west_4_0;
wire [MSG_WIDTH -1 : 0] value_open_west_4_0;
wire valid_open_west_4_0;
wire ready_open_east_4_6;
wire [MSG_WIDTH -1 : 0] value_open_east_4_6;
wire valid_open_east_4_6;
wire ready_open_west_5_0;
wire [MSG_WIDTH -1 : 0] value_open_west_5_0;
wire valid_open_west_5_0;
wire ready_open_east_5_6;
wire [MSG_WIDTH -1 : 0] value_open_east_5_6;
wire valid_open_east_5_6;

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
	.measurement(measurement_0_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(0),
	.BOUNDARY_COST(1)
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
	.measurement(measurement_0_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(1),
	.BOUNDARY_COST(1)
);

pe unit_0_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_2),
	.measurement_valid_in(measurement_valid_in_0_2),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_2),
	.mailbox_east_value_in(east_west_value_0_2_0_3),
	.mailbox_east_valid_in(east_west_valid_0_2_0_3),
	.mailbox_east_ready_out(east_west_ready_0_2_0_3),
	.mailbox_south_value_in(south_north_value_0_2_1_2),
	.mailbox_south_valid_in(south_north_valid_0_2_1_2),
	.mailbox_south_ready_out(south_north_ready_0_2_1_2),
	.mailbox_west_value_in(west_east_value_0_1_0_2),
	.mailbox_west_valid_in(west_east_valid_0_1_0_2),
	.mailbox_west_ready_out(west_east_ready_0_1_0_2),
	.outqueue_north_value_out(value_open_north_0_2),
	.outqueue_north_valid_out(valid_open_north_0_2),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(west_east_value_0_2_0_3),
	.outqueue_east_valid_out(west_east_valid_0_2_0_3),
	.outqueue_east_ready_in(west_east_ready_0_2_0_3),
	.outqueue_south_value_out(north_south_value_0_2_1_2),
	.outqueue_south_valid_out(north_south_valid_0_2_1_2),
	.outqueue_south_ready_in(north_south_ready_0_2_1_2),
	.outqueue_west_value_out(east_west_value_0_1_0_2),
	.outqueue_west_valid_out(east_west_valid_0_1_0_2),
	.outqueue_west_ready_in(east_west_ready_0_1_0_2),
	.match_value_out(match_value_out_0_2),
	.measurement(measurement_0_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(2),
	.BOUNDARY_COST(1)
);

pe unit_0_3 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_3),
	.measurement_valid_in(measurement_valid_in_0_3),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_3),
	.mailbox_east_value_in(east_west_value_0_3_0_4),
	.mailbox_east_valid_in(east_west_valid_0_3_0_4),
	.mailbox_east_ready_out(east_west_ready_0_3_0_4),
	.mailbox_south_value_in(south_north_value_0_3_1_3),
	.mailbox_south_valid_in(south_north_valid_0_3_1_3),
	.mailbox_south_ready_out(south_north_ready_0_3_1_3),
	.mailbox_west_value_in(west_east_value_0_2_0_3),
	.mailbox_west_valid_in(west_east_valid_0_2_0_3),
	.mailbox_west_ready_out(west_east_ready_0_2_0_3),
	.outqueue_north_value_out(value_open_north_0_3),
	.outqueue_north_valid_out(valid_open_north_0_3),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(west_east_value_0_3_0_4),
	.outqueue_east_valid_out(west_east_valid_0_3_0_4),
	.outqueue_east_ready_in(west_east_ready_0_3_0_4),
	.outqueue_south_value_out(north_south_value_0_3_1_3),
	.outqueue_south_valid_out(north_south_valid_0_3_1_3),
	.outqueue_south_ready_in(north_south_ready_0_3_1_3),
	.outqueue_west_value_out(east_west_value_0_2_0_3),
	.outqueue_west_valid_out(east_west_valid_0_2_0_3),
	.outqueue_west_ready_in(east_west_ready_0_2_0_3),
	.match_value_out(match_value_out_0_3),
	.measurement(measurement_0_3),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(3),
	.BOUNDARY_COST(1)
);

pe unit_0_4 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_4),
	.measurement_valid_in(measurement_valid_in_0_4),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_4),
	.mailbox_east_value_in(east_west_value_0_4_0_5),
	.mailbox_east_valid_in(east_west_valid_0_4_0_5),
	.mailbox_east_ready_out(east_west_ready_0_4_0_5),
	.mailbox_south_value_in(south_north_value_0_4_1_4),
	.mailbox_south_valid_in(south_north_valid_0_4_1_4),
	.mailbox_south_ready_out(south_north_ready_0_4_1_4),
	.mailbox_west_value_in(west_east_value_0_3_0_4),
	.mailbox_west_valid_in(west_east_valid_0_3_0_4),
	.mailbox_west_ready_out(west_east_ready_0_3_0_4),
	.outqueue_north_value_out(value_open_north_0_4),
	.outqueue_north_valid_out(valid_open_north_0_4),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(west_east_value_0_4_0_5),
	.outqueue_east_valid_out(west_east_valid_0_4_0_5),
	.outqueue_east_ready_in(west_east_ready_0_4_0_5),
	.outqueue_south_value_out(north_south_value_0_4_1_4),
	.outqueue_south_valid_out(north_south_valid_0_4_1_4),
	.outqueue_south_ready_in(north_south_ready_0_4_1_4),
	.outqueue_west_value_out(east_west_value_0_3_0_4),
	.outqueue_west_valid_out(east_west_valid_0_3_0_4),
	.outqueue_west_ready_in(east_west_ready_0_3_0_4),
	.match_value_out(match_value_out_0_4),
	.measurement(measurement_0_4),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(4),
	.BOUNDARY_COST(1)
);

pe unit_0_5 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_5),
	.measurement_valid_in(measurement_valid_in_0_5),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_5),
	.mailbox_east_value_in(east_west_value_0_5_0_6),
	.mailbox_east_valid_in(east_west_valid_0_5_0_6),
	.mailbox_east_ready_out(east_west_ready_0_5_0_6),
	.mailbox_south_value_in(south_north_value_0_5_1_5),
	.mailbox_south_valid_in(south_north_valid_0_5_1_5),
	.mailbox_south_ready_out(south_north_ready_0_5_1_5),
	.mailbox_west_value_in(west_east_value_0_4_0_5),
	.mailbox_west_valid_in(west_east_valid_0_4_0_5),
	.mailbox_west_ready_out(west_east_ready_0_4_0_5),
	.outqueue_north_value_out(value_open_north_0_5),
	.outqueue_north_valid_out(valid_open_north_0_5),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(west_east_value_0_5_0_6),
	.outqueue_east_valid_out(west_east_valid_0_5_0_6),
	.outqueue_east_ready_in(west_east_ready_0_5_0_6),
	.outqueue_south_value_out(north_south_value_0_5_1_5),
	.outqueue_south_valid_out(north_south_valid_0_5_1_5),
	.outqueue_south_ready_in(north_south_ready_0_5_1_5),
	.outqueue_west_value_out(east_west_value_0_4_0_5),
	.outqueue_west_valid_out(east_west_valid_0_4_0_5),
	.outqueue_west_ready_in(east_west_ready_0_4_0_5),
	.match_value_out(match_value_out_0_5),
	.measurement(measurement_0_5),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(5),
	.BOUNDARY_COST(1)
);

pe unit_0_6 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_0_6),
	.measurement_valid_in(measurement_valid_in_0_6),
	.mailbox_north_value_in(32'bx),
	.mailbox_north_valid_in(1'b0),
	.mailbox_north_ready_out(ready_open_north_0_6),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_0_6),
	.mailbox_south_value_in(south_north_value_0_6_1_6),
	.mailbox_south_valid_in(south_north_valid_0_6_1_6),
	.mailbox_south_ready_out(south_north_ready_0_6_1_6),
	.mailbox_west_value_in(west_east_value_0_5_0_6),
	.mailbox_west_valid_in(west_east_valid_0_5_0_6),
	.mailbox_west_ready_out(west_east_ready_0_5_0_6),
	.outqueue_north_value_out(value_open_north_0_6),
	.outqueue_north_valid_out(valid_open_north_0_6),
	.outqueue_north_ready_in(1'b1),
	.outqueue_east_value_out(value_open_east_0_6),
	.outqueue_east_valid_out(valid_open_east_0_6),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(north_south_value_0_6_1_6),
	.outqueue_south_valid_out(north_south_valid_0_6_1_6),
	.outqueue_south_ready_in(north_south_ready_0_6_1_6),
	.outqueue_west_value_out(east_west_value_0_5_0_6),
	.outqueue_west_valid_out(east_west_valid_0_5_0_6),
	.outqueue_west_ready_in(east_west_ready_0_5_0_6),
	.match_value_out(match_value_out_0_6),
	.measurement(measurement_0_6),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(0),
	.COL_ID(6),
	.BOUNDARY_COST(1)
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
	.mailbox_south_value_in(south_north_value_1_0_2_0),
	.mailbox_south_valid_in(south_north_valid_1_0_2_0),
	.mailbox_south_ready_out(south_north_ready_1_0_2_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_1_0),
	.outqueue_north_value_out(south_north_value_0_0_1_0),
	.outqueue_north_valid_out(south_north_valid_0_0_1_0),
	.outqueue_north_ready_in(south_north_ready_0_0_1_0),
	.outqueue_east_value_out(west_east_value_1_0_1_1),
	.outqueue_east_valid_out(west_east_valid_1_0_1_1),
	.outqueue_east_ready_in(west_east_ready_1_0_1_1),
	.outqueue_south_value_out(north_south_value_1_0_2_0),
	.outqueue_south_valid_out(north_south_valid_1_0_2_0),
	.outqueue_south_ready_in(north_south_ready_1_0_2_0),
	.outqueue_west_value_out(value_open_west_1_0),
	.outqueue_west_valid_out(valid_open_west_1_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_1_0),
	.measurement(measurement_1_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(0),
	.BOUNDARY_COST(2)
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
	.mailbox_south_value_in(south_north_value_1_1_2_1),
	.mailbox_south_valid_in(south_north_valid_1_1_2_1),
	.mailbox_south_ready_out(south_north_ready_1_1_2_1),
	.mailbox_west_value_in(west_east_value_1_0_1_1),
	.mailbox_west_valid_in(west_east_valid_1_0_1_1),
	.mailbox_west_ready_out(west_east_ready_1_0_1_1),
	.outqueue_north_value_out(south_north_value_0_1_1_1),
	.outqueue_north_valid_out(south_north_valid_0_1_1_1),
	.outqueue_north_ready_in(south_north_ready_0_1_1_1),
	.outqueue_east_value_out(west_east_value_1_1_1_2),
	.outqueue_east_valid_out(west_east_valid_1_1_1_2),
	.outqueue_east_ready_in(west_east_ready_1_1_1_2),
	.outqueue_south_value_out(north_south_value_1_1_2_1),
	.outqueue_south_valid_out(north_south_valid_1_1_2_1),
	.outqueue_south_ready_in(north_south_ready_1_1_2_1),
	.outqueue_west_value_out(east_west_value_1_0_1_1),
	.outqueue_west_valid_out(east_west_valid_1_0_1_1),
	.outqueue_west_ready_in(east_west_ready_1_0_1_1),
	.match_value_out(match_value_out_1_1),
	.measurement(measurement_1_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(1),
	.BOUNDARY_COST(2)
);

pe unit_1_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_2),
	.measurement_valid_in(measurement_valid_in_1_2),
	.mailbox_north_value_in(north_south_value_0_2_1_2),
	.mailbox_north_valid_in(north_south_valid_0_2_1_2),
	.mailbox_north_ready_out(north_south_ready_0_2_1_2),
	.mailbox_east_value_in(east_west_value_1_2_1_3),
	.mailbox_east_valid_in(east_west_valid_1_2_1_3),
	.mailbox_east_ready_out(east_west_ready_1_2_1_3),
	.mailbox_south_value_in(south_north_value_1_2_2_2),
	.mailbox_south_valid_in(south_north_valid_1_2_2_2),
	.mailbox_south_ready_out(south_north_ready_1_2_2_2),
	.mailbox_west_value_in(west_east_value_1_1_1_2),
	.mailbox_west_valid_in(west_east_valid_1_1_1_2),
	.mailbox_west_ready_out(west_east_ready_1_1_1_2),
	.outqueue_north_value_out(south_north_value_0_2_1_2),
	.outqueue_north_valid_out(south_north_valid_0_2_1_2),
	.outqueue_north_ready_in(south_north_ready_0_2_1_2),
	.outqueue_east_value_out(west_east_value_1_2_1_3),
	.outqueue_east_valid_out(west_east_valid_1_2_1_3),
	.outqueue_east_ready_in(west_east_ready_1_2_1_3),
	.outqueue_south_value_out(north_south_value_1_2_2_2),
	.outqueue_south_valid_out(north_south_valid_1_2_2_2),
	.outqueue_south_ready_in(north_south_ready_1_2_2_2),
	.outqueue_west_value_out(east_west_value_1_1_1_2),
	.outqueue_west_valid_out(east_west_valid_1_1_1_2),
	.outqueue_west_ready_in(east_west_ready_1_1_1_2),
	.match_value_out(match_value_out_1_2),
	.measurement(measurement_1_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(2),
	.BOUNDARY_COST(2)
);

pe unit_1_3 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_3),
	.measurement_valid_in(measurement_valid_in_1_3),
	.mailbox_north_value_in(north_south_value_0_3_1_3),
	.mailbox_north_valid_in(north_south_valid_0_3_1_3),
	.mailbox_north_ready_out(north_south_ready_0_3_1_3),
	.mailbox_east_value_in(east_west_value_1_3_1_4),
	.mailbox_east_valid_in(east_west_valid_1_3_1_4),
	.mailbox_east_ready_out(east_west_ready_1_3_1_4),
	.mailbox_south_value_in(south_north_value_1_3_2_3),
	.mailbox_south_valid_in(south_north_valid_1_3_2_3),
	.mailbox_south_ready_out(south_north_ready_1_3_2_3),
	.mailbox_west_value_in(west_east_value_1_2_1_3),
	.mailbox_west_valid_in(west_east_valid_1_2_1_3),
	.mailbox_west_ready_out(west_east_ready_1_2_1_3),
	.outqueue_north_value_out(south_north_value_0_3_1_3),
	.outqueue_north_valid_out(south_north_valid_0_3_1_3),
	.outqueue_north_ready_in(south_north_ready_0_3_1_3),
	.outqueue_east_value_out(west_east_value_1_3_1_4),
	.outqueue_east_valid_out(west_east_valid_1_3_1_4),
	.outqueue_east_ready_in(west_east_ready_1_3_1_4),
	.outqueue_south_value_out(north_south_value_1_3_2_3),
	.outqueue_south_valid_out(north_south_valid_1_3_2_3),
	.outqueue_south_ready_in(north_south_ready_1_3_2_3),
	.outqueue_west_value_out(east_west_value_1_2_1_3),
	.outqueue_west_valid_out(east_west_valid_1_2_1_3),
	.outqueue_west_ready_in(east_west_ready_1_2_1_3),
	.match_value_out(match_value_out_1_3),
	.measurement(measurement_1_3),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(3),
	.BOUNDARY_COST(2)
);

pe unit_1_4 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_4),
	.measurement_valid_in(measurement_valid_in_1_4),
	.mailbox_north_value_in(north_south_value_0_4_1_4),
	.mailbox_north_valid_in(north_south_valid_0_4_1_4),
	.mailbox_north_ready_out(north_south_ready_0_4_1_4),
	.mailbox_east_value_in(east_west_value_1_4_1_5),
	.mailbox_east_valid_in(east_west_valid_1_4_1_5),
	.mailbox_east_ready_out(east_west_ready_1_4_1_5),
	.mailbox_south_value_in(south_north_value_1_4_2_4),
	.mailbox_south_valid_in(south_north_valid_1_4_2_4),
	.mailbox_south_ready_out(south_north_ready_1_4_2_4),
	.mailbox_west_value_in(west_east_value_1_3_1_4),
	.mailbox_west_valid_in(west_east_valid_1_3_1_4),
	.mailbox_west_ready_out(west_east_ready_1_3_1_4),
	.outqueue_north_value_out(south_north_value_0_4_1_4),
	.outqueue_north_valid_out(south_north_valid_0_4_1_4),
	.outqueue_north_ready_in(south_north_ready_0_4_1_4),
	.outqueue_east_value_out(west_east_value_1_4_1_5),
	.outqueue_east_valid_out(west_east_valid_1_4_1_5),
	.outqueue_east_ready_in(west_east_ready_1_4_1_5),
	.outqueue_south_value_out(north_south_value_1_4_2_4),
	.outqueue_south_valid_out(north_south_valid_1_4_2_4),
	.outqueue_south_ready_in(north_south_ready_1_4_2_4),
	.outqueue_west_value_out(east_west_value_1_3_1_4),
	.outqueue_west_valid_out(east_west_valid_1_3_1_4),
	.outqueue_west_ready_in(east_west_ready_1_3_1_4),
	.match_value_out(match_value_out_1_4),
	.measurement(measurement_1_4),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(4),
	.BOUNDARY_COST(2)
);

pe unit_1_5 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_5),
	.measurement_valid_in(measurement_valid_in_1_5),
	.mailbox_north_value_in(north_south_value_0_5_1_5),
	.mailbox_north_valid_in(north_south_valid_0_5_1_5),
	.mailbox_north_ready_out(north_south_ready_0_5_1_5),
	.mailbox_east_value_in(east_west_value_1_5_1_6),
	.mailbox_east_valid_in(east_west_valid_1_5_1_6),
	.mailbox_east_ready_out(east_west_ready_1_5_1_6),
	.mailbox_south_value_in(south_north_value_1_5_2_5),
	.mailbox_south_valid_in(south_north_valid_1_5_2_5),
	.mailbox_south_ready_out(south_north_ready_1_5_2_5),
	.mailbox_west_value_in(west_east_value_1_4_1_5),
	.mailbox_west_valid_in(west_east_valid_1_4_1_5),
	.mailbox_west_ready_out(west_east_ready_1_4_1_5),
	.outqueue_north_value_out(south_north_value_0_5_1_5),
	.outqueue_north_valid_out(south_north_valid_0_5_1_5),
	.outqueue_north_ready_in(south_north_ready_0_5_1_5),
	.outqueue_east_value_out(west_east_value_1_5_1_6),
	.outqueue_east_valid_out(west_east_valid_1_5_1_6),
	.outqueue_east_ready_in(west_east_ready_1_5_1_6),
	.outqueue_south_value_out(north_south_value_1_5_2_5),
	.outqueue_south_valid_out(north_south_valid_1_5_2_5),
	.outqueue_south_ready_in(north_south_ready_1_5_2_5),
	.outqueue_west_value_out(east_west_value_1_4_1_5),
	.outqueue_west_valid_out(east_west_valid_1_4_1_5),
	.outqueue_west_ready_in(east_west_ready_1_4_1_5),
	.match_value_out(match_value_out_1_5),
	.measurement(measurement_1_5),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(5),
	.BOUNDARY_COST(2)
);

pe unit_1_6 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_1_6),
	.measurement_valid_in(measurement_valid_in_1_6),
	.mailbox_north_value_in(north_south_value_0_6_1_6),
	.mailbox_north_valid_in(north_south_valid_0_6_1_6),
	.mailbox_north_ready_out(north_south_ready_0_6_1_6),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_1_6),
	.mailbox_south_value_in(south_north_value_1_6_2_6),
	.mailbox_south_valid_in(south_north_valid_1_6_2_6),
	.mailbox_south_ready_out(south_north_ready_1_6_2_6),
	.mailbox_west_value_in(west_east_value_1_5_1_6),
	.mailbox_west_valid_in(west_east_valid_1_5_1_6),
	.mailbox_west_ready_out(west_east_ready_1_5_1_6),
	.outqueue_north_value_out(south_north_value_0_6_1_6),
	.outqueue_north_valid_out(south_north_valid_0_6_1_6),
	.outqueue_north_ready_in(south_north_ready_0_6_1_6),
	.outqueue_east_value_out(value_open_east_1_6),
	.outqueue_east_valid_out(valid_open_east_1_6),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(north_south_value_1_6_2_6),
	.outqueue_south_valid_out(north_south_valid_1_6_2_6),
	.outqueue_south_ready_in(north_south_ready_1_6_2_6),
	.outqueue_west_value_out(east_west_value_1_5_1_6),
	.outqueue_west_valid_out(east_west_valid_1_5_1_6),
	.outqueue_west_ready_in(east_west_ready_1_5_1_6),
	.match_value_out(match_value_out_1_6),
	.measurement(measurement_1_6),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(1),
	.COL_ID(6),
	.BOUNDARY_COST(2)
);

pe unit_2_0 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_0),
	.measurement_valid_in(measurement_valid_in_2_0),
	.mailbox_north_value_in(north_south_value_1_0_2_0),
	.mailbox_north_valid_in(north_south_valid_1_0_2_0),
	.mailbox_north_ready_out(north_south_ready_1_0_2_0),
	.mailbox_east_value_in(east_west_value_2_0_2_1),
	.mailbox_east_valid_in(east_west_valid_2_0_2_1),
	.mailbox_east_ready_out(east_west_ready_2_0_2_1),
	.mailbox_south_value_in(south_north_value_2_0_3_0),
	.mailbox_south_valid_in(south_north_valid_2_0_3_0),
	.mailbox_south_ready_out(south_north_ready_2_0_3_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_2_0),
	.outqueue_north_value_out(south_north_value_1_0_2_0),
	.outqueue_north_valid_out(south_north_valid_1_0_2_0),
	.outqueue_north_ready_in(south_north_ready_1_0_2_0),
	.outqueue_east_value_out(west_east_value_2_0_2_1),
	.outqueue_east_valid_out(west_east_valid_2_0_2_1),
	.outqueue_east_ready_in(west_east_ready_2_0_2_1),
	.outqueue_south_value_out(north_south_value_2_0_3_0),
	.outqueue_south_valid_out(north_south_valid_2_0_3_0),
	.outqueue_south_ready_in(north_south_ready_2_0_3_0),
	.outqueue_west_value_out(value_open_west_2_0),
	.outqueue_west_valid_out(valid_open_west_2_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_2_0),
	.measurement(measurement_2_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(0),
	.BOUNDARY_COST(3)
);

pe unit_2_1 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_1),
	.measurement_valid_in(measurement_valid_in_2_1),
	.mailbox_north_value_in(north_south_value_1_1_2_1),
	.mailbox_north_valid_in(north_south_valid_1_1_2_1),
	.mailbox_north_ready_out(north_south_ready_1_1_2_1),
	.mailbox_east_value_in(east_west_value_2_1_2_2),
	.mailbox_east_valid_in(east_west_valid_2_1_2_2),
	.mailbox_east_ready_out(east_west_ready_2_1_2_2),
	.mailbox_south_value_in(south_north_value_2_1_3_1),
	.mailbox_south_valid_in(south_north_valid_2_1_3_1),
	.mailbox_south_ready_out(south_north_ready_2_1_3_1),
	.mailbox_west_value_in(west_east_value_2_0_2_1),
	.mailbox_west_valid_in(west_east_valid_2_0_2_1),
	.mailbox_west_ready_out(west_east_ready_2_0_2_1),
	.outqueue_north_value_out(south_north_value_1_1_2_1),
	.outqueue_north_valid_out(south_north_valid_1_1_2_1),
	.outqueue_north_ready_in(south_north_ready_1_1_2_1),
	.outqueue_east_value_out(west_east_value_2_1_2_2),
	.outqueue_east_valid_out(west_east_valid_2_1_2_2),
	.outqueue_east_ready_in(west_east_ready_2_1_2_2),
	.outqueue_south_value_out(north_south_value_2_1_3_1),
	.outqueue_south_valid_out(north_south_valid_2_1_3_1),
	.outqueue_south_ready_in(north_south_ready_2_1_3_1),
	.outqueue_west_value_out(east_west_value_2_0_2_1),
	.outqueue_west_valid_out(east_west_valid_2_0_2_1),
	.outqueue_west_ready_in(east_west_ready_2_0_2_1),
	.match_value_out(match_value_out_2_1),
	.measurement(measurement_2_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(1),
	.BOUNDARY_COST(3)
);

pe unit_2_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_2),
	.measurement_valid_in(measurement_valid_in_2_2),
	.mailbox_north_value_in(north_south_value_1_2_2_2),
	.mailbox_north_valid_in(north_south_valid_1_2_2_2),
	.mailbox_north_ready_out(north_south_ready_1_2_2_2),
	.mailbox_east_value_in(east_west_value_2_2_2_3),
	.mailbox_east_valid_in(east_west_valid_2_2_2_3),
	.mailbox_east_ready_out(east_west_ready_2_2_2_3),
	.mailbox_south_value_in(south_north_value_2_2_3_2),
	.mailbox_south_valid_in(south_north_valid_2_2_3_2),
	.mailbox_south_ready_out(south_north_ready_2_2_3_2),
	.mailbox_west_value_in(west_east_value_2_1_2_2),
	.mailbox_west_valid_in(west_east_valid_2_1_2_2),
	.mailbox_west_ready_out(west_east_ready_2_1_2_2),
	.outqueue_north_value_out(south_north_value_1_2_2_2),
	.outqueue_north_valid_out(south_north_valid_1_2_2_2),
	.outqueue_north_ready_in(south_north_ready_1_2_2_2),
	.outqueue_east_value_out(west_east_value_2_2_2_3),
	.outqueue_east_valid_out(west_east_valid_2_2_2_3),
	.outqueue_east_ready_in(west_east_ready_2_2_2_3),
	.outqueue_south_value_out(north_south_value_2_2_3_2),
	.outqueue_south_valid_out(north_south_valid_2_2_3_2),
	.outqueue_south_ready_in(north_south_ready_2_2_3_2),
	.outqueue_west_value_out(east_west_value_2_1_2_2),
	.outqueue_west_valid_out(east_west_valid_2_1_2_2),
	.outqueue_west_ready_in(east_west_ready_2_1_2_2),
	.match_value_out(match_value_out_2_2),
	.measurement(measurement_2_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(2),
	.BOUNDARY_COST(3)
);

pe unit_2_3 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_3),
	.measurement_valid_in(measurement_valid_in_2_3),
	.mailbox_north_value_in(north_south_value_1_3_2_3),
	.mailbox_north_valid_in(north_south_valid_1_3_2_3),
	.mailbox_north_ready_out(north_south_ready_1_3_2_3),
	.mailbox_east_value_in(east_west_value_2_3_2_4),
	.mailbox_east_valid_in(east_west_valid_2_3_2_4),
	.mailbox_east_ready_out(east_west_ready_2_3_2_4),
	.mailbox_south_value_in(south_north_value_2_3_3_3),
	.mailbox_south_valid_in(south_north_valid_2_3_3_3),
	.mailbox_south_ready_out(south_north_ready_2_3_3_3),
	.mailbox_west_value_in(west_east_value_2_2_2_3),
	.mailbox_west_valid_in(west_east_valid_2_2_2_3),
	.mailbox_west_ready_out(west_east_ready_2_2_2_3),
	.outqueue_north_value_out(south_north_value_1_3_2_3),
	.outqueue_north_valid_out(south_north_valid_1_3_2_3),
	.outqueue_north_ready_in(south_north_ready_1_3_2_3),
	.outqueue_east_value_out(west_east_value_2_3_2_4),
	.outqueue_east_valid_out(west_east_valid_2_3_2_4),
	.outqueue_east_ready_in(west_east_ready_2_3_2_4),
	.outqueue_south_value_out(north_south_value_2_3_3_3),
	.outqueue_south_valid_out(north_south_valid_2_3_3_3),
	.outqueue_south_ready_in(north_south_ready_2_3_3_3),
	.outqueue_west_value_out(east_west_value_2_2_2_3),
	.outqueue_west_valid_out(east_west_valid_2_2_2_3),
	.outqueue_west_ready_in(east_west_ready_2_2_2_3),
	.match_value_out(match_value_out_2_3),
	.measurement(measurement_2_3),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(3),
	.BOUNDARY_COST(3)
);

pe unit_2_4 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_4),
	.measurement_valid_in(measurement_valid_in_2_4),
	.mailbox_north_value_in(north_south_value_1_4_2_4),
	.mailbox_north_valid_in(north_south_valid_1_4_2_4),
	.mailbox_north_ready_out(north_south_ready_1_4_2_4),
	.mailbox_east_value_in(east_west_value_2_4_2_5),
	.mailbox_east_valid_in(east_west_valid_2_4_2_5),
	.mailbox_east_ready_out(east_west_ready_2_4_2_5),
	.mailbox_south_value_in(south_north_value_2_4_3_4),
	.mailbox_south_valid_in(south_north_valid_2_4_3_4),
	.mailbox_south_ready_out(south_north_ready_2_4_3_4),
	.mailbox_west_value_in(west_east_value_2_3_2_4),
	.mailbox_west_valid_in(west_east_valid_2_3_2_4),
	.mailbox_west_ready_out(west_east_ready_2_3_2_4),
	.outqueue_north_value_out(south_north_value_1_4_2_4),
	.outqueue_north_valid_out(south_north_valid_1_4_2_4),
	.outqueue_north_ready_in(south_north_ready_1_4_2_4),
	.outqueue_east_value_out(west_east_value_2_4_2_5),
	.outqueue_east_valid_out(west_east_valid_2_4_2_5),
	.outqueue_east_ready_in(west_east_ready_2_4_2_5),
	.outqueue_south_value_out(north_south_value_2_4_3_4),
	.outqueue_south_valid_out(north_south_valid_2_4_3_4),
	.outqueue_south_ready_in(north_south_ready_2_4_3_4),
	.outqueue_west_value_out(east_west_value_2_3_2_4),
	.outqueue_west_valid_out(east_west_valid_2_3_2_4),
	.outqueue_west_ready_in(east_west_ready_2_3_2_4),
	.match_value_out(match_value_out_2_4),
	.measurement(measurement_2_4),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(4),
	.BOUNDARY_COST(3)
);

pe unit_2_5 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_5),
	.measurement_valid_in(measurement_valid_in_2_5),
	.mailbox_north_value_in(north_south_value_1_5_2_5),
	.mailbox_north_valid_in(north_south_valid_1_5_2_5),
	.mailbox_north_ready_out(north_south_ready_1_5_2_5),
	.mailbox_east_value_in(east_west_value_2_5_2_6),
	.mailbox_east_valid_in(east_west_valid_2_5_2_6),
	.mailbox_east_ready_out(east_west_ready_2_5_2_6),
	.mailbox_south_value_in(south_north_value_2_5_3_5),
	.mailbox_south_valid_in(south_north_valid_2_5_3_5),
	.mailbox_south_ready_out(south_north_ready_2_5_3_5),
	.mailbox_west_value_in(west_east_value_2_4_2_5),
	.mailbox_west_valid_in(west_east_valid_2_4_2_5),
	.mailbox_west_ready_out(west_east_ready_2_4_2_5),
	.outqueue_north_value_out(south_north_value_1_5_2_5),
	.outqueue_north_valid_out(south_north_valid_1_5_2_5),
	.outqueue_north_ready_in(south_north_ready_1_5_2_5),
	.outqueue_east_value_out(west_east_value_2_5_2_6),
	.outqueue_east_valid_out(west_east_valid_2_5_2_6),
	.outqueue_east_ready_in(west_east_ready_2_5_2_6),
	.outqueue_south_value_out(north_south_value_2_5_3_5),
	.outqueue_south_valid_out(north_south_valid_2_5_3_5),
	.outqueue_south_ready_in(north_south_ready_2_5_3_5),
	.outqueue_west_value_out(east_west_value_2_4_2_5),
	.outqueue_west_valid_out(east_west_valid_2_4_2_5),
	.outqueue_west_ready_in(east_west_ready_2_4_2_5),
	.match_value_out(match_value_out_2_5),
	.measurement(measurement_2_5),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(5),
	.BOUNDARY_COST(3)
);

pe unit_2_6 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_2_6),
	.measurement_valid_in(measurement_valid_in_2_6),
	.mailbox_north_value_in(north_south_value_1_6_2_6),
	.mailbox_north_valid_in(north_south_valid_1_6_2_6),
	.mailbox_north_ready_out(north_south_ready_1_6_2_6),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_2_6),
	.mailbox_south_value_in(south_north_value_2_6_3_6),
	.mailbox_south_valid_in(south_north_valid_2_6_3_6),
	.mailbox_south_ready_out(south_north_ready_2_6_3_6),
	.mailbox_west_value_in(west_east_value_2_5_2_6),
	.mailbox_west_valid_in(west_east_valid_2_5_2_6),
	.mailbox_west_ready_out(west_east_ready_2_5_2_6),
	.outqueue_north_value_out(south_north_value_1_6_2_6),
	.outqueue_north_valid_out(south_north_valid_1_6_2_6),
	.outqueue_north_ready_in(south_north_ready_1_6_2_6),
	.outqueue_east_value_out(value_open_east_2_6),
	.outqueue_east_valid_out(valid_open_east_2_6),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(north_south_value_2_6_3_6),
	.outqueue_south_valid_out(north_south_valid_2_6_3_6),
	.outqueue_south_ready_in(north_south_ready_2_6_3_6),
	.outqueue_west_value_out(east_west_value_2_5_2_6),
	.outqueue_west_valid_out(east_west_valid_2_5_2_6),
	.outqueue_west_ready_in(east_west_ready_2_5_2_6),
	.match_value_out(match_value_out_2_6),
	.measurement(measurement_2_6),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(2),
	.COL_ID(6),
	.BOUNDARY_COST(3)
);

pe unit_3_0 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_0),
	.measurement_valid_in(measurement_valid_in_3_0),
	.mailbox_north_value_in(north_south_value_2_0_3_0),
	.mailbox_north_valid_in(north_south_valid_2_0_3_0),
	.mailbox_north_ready_out(north_south_ready_2_0_3_0),
	.mailbox_east_value_in(east_west_value_3_0_3_1),
	.mailbox_east_valid_in(east_west_valid_3_0_3_1),
	.mailbox_east_ready_out(east_west_ready_3_0_3_1),
	.mailbox_south_value_in(south_north_value_3_0_4_0),
	.mailbox_south_valid_in(south_north_valid_3_0_4_0),
	.mailbox_south_ready_out(south_north_ready_3_0_4_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_3_0),
	.outqueue_north_value_out(south_north_value_2_0_3_0),
	.outqueue_north_valid_out(south_north_valid_2_0_3_0),
	.outqueue_north_ready_in(south_north_ready_2_0_3_0),
	.outqueue_east_value_out(west_east_value_3_0_3_1),
	.outqueue_east_valid_out(west_east_valid_3_0_3_1),
	.outqueue_east_ready_in(west_east_ready_3_0_3_1),
	.outqueue_south_value_out(north_south_value_3_0_4_0),
	.outqueue_south_valid_out(north_south_valid_3_0_4_0),
	.outqueue_south_ready_in(north_south_ready_3_0_4_0),
	.outqueue_west_value_out(value_open_west_3_0),
	.outqueue_west_valid_out(valid_open_west_3_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_3_0),
	.measurement(measurement_3_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(0),
	.BOUNDARY_COST(3)
);

pe unit_3_1 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_1),
	.measurement_valid_in(measurement_valid_in_3_1),
	.mailbox_north_value_in(north_south_value_2_1_3_1),
	.mailbox_north_valid_in(north_south_valid_2_1_3_1),
	.mailbox_north_ready_out(north_south_ready_2_1_3_1),
	.mailbox_east_value_in(east_west_value_3_1_3_2),
	.mailbox_east_valid_in(east_west_valid_3_1_3_2),
	.mailbox_east_ready_out(east_west_ready_3_1_3_2),
	.mailbox_south_value_in(south_north_value_3_1_4_1),
	.mailbox_south_valid_in(south_north_valid_3_1_4_1),
	.mailbox_south_ready_out(south_north_ready_3_1_4_1),
	.mailbox_west_value_in(west_east_value_3_0_3_1),
	.mailbox_west_valid_in(west_east_valid_3_0_3_1),
	.mailbox_west_ready_out(west_east_ready_3_0_3_1),
	.outqueue_north_value_out(south_north_value_2_1_3_1),
	.outqueue_north_valid_out(south_north_valid_2_1_3_1),
	.outqueue_north_ready_in(south_north_ready_2_1_3_1),
	.outqueue_east_value_out(west_east_value_3_1_3_2),
	.outqueue_east_valid_out(west_east_valid_3_1_3_2),
	.outqueue_east_ready_in(west_east_ready_3_1_3_2),
	.outqueue_south_value_out(north_south_value_3_1_4_1),
	.outqueue_south_valid_out(north_south_valid_3_1_4_1),
	.outqueue_south_ready_in(north_south_ready_3_1_4_1),
	.outqueue_west_value_out(east_west_value_3_0_3_1),
	.outqueue_west_valid_out(east_west_valid_3_0_3_1),
	.outqueue_west_ready_in(east_west_ready_3_0_3_1),
	.match_value_out(match_value_out_3_1),
	.measurement(measurement_3_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(1),
	.BOUNDARY_COST(3)
);

pe unit_3_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_2),
	.measurement_valid_in(measurement_valid_in_3_2),
	.mailbox_north_value_in(north_south_value_2_2_3_2),
	.mailbox_north_valid_in(north_south_valid_2_2_3_2),
	.mailbox_north_ready_out(north_south_ready_2_2_3_2),
	.mailbox_east_value_in(east_west_value_3_2_3_3),
	.mailbox_east_valid_in(east_west_valid_3_2_3_3),
	.mailbox_east_ready_out(east_west_ready_3_2_3_3),
	.mailbox_south_value_in(south_north_value_3_2_4_2),
	.mailbox_south_valid_in(south_north_valid_3_2_4_2),
	.mailbox_south_ready_out(south_north_ready_3_2_4_2),
	.mailbox_west_value_in(west_east_value_3_1_3_2),
	.mailbox_west_valid_in(west_east_valid_3_1_3_2),
	.mailbox_west_ready_out(west_east_ready_3_1_3_2),
	.outqueue_north_value_out(south_north_value_2_2_3_2),
	.outqueue_north_valid_out(south_north_valid_2_2_3_2),
	.outqueue_north_ready_in(south_north_ready_2_2_3_2),
	.outqueue_east_value_out(west_east_value_3_2_3_3),
	.outqueue_east_valid_out(west_east_valid_3_2_3_3),
	.outqueue_east_ready_in(west_east_ready_3_2_3_3),
	.outqueue_south_value_out(north_south_value_3_2_4_2),
	.outqueue_south_valid_out(north_south_valid_3_2_4_2),
	.outqueue_south_ready_in(north_south_ready_3_2_4_2),
	.outqueue_west_value_out(east_west_value_3_1_3_2),
	.outqueue_west_valid_out(east_west_valid_3_1_3_2),
	.outqueue_west_ready_in(east_west_ready_3_1_3_2),
	.match_value_out(match_value_out_3_2),
	.measurement(measurement_3_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(2),
	.BOUNDARY_COST(3)
);

pe unit_3_3 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_3),
	.measurement_valid_in(measurement_valid_in_3_3),
	.mailbox_north_value_in(north_south_value_2_3_3_3),
	.mailbox_north_valid_in(north_south_valid_2_3_3_3),
	.mailbox_north_ready_out(north_south_ready_2_3_3_3),
	.mailbox_east_value_in(east_west_value_3_3_3_4),
	.mailbox_east_valid_in(east_west_valid_3_3_3_4),
	.mailbox_east_ready_out(east_west_ready_3_3_3_4),
	.mailbox_south_value_in(south_north_value_3_3_4_3),
	.mailbox_south_valid_in(south_north_valid_3_3_4_3),
	.mailbox_south_ready_out(south_north_ready_3_3_4_3),
	.mailbox_west_value_in(west_east_value_3_2_3_3),
	.mailbox_west_valid_in(west_east_valid_3_2_3_3),
	.mailbox_west_ready_out(west_east_ready_3_2_3_3),
	.outqueue_north_value_out(south_north_value_2_3_3_3),
	.outqueue_north_valid_out(south_north_valid_2_3_3_3),
	.outqueue_north_ready_in(south_north_ready_2_3_3_3),
	.outqueue_east_value_out(west_east_value_3_3_3_4),
	.outqueue_east_valid_out(west_east_valid_3_3_3_4),
	.outqueue_east_ready_in(west_east_ready_3_3_3_4),
	.outqueue_south_value_out(north_south_value_3_3_4_3),
	.outqueue_south_valid_out(north_south_valid_3_3_4_3),
	.outqueue_south_ready_in(north_south_ready_3_3_4_3),
	.outqueue_west_value_out(east_west_value_3_2_3_3),
	.outqueue_west_valid_out(east_west_valid_3_2_3_3),
	.outqueue_west_ready_in(east_west_ready_3_2_3_3),
	.match_value_out(match_value_out_3_3),
	.measurement(measurement_3_3),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(3),
	.BOUNDARY_COST(3)
);

pe unit_3_4 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_4),
	.measurement_valid_in(measurement_valid_in_3_4),
	.mailbox_north_value_in(north_south_value_2_4_3_4),
	.mailbox_north_valid_in(north_south_valid_2_4_3_4),
	.mailbox_north_ready_out(north_south_ready_2_4_3_4),
	.mailbox_east_value_in(east_west_value_3_4_3_5),
	.mailbox_east_valid_in(east_west_valid_3_4_3_5),
	.mailbox_east_ready_out(east_west_ready_3_4_3_5),
	.mailbox_south_value_in(south_north_value_3_4_4_4),
	.mailbox_south_valid_in(south_north_valid_3_4_4_4),
	.mailbox_south_ready_out(south_north_ready_3_4_4_4),
	.mailbox_west_value_in(west_east_value_3_3_3_4),
	.mailbox_west_valid_in(west_east_valid_3_3_3_4),
	.mailbox_west_ready_out(west_east_ready_3_3_3_4),
	.outqueue_north_value_out(south_north_value_2_4_3_4),
	.outqueue_north_valid_out(south_north_valid_2_4_3_4),
	.outqueue_north_ready_in(south_north_ready_2_4_3_4),
	.outqueue_east_value_out(west_east_value_3_4_3_5),
	.outqueue_east_valid_out(west_east_valid_3_4_3_5),
	.outqueue_east_ready_in(west_east_ready_3_4_3_5),
	.outqueue_south_value_out(north_south_value_3_4_4_4),
	.outqueue_south_valid_out(north_south_valid_3_4_4_4),
	.outqueue_south_ready_in(north_south_ready_3_4_4_4),
	.outqueue_west_value_out(east_west_value_3_3_3_4),
	.outqueue_west_valid_out(east_west_valid_3_3_3_4),
	.outqueue_west_ready_in(east_west_ready_3_3_3_4),
	.match_value_out(match_value_out_3_4),
	.measurement(measurement_3_4),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(4),
	.BOUNDARY_COST(3)
);

pe unit_3_5 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_5),
	.measurement_valid_in(measurement_valid_in_3_5),
	.mailbox_north_value_in(north_south_value_2_5_3_5),
	.mailbox_north_valid_in(north_south_valid_2_5_3_5),
	.mailbox_north_ready_out(north_south_ready_2_5_3_5),
	.mailbox_east_value_in(east_west_value_3_5_3_6),
	.mailbox_east_valid_in(east_west_valid_3_5_3_6),
	.mailbox_east_ready_out(east_west_ready_3_5_3_6),
	.mailbox_south_value_in(south_north_value_3_5_4_5),
	.mailbox_south_valid_in(south_north_valid_3_5_4_5),
	.mailbox_south_ready_out(south_north_ready_3_5_4_5),
	.mailbox_west_value_in(west_east_value_3_4_3_5),
	.mailbox_west_valid_in(west_east_valid_3_4_3_5),
	.mailbox_west_ready_out(west_east_ready_3_4_3_5),
	.outqueue_north_value_out(south_north_value_2_5_3_5),
	.outqueue_north_valid_out(south_north_valid_2_5_3_5),
	.outqueue_north_ready_in(south_north_ready_2_5_3_5),
	.outqueue_east_value_out(west_east_value_3_5_3_6),
	.outqueue_east_valid_out(west_east_valid_3_5_3_6),
	.outqueue_east_ready_in(west_east_ready_3_5_3_6),
	.outqueue_south_value_out(north_south_value_3_5_4_5),
	.outqueue_south_valid_out(north_south_valid_3_5_4_5),
	.outqueue_south_ready_in(north_south_ready_3_5_4_5),
	.outqueue_west_value_out(east_west_value_3_4_3_5),
	.outqueue_west_valid_out(east_west_valid_3_4_3_5),
	.outqueue_west_ready_in(east_west_ready_3_4_3_5),
	.match_value_out(match_value_out_3_5),
	.measurement(measurement_3_5),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(5),
	.BOUNDARY_COST(3)
);

pe unit_3_6 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_3_6),
	.measurement_valid_in(measurement_valid_in_3_6),
	.mailbox_north_value_in(north_south_value_2_6_3_6),
	.mailbox_north_valid_in(north_south_valid_2_6_3_6),
	.mailbox_north_ready_out(north_south_ready_2_6_3_6),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_3_6),
	.mailbox_south_value_in(south_north_value_3_6_4_6),
	.mailbox_south_valid_in(south_north_valid_3_6_4_6),
	.mailbox_south_ready_out(south_north_ready_3_6_4_6),
	.mailbox_west_value_in(west_east_value_3_5_3_6),
	.mailbox_west_valid_in(west_east_valid_3_5_3_6),
	.mailbox_west_ready_out(west_east_ready_3_5_3_6),
	.outqueue_north_value_out(south_north_value_2_6_3_6),
	.outqueue_north_valid_out(south_north_valid_2_6_3_6),
	.outqueue_north_ready_in(south_north_ready_2_6_3_6),
	.outqueue_east_value_out(value_open_east_3_6),
	.outqueue_east_valid_out(valid_open_east_3_6),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(north_south_value_3_6_4_6),
	.outqueue_south_valid_out(north_south_valid_3_6_4_6),
	.outqueue_south_ready_in(north_south_ready_3_6_4_6),
	.outqueue_west_value_out(east_west_value_3_5_3_6),
	.outqueue_west_valid_out(east_west_valid_3_5_3_6),
	.outqueue_west_ready_in(east_west_ready_3_5_3_6),
	.match_value_out(match_value_out_3_6),
	.measurement(measurement_3_6),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(3),
	.COL_ID(6),
	.BOUNDARY_COST(3)
);

pe unit_4_0 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_0),
	.measurement_valid_in(measurement_valid_in_4_0),
	.mailbox_north_value_in(north_south_value_3_0_4_0),
	.mailbox_north_valid_in(north_south_valid_3_0_4_0),
	.mailbox_north_ready_out(north_south_ready_3_0_4_0),
	.mailbox_east_value_in(east_west_value_4_0_4_1),
	.mailbox_east_valid_in(east_west_valid_4_0_4_1),
	.mailbox_east_ready_out(east_west_ready_4_0_4_1),
	.mailbox_south_value_in(south_north_value_4_0_5_0),
	.mailbox_south_valid_in(south_north_valid_4_0_5_0),
	.mailbox_south_ready_out(south_north_ready_4_0_5_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_4_0),
	.outqueue_north_value_out(south_north_value_3_0_4_0),
	.outqueue_north_valid_out(south_north_valid_3_0_4_0),
	.outqueue_north_ready_in(south_north_ready_3_0_4_0),
	.outqueue_east_value_out(west_east_value_4_0_4_1),
	.outqueue_east_valid_out(west_east_valid_4_0_4_1),
	.outqueue_east_ready_in(west_east_ready_4_0_4_1),
	.outqueue_south_value_out(north_south_value_4_0_5_0),
	.outqueue_south_valid_out(north_south_valid_4_0_5_0),
	.outqueue_south_ready_in(north_south_ready_4_0_5_0),
	.outqueue_west_value_out(value_open_west_4_0),
	.outqueue_west_valid_out(valid_open_west_4_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_4_0),
	.measurement(measurement_4_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(0),
	.BOUNDARY_COST(2)
);

pe unit_4_1 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_1),
	.measurement_valid_in(measurement_valid_in_4_1),
	.mailbox_north_value_in(north_south_value_3_1_4_1),
	.mailbox_north_valid_in(north_south_valid_3_1_4_1),
	.mailbox_north_ready_out(north_south_ready_3_1_4_1),
	.mailbox_east_value_in(east_west_value_4_1_4_2),
	.mailbox_east_valid_in(east_west_valid_4_1_4_2),
	.mailbox_east_ready_out(east_west_ready_4_1_4_2),
	.mailbox_south_value_in(south_north_value_4_1_5_1),
	.mailbox_south_valid_in(south_north_valid_4_1_5_1),
	.mailbox_south_ready_out(south_north_ready_4_1_5_1),
	.mailbox_west_value_in(west_east_value_4_0_4_1),
	.mailbox_west_valid_in(west_east_valid_4_0_4_1),
	.mailbox_west_ready_out(west_east_ready_4_0_4_1),
	.outqueue_north_value_out(south_north_value_3_1_4_1),
	.outqueue_north_valid_out(south_north_valid_3_1_4_1),
	.outqueue_north_ready_in(south_north_ready_3_1_4_1),
	.outqueue_east_value_out(west_east_value_4_1_4_2),
	.outqueue_east_valid_out(west_east_valid_4_1_4_2),
	.outqueue_east_ready_in(west_east_ready_4_1_4_2),
	.outqueue_south_value_out(north_south_value_4_1_5_1),
	.outqueue_south_valid_out(north_south_valid_4_1_5_1),
	.outqueue_south_ready_in(north_south_ready_4_1_5_1),
	.outqueue_west_value_out(east_west_value_4_0_4_1),
	.outqueue_west_valid_out(east_west_valid_4_0_4_1),
	.outqueue_west_ready_in(east_west_ready_4_0_4_1),
	.match_value_out(match_value_out_4_1),
	.measurement(measurement_4_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(1),
	.BOUNDARY_COST(2)
);

pe unit_4_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_2),
	.measurement_valid_in(measurement_valid_in_4_2),
	.mailbox_north_value_in(north_south_value_3_2_4_2),
	.mailbox_north_valid_in(north_south_valid_3_2_4_2),
	.mailbox_north_ready_out(north_south_ready_3_2_4_2),
	.mailbox_east_value_in(east_west_value_4_2_4_3),
	.mailbox_east_valid_in(east_west_valid_4_2_4_3),
	.mailbox_east_ready_out(east_west_ready_4_2_4_3),
	.mailbox_south_value_in(south_north_value_4_2_5_2),
	.mailbox_south_valid_in(south_north_valid_4_2_5_2),
	.mailbox_south_ready_out(south_north_ready_4_2_5_2),
	.mailbox_west_value_in(west_east_value_4_1_4_2),
	.mailbox_west_valid_in(west_east_valid_4_1_4_2),
	.mailbox_west_ready_out(west_east_ready_4_1_4_2),
	.outqueue_north_value_out(south_north_value_3_2_4_2),
	.outqueue_north_valid_out(south_north_valid_3_2_4_2),
	.outqueue_north_ready_in(south_north_ready_3_2_4_2),
	.outqueue_east_value_out(west_east_value_4_2_4_3),
	.outqueue_east_valid_out(west_east_valid_4_2_4_3),
	.outqueue_east_ready_in(west_east_ready_4_2_4_3),
	.outqueue_south_value_out(north_south_value_4_2_5_2),
	.outqueue_south_valid_out(north_south_valid_4_2_5_2),
	.outqueue_south_ready_in(north_south_ready_4_2_5_2),
	.outqueue_west_value_out(east_west_value_4_1_4_2),
	.outqueue_west_valid_out(east_west_valid_4_1_4_2),
	.outqueue_west_ready_in(east_west_ready_4_1_4_2),
	.match_value_out(match_value_out_4_2),
	.measurement(measurement_4_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(2),
	.BOUNDARY_COST(2)
);

pe unit_4_3 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_3),
	.measurement_valid_in(measurement_valid_in_4_3),
	.mailbox_north_value_in(north_south_value_3_3_4_3),
	.mailbox_north_valid_in(north_south_valid_3_3_4_3),
	.mailbox_north_ready_out(north_south_ready_3_3_4_3),
	.mailbox_east_value_in(east_west_value_4_3_4_4),
	.mailbox_east_valid_in(east_west_valid_4_3_4_4),
	.mailbox_east_ready_out(east_west_ready_4_3_4_4),
	.mailbox_south_value_in(south_north_value_4_3_5_3),
	.mailbox_south_valid_in(south_north_valid_4_3_5_3),
	.mailbox_south_ready_out(south_north_ready_4_3_5_3),
	.mailbox_west_value_in(west_east_value_4_2_4_3),
	.mailbox_west_valid_in(west_east_valid_4_2_4_3),
	.mailbox_west_ready_out(west_east_ready_4_2_4_3),
	.outqueue_north_value_out(south_north_value_3_3_4_3),
	.outqueue_north_valid_out(south_north_valid_3_3_4_3),
	.outqueue_north_ready_in(south_north_ready_3_3_4_3),
	.outqueue_east_value_out(west_east_value_4_3_4_4),
	.outqueue_east_valid_out(west_east_valid_4_3_4_4),
	.outqueue_east_ready_in(west_east_ready_4_3_4_4),
	.outqueue_south_value_out(north_south_value_4_3_5_3),
	.outqueue_south_valid_out(north_south_valid_4_3_5_3),
	.outqueue_south_ready_in(north_south_ready_4_3_5_3),
	.outqueue_west_value_out(east_west_value_4_2_4_3),
	.outqueue_west_valid_out(east_west_valid_4_2_4_3),
	.outqueue_west_ready_in(east_west_ready_4_2_4_3),
	.match_value_out(match_value_out_4_3),
	.measurement(measurement_4_3),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(3),
	.BOUNDARY_COST(2)
);

pe unit_4_4 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_4),
	.measurement_valid_in(measurement_valid_in_4_4),
	.mailbox_north_value_in(north_south_value_3_4_4_4),
	.mailbox_north_valid_in(north_south_valid_3_4_4_4),
	.mailbox_north_ready_out(north_south_ready_3_4_4_4),
	.mailbox_east_value_in(east_west_value_4_4_4_5),
	.mailbox_east_valid_in(east_west_valid_4_4_4_5),
	.mailbox_east_ready_out(east_west_ready_4_4_4_5),
	.mailbox_south_value_in(south_north_value_4_4_5_4),
	.mailbox_south_valid_in(south_north_valid_4_4_5_4),
	.mailbox_south_ready_out(south_north_ready_4_4_5_4),
	.mailbox_west_value_in(west_east_value_4_3_4_4),
	.mailbox_west_valid_in(west_east_valid_4_3_4_4),
	.mailbox_west_ready_out(west_east_ready_4_3_4_4),
	.outqueue_north_value_out(south_north_value_3_4_4_4),
	.outqueue_north_valid_out(south_north_valid_3_4_4_4),
	.outqueue_north_ready_in(south_north_ready_3_4_4_4),
	.outqueue_east_value_out(west_east_value_4_4_4_5),
	.outqueue_east_valid_out(west_east_valid_4_4_4_5),
	.outqueue_east_ready_in(west_east_ready_4_4_4_5),
	.outqueue_south_value_out(north_south_value_4_4_5_4),
	.outqueue_south_valid_out(north_south_valid_4_4_5_4),
	.outqueue_south_ready_in(north_south_ready_4_4_5_4),
	.outqueue_west_value_out(east_west_value_4_3_4_4),
	.outqueue_west_valid_out(east_west_valid_4_3_4_4),
	.outqueue_west_ready_in(east_west_ready_4_3_4_4),
	.match_value_out(match_value_out_4_4),
	.measurement(measurement_4_4),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(4),
	.BOUNDARY_COST(2)
);

pe unit_4_5 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_5),
	.measurement_valid_in(measurement_valid_in_4_5),
	.mailbox_north_value_in(north_south_value_3_5_4_5),
	.mailbox_north_valid_in(north_south_valid_3_5_4_5),
	.mailbox_north_ready_out(north_south_ready_3_5_4_5),
	.mailbox_east_value_in(east_west_value_4_5_4_6),
	.mailbox_east_valid_in(east_west_valid_4_5_4_6),
	.mailbox_east_ready_out(east_west_ready_4_5_4_6),
	.mailbox_south_value_in(south_north_value_4_5_5_5),
	.mailbox_south_valid_in(south_north_valid_4_5_5_5),
	.mailbox_south_ready_out(south_north_ready_4_5_5_5),
	.mailbox_west_value_in(west_east_value_4_4_4_5),
	.mailbox_west_valid_in(west_east_valid_4_4_4_5),
	.mailbox_west_ready_out(west_east_ready_4_4_4_5),
	.outqueue_north_value_out(south_north_value_3_5_4_5),
	.outqueue_north_valid_out(south_north_valid_3_5_4_5),
	.outqueue_north_ready_in(south_north_ready_3_5_4_5),
	.outqueue_east_value_out(west_east_value_4_5_4_6),
	.outqueue_east_valid_out(west_east_valid_4_5_4_6),
	.outqueue_east_ready_in(west_east_ready_4_5_4_6),
	.outqueue_south_value_out(north_south_value_4_5_5_5),
	.outqueue_south_valid_out(north_south_valid_4_5_5_5),
	.outqueue_south_ready_in(north_south_ready_4_5_5_5),
	.outqueue_west_value_out(east_west_value_4_4_4_5),
	.outqueue_west_valid_out(east_west_valid_4_4_4_5),
	.outqueue_west_ready_in(east_west_ready_4_4_4_5),
	.match_value_out(match_value_out_4_5),
	.measurement(measurement_4_5),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(5),
	.BOUNDARY_COST(2)
);

pe unit_4_6 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_4_6),
	.measurement_valid_in(measurement_valid_in_4_6),
	.mailbox_north_value_in(north_south_value_3_6_4_6),
	.mailbox_north_valid_in(north_south_valid_3_6_4_6),
	.mailbox_north_ready_out(north_south_ready_3_6_4_6),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_4_6),
	.mailbox_south_value_in(south_north_value_4_6_5_6),
	.mailbox_south_valid_in(south_north_valid_4_6_5_6),
	.mailbox_south_ready_out(south_north_ready_4_6_5_6),
	.mailbox_west_value_in(west_east_value_4_5_4_6),
	.mailbox_west_valid_in(west_east_valid_4_5_4_6),
	.mailbox_west_ready_out(west_east_ready_4_5_4_6),
	.outqueue_north_value_out(south_north_value_3_6_4_6),
	.outqueue_north_valid_out(south_north_valid_3_6_4_6),
	.outqueue_north_ready_in(south_north_ready_3_6_4_6),
	.outqueue_east_value_out(value_open_east_4_6),
	.outqueue_east_valid_out(valid_open_east_4_6),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(north_south_value_4_6_5_6),
	.outqueue_south_valid_out(north_south_valid_4_6_5_6),
	.outqueue_south_ready_in(north_south_ready_4_6_5_6),
	.outqueue_west_value_out(east_west_value_4_5_4_6),
	.outqueue_west_valid_out(east_west_valid_4_5_4_6),
	.outqueue_west_ready_in(east_west_ready_4_5_4_6),
	.match_value_out(match_value_out_4_6),
	.measurement(measurement_4_6),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(4),
	.COL_ID(6),
	.BOUNDARY_COST(2)
);

pe unit_5_0 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_0),
	.measurement_valid_in(measurement_valid_in_5_0),
	.mailbox_north_value_in(north_south_value_4_0_5_0),
	.mailbox_north_valid_in(north_south_valid_4_0_5_0),
	.mailbox_north_ready_out(north_south_ready_4_0_5_0),
	.mailbox_east_value_in(east_west_value_5_0_5_1),
	.mailbox_east_valid_in(east_west_valid_5_0_5_1),
	.mailbox_east_ready_out(east_west_ready_5_0_5_1),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_0),
	.mailbox_west_value_in(32'bx),
	.mailbox_west_valid_in(1'b0),
	.mailbox_west_ready_out(ready_open_west_5_0),
	.outqueue_north_value_out(south_north_value_4_0_5_0),
	.outqueue_north_valid_out(south_north_valid_4_0_5_0),
	.outqueue_north_ready_in(south_north_ready_4_0_5_0),
	.outqueue_east_value_out(west_east_value_5_0_5_1),
	.outqueue_east_valid_out(west_east_valid_5_0_5_1),
	.outqueue_east_ready_in(west_east_ready_5_0_5_1),
	.outqueue_south_value_out(value_open_south_5_0),
	.outqueue_south_valid_out(valid_open_south_5_0),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(value_open_west_5_0),
	.outqueue_west_valid_out(valid_open_west_5_0),
	.outqueue_west_ready_in(1'b1),
	.match_value_out(match_value_out_5_0),
	.measurement(measurement_5_0),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(0),
	.BOUNDARY_COST(1)
);

pe unit_5_1 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_1),
	.measurement_valid_in(measurement_valid_in_5_1),
	.mailbox_north_value_in(north_south_value_4_1_5_1),
	.mailbox_north_valid_in(north_south_valid_4_1_5_1),
	.mailbox_north_ready_out(north_south_ready_4_1_5_1),
	.mailbox_east_value_in(east_west_value_5_1_5_2),
	.mailbox_east_valid_in(east_west_valid_5_1_5_2),
	.mailbox_east_ready_out(east_west_ready_5_1_5_2),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_1),
	.mailbox_west_value_in(west_east_value_5_0_5_1),
	.mailbox_west_valid_in(west_east_valid_5_0_5_1),
	.mailbox_west_ready_out(west_east_ready_5_0_5_1),
	.outqueue_north_value_out(south_north_value_4_1_5_1),
	.outqueue_north_valid_out(south_north_valid_4_1_5_1),
	.outqueue_north_ready_in(south_north_ready_4_1_5_1),
	.outqueue_east_value_out(west_east_value_5_1_5_2),
	.outqueue_east_valid_out(west_east_valid_5_1_5_2),
	.outqueue_east_ready_in(west_east_ready_5_1_5_2),
	.outqueue_south_value_out(value_open_south_5_1),
	.outqueue_south_valid_out(valid_open_south_5_1),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_5_0_5_1),
	.outqueue_west_valid_out(east_west_valid_5_0_5_1),
	.outqueue_west_ready_in(east_west_ready_5_0_5_1),
	.match_value_out(match_value_out_5_1),
	.measurement(measurement_5_1),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(1),
	.BOUNDARY_COST(1)
);

pe unit_5_2 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_2),
	.measurement_valid_in(measurement_valid_in_5_2),
	.mailbox_north_value_in(north_south_value_4_2_5_2),
	.mailbox_north_valid_in(north_south_valid_4_2_5_2),
	.mailbox_north_ready_out(north_south_ready_4_2_5_2),
	.mailbox_east_value_in(east_west_value_5_2_5_3),
	.mailbox_east_valid_in(east_west_valid_5_2_5_3),
	.mailbox_east_ready_out(east_west_ready_5_2_5_3),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_2),
	.mailbox_west_value_in(west_east_value_5_1_5_2),
	.mailbox_west_valid_in(west_east_valid_5_1_5_2),
	.mailbox_west_ready_out(west_east_ready_5_1_5_2),
	.outqueue_north_value_out(south_north_value_4_2_5_2),
	.outqueue_north_valid_out(south_north_valid_4_2_5_2),
	.outqueue_north_ready_in(south_north_ready_4_2_5_2),
	.outqueue_east_value_out(west_east_value_5_2_5_3),
	.outqueue_east_valid_out(west_east_valid_5_2_5_3),
	.outqueue_east_ready_in(west_east_ready_5_2_5_3),
	.outqueue_south_value_out(value_open_south_5_2),
	.outqueue_south_valid_out(valid_open_south_5_2),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_5_1_5_2),
	.outqueue_west_valid_out(east_west_valid_5_1_5_2),
	.outqueue_west_ready_in(east_west_ready_5_1_5_2),
	.match_value_out(match_value_out_5_2),
	.measurement(measurement_5_2),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(2),
	.BOUNDARY_COST(1)
);

pe unit_5_3 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_3),
	.measurement_valid_in(measurement_valid_in_5_3),
	.mailbox_north_value_in(north_south_value_4_3_5_3),
	.mailbox_north_valid_in(north_south_valid_4_3_5_3),
	.mailbox_north_ready_out(north_south_ready_4_3_5_3),
	.mailbox_east_value_in(east_west_value_5_3_5_4),
	.mailbox_east_valid_in(east_west_valid_5_3_5_4),
	.mailbox_east_ready_out(east_west_ready_5_3_5_4),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_3),
	.mailbox_west_value_in(west_east_value_5_2_5_3),
	.mailbox_west_valid_in(west_east_valid_5_2_5_3),
	.mailbox_west_ready_out(west_east_ready_5_2_5_3),
	.outqueue_north_value_out(south_north_value_4_3_5_3),
	.outqueue_north_valid_out(south_north_valid_4_3_5_3),
	.outqueue_north_ready_in(south_north_ready_4_3_5_3),
	.outqueue_east_value_out(west_east_value_5_3_5_4),
	.outqueue_east_valid_out(west_east_valid_5_3_5_4),
	.outqueue_east_ready_in(west_east_ready_5_3_5_4),
	.outqueue_south_value_out(value_open_south_5_3),
	.outqueue_south_valid_out(valid_open_south_5_3),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_5_2_5_3),
	.outqueue_west_valid_out(east_west_valid_5_2_5_3),
	.outqueue_west_ready_in(east_west_ready_5_2_5_3),
	.match_value_out(match_value_out_5_3),
	.measurement(measurement_5_3),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(3),
	.BOUNDARY_COST(1)
);

pe unit_5_4 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_4),
	.measurement_valid_in(measurement_valid_in_5_4),
	.mailbox_north_value_in(north_south_value_4_4_5_4),
	.mailbox_north_valid_in(north_south_valid_4_4_5_4),
	.mailbox_north_ready_out(north_south_ready_4_4_5_4),
	.mailbox_east_value_in(east_west_value_5_4_5_5),
	.mailbox_east_valid_in(east_west_valid_5_4_5_5),
	.mailbox_east_ready_out(east_west_ready_5_4_5_5),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_4),
	.mailbox_west_value_in(west_east_value_5_3_5_4),
	.mailbox_west_valid_in(west_east_valid_5_3_5_4),
	.mailbox_west_ready_out(west_east_ready_5_3_5_4),
	.outqueue_north_value_out(south_north_value_4_4_5_4),
	.outqueue_north_valid_out(south_north_valid_4_4_5_4),
	.outqueue_north_ready_in(south_north_ready_4_4_5_4),
	.outqueue_east_value_out(west_east_value_5_4_5_5),
	.outqueue_east_valid_out(west_east_valid_5_4_5_5),
	.outqueue_east_ready_in(west_east_ready_5_4_5_5),
	.outqueue_south_value_out(value_open_south_5_4),
	.outqueue_south_valid_out(valid_open_south_5_4),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_5_3_5_4),
	.outqueue_west_valid_out(east_west_valid_5_3_5_4),
	.outqueue_west_ready_in(east_west_ready_5_3_5_4),
	.match_value_out(match_value_out_5_4),
	.measurement(measurement_5_4),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(4),
	.BOUNDARY_COST(1)
);

pe unit_5_5 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_5),
	.measurement_valid_in(measurement_valid_in_5_5),
	.mailbox_north_value_in(north_south_value_4_5_5_5),
	.mailbox_north_valid_in(north_south_valid_4_5_5_5),
	.mailbox_north_ready_out(north_south_ready_4_5_5_5),
	.mailbox_east_value_in(east_west_value_5_5_5_6),
	.mailbox_east_valid_in(east_west_valid_5_5_5_6),
	.mailbox_east_ready_out(east_west_ready_5_5_5_6),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_5),
	.mailbox_west_value_in(west_east_value_5_4_5_5),
	.mailbox_west_valid_in(west_east_valid_5_4_5_5),
	.mailbox_west_ready_out(west_east_ready_5_4_5_5),
	.outqueue_north_value_out(south_north_value_4_5_5_5),
	.outqueue_north_valid_out(south_north_valid_4_5_5_5),
	.outqueue_north_ready_in(south_north_ready_4_5_5_5),
	.outqueue_east_value_out(west_east_value_5_5_5_6),
	.outqueue_east_valid_out(west_east_valid_5_5_5_6),
	.outqueue_east_ready_in(west_east_ready_5_5_5_6),
	.outqueue_south_value_out(value_open_south_5_5),
	.outqueue_south_valid_out(valid_open_south_5_5),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_5_4_5_5),
	.outqueue_west_valid_out(east_west_valid_5_4_5_5),
	.outqueue_west_ready_in(east_west_ready_5_4_5_5),
	.match_value_out(match_value_out_5_5),
	.measurement(measurement_5_5),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(5),
	.BOUNDARY_COST(1)
);

pe unit_5_6 (
	.clk(clk),
	.reset(reset),
	.measurement_value_in(measurement_value_in_5_6),
	.measurement_valid_in(measurement_valid_in_5_6),
	.mailbox_north_value_in(north_south_value_4_6_5_6),
	.mailbox_north_valid_in(north_south_valid_4_6_5_6),
	.mailbox_north_ready_out(north_south_ready_4_6_5_6),
	.mailbox_east_value_in(32'bx),
	.mailbox_east_valid_in(1'b0),
	.mailbox_east_ready_out(ready_open_east_5_6),
	.mailbox_south_value_in(32'bx),
	.mailbox_south_valid_in(1'b0),
	.mailbox_south_ready_out(ready_open_south_5_6),
	.mailbox_west_value_in(west_east_value_5_5_5_6),
	.mailbox_west_valid_in(west_east_valid_5_5_5_6),
	.mailbox_west_ready_out(west_east_ready_5_5_5_6),
	.outqueue_north_value_out(south_north_value_4_6_5_6),
	.outqueue_north_valid_out(south_north_valid_4_6_5_6),
	.outqueue_north_ready_in(south_north_ready_4_6_5_6),
	.outqueue_east_value_out(value_open_east_5_6),
	.outqueue_east_valid_out(valid_open_east_5_6),
	.outqueue_east_ready_in(1'b1),
	.outqueue_south_value_out(value_open_south_5_6),
	.outqueue_south_valid_out(valid_open_south_5_6),
	.outqueue_south_ready_in(1'b1),
	.outqueue_west_value_out(east_west_value_5_5_5_6),
	.outqueue_west_valid_out(east_west_valid_5_5_5_6),
	.outqueue_west_ready_in(east_west_ready_5_5_5_6),
	.match_value_out(match_value_out_5_6),
	.measurement(measurement_5_6),
	.start_offer(start_offer),
	.stop_offer(stop_offer),
	.ROW_ID(5),
	.COL_ID(6),
	.BOUNDARY_COST(1)
);

endmodule