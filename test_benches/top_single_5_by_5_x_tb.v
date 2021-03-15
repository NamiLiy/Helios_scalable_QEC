`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module top_single_5_by_5_x_tb;

// This is test bench of 5 by 4 grid of x stabilizers

`include "parameters.v"

reg measurement_value_in[0:3][0:4];
reg measurement_valid_in;
wire [MATCH_VALUE_WIDTH -1 : 0] match_value_out[0:3][0:4];
wire measurement[0:3][0:4];
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

top_single_5_by_5_x uut(
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
	.start_offer(start_offer),
	.stop_offer(stop_offer)
);

initial
begin
	measurement_value_in[0][0] = 1;
	measurement_value_in[0][1] = 1;
	measurement_value_in[0][2] = 0;
	measurement_value_in[0][3] = 0;
	measurement_value_in[0][4] = 0;
	measurement_value_in[1][0] = 0;
	measurement_value_in[1][1] = 0;
	measurement_value_in[1][2] = 0;
	measurement_value_in[1][3] = 0;
	measurement_value_in[1][4] = 0;
	measurement_value_in[2][0] = 0;
	measurement_value_in[2][1] = 0;
	measurement_value_in[2][2] = 0;
	measurement_value_in[2][3] = 0;
	measurement_value_in[2][4] = 0;
	measurement_value_in[3][0] = 0;
	measurement_value_in[3][1] = 0;
	measurement_value_in[3][2] = 0;
	measurement_value_in[3][3] = 0;
	measurement_value_in[3][4] = 0;
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
end

endmodule