`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps

module unit_test_tb;

`include "parameters.v"

reg clk;
reg reset; 
reg measurement_value_in;
reg measurement_valid_in;
reg start_offer;
reg stop_offer;
reg [MSG_WIDTH -1 : 0] mailbox_north_value_in;
reg mailbox_north_valid_in;
wire mailbox_north_ready_out;
reg [MSG_WIDTH -1 : 0] mailbox_east_value_in;
reg mailbox_east_valid_in;
wire mailbox_east_ready_out;
reg [MSG_WIDTH -1 : 0] mailbox_west_value_in;
reg mailbox_west_valid_in;
wire mailbox_west_ready_out;
reg [MSG_WIDTH -1 : 0] mailbox_south_value_in;
reg mailbox_south_valid_in;
wire mailbox_south_ready_out;
wire [MSG_WIDTH -1 : 0] outqueue_north_value_out;
wire outqueue_north_valid_out;
reg outqueue_north_ready_in;
wire [MSG_WIDTH -1 : 0] outqueue_east_value_out;
wire outqueue_east_valid_out;
reg outqueue_east_ready_in;
wire [MSG_WIDTH -1 : 0] outqueue_west_value_out;
wire outqueue_west_valid_out;
reg outqueue_west_ready_in;
wire [MSG_WIDTH -1 : 0] outqueue_south_value_out;
wire outqueue_south_valid_out;
reg outqueue_south_ready_in;
wire [MATCH_VALUE_WIDTH -1 : 0] match_value_out;

reg [CORDINATE_WIDTH - 1:0] ROW_ID;
reg [CORDINATE_WIDTH - 1:0] COL_ID;
reg [COST_WIDTH - 1:0] BOUNDARY_COST;

always 
begin
    clk = 1'b1; 
    #5; // high for 20 * timescale = 20 ns

    clk = 1'b0;
    #5; // low for 20 * timescale = 20 ns
end

pe uut
(
    .clk(clk),
    .reset(reset),
    .measurement_value_in(measurement_value_in),
    .measurement_valid_in(measurement_valid_in),
    .start_offer(start_offer),
    .stop_offer(stop_offer),
    .match_value_out(match_value_out),
    .mailbox_north_value_in(mailbox_north_value_in),
    .mailbox_north_valid_in(mailbox_north_valid_in),
    .mailbox_north_ready_out(mailbox_north_ready_out),
    .mailbox_east_value_in(mailbox_east_value_in),
    .mailbox_east_valid_in(mailbox_east_valid_in),
    .mailbox_east_ready_out(mailbox_east_ready_out),
    .mailbox_west_value_in(mailbox_west_value_in),
    .mailbox_west_valid_in(mailbox_west_valid_in),
    .mailbox_west_ready_out(mailbox_west_ready_out),
    .mailbox_south_value_in(mailbox_south_value_in),
    .mailbox_south_valid_in(mailbox_south_valid_in),
    .mailbox_south_ready_out(mailbox_south_ready_out),
    .outqueue_north_value_out(outqueue_north_value_out),
    .outqueue_north_valid_out(outqueue_north_valid_out),
    .outqueue_north_ready_in(outqueue_north_ready_in),
    .outqueue_east_value_out(outqueue_east_value_out),
    .outqueue_east_valid_out(outqueue_east_valid_out),
    .outqueue_east_ready_in(outqueue_east_ready_in),
    .outqueue_west_value_out(outqueue_west_value_out),
    .outqueue_west_valid_out(outqueue_west_valid_out),
    .outqueue_west_ready_in(outqueue_west_ready_in),
    .outqueue_south_value_out(outqueue_south_value_out),
    .outqueue_south_valid_out(outqueue_south_valid_out),
    .outqueue_south_ready_in(outqueue_south_ready_in),
    .ROW_ID(ROW_ID),
    .COL_ID(COL_ID),
    .BOUNDARY_COST(BOUNDARY_COST)
);

initial
begin
    reset = 1;
    measurement_value_in = 0;
    measurement_valid_in = 0;
    start_offer = 0;
    stop_offer = 0;
    mailbox_north_value_in = 0;
    mailbox_north_valid_in = 0;
    mailbox_east_value_in = 0;
    mailbox_east_valid_in = 0;
    mailbox_west_value_in = 0;
    mailbox_west_valid_in = 0;
    mailbox_south_value_in = 0;
    mailbox_south_valid_in = 0;
    outqueue_north_ready_in = 0;
    outqueue_east_ready_in = 0;
    outqueue_west_ready_in = 0;
    outqueue_south_ready_in = 0;
    ROW_ID = 4;
    COL_ID = 2;
    BOUNDARY_COST = 6;
end
endmodule