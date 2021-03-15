`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module top_single_7_by_7_x_tb;

// This is test bench of 7 by 6 grid of x stabilizers

`include "parameters.v"

reg measurement_value_in[0:5][0:6];
reg measurement_valid_in;
wire [MATCH_VALUE_WIDTH -1 : 0] match_value_out[0:5][0:6];
wire measurement[0:5][0:6];
reg start_offer;
reg stop_offer;
reg clk;
reg reset;

always
begin
	clk = 1'b1;
	#5;
	clk = 1'b0;
	#5;
end

top_single_7_by_7_x uut(
	.clk(clk),
	.reset(reset),
	.measurement_value_in_0_0(measurement_value_in[0][0]),
	.measurement_valid_in_0_0(measurement_valid_in),
	.match_value_out_0_0(match_value_out[0][0]),
	.measurement_0_0(measurement[0][0]),
	.measurement_value_in_0_1(measurement_value_in[0][1]),
	.measurement_valid_in_0_1(measurement_valid_in),
	.match_value_out_0_1(match_value_out[0][1]),
	.measurement_0_1(measurement[0][1]),
	.measurement_value_in_0_2(measurement_value_in[0][2]),
	.measurement_valid_in_0_2(measurement_valid_in),
	.match_value_out_0_2(match_value_out[0][2]),
	.measurement_0_2(measurement[0][2]),
	.measurement_value_in_0_3(measurement_value_in[0][3]),
	.measurement_valid_in_0_3(measurement_valid_in),
	.match_value_out_0_3(match_value_out[0][3]),
	.measurement_0_3(measurement[0][3]),
	.measurement_value_in_0_4(measurement_value_in[0][4]),
	.measurement_valid_in_0_4(measurement_valid_in),
	.match_value_out_0_4(match_value_out[0][4]),
	.measurement_0_4(measurement[0][4]),
	.measurement_value_in_0_5(measurement_value_in[0][5]),
	.measurement_valid_in_0_5(measurement_valid_in),
	.match_value_out_0_5(match_value_out[0][5]),
	.measurement_0_5(measurement[0][5]),
	.measurement_value_in_0_6(measurement_value_in[0][6]),
	.measurement_valid_in_0_6(measurement_valid_in),
	.match_value_out_0_6(match_value_out[0][6]),
	.measurement_0_6(measurement[0][6]),
	.measurement_value_in_1_0(measurement_value_in[1][0]),
	.measurement_valid_in_1_0(measurement_valid_in),
	.match_value_out_1_0(match_value_out[1][0]),
	.measurement_1_0(measurement[1][0]),
	.measurement_value_in_1_1(measurement_value_in[1][1]),
	.measurement_valid_in_1_1(measurement_valid_in),
	.match_value_out_1_1(match_value_out[1][1]),
	.measurement_1_1(measurement[1][1]),
	.measurement_value_in_1_2(measurement_value_in[1][2]),
	.measurement_valid_in_1_2(measurement_valid_in),
	.match_value_out_1_2(match_value_out[1][2]),
	.measurement_1_2(measurement[1][2]),
	.measurement_value_in_1_3(measurement_value_in[1][3]),
	.measurement_valid_in_1_3(measurement_valid_in),
	.match_value_out_1_3(match_value_out[1][3]),
	.measurement_1_3(measurement[1][3]),
	.measurement_value_in_1_4(measurement_value_in[1][4]),
	.measurement_valid_in_1_4(measurement_valid_in),
	.match_value_out_1_4(match_value_out[1][4]),
	.measurement_1_4(measurement[1][4]),
	.measurement_value_in_1_5(measurement_value_in[1][5]),
	.measurement_valid_in_1_5(measurement_valid_in),
	.match_value_out_1_5(match_value_out[1][5]),
	.measurement_1_5(measurement[1][5]),
	.measurement_value_in_1_6(measurement_value_in[1][6]),
	.measurement_valid_in_1_6(measurement_valid_in),
	.match_value_out_1_6(match_value_out[1][6]),
	.measurement_1_6(measurement[1][6]),
	.measurement_value_in_2_0(measurement_value_in[2][0]),
	.measurement_valid_in_2_0(measurement_valid_in),
	.match_value_out_2_0(match_value_out[2][0]),
	.measurement_2_0(measurement[2][0]),
	.measurement_value_in_2_1(measurement_value_in[2][1]),
	.measurement_valid_in_2_1(measurement_valid_in),
	.match_value_out_2_1(match_value_out[2][1]),
	.measurement_2_1(measurement[2][1]),
	.measurement_value_in_2_2(measurement_value_in[2][2]),
	.measurement_valid_in_2_2(measurement_valid_in),
	.match_value_out_2_2(match_value_out[2][2]),
	.measurement_2_2(measurement[2][2]),
	.measurement_value_in_2_3(measurement_value_in[2][3]),
	.measurement_valid_in_2_3(measurement_valid_in),
	.match_value_out_2_3(match_value_out[2][3]),
	.measurement_2_3(measurement[2][3]),
	.measurement_value_in_2_4(measurement_value_in[2][4]),
	.measurement_valid_in_2_4(measurement_valid_in),
	.match_value_out_2_4(match_value_out[2][4]),
	.measurement_2_4(measurement[2][4]),
	.measurement_value_in_2_5(measurement_value_in[2][5]),
	.measurement_valid_in_2_5(measurement_valid_in),
	.match_value_out_2_5(match_value_out[2][5]),
	.measurement_2_5(measurement[2][5]),
	.measurement_value_in_2_6(measurement_value_in[2][6]),
	.measurement_valid_in_2_6(measurement_valid_in),
	.match_value_out_2_6(match_value_out[2][6]),
	.measurement_2_6(measurement[2][6]),
	.measurement_value_in_3_0(measurement_value_in[3][0]),
	.measurement_valid_in_3_0(measurement_valid_in),
	.match_value_out_3_0(match_value_out[3][0]),
	.measurement_3_0(measurement[3][0]),
	.measurement_value_in_3_1(measurement_value_in[3][1]),
	.measurement_valid_in_3_1(measurement_valid_in),
	.match_value_out_3_1(match_value_out[3][1]),
	.measurement_3_1(measurement[3][1]),
	.measurement_value_in_3_2(measurement_value_in[3][2]),
	.measurement_valid_in_3_2(measurement_valid_in),
	.match_value_out_3_2(match_value_out[3][2]),
	.measurement_3_2(measurement[3][2]),
	.measurement_value_in_3_3(measurement_value_in[3][3]),
	.measurement_valid_in_3_3(measurement_valid_in),
	.match_value_out_3_3(match_value_out[3][3]),
	.measurement_3_3(measurement[3][3]),
	.measurement_value_in_3_4(measurement_value_in[3][4]),
	.measurement_valid_in_3_4(measurement_valid_in),
	.match_value_out_3_4(match_value_out[3][4]),
	.measurement_3_4(measurement[3][4]),
	.measurement_value_in_3_5(measurement_value_in[3][5]),
	.measurement_valid_in_3_5(measurement_valid_in),
	.match_value_out_3_5(match_value_out[3][5]),
	.measurement_3_5(measurement[3][5]),
	.measurement_value_in_3_6(measurement_value_in[3][6]),
	.measurement_valid_in_3_6(measurement_valid_in),
	.match_value_out_3_6(match_value_out[3][6]),
	.measurement_3_6(measurement[3][6]),
	.measurement_value_in_4_0(measurement_value_in[4][0]),
	.measurement_valid_in_4_0(measurement_valid_in),
	.match_value_out_4_0(match_value_out[4][0]),
	.measurement_4_0(measurement[4][0]),
	.measurement_value_in_4_1(measurement_value_in[4][1]),
	.measurement_valid_in_4_1(measurement_valid_in),
	.match_value_out_4_1(match_value_out[4][1]),
	.measurement_4_1(measurement[4][1]),
	.measurement_value_in_4_2(measurement_value_in[4][2]),
	.measurement_valid_in_4_2(measurement_valid_in),
	.match_value_out_4_2(match_value_out[4][2]),
	.measurement_4_2(measurement[4][2]),
	.measurement_value_in_4_3(measurement_value_in[4][3]),
	.measurement_valid_in_4_3(measurement_valid_in),
	.match_value_out_4_3(match_value_out[4][3]),
	.measurement_4_3(measurement[4][3]),
	.measurement_value_in_4_4(measurement_value_in[4][4]),
	.measurement_valid_in_4_4(measurement_valid_in),
	.match_value_out_4_4(match_value_out[4][4]),
	.measurement_4_4(measurement[4][4]),
	.measurement_value_in_4_5(measurement_value_in[4][5]),
	.measurement_valid_in_4_5(measurement_valid_in),
	.match_value_out_4_5(match_value_out[4][5]),
	.measurement_4_5(measurement[4][5]),
	.measurement_value_in_4_6(measurement_value_in[4][6]),
	.measurement_valid_in_4_6(measurement_valid_in),
	.match_value_out_4_6(match_value_out[4][6]),
	.measurement_4_6(measurement[4][6]),
	.measurement_value_in_5_0(measurement_value_in[5][0]),
	.measurement_valid_in_5_0(measurement_valid_in),
	.match_value_out_5_0(match_value_out[5][0]),
	.measurement_5_0(measurement[5][0]),
	.measurement_value_in_5_1(measurement_value_in[5][1]),
	.measurement_valid_in_5_1(measurement_valid_in),
	.match_value_out_5_1(match_value_out[5][1]),
	.measurement_5_1(measurement[5][1]),
	.measurement_value_in_5_2(measurement_value_in[5][2]),
	.measurement_valid_in_5_2(measurement_valid_in),
	.match_value_out_5_2(match_value_out[5][2]),
	.measurement_5_2(measurement[5][2]),
	.measurement_value_in_5_3(measurement_value_in[5][3]),
	.measurement_valid_in_5_3(measurement_valid_in),
	.match_value_out_5_3(match_value_out[5][3]),
	.measurement_5_3(measurement[5][3]),
	.measurement_value_in_5_4(measurement_value_in[5][4]),
	.measurement_valid_in_5_4(measurement_valid_in),
	.match_value_out_5_4(match_value_out[5][4]),
	.measurement_5_4(measurement[5][4]),
	.measurement_value_in_5_5(measurement_value_in[5][5]),
	.measurement_valid_in_5_5(measurement_valid_in),
	.match_value_out_5_5(match_value_out[5][5]),
	.measurement_5_5(measurement[5][5]),
	.measurement_value_in_5_6(measurement_value_in[5][6]),
	.measurement_valid_in_5_6(measurement_valid_in),
	.match_value_out_5_6(match_value_out[5][6]),
	.measurement_5_6(measurement[5][6]),
	.start_offer(start_offer),
	.stop_offer(stop_offer)
);

initial
begin
	measurement_value_in[0][0] = 0;
	measurement_value_in[0][1] = 0;
	measurement_value_in[0][2] = 0;
	measurement_value_in[0][3] = 0;
	measurement_value_in[0][4] = 0;
	measurement_value_in[0][5] = 0;
	measurement_value_in[0][6] = 0;
	measurement_value_in[1][0] = 0;
	measurement_value_in[1][1] = 0;
	measurement_value_in[1][2] = 0;
	measurement_value_in[1][3] = 0;
	measurement_value_in[1][4] = 0;
	measurement_value_in[1][5] = 0;
	measurement_value_in[1][6] = 0;
	measurement_value_in[2][0] = 0;
	measurement_value_in[2][1] = 0;
	measurement_value_in[2][2] = 0;
	measurement_value_in[2][3] = 1;
	measurement_value_in[2][4] = 0;
	measurement_value_in[2][5] = 0;
	measurement_value_in[2][6] = 0;
	measurement_value_in[3][0] = 0;
	measurement_value_in[3][1] = 0;
	measurement_value_in[3][2] = 0;
	measurement_value_in[3][3] = 0;
	measurement_value_in[3][4] = 0;
	measurement_value_in[3][5] = 0;
	measurement_value_in[3][6] = 0;
	measurement_value_in[4][0] = 0;
	measurement_value_in[4][1] = 0;
	measurement_value_in[4][2] = 0;
	measurement_value_in[4][3] = 1;
	measurement_value_in[4][4] = 0;
	measurement_value_in[4][5] = 0;
	measurement_value_in[4][6] = 0;
	measurement_value_in[5][0] = 0;
	measurement_value_in[5][1] = 0;
	measurement_value_in[5][2] = 0;
	measurement_value_in[5][3] = 1;
	measurement_value_in[5][4] = 0;
	measurement_value_in[5][5] = 0;
	measurement_value_in[5][6] = 0;
	measurement_valid_in = 0;
	reset = 1;
	start_offer = 0;
	stop_offer = 0;
	#102;
	reset = 0;
	#20;
	measurement_valid_in = 1;
	#10;
	measurement_valid_in = 0;
	#1000;
	start_offer = 1;
	#10;
	start_offer = 0;
	#25000; // We wait for 2500 cycles
	stop_offer = 1;
	#10;
	stop_offer = 0;
	if(measurement[0][0] == 1'b1) begin;
		$display("%t \t (y,x) = 0,0 \t match = \%d,\%d",$time,match_value_out[0][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[0][1] == 1'b1) begin;
		$display("%t \t (y,x) = 0,1 \t match = \%d,\%d",$time,match_value_out[0][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[0][2] == 1'b1) begin;
		$display("%t \t (y,x) = 0,2 \t match = \%d,\%d",$time,match_value_out[0][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][2][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[0][3] == 1'b1) begin;
		$display("%t \t (y,x) = 0,3 \t match = \%d,\%d",$time,match_value_out[0][3][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][3][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[0][4] == 1'b1) begin;
		$display("%t \t (y,x) = 0,4 \t match = \%d,\%d",$time,match_value_out[0][4][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][4][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[0][5] == 1'b1) begin;
		$display("%t \t (y,x) = 0,5 \t match = \%d,\%d",$time,match_value_out[0][5][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][5][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[0][6] == 1'b1) begin;
		$display("%t \t (y,x) = 0,6 \t match = \%d,\%d",$time,match_value_out[0][6][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[0][6][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][0] == 1'b1) begin;
		$display("%t \t (y,x) = 1,0 \t match = \%d,\%d",$time,match_value_out[1][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][1] == 1'b1) begin;
		$display("%t \t (y,x) = 1,1 \t match = \%d,\%d",$time,match_value_out[1][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][2] == 1'b1) begin;
		$display("%t \t (y,x) = 1,2 \t match = \%d,\%d",$time,match_value_out[1][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][2][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][3] == 1'b1) begin;
		$display("%t \t (y,x) = 1,3 \t match = \%d,\%d",$time,match_value_out[1][3][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][3][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][4] == 1'b1) begin;
		$display("%t \t (y,x) = 1,4 \t match = \%d,\%d",$time,match_value_out[1][4][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][4][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][5] == 1'b1) begin;
		$display("%t \t (y,x) = 1,5 \t match = \%d,\%d",$time,match_value_out[1][5][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][5][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][6] == 1'b1) begin;
		$display("%t \t (y,x) = 1,6 \t match = \%d,\%d",$time,match_value_out[1][6][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][6][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][0] == 1'b1) begin;
		$display("%t \t (y,x) = 2,0 \t match = \%d,\%d",$time,match_value_out[2][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][1] == 1'b1) begin;
		$display("%t \t (y,x) = 2,1 \t match = \%d,\%d",$time,match_value_out[2][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][2] == 1'b1) begin;
		$display("%t \t (y,x) = 2,2 \t match = \%d,\%d",$time,match_value_out[2][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][2][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][3] == 1'b1) begin;
		$display("%t \t (y,x) = 2,3 \t match = \%d,\%d",$time,match_value_out[2][3][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][3][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][4] == 1'b1) begin;
		$display("%t \t (y,x) = 2,4 \t match = \%d,\%d",$time,match_value_out[2][4][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][4][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][5] == 1'b1) begin;
		$display("%t \t (y,x) = 2,5 \t match = \%d,\%d",$time,match_value_out[2][5][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][5][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[2][6] == 1'b1) begin;
		$display("%t \t (y,x) = 2,6 \t match = \%d,\%d",$time,match_value_out[2][6][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[2][6][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][0] == 1'b1) begin;
		$display("%t \t (y,x) = 3,0 \t match = \%d,\%d",$time,match_value_out[3][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][1] == 1'b1) begin;
		$display("%t \t (y,x) = 3,1 \t match = \%d,\%d",$time,match_value_out[3][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][2] == 1'b1) begin;
		$display("%t \t (y,x) = 3,2 \t match = \%d,\%d",$time,match_value_out[3][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][2][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][3] == 1'b1) begin;
		$display("%t \t (y,x) = 3,3 \t match = \%d,\%d",$time,match_value_out[3][3][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][3][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][4] == 1'b1) begin;
		$display("%t \t (y,x) = 3,4 \t match = \%d,\%d",$time,match_value_out[3][4][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][4][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][5] == 1'b1) begin;
		$display("%t \t (y,x) = 3,5 \t match = \%d,\%d",$time,match_value_out[3][5][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][5][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[3][6] == 1'b1) begin;
		$display("%t \t (y,x) = 3,6 \t match = \%d,\%d",$time,match_value_out[3][6][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[3][6][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][0] == 1'b1) begin;
		$display("%t \t (y,x) = 4,0 \t match = \%d,\%d",$time,match_value_out[4][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][1] == 1'b1) begin;
		$display("%t \t (y,x) = 4,1 \t match = \%d,\%d",$time,match_value_out[4][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][2] == 1'b1) begin;
		$display("%t \t (y,x) = 4,2 \t match = \%d,\%d",$time,match_value_out[4][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][2][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][3] == 1'b1) begin;
		$display("%t \t (y,x) = 4,3 \t match = \%d,\%d",$time,match_value_out[4][3][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][3][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][4] == 1'b1) begin;
		$display("%t \t (y,x) = 4,4 \t match = \%d,\%d",$time,match_value_out[4][4][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][4][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][5] == 1'b1) begin;
		$display("%t \t (y,x) = 4,5 \t match = \%d,\%d",$time,match_value_out[4][5][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][5][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[4][6] == 1'b1) begin;
		$display("%t \t (y,x) = 4,6 \t match = \%d,\%d",$time,match_value_out[4][6][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[4][6][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][0] == 1'b1) begin;
		$display("%t \t (y,x) = 5,0 \t match = \%d,\%d",$time,match_value_out[5][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][1] == 1'b1) begin;
		$display("%t \t (y,x) = 5,1 \t match = \%d,\%d",$time,match_value_out[5][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][2] == 1'b1) begin;
		$display("%t \t (y,x) = 5,2 \t match = \%d,\%d",$time,match_value_out[5][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][2][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][3] == 1'b1) begin;
		$display("%t \t (y,x) = 5,3 \t match = \%d,\%d",$time,match_value_out[5][3][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][3][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][4] == 1'b1) begin;
		$display("%t \t (y,x) = 5,4 \t match = \%d,\%d",$time,match_value_out[5][4][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][4][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][5] == 1'b1) begin;
		$display("%t \t (y,x) = 5,5 \t match = \%d,\%d",$time,match_value_out[5][5][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][5][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[5][6] == 1'b1) begin;
		$display("%t \t (y,x) = 5,6 \t match = \%d,\%d",$time,match_value_out[5][6][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[5][6][CORDINATE_WIDTH -1:0]);
	end
end

endmodule