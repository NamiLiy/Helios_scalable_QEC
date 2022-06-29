module top_module_hub_/*$$ID*/ #(
    parameter CODE_DISTANCE_X = 3,
    parameter CODE_DISTANCE_Z = 2,
    parameter WEIGHT_X = 1,
    parameter WEIGHT_Z = 1,
    parameter WEIGHT_UD = 1 // Weight up down
) (
    clk,
    reset,

    // Temporary ports for debug
    // new_round_start,
    // is_error_syndromes,
    // roots,
    // result_valid,
    // iteration_counter,
    // cycle_counter,
    // deadlock,
    // final_cardinality,

    upstream_fifo_out_data,
    upstream_fifo_out_valid,
    upstream_fifo_out_ready,
    upstream_fifo_in_data,
    upstream_fifo_in_valid,
    upstream_fifo_in_ready,

    downstream_fifo_out_data,
    downstream_fifo_out_valid,
    downstream_fifo_out_ready,
    downstream_fifo_in_data,
    downstream_fifo_in_valid,
    downstream_fifo_in_ready,

    upstream_has_message_flying,
    upstream_has_odd_clusters,

    downstream_has_message_flying,
    downstream_has_odd_clusters,
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;
localparam PER_DIMENSION_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3;
localparam ITERATION_COUNTER_WIDTH = 8;  // counts up to CODE_DISTANCE iterations

localparam DIRECT_MESSAGE_WIDTH = ADDRESS_WIDTH + 1 + 1;  // [receiver, is_odd_cardinality_root, is_touching_boundary]

localparam MASTER_FIFO_WIDTH = DIRECT_MESSAGE_WIDTH + 1;

localparam HUB_FIFO_WIDTH = /*$$HUB_FIFO_WIDTH*/;
localparam HUB_FIFO_PHYSICAL_WIDTH_DWN = /*$$HUB_FIFO_PHYSICAL_WIDTH_DWN*/;
localparam HUB_FIFO_PHYSICAL_WIDTH_UP = /*$$HUB_FIFO_PHYSICAL_WIDTH_UP*/;
localparam DOWNSTREAM_FIFO_COUNT = /*$$DOWNSTREAM_FIFO_COUNT*/;
localparam FPGAID_WIDTH = /*$$FPGAID_WIDTH*/;
localparam FIFO_IDWIDTH = /*$$FIFO_IDWIDTH*/;


input clk;
input reset;
// input new_round_start;
// input [PU_COUNT-1:0] is_error_syndromes;
// output [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots;
// output reg result_valid;
// output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
// output [31:0] cycle_counter;
// output deadlock;
// output final_cardinality;

// output has_message_flying_otherside;
// output has_odd_clusters_otherside;

output [HUB_FIFO_PHYSICAL_WIDTH_UP - 1 :0] upstream_fifo_out_data;
output upstream_fifo_out_valid;
input upstream_fifo_out_ready;
input [HUB_FIFO_PHYSICAL_WIDTH_UP - 1 :0] upstream_fifo_in_data;
input upstream_fifo_in_valid;
output upstream_fifo_in_ready;

output [DOWNSTREAM_FIFO_COUNT*HUB_FIFO_PHYSICAL_WIDTH_DWN - 1 :0] downstream_fifo_out_data;
output [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_out_valid;
input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_out_ready;
input [DOWNSTREAM_FIFO_COUNT*HUB_FIFO_PHYSICAL_WIDTH_DWN - 1 :0] downstream_fifo_in_data;
input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_in_valid;
output [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_in_ready;

output reg upstream_has_message_flying;
output reg upstream_has_odd_clusters;

input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_has_message_flying;
input [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_has_odd_clusters;

wire [DOWNSTREAM_FIFO_COUNT*HUB_FIFO_WIDTH - 1 :0] downstream_fifo_out_data_pre;
wire [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_out_valid_pre;
wire [DOWNSTREAM_FIFO_COUNT - 1 :0] downstream_fifo_out_ready_pre;

wire [HUB_FIFO_WIDTH - 1 :0] upstream_fifo_out_data_pre;
wire upstream_fifo_out_valid_pre;
wire upstream_fifo_out_ready_pre;

always@(posedge clk) begin
    upstream_has_odd_clusters <= |downstream_has_odd_clusters;
    upstream_has_message_flying <= (|downstream_has_message_flying) || upstream_fifo_out_valid || upstream_fifo_in_valid || downstream_fifo_out_valid || downstream_fifo_in_valid;
end

// Todo : Final result calculation can be perfomed more efficiently. So this is a workaround.
// Todo : Nearest neighbor routing can be made more efficient than this as it is always send to the next fifo

//-----------------------Routing logic-----------------------//

// 1. First lets put all data into fifos

genvar i;

generate
    for (i=0; i < DOWNSTREAM_FIFO_COUNT; i=i+1) begin: dwn_input_fifos
        // instantiate processing unit
        wire [HUB_FIFO_WIDTH - 1 :0] downstream_fifo_in_data_d;
        wire downstream_fifo_in_valid_d;
        wire downstream_fifo_in_taken_d;
        wire downstream_fifo_is_full;

        wire [HUB_FIFO_PHYSICAL_WIDTH_DWN - 1 :0] downstream_fifo_in_data_temp;
        wire downstream_fifo_in_valid_temp;
        wire downstream_fifo_in_taken_temp;

        blocking_channel #(
            .WIDTH(HUB_FIFO_PHYSICAL_WIDTH_DWN), // width of data
            .DEPTH(256)
        ) down_input_fifo (
            .in_data(downstream_fifo_in_data[(i+1)*HUB_FIFO_PHYSICAL_WIDTH_DWN -1 : i*HUB_FIFO_PHYSICAL_WIDTH_DWN]),
            .in_valid(downstream_fifo_in_valid[i]),
            .in_is_full(downstream_fifo_is_full),
            .out_data(downstream_fifo_in_data_temp),
            .out_valid(downstream_fifo_in_valid_temp),
            .out_is_taken(downstream_fifo_in_taken_temp),
            .clk(clk),
            .reset(reset),
            .initialize(reset) //Check for correct signal
        );

        deserializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH_DWN)) des_down_input
        (
            .clk(clk),
            .reset(reset),
            .wide_fifo_data(downstream_fifo_in_data_d),
            .wide_fifo_valid(downstream_fifo_in_valid_d),
            .wide_fifo_ready(downstream_fifo_in_taken_d),
            .narrow_fifo_valid(downstream_fifo_in_valid_temp),
            .narrow_fifo_ready(downstream_fifo_in_taken_temp),
            .narrow_fifo_data(downstream_fifo_in_data_temp)
        );

        assign downstream_fifo_in_ready[i] = ~downstream_fifo_is_full;
        
    end
endgenerate

wire [HUB_FIFO_WIDTH - 1 :0] upstream_fifo_in_data_d;
wire upstream_fifo_in_valid_d;
wire upstream_fifo_in_taken_d;
wire upstream_fifo_is_full;

wire [HUB_FIFO_PHYSICAL_WIDTH_UP - 1 :0] upstream_fifo_in_data_temp;
wire upstream_fifo_in_valid_temp;
wire upstream_fifo_in_taken_temp;

blocking_channel #(
    .WIDTH(HUB_FIFO_PHYSICAL_WIDTH_UP), // width of data
    .DEPTH(256)
) down_input_fifo (
    .in_data(upstream_fifo_in_data),
    .in_valid(upstream_fifo_in_valid),
    .in_is_full(upstream_fifo_is_full),
    .out_data(upstream_fifo_in_data_temp),
    .out_valid(upstream_fifo_in_valid_temp),
    .out_is_taken(upstream_fifo_in_taken_temp),
    .clk(clk),
    .reset(reset),
    .initialize(reset) //Check for correct signal
);

deserializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH_UP)) des_up_input
        (
            .clk(clk),
            .reset(reset),
            .wide_fifo_data(upstream_fifo_in_data_d),
            .wide_fifo_valid(upstream_fifo_in_valid_d),
            .wide_fifo_ready(upstream_fifo_in_taken_d),
            .narrow_fifo_valid(upstream_fifo_in_valid_temp),
            .narrow_fifo_ready(upstream_fifo_in_taken_temp),
            .narrow_fifo_data(upstream_fifo_in_data_temp)
        );

assign upstream_fifo_in_ready = ~upstream_fifo_is_full;

// 2. Select a message to process. Upstream gets priority

`define downstream_coming_data(i) dwn_input_fifos[i].downstream_fifo_in_data_d
`define downstream_coming_valid(i) dwn_input_fifos[i].downstream_fifo_in_valid_d
`define downstream_coming_is_taken(i) dwn_input_fifos[i].downstream_fifo_in_taken_d

localparam DIRECT_CHANNEL_DEPTH = $clog2(DOWNSTREAM_FIFO_COUNT); //1
localparam DIRECT_CHANNEL_EXPAND_COUNT = 2 ** DIRECT_CHANNEL_DEPTH; //2
localparam DIRECT_CHANNEL_ALL_EXPAND_COUNT = 2 * DIRECT_CHANNEL_EXPAND_COUNT - 1;  // the length of tree structured gathering // 3

wire [DIRECT_CHANNEL_ALL_EXPAND_COUNT-1:0] tree_gathering_elected_direct_message_valid;
wire [(HUB_FIFO_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_data;
`define expanded_elected_output_message_data(i) tree_gathering_elected_direct_message_data[((i+1) * HUB_FIFO_WIDTH) - 1 : (i * HUB_FIFO_WIDTH)]
wire [(HUB_FIFO_WIDTH * DIRECT_CHANNEL_ALL_EXPAND_COUNT)-1:0] tree_gathering_elected_direct_message_index; // double check the dimensions
`define expanded_elected_output_message_index(i) tree_gathering_elected_direct_message_index[((i+1) * HUB_FIFO_WIDTH) - 1 : (i * HUB_FIFO_WIDTH)]

`define DIRECT_CHANNEL_LAYER_WIDTH (2 ** (DIRECT_CHANNEL_DEPTH - 1 - i))
`define DIRECT_CHANNEL_LAYERT_IDX (2 ** (DIRECT_CHANNEL_DEPTH + 1) - 2 ** (DIRECT_CHANNEL_DEPTH - i))
`define DIRECT_CHANNEL_LAST_LAYERT_IDX (2 ** (DIRECT_CHANNEL_DEPTH + 1) - 2 ** (DIRECT_CHANNEL_DEPTH + 1 - i))
`define DIRECT_CHANNEL_CURRENT_IDX (`DIRECT_CHANNEL_LAYERT_IDX + j)
`define DIRECT_CHANNEL_CHILD_1_IDX (`DIRECT_CHANNEL_LAST_LAYERT_IDX + 2 * j)
`define DIRECT_CHANNEL_CHILD_2_IDX (`DIRECT_CHANNEL_CHILD_1_IDX + 1)
localparam DIRECT_CHANNEL_ROOT_IDX = DIRECT_CHANNEL_ALL_EXPAND_COUNT - 1; // 6

generate
    for (i=0; i < DIRECT_CHANNEL_EXPAND_COUNT; i=i+1) begin: direct_channel_gathering_initialization
        if (i < DOWNSTREAM_FIFO_COUNT) begin
            assign tree_gathering_elected_direct_message_valid[i] = `downstream_coming_valid(i);
            assign `expanded_elected_output_message_index(i) = i;
            assign `expanded_elected_output_message_data(i) = `downstream_coming_data(i);
        end else begin
            assign tree_gathering_elected_direct_message_valid[i] = 0;
        end
    end
    for (i=0; i < DIRECT_CHANNEL_DEPTH; i=i+1) begin: direct_channel_gathering_election
        genvar j;
        for (j=0; j < `DIRECT_CHANNEL_LAYER_WIDTH; j=j+1) begin: direct_channel_gathering_layer_election
            assign tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CURRENT_IDX] = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] | tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_2_IDX];
            assign `expanded_elected_output_message_index(`DIRECT_CHANNEL_CURRENT_IDX) = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] ? (
                `expanded_elected_output_message_index(`DIRECT_CHANNEL_CHILD_1_IDX)
            ) : (
                `expanded_elected_output_message_index(`DIRECT_CHANNEL_CHILD_2_IDX)
            );
            assign `expanded_elected_output_message_data(`DIRECT_CHANNEL_CURRENT_IDX) = tree_gathering_elected_direct_message_valid[`DIRECT_CHANNEL_CHILD_1_IDX] ? (
                `expanded_elected_output_message_data(`DIRECT_CHANNEL_CHILD_1_IDX)
            ) : (
                `expanded_elected_output_message_data(`DIRECT_CHANNEL_CHILD_2_IDX)
            );
        end
    end
endgenerate

`define gathered_elected_downstream_message_valid (tree_gathering_elected_direct_message_valid[DIRECT_CHANNEL_ROOT_IDX])
`define gathered_elected_downstream_message_index (`expanded_elected_output_message_index(DIRECT_CHANNEL_ROOT_IDX))
`define gathered_elected_downstream_message_data (`expanded_elected_output_message_data(DIRECT_CHANNEL_ROOT_IDX))

wire router_ready;
reg [HUB_FIFO_WIDTH - 1 :0] selected_message;
reg selected_valid;
reg [7:0] selected_index;



// take the direct message from downstream
generate
    for (i=0; i < DOWNSTREAM_FIFO_COUNT; i=i+1) begin: taking_direct_message
        assign `downstream_coming_is_taken(i) = ((i == `gathered_elected_downstream_message_index) && `gathered_elected_downstream_message_valid  && router_ready && !upstream_fifo_in_valid_d);
    end
endgenerate

assign upstream_fifo_in_taken_d = router_ready;

always@(posedge clk) begin
    if(upstream_fifo_in_valid_d && router_ready) begin
        selected_message <= upstream_fifo_in_data_d;
        selected_valid <= 1;
        selected_index <= 8'b11111111;
    end else begin
        if(`gathered_elected_downstream_message_valid && router_ready) begin
            selected_message <= `gathered_elected_downstream_message_data;
            selected_valid <= 1;
            selected_index <= `gathered_elected_downstream_message_index;
        end else begin
            if(router_ready) begin
                selected_valid <= 0;
            end
        end
    end
end
        
// 3. Now write the routing logic
// Todo : Check the logic here
wire all_output_fifos_free;
assign all_output_fifos_free = (& downstream_fifo_out_ready_pre) && upstream_fifo_out_ready_pre;
assign router_ready =  all_output_fifos_free;

reg [HUB_FIFO_WIDTH - 1 :0] output_message_register;
reg [DOWNSTREAM_FIFO_COUNT : 0] output_valid_register;

`define message_from_upstream (selected_index == 8'b11111111 ? 1 : 0)
`define message_from_stage_controller (selected_message[HUB_FIFO_WIDTH-FPGAID_WIDTH-1:HUB_FIFO_WIDTH-FPGAID_WIDTH-FIFO_IDWIDTH] == {FIFO_IDWIDTH{1'b1}} ? 1 : 0)
`define direct_message (selected_message[DIRECT_MESSAGE_WIDTH])

wire [DOWNSTREAM_FIFO_COUNT : 0] destination_index;
wire [ADDRESS_WIDTH-1 : 0] direct_address; 

assign direct_address = selected_message [DIRECT_MESSAGE_WIDTH - 1 : 2];

// Finding the correct output FIFO to a neighboring message is follows
// First if you are the first L1 fifo and input message is connected then you must decide whether it is from the top half or the bottom half of the split
// Then the index should be redirected to the proper s follows
// If top half then to bottom half unless going to the first FIFO
// If bottom half then definitely to the first half.
// This is also offloaded to the leaf card
wire [FPGAID_WIDTH - 1 : 0] dest_fpga_id;
assign dest_fpga_id = selected_message[HUB_FIFO_WIDTH - 1: HUB_FIFO_WIDTH - FPGAID_WIDTH];

genvar k;

// generate
//     for (k=0; i < DOWNSTREAM_FIFO_COUNT; k=k+1) begin: downstream_fifo_selectio`default_nettype 
//         if(`direct_message) begin
//             if(direct_address >= lower_bounds[k] && `direct_address <= upper_bounds[k]) begin
//                 destination_index[k] = 1'b1;
//             end
//         end else begin
//             if(dest_fpga_id >= lower_bounds_fpga[k] && `direct_address <= upper_bounds_fpga[k]) begin
//                 destination_index[k] = 1'b1;
//             end
//         end
//     end
// end

  routing_table_/*$$ID*/ ru (
      .dest_fpga_id(dest_fpga_id),
      .destination_index(destination_index)
  );



always@(posedge clk) begin
    if (reset) begin
        output_valid_register <= 32'b0;
    end else begin
        if(all_output_fifos_free) begin
            if(selected_valid) begin
                if(`message_from_upstream) begin
                    if(`message_from_stage_controller) begin
                        output_valid_register[DOWNSTREAM_FIFO_COUNT-1 :0] <= {DOWNSTREAM_FIFO_COUNT{1'b1}};
                        output_valid_register[DOWNSTREAM_FIFO_COUNT] <= 1'b0;
                    end else begin
                        if(`direct_message) begin
                            output_valid_register[DOWNSTREAM_FIFO_COUNT :0] <= destination_index;
                        end else begin
                            output_valid_register[DOWNSTREAM_FIFO_COUNT :0] <= destination_index;
                        end
                    end
                end else begin
                    if(`message_from_stage_controller) begin
                        output_valid_register[DOWNSTREAM_FIFO_COUNT-1 :0] <= {DOWNSTREAM_FIFO_COUNT{1'b0}};
                        output_valid_register[DOWNSTREAM_FIFO_COUNT] <= 1'b1;
                    end else begin
                        if(`direct_message) begin
                            output_valid_register[DOWNSTREAM_FIFO_COUNT :0] <= destination_index;
                        end else begin
                            output_valid_register[DOWNSTREAM_FIFO_COUNT :0] <= destination_index;
                        end
                    end        
                end
            end else begin
                output_valid_register[DOWNSTREAM_FIFO_COUNT-1 :0] <= {DOWNSTREAM_FIFO_COUNT{1'b0}};
                output_valid_register[DOWNSTREAM_FIFO_COUNT] <= 1'b0;
            end
            output_message_register <= selected_message;
        end
    end
end

assign upstream_fifo_out_data = output_message_register;
assign upstream_fifo_out_valid = output_valid_register[DOWNSTREAM_FIFO_COUNT];

`define downstream_fifo_out_data(i) downstream_fifo_out_data[((i+1) * HUB_FIFO_PHYSICAL_WIDTH_DWN) - 1 : (i * HUB_FIFO_PHYSICAL_WIDTH_DWN)]

generate
    for (i=0; i < DOWNSTREAM_FIFO_COUNT; i=i+1) begin: output_data_writing

        wire[HUB_FIFO_PHYSICAL_WIDTH_DWN-1 : 0] narrow_fifo_data;

        serializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH_DWN)) ser_dwn_out
        (
            .clk(clk),
            .reset(reset),
            .wide_fifo_data(output_message_register),
            .wide_fifo_valid(output_valid_register[i]),
            .wide_fifo_ready(downstream_fifo_out_ready_pre[i]),
            .narrow_fifo_valid(downstream_fifo_out_valid[i]),
            .narrow_fifo_ready(downstream_fifo_out_ready[i]),
            .narrow_fifo_data(narrow_fifo_data)
        );

        assign `downstream_fifo_out_data(i) = narrow_fifo_data;
    end
endgenerate

serializer #(.HUB_FIFO_WIDTH(HUB_FIFO_WIDTH), .HUB_FIFO_PHYSICAL_WIDTH(HUB_FIFO_PHYSICAL_WIDTH_UP)) ser_up_out
(
    .clk(clk),
    .reset(reset),
    .wide_fifo_data(output_message_register),
    .wide_fifo_valid(output_valid_register[DOWNSTREAM_FIFO_COUNT]),
    .wide_fifo_ready(upstream_fifo_out_ready_pre),
    .narrow_fifo_data(upstream_fifo_out_data),
    .narrow_fifo_ready(upstream_fifo_out_ready),
    .narrow_fifo_valid(upstream_fifo_out_valid)
);

// upstream messages from the stage controller has to be broadcasted down
// upstream messages for neighboring or blocking FIFOs need to be send to the correct downstream port
// downstream messages from stage controller has to be send to upstream (unless this is the root)
// upstream messages for neighboring or blocking FIFOs need to be send to the correct downstream port

endmodule





