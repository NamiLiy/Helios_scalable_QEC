`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module top_single_3_by_3_x_tb;

// This is test bench of 3 by 2 grid of x stabilizers

`include "parameters.v"

reg measurement_value_in[0:1][0:2];
reg measurement_valid_in;
wire [MATCH_VALUE_WIDTH -1 : 0] match_value_out[0:1][0:2];
wire measurement[0:1][0:2];
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

top_single_3_by_3_x uut(
	.clk(clk),
	.reset(reset),
	.measurement_value_in_0_0(measurement_value_in[0][0]),
	.measurement_valid_in_0_0(measurement_valid_in),
	.match_value_out_0_0(match_value_out[0][0]),
	.measurement_value_in_0_1(measurement_value_in[0][1]),
	.measurement_valid_in_0_1(measurement_valid_in),
	.match_value_out_0_1(match_value_out[0][1]),
	.measurement_value_in_0_2(measurement_value_in[0][2]),
	.measurement_valid_in_0_2(measurement_valid_in),
	.match_value_out_0_2(match_value_out[0][2]),
	.measurement_value_in_1_0(measurement_value_in[1][0]),
	.measurement_valid_in_1_0(measurement_valid_in),
	.match_value_out_1_0(match_value_out[1][0]),
	.measurement_value_in_1_1(measurement_value_in[1][1]),
	.measurement_valid_in_1_1(measurement_valid_in),
	.match_value_out_1_1(match_value_out[1][1]),
	.measurement_value_in_1_2(measurement_value_in[1][2]),
	.measurement_valid_in_1_2(measurement_valid_in),
	.match_value_out_1_2(match_value_out[1][2]),
	.start_offer(start_offer),
	.stop_offer(stop_offer)
);

initial
begin
	measurement_value_in[0][0] = 1;
	measurement_value_in[0][1] = 1;
	measurement_value_in[0][2] = 0;
	measurement_value_in[1][0] = 0;
	measurement_value_in[1][1] = 0;
	measurement_value_in[1][2] = 0;
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
	if(measurement[1][0] == 1'b1) begin;
		$display("%t \t (y,x) = 1,0 \t match = \%d,\%d",$time,match_value_out[1][0][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][0][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][1] == 1'b1) begin;
		$display("%t \t (y,x) = 1,1 \t match = \%d,\%d",$time,match_value_out[1][1][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][1][CORDINATE_WIDTH -1:0]);
	end
	if(measurement[1][2] == 1'b1) begin;
		$display("%t \t (y,x) = 1,2 \t match = \%d,\%d",$time,match_value_out[1][2][MATCH_VALUE_WIDTH -1:CORDINATE_WIDTH], match_value_out[1][2][CORDINATE_WIDTH -1:0]);
	end
end

endmodule