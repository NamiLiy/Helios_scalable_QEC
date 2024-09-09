module Helios_single_FPGA #(
    parameter GRID_WIDTH_X = 12,
    parameter GRID_WIDTH_Z = 2,
    parameter GRID_WIDTH_U = 10,
    parameter MAX_WEIGHT = 2,
    parameter NUM_CONTEXTS = 2,
    parameter NUM_FPGAS = 5,
    parameter FPGA_ID = 1,
    parameter ROUTER_DELAY_COUNTER = 18,
    parameter ACTUAL_D = 5
) (
    clk,
    reset,

    input_data,
    input_valid,
    input_ready,

    output_data,
    output_valid,
    output_ready,

    parent_rx_data,
    parent_rx_valid,
    parent_rx_ready,

    parent_tx_data,
    parent_tx_valid,
    parent_tx_ready,

    grid_1_out_data,
    grid_1_out_valid,
    grid_1_out_ready,

    grid_1_in_data,
    grid_1_in_valid,
    grid_1_in_ready,

    grid_2_out_data,
    grid_2_out_valid,
    grid_2_out_ready,

    grid_2_in_data,
    grid_2_in_valid,
    grid_2_in_ready


    // roots // A debug port. Do not use in the real implementation
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam FPGA_BIT_WIDTH = $clog2(NUM_FPGAS);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH;

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PU_COUNT = PU_COUNT_PER_ROUND * GRID_WIDTH_U;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;

localparam ADDRESS_WIDTH_WITH_B = ADDRESS_WIDTH + 1;
localparam EXPOSED_DATA_SIZE = ADDRESS_WIDTH_WITH_B + 1 + 1 + 1;
localparam FPGA_FIFO_SIZE = EXPOSED_DATA_SIZE + 1;
localparam FPGA_FIFO_COUNT = (2*GRID_WIDTH_Z - 1)*GRID_WIDTH_U;


localparam logical_qubits_in_j_dim = (GRID_WIDTH_Z + (ACTUAL_D-1)/2 - 1) / ((ACTUAL_D-1)/2); // round up to the nearest integer
localparam logical_qubits_in_i_dim = (GRID_WIDTH_X + ACTUAL_D+1 - 1) / (ACTUAL_D+1); // round up to the nearest integer
localparam borders_in_j_dim = (logical_qubits_in_j_dim + 1)*logical_qubits_in_i_dim;
localparam borders_in_i_dim = (logical_qubits_in_i_dim + 1)*logical_qubits_in_j_dim;


input clk;
input reset;

input [31 : 0] input_data;
input input_valid;
output input_ready;
output [31 : 0] output_data;
output output_valid;
input output_ready;

input [63 : 0] parent_rx_data;
input parent_rx_valid;
output parent_rx_ready;

output [63 : 0] parent_tx_data;
output parent_tx_valid;
input parent_tx_ready;

output [63 : 0] grid_1_out_data;
output grid_1_out_valid;
input grid_1_out_ready;

input [63 : 0] grid_1_in_data;
input grid_1_in_valid;
output grid_1_in_ready;

output [63 : 0] grid_2_out_data;
output grid_2_out_valid;
input grid_2_out_ready;

input [63 : 0] grid_2_in_data;
input grid_2_in_valid;
output grid_2_in_ready;

wire [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;

wire [STAGE_WIDTH-1:0] global_stage;
wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] correction;

wire [PU_COUNT_PER_ROUND-1:0] measurements;
wire [PU_COUNT - 1 : 0] odd_clusters;
wire [PU_COUNT - 1 : 0] busy;

wire [63:0] input_ctrl_rx_data;
wire input_ctrl_rx_valid;
wire input_ctrl_rx_ready;

wire [63:0] output_ctrl_tx_data;
wire output_ctrl_tx_valid;
wire output_ctrl_tx_ready;

wire [2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0] border_output_data;
wire [2*FPGA_FIFO_COUNT-1:0] border_output_valid;
wire [2*FPGA_FIFO_COUNT-1:0] border_output_ready;

wire [2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0] border_input_data;
wire [2*FPGA_FIFO_COUNT-1:0] border_input_valid;
wire [2*FPGA_FIFO_COUNT-1:0] border_input_ready;

wire [63:0] handler_to_controller_data;
wire handler_to_controller_valid;
wire handler_to_controller_ready;

wire [63:0] controller_to_handler_data;
wire controller_to_handler_valid;
wire controller_to_handler_ready;

wire [1:0] border_continous;

wire router_busy;
wire artificial_boundary;
wire [borders_in_j_dim + borders_in_i_dim - 1 : 0] fusion_boundary;
wire reset_all_edges;

localparam EW_BORDER_WIDTH = GRID_WIDTH_X / 2;
localparam NS_BORDER_WIDTH = GRID_WIDTH_Z;

wire [EW_BORDER_WIDTH-1:0] east_border;
wire [EW_BORDER_WIDTH-1:0] west_border;
wire [NS_BORDER_WIDTH-1:0] north_border;
wire [NS_BORDER_WIDTH-1:0] south_border;

single_FPGA_decoding_graph_dynamic_rsc #( 
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .MAX_WEIGHT(MAX_WEIGHT),
    .NUM_CONTEXTS(NUM_CONTEXTS),
    .NUM_FPGAS(NUM_FPGAS),
    .ACTUAL_D(ACTUAL_D),
    .FPGA_ID(FPGA_ID)
) decoding_graph_rsc (
    .clk(clk),
    .reset(reset),
    .measurements(measurements),
    .odd_clusters(odd_clusters),
    .roots(roots),
    .correction(correction),
    .busy(busy),
    .global_stage(global_stage),
    
    .artificial_boundary(artificial_boundary),
    .fusion_boundary(fusion_boundary),
    .reset_all_edges(reset_all_edges),

    .east_border(east_border),
    .west_border(west_border),
    .north_border(north_border),
    .south_border(south_border)
);

unified_controller #( 
    .GRID_WIDTH_X(GRID_WIDTH_X),
    .GRID_WIDTH_Z(GRID_WIDTH_Z),
    .GRID_WIDTH_U(GRID_WIDTH_U),
    .ITERATION_COUNTER_WIDTH(8),
    .MAXIMUM_DELAY(3),
    .NUM_CONTEXTS(NUM_CONTEXTS),
    .CTRL_FIFO_WIDTH(64),
    .NUM_FPGAS(NUM_FPGAS),
    .ROUTER_DELAY_COUNTER(ROUTER_DELAY_COUNTER),
    .ACTUAL_D(ACTUAL_D),
    .FPGA_ID(FPGA_ID)
) controller (
    .clk(clk),
    .reset(reset),
    .input_data(input_data),
    .input_valid(input_valid),
    .input_ready(input_ready),
    .output_data(output_data),
    .output_valid(output_valid),
    .output_ready(output_ready),
    .input_ctrl_rx_data(input_ctrl_rx_data),
    .input_ctrl_rx_valid(input_ctrl_rx_valid),
    .input_ctrl_rx_ready(input_ctrl_rx_ready),
    .output_ctrl_tx_data(output_ctrl_tx_data),
    .output_ctrl_tx_valid(output_ctrl_tx_valid),
    .output_ctrl_tx_ready(output_ctrl_tx_ready),
    .busy_PE(busy),
    .odd_clusters_PE(odd_clusters),
    .global_stage(global_stage),
    .measurements(measurements),
    .correction(correction),
    .router_busy(router_busy),
    .border_continous(border_continous),
    .artificial_boundary(artificial_boundary),
    .fusion_boundary(fusion_boundary),
    .reset_all_edges(reset_all_edges),

    .east_border(east_border),
    .west_border(west_border),
    .north_border(north_border),
    .south_border(south_border),

    .grid_1_in_data(grid_1_in_data),
    .grid_1_in_valid(grid_1_in_valid),
    .grid_1_in_ready(grid_1_in_ready),

    .grid_1_out_data(grid_1_out_data),
    .grid_1_out_valid(grid_1_out_valid),
    .grid_1_out_ready(grid_1_out_ready),

    .grid_2_in_data(grid_2_in_data),
    .grid_2_in_valid(grid_2_in_valid),
    .grid_2_in_ready(grid_2_in_ready),

    .grid_2_out_data(grid_2_out_data),
    .grid_2_out_valid(grid_2_out_valid),
    .grid_2_out_ready(grid_2_out_ready)
);

message_handler #(
    .GT_FIFO_SIZE(64),
    .FPGA_ID(FPGA_ID)
) handler (
    .clk(clk),
    .reset(reset),
    .handler_to_control_data(handler_to_controller_data),
    .handler_to_control_valid(handler_to_controller_valid),
    .handler_to_control_ready(handler_to_controller_ready),
    .control_to_handler_data(controller_to_handler_data),
    .control_to_handler_valid(controller_to_handler_valid),
    .control_to_handler_ready(controller_to_handler_ready),
    .in_data(parent_rx_data),
    .in_valid(parent_rx_valid),
    .in_ready(parent_rx_ready),
    .out_data(parent_tx_data),
    .out_valid(parent_tx_valid),
    .out_ready(parent_tx_ready),
    .router_busy(router_busy)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(64)
) parent_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(handler_to_controller_data),
    .input_valid(handler_to_controller_valid),
    .input_ready(handler_to_controller_ready),
    .output_data(input_ctrl_rx_data),
    .output_valid(input_ctrl_rx_valid),
    .output_ready(input_ctrl_rx_ready)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(64)
) controller_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(output_ctrl_tx_data),
    .input_valid(output_ctrl_tx_valid),
    .input_ready(output_ctrl_tx_ready),
    .output_data(controller_to_handler_data),
    .output_valid(controller_to_handler_valid),
    .output_ready(controller_to_handler_ready)
);

endmodule