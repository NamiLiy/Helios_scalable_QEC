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
    #102;
    reset = 0;
    outqueue_north_ready_in = 1;
    outqueue_east_ready_in = 1;
    outqueue_west_ready_in = 1;
    outqueue_south_ready_in = 1;
    #20;
    measurement_value_in = 1;
    measurement_valid_in = 1;
    #10;
    measurement_value_in = 0;
    measurement_valid_in = 0;
    #400;
    start_offer = 1;
    #10;
    start_offer = 0;
    #2000;
end

wire [MSG_TYPE_WIDTH-1:0] get_msg_type;
wire [CORDINATE_WIDTH-1:0] get_source_row;
wire [CORDINATE_WIDTH-1:0] get_source_col;
wire [CORDINATE_WIDTH-1:0] get_broker_row;
wire [CORDINATE_WIDTH-1:0] get_broker_col;
wire [CORDINATE_WIDTH-1:0] get_receiver_row;
wire [CORDINATE_WIDTH-1:0] get_receiver_col;
wire [COST_WIDTH-1:0] get_cost;
wire [TIMESTAMP_WIDTH-1:0] get_timestamp;
wire [MAX_HOP_WIDTH-1:0] get_max_hops;
wire [CORDINATE_WIDTH-1:0] get_target_row;
wire [CORDINATE_WIDTH-1:0] get_target_col;
wire get_is_loop;

assign get_msg_type = outqueue_east_value_out[MSG_TYPE_WIDTH-1:0];
assign get_source_row = outqueue_east_value_out[MSG_WIDTH -1 - CORDINATE_WIDTH*2 : CORDINATE_WIDTH*3 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
assign get_source_col = outqueue_east_value_out[MSG_WIDTH -1 - CORDINATE_WIDTH*3 : CORDINATE_WIDTH*2 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
assign get_broker_row = outqueue_east_value_out[MSG_WIDTH -1 - CORDINATE_WIDTH*4 : CORDINATE_WIDTH + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
assign get_broker_col =  outqueue_east_value_out[MSG_WIDTH -1 - CORDINATE_WIDTH*5 :  COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
assign get_receiver_row = outqueue_east_value_out [MSG_WIDTH -1 : CORDINATE_WIDTH*5 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
assign get_receiver_col = outqueue_east_value_out [MSG_WIDTH -1 - CORDINATE_WIDTH : CORDINATE_WIDTH*4 + COST_WIDTH + MAX_HOP_WIDTH + TIMESTAMP_WIDTH + MSG_TYPE_WIDTH];
assign get_cost = outqueue_east_value_out [MSG_WIDTH -1 - CORDINATE_WIDTH*6 - TIMESTAMP_WIDTH : MAX_HOP_WIDTH + MSG_TYPE_WIDTH];
assign get_timestamp = outqueue_east_value_out [MSG_WIDTH -1 - CORDINATE_WIDTH*6  : COST_WIDTH + MAX_HOP_WIDTH + MSG_TYPE_WIDTH];
assign get_max_hops = outqueue_east_value_out [MSG_WIDTH -1 - CORDINATE_WIDTH*6 - TIMESTAMP_WIDTH - COST_WIDTH : MSG_TYPE_WIDTH];
assign get_target_row = outqueue_east_value_out [MSG_WIDTH -1 - CORDINATE_WIDTH*6  : MSG_WIDTH - CORDINATE_WIDTH*7];
assign get_target_col = outqueue_east_value_out [MSG_WIDTH -1 - CORDINATE_WIDTH*7  : MSG_WIDTH - CORDINATE_WIDTH*8];
assign get_is_loop = outqueue_east_value_out [MAX_HOP_WIDTH + MSG_TYPE_WIDTH + 1  : MAX_HOP_WIDTH + MSG_TYPE_WIDTH];


always @(posedge clk) begin
    if(outqueue_east_valid_out == 1'b1 && outqueue_east_ready_in == 1'b1) begin
        //  $fdisplay("%d,\t%b,\t%b,\t%b,\t%d",$time, clk,reset,enable,count); 
        $display("%t \t %d dest = %d,%d, src = %d,%d, broker = %d,%d, cost = %d, tsp = %d, hops = %d ",$time,get_msg_type,get_receiver_row,get_receiver_col,get_source_row,get_source_col,get_broker_row,get_broker_col,$signed(get_cost),get_timestamp,get_max_hops);
    end
end

endmodule