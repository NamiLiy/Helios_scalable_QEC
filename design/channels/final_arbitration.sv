module final_arbitration_unit#(
    // parameter CODE_DISTANCE_X = 5,
    // parameter CODE_DISTANCE_Z = 4,
    parameter HUB_FIFO_WIDTH = 13,
    parameter HUB_FIFO_PHYSICAL_WIDTH = 128, //this should exclude valid and ready or out of band signals
    parameter FPGAID_WIDTH = 2,
    // parameter MY_ID = 0 ,
    // parameter X_START = 0,
    // parameter X_END = 0,
    parameter FIFO_IDWIDTH = 2,
    parameter FIFO_COUNT = 3
)(
    clk,
    reset,
    master_fifo_out_data_vector,
    master_fifo_out_valid_vector,
    master_fifo_out_ready_vector,
    master_fifo_in_data_vector,
    master_fifo_in_valid_vector,
    master_fifo_in_ready_vector,
    sc_fifo_out_data,
    sc_fifo_out_valid,
    sc_fifo_out_ready,
    sc_fifo_in_data,
    sc_fifo_in_valid,
    sc_fifo_in_ready,
    final_fifo_out_data,
    final_fifo_out_valid,
    final_fifo_out_ready,
    final_fifo_in_data,
    final_fifo_in_valid,
    final_fifo_in_ready,
    has_flying_messages
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
// localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
// localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
// localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
// localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
// localparam DISTANCE_WIDTH = 1 + PER_DIMENSION_WIDTH;
// localparam WEIGHT = 1;  // the weight in MWPM graph
// localparam BOUNDARY_COST = 2 * WEIGHT;
// localparam NEIGHBOR_COST = 2 * WEIGHT;
// localparam BOUNDARY_WIDTH = $clog2(BOUNDARY_COST + 1);
// localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]
// localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;
// // localparam FIFO_COUNT = MEASUREMENT_ROUNDS * (CODE_DISTANCE_Z);
// localparam FINAL_FIFO_WIDTH = MASTER_FIFO_WIDTH + $clog2(FIFO_COUNT+1);

// localparam TOP_FPGA_ID = MY_ID - 1;
// localparam BOTTOM_FPGA_ID = MY_ID + 1;

input clk;
input reset;

input [HUB_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_out_data_vector;
input [FIFO_COUNT - 1 :0] master_fifo_out_valid_vector;
output [FIFO_COUNT - 1 :0] master_fifo_out_ready_vector;
output [HUB_FIFO_WIDTH*FIFO_COUNT - 1 :0] master_fifo_in_data_vector;
output [FIFO_COUNT - 1 :0] master_fifo_in_valid_vector;
input [FIFO_COUNT - 1 :0] master_fifo_in_ready_vector;

input [HUB_FIFO_WIDTH - 1 :0] sc_fifo_out_data;
input sc_fifo_out_valid;
output sc_fifo_out_ready;
output [HUB_FIFO_WIDTH - 1 :0] sc_fifo_in_data;
output sc_fifo_in_valid;
input sc_fifo_in_ready;

output reg [HUB_FIFO_PHYSICAL_WIDTH - 1 :0] final_fifo_out_data;
output final_fifo_out_valid;
input final_fifo_out_ready;
input [HUB_FIFO_PHYSICAL_WIDTH - 1 :0] final_fifo_in_data;
input final_fifo_in_valid;
output final_fifo_in_ready;

output has_flying_messages;

assign has_flying_messages = 1'b0;
assign final_fifo_in_ready = 1'b1;
assign sc_fifo_in_valid = 1'b0;
assign master_fifo_out_ready_vector = 1;
assign master_fifo_in_valid_vector = 0;
assign sc_fifo_out_ready = 1;
assign final_fifo_out_valid = 0;
assign final_fifo_in_ready = 1;
assign has_flying_messages = 0;

reg [HUB_FIFO_PHYSICAL_WIDTH-1: 0] final_fifo_out_data_internal;
wire final_fifo_out_valid_internal;
wire final_fifo_out_is_full_internal;

wire [HUB_FIFO_PHYSICAL_WIDTH-1: 0] final_fifo_in_data_internal;
reg final_fifo_in_ready_internal;
wire final_fifo_in_empty_inernal;


endmodule