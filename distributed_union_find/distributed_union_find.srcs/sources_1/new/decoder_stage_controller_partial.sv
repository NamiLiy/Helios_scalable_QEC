`timescale 1ns / 1ps

`include "parameters.sv"

module decoder_stage_controller_left #(
    parameter CODE_DISTANCE = 3,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter BOUNDARY_GROW_DELAY = 10,  // clock cycles
    parameter SPREAD_CLUSTER_DELAY = 10,  // clock cycles
    parameter SYNC_IS_ODD_CLUSTER_DELAY = 10,  // clock cycles
    parameter PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE),
    parameter ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3,
    parameter PU_COUNT = CODE_DISTANCE*CODE_DISTANCE*(CODE_DISTANCE-1),
    parameter UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH,  // [old_root, updated_root]
    parameter MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1,
    parameter LEFT_BLOCK = ((CODE_DISTANCE**2)-1)/2,
    parameter RIGHT_BLOCK = ((CODE_DISTANCE-1)**2)/2
) (
    input clk,
    input reset,
    input new_round_start,
    input has_message_flying,
    input has_odd_clusters,
    input [PU_COUNT-1:0] is_touching_boundaries,
    input [PU_COUNT-1:0] is_odd_cardinalities,
    input [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots,
    output reg [STAGE_WIDTH-1:0] stage,
    output reg result_valid,
    output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter,
    output reg [31:0] cycle_counter,
    output reg deadlock,
    output final_cardinality,
    output [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data,
    output sc_fifo_out_valid,
    input sc_fifo_out_ready,
    input [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data,
    input sc_fifo_in_valid,
    output sc_fifo_in_ready,
    input has_message_flying_otherside,
    input has_odd_clusters_otherside,
    output [(ADDRESS_WIDTH * PU_COUNT)-1:0] net_roots_out
);
`define MAX(a, b) (((a) > (b)) ? (a) : (b))
`define MAX3(a, b, c) (((a) > `MAX((b), (c))) ? (a) : `MAX((b), (c)))
`define MIN(a, b) (((a) < (b))? (a) : (b))

localparam MAXIMUM_DELAY = `MAX3(BOUNDARY_GROW_DELAY, SPREAD_CLUSTER_DELAY, SYNC_IS_ODD_CLUSTER_DELAY);
localparam COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 1);
reg [COUNTER_WIDTH-1:0] delay_counter;
reg [31:0] cycles_in_stage;

localparam DEADLOCK_THRESHOLD = CODE_DISTANCE*CODE_DISTANCE*CODE_DISTANCE*10;

reg go_to_result_calculator;
wire done_from_calculator;

reg has_messages_flying_both_sides;
reg has_odd_clusters_both_sides;

reg [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data_internal;
reg sc_fifo_out_valid_internal;
wire sc_fifo_out_full_internal;

wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data_internal;
wire sc_fifo_in_empty_internal;
reg sc_fifo_in_ready_internal;

wire sc_fifo_out_empty;
assign sc_fifo_out_valid = !sc_fifo_out_empty;

fifo_fwft #(.DEPTH(16), .WIDTH(MASTER_FIFO_WIDTH)) out_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(sc_fifo_out_valid_internal),
    .din(sc_fifo_out_data_internal),
    .full(sc_fifo_out_full_internal),
    .empty(sc_fifo_out_empty),
    .dout(sc_fifo_out_data),
    .rd_en(sc_fifo_out_ready)
);

wire sc_fifo_in_full;
assign sc_fifo_in_ready = !sc_fifo_in_full;

fifo_fwft #(.DEPTH(16), .WIDTH(MASTER_FIFO_WIDTH)) in_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(sc_fifo_in_valid),
    .din(sc_fifo_in_data),
    .full(sc_fifo_in_full),
    .empty(sc_fifo_in_empty_internal),
    .dout(sc_fifo_in_data_internal),
    .rd_en(sc_fifo_in_ready_internal)
);

// always@(*) begin
//     if (sc_fifo_in_data_internal[0] == 1'b1 && !sc_fifo_in_empty_internal) begin
//         has_messages_flying_both_sides == 1'b1;
//     end
// end

// always@(*) begin
//     if (sc_fifo_in_data_internal[1] == 1'b1 && !sc_fifo_in_empty_internal) begin
//         has_odd_clusters_both_sides == 1'b1;
//     end
// end

always@(*) begin
    if (has_message_flying || has_message_flying_otherside) begin
        has_messages_flying_both_sides = 1'b1;
    end else begin
        has_messages_flying_both_sides = 1'b0;
    end
end

always@(*) begin
    if (has_odd_clusters || has_odd_clusters_otherside) begin
        has_odd_clusters_both_sides = 1'b1;
    end else begin
        has_odd_clusters_both_sides = 1'b0;
    end
end

// deadlock detection logic
always @(posedge clk) begin
    if (reset) begin
        cycles_in_stage <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING || stage == STAGE_IDLE || stage == STAGE_GROW_BOUNDARY) begin
            cycles_in_stage <= 0;
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER || stage == STAGE_SPREAD_CLUSTER) begin
            cycles_in_stage <= cycles_in_stage + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        deadlock <= 0;
    end else begin
        if (new_round_start) begin
            deadlock <= 0;
        end else if (cycles_in_stage > DEADLOCK_THRESHOLD) begin
            deadlock <= 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        iteration_counter <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            iteration_counter <= 0;
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER && delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY && !has_messages_flying_both_sides) begin
            iteration_counter <= iteration_counter + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        cycle_counter <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            cycle_counter <= 1;
        end else if (!result_valid) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
end

reg [2:0] result_data_frame;
reg [PU_COUNT-1:0] net_is_touching_boundaries;
reg [PU_COUNT-1:0] net_is_odd_cardinalities;
reg [ADDRESS_WIDTH*PU_COUNT-1:0] net_roots;
assign net_roots_out = net_roots;
integer i;

always @(posedge clk) begin
    if (reset) begin
        stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
        result_data_frame <= 0;
        net_is_touching_boundaries <= 0;
        net_is_odd_cardinalities <= 0;
        net_roots <= {ADDRESS_WIDTH*PU_COUNT-1{1'b0}};

    end else begin
        case (stage)
            STAGE_IDLE: begin
                if (new_round_start) begin
                    stage <= STAGE_MEASUREMENT_LOADING;
                    delay_counter <= 0;
                    result_valid <= 0;
                end else begin
                    if (done_from_calculator == 1'b1) begin
                        result_valid <= 1'b1;
                    end
                end
                go_to_result_calculator <= 0;
            end
            STAGE_SPREAD_CLUSTER: begin
                if (delay_counter >= SPREAD_CLUSTER_DELAY) begin
                    if (!has_messages_flying_both_sides) begin
                        stage <= STAGE_SYNC_IS_ODD_CLUSTER;
                        delay_counter <= 0;
                    end else if (cycles_in_stage > DEADLOCK_THRESHOLD)  begin
                        stage <= STAGE_IDLE;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end
            STAGE_GROW_BOUNDARY: begin
                if (delay_counter >= BOUNDARY_GROW_DELAY) begin
                    stage <= STAGE_SPREAD_CLUSTER;
                    delay_counter <= 0;
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end
            STAGE_SYNC_IS_ODD_CLUSTER: begin
                if (delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY) begin
                    if (!has_messages_flying_both_sides) begin
                        if (has_odd_clusters_both_sides) begin
                            stage <= STAGE_GROW_BOUNDARY;
                            delay_counter <= 0;
                        end else begin
                            stage <= STAGE_RESULT_CALCULATING;
                            delay_counter <= 0;
                           sc_fifo_in_ready_internal <= 1'b1;
                        end
                    end else if (cycles_in_stage > DEADLOCK_THRESHOLD)  begin
                        stage <= STAGE_IDLE;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end
            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                stage <= STAGE_SPREAD_CLUSTER;
                delay_counter <= 0;
                result_valid <= 0; // for safety
            end
            STAGE_RESULT_CALCULATING: begin     
                for(i =0; i < CODE_DISTANCE; i = i + 1) begin
                    net_roots[(RIGHT_BLOCK+LEFT_BLOCK)*ADDRESS_WIDTH*result_data_frame +: LEFT_BLOCK*ADDRESS_WIDTH] <=  roots[(RIGHT_BLOCK+LEFT_BLOCK)*ADDRESS_WIDTH +: LEFT_BLOCK*ADDRESS_WIDTH];
                    net_is_odd_cardinalities[(RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:LEFT_BLOCK] <= is_odd_cardinalities[(RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:LEFT_BLOCK];
                    net_is_touching_boundaries[(RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:LEFT_BLOCK] <= is_touching_boundaries[(RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:LEFT_BLOCK];

                end    
                if (sc_fifo_in_data_internal[2:0] == 32'd4 && sc_fifo_in_data_internal[MASTER_FIFO_WIDTH - 1 : 3] == 32'd0 && !sc_fifo_in_empty_internal) begin
                    stage <= STAGE_IDLE;
                    go_to_result_calculator <= 1;
                    result_valid <= 0; // for safety
                    sc_fifo_in_ready_internal <= 1'b0;
                end else if(!sc_fifo_in_empty_internal) begin
                    result_data_frame <= (result_data_frame+1) % (2*CODE_DISTANCE);
                    if(result_data_frame%2 == 0) begin
                        if(result_data_frame == 0) begin
                            for(i = 0; i < 3; i = i + 1) begin
                                net_is_odd_cardinalities[(LEFT_BLOCK+RIGHT_BLOCK)*i+:LEFT_BLOCK] <= is_odd_cardinalities[(LEFT_BLOCK+RIGHT_BLOCK)*i+:LEFT_BLOCK];
                                net_is_touching_boundaries[(LEFT_BLOCK+RIGHT_BLOCK)*i+:LEFT_BLOCK] <= is_touching_boundaries[(LEFT_BLOCK+RIGHT_BLOCK)*i+:LEFT_BLOCK];
                                net_roots[(LEFT_BLOCK+RIGHT_BLOCK)*ADDRESS_WIDTH*i+:LEFT_BLOCK*ADDRESS_WIDTH] <= roots[(LEFT_BLOCK+RIGHT_BLOCK)*ADDRESS_WIDTH*i+:LEFT_BLOCK*ADDRESS_WIDTH];
                            end
                        end
                        net_roots[LEFT_BLOCK*ADDRESS_WIDTH + (RIGHT_BLOCK+LEFT_BLOCK)*ADDRESS_WIDTH*result_data_frame +: RIGHT_BLOCK*ADDRESS_WIDTH] <= sc_fifo_out_data_internal[ADDRESS_WIDTH-1:0];
                        net_is_odd_cardinalities[LEFT_BLOCK + (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1] <= sc_fifo_out_data_internal[ADDRESS_WIDTH:ADDRESS_WIDTH];
                        net_is_touching_boundaries[LEFT_BLOCK + (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1] <= sc_fifo_out_data_internal[ADDRESS_WIDTH+1:ADDRESS_WIDTH+1];
                    end else begin
                        net_roots[(LEFT_BLOCK+1)*ADDRESS_WIDTH + (RIGHT_BLOCK+LEFT_BLOCK)*ADDRESS_WIDTH*result_data_frame +: RIGHT_BLOCK*ADDRESS_WIDTH] <= sc_fifo_out_data_internal[ADDRESS_WIDTH-1:0] ;
                        net_is_odd_cardinalities[(LEFT_BLOCK + 1) + (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1] <= sc_fifo_out_data_internal[ADDRESS_WIDTH+:1];
                        net_is_touching_boundaries[(LEFT_BLOCK + 1)+ (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1] <= sc_fifo_out_data_internal[ADDRESS_WIDTH+1+:1];
                    end
                end
//                if (sc_fifo_in_data_internal[2:0] == 32'd4 && sc_fifo_in_data_internal[MASTER_FIFO_WIDTH - 1 : 3] == 32'd0 && !sc_fifo_in_empty_internal) begin
//                    stage <= STAGE_IDLE;
//                    go_to_result_calculator <= 1;
//                    result_valid <= 0; // for safety
//                    sc_fifo_in_ready_internal <= 1'b0;
//                end else if(!sc_fifo_in_empty_internal) begin
//                    result_data_frame <= (result_data_frame+1)%5;
//                    if(result_data_frame == 0) begin
//                        for(i = 0; i < 3; i = i + 1) begin
//                            net_is_odd_cardinalities[6*i+:4] <= is_odd_cardinalities[4*i+:4];
//                            net_is_touching_boundaries[6*i+:4] <= is_touching_boundaries[4*i+:4];
//                            net_roots[6*ADDRESS_WIDTH*i+:4*ADDRESS_WIDTH] <= roots[6*ADDRESS_WIDTH*i+:4*ADDRESS_WIDTH];
//                        end
//                        for(i = 0; i < 3; i = i + 1) begin
//                            net_is_odd_cardinalities[3+5*i+:2] <= sc_fifo_in_data_internal[2*i+:2];
//                        end
//                    end else if(result_data_frame == 1 )begin
//                        for(i = 0; i < 3; i = i + 1) begin
//                            net_is_touching_boundaries[3+5*i+:2] <= sc_fifo_in_data_internal[2*i+:2];
//                        end
//                    end else begin
//                        net_roots[ADDRESS_WIDTH*4 + 6*(result_data_frame-2)*ADDRESS_WIDTH+:2*ADDRESS_WIDTH] <= sc_fifo_in_data_internal[2*ADDRESS_WIDTH:0];
//                    end
//                end
            end
        endcase
    end
end

always @(*) begin
    
    // STAGE_MEASUREMENT_LOADING: 001
    // STAGE_SYNC_IS_ODD_CLUSTER 
    // if (reset) begin
    //     stage <= STAGE_IDLE;
    //     delay_counter <= 0;
    //     result_valid <= 0;
    // end else begin
    sc_fifo_out_data_internal = {MASTER_FIFO_WIDTH{1'b0}};
    sc_fifo_out_valid_internal = 1'b0;
    sc_fifo_in_ready_internal = 1'b0;
        case (stage)
            STAGE_IDLE: begin
                if (new_round_start) begin
                    // stage <= STAGE_MEASUREMENT_LOADING;
                    // delay_counter <= 0;
                    // result_valid <= 0;
                    sc_fifo_out_data_internal[2:0] = 3'b1;
                    sc_fifo_out_valid_internal = 1'b1;
                end else begin
                    // if (done_from_calculator == 1'b1) begin
                    //     result_valid <= 1'b1;
                    // end
                end
                // go_to_result_calculator <= 0;
            end
            STAGE_SPREAD_CLUSTER: begin
                if (delay_counter >= SPREAD_CLUSTER_DELAY) begin
                    if (!has_messages_flying_both_sides) begin
                        // stage <= STAGE_SYNC_IS_ODD_CLUSTER;
                        // delay_counter <= 0;
                        sc_fifo_out_data_internal[2:0] = 3'b1;
                        sc_fifo_out_valid_internal = 1'b1;
                        sc_fifo_in_ready_internal = 1'b1;
                    end else if (cycles_in_stage > DEADLOCK_THRESHOLD)  begin
                        // stage <= STAGE_IDLE;
                        sc_fifo_out_data_internal[2:0] = 3'b10;
                        sc_fifo_out_valid_internal = 1'b1;
                        sc_fifo_in_ready_internal = 1'b1;
                    end
                end else begin
                    // delay_counter <= delay_counter + 1;
                end
            end
            STAGE_GROW_BOUNDARY: begin
                if (delay_counter >= BOUNDARY_GROW_DELAY) begin
                    // stage <= STAGE_SPREAD_CLUSTER;
                    // delay_counter <= 0;
                    sc_fifo_out_data_internal[2:0] = 3'b1;
                    sc_fifo_out_valid_internal = 1'b1;
                end else begin
                    // delay_counter <= delay_counter + 1;
                end
            end
            STAGE_SYNC_IS_ODD_CLUSTER: begin
                if (delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY) begin
                    if (!has_messages_flying_both_sides) begin
                        if (has_odd_clusters_both_sides) begin
                            // stage <= STAGE_GROW_BOUNDARY;
                            // delay_counter <= 0;
                            sc_fifo_out_data_internal[2:0] = 3'b1;
                            sc_fifo_out_valid_internal = 1'b1;
                            //sc_fifo_in_ready_internal = 1'b1;
                        end else begin
                            sc_fifo_out_data_internal[2:0] = 3'b10;
                            sc_fifo_out_valid_internal = 1'b1;
                            //sc_fifo_in_ready_internal = 1'b1;
                            // stage <= STAGE_RESULT_CALCULATING;
                            // delay_counter <= 0;
                        end
                    end else if (cycles_in_stage > DEADLOCK_THRESHOLD)  begin
                        // stage <= STAGE_IDLE;
                        sc_fifo_out_data_internal[2:0] = 3'b11;
                        sc_fifo_out_valid_internal = 1'b1;
                        sc_fifo_in_ready_internal = 1'b1;
                    end
                end else begin
                    // delay_counter <= delay_counter + 1;
                end
            end
            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                // stage <= STAGE_SPREAD_CLUSTER;
                // delay_counter <= 0;
                // result_valid <= 0; // for safety
            end
            STAGE_RESULT_CALCULATING: begin
                sc_fifo_in_ready_internal = 1'b1;
                // stage <= STAGE_IDLE;
                // go_to_result_calculator <= 1;
                // result_valid <= 0; // for safety
            end
        endcase
    // end
end

get_boundry_cardinality #(
    .CODE_DISTANCE(CODE_DISTANCE)
) result_calculator(
    .clk(clk),
    .reset(reset),
    .is_touching_boundaries(net_is_touching_boundaries),
    .is_odd_cardinalities(net_is_odd_cardinalities),
    .roots(net_roots),
    .final_cardinality(final_cardinality),
    .go(go_to_result_calculator),
    .done(done_from_calculator)
);

// always @(posedge clk) begin
//     if (reset) begin
//         result_valid <= 0;
//     end else begin
//         if (new_round_start) begin
//             result_valid <= 0;
//         end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER && delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY && !has_message_flying && !has_odd_clusters) begin
//             result_valid <= 1;
//         end else if(stage == STAGE_MEASUREMENT_LOADING) begin
//             result_valid <= 0;
//         end
//     end
// end

endmodule


module decoder_stage_controller_right #(
    parameter CODE_DISTANCE = 3,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter BOUNDARY_GROW_DELAY = 10,  // clock cycles
    parameter SPREAD_CLUSTER_DELAY = 10,  // clock cycles
    parameter SYNC_IS_ODD_CLUSTER_DELAY = 10,  // clock cycles
    parameter PER_DIMENSION_WIDTH = $clog2(CODE_DISTANCE),
    parameter ADDRESS_WIDTH = PER_DIMENSION_WIDTH * 3,
    parameter PU_COUNT = CODE_DISTANCE*CODE_DISTANCE*(CODE_DISTANCE-1),
    parameter UNION_MESSAGE_WIDTH = 2 * ADDRESS_WIDTH,  // [old_root, updated_root]
    parameter MASTER_FIFO_WIDTH = UNION_MESSAGE_WIDTH + 1 + 1,
    parameter LEFT_BLOCK = ((CODE_DISTANCE**2)-1)/2,
    parameter RIGHT_BLOCK = ((CODE_DISTANCE-1)**2)/2

) (
    input clk,
    input reset,
    input new_round_start,
    input has_message_flying,
    input has_odd_clusters,
    input [PU_COUNT-1:0] is_touching_boundaries,
    input [PU_COUNT-1:0] is_odd_cardinalities,
    input [(ADDRESS_WIDTH * PU_COUNT)-1:0] roots,
    output reg [STAGE_WIDTH-1:0] stage,
    output reg result_valid,
    output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter,
    output reg [31:0] cycle_counter,
    output reg deadlock,
    output final_cardinality,
    output [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data,
    output sc_fifo_out_valid,
    input sc_fifo_out_ready,
    input [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data,
    input sc_fifo_in_valid,
    output sc_fifo_in_ready,
    output has_message_flying_otherside, // Temporary solution 
    output has_odd_clusters_otherside
);

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
`define MAX3(a, b, c) (((a) > `MAX((b), (c))) ? (a) : `MAX((b), (c)))
localparam MAXIMUM_DELAY = `MAX3(BOUNDARY_GROW_DELAY, SPREAD_CLUSTER_DELAY, SYNC_IS_ODD_CLUSTER_DELAY);
localparam COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 1);
reg [COUNTER_WIDTH-1:0] delay_counter;
reg [31:0] cycles_in_stage;

localparam DEADLOCK_THRESHOLD = CODE_DISTANCE*CODE_DISTANCE*CODE_DISTANCE*10;

reg go_to_result_calculator;
wire done_from_calculator;

reg has_messages_flying_both_sides;
reg has_odd_clusters_both_sides;

reg [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_out_data_internal;
reg sc_fifo_out_valid_internal;
wire sc_fifo_out_full_internal;

wire [MASTER_FIFO_WIDTH - 1 :0] sc_fifo_in_data_internal;
wire sc_fifo_in_empty_internal;
reg sc_fifo_in_ready_internal;

wire sc_fifo_out_empty;
assign sc_fifo_out_valid = !sc_fifo_out_empty;

fifo_fwft #(.DEPTH(16), .WIDTH(MASTER_FIFO_WIDTH)) out_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(sc_fifo_out_valid_internal),
    .din(sc_fifo_out_data_internal),
    .full(sc_fifo_out_full_internal),
    .empty(sc_fifo_out_empty),
    .dout(sc_fifo_out_data),
    .rd_en(sc_fifo_out_ready)
);

wire sc_fifo_in_full;
assign sc_fifo_in_ready = !sc_fifo_in_full;

fifo_fwft #(.DEPTH(16), .WIDTH(MASTER_FIFO_WIDTH)) in_fifo 
    (
    .clk(clk),
    .srst(reset),
    .wr_en(sc_fifo_in_valid),
    .din(sc_fifo_in_data),
    .full(sc_fifo_in_full),
    .empty(sc_fifo_in_empty_internal),
    .dout(sc_fifo_in_data_internal),
    .rd_en(sc_fifo_in_ready_internal)
);

// always@(*) begin
//     if (sc_fifo_in_data_internal[0] == 1'b1 && !sc_fifo_in_empty_internal) begin
//         has_messages_flying_both_sides == 1'b1;
//     end
// end

// always@(*) begin
//     if (sc_fifo_in_data_internal[1] == 1'b1 && !sc_fifo_in_empty_internal) begin
//         has_odd_clusters_both_sides == 1'b1;
//     end
// end

assign has_message_flying_otherside = has_message_flying;
assign has_odd_clusters_otherside = has_odd_clusters;

// deadlock detection logic
always @(posedge clk) begin
    if (reset) begin
        cycles_in_stage <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING || stage == STAGE_IDLE || stage == STAGE_GROW_BOUNDARY) begin
            cycles_in_stage <= 0;
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER || stage == STAGE_SPREAD_CLUSTER) begin
            cycles_in_stage <= cycles_in_stage + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        deadlock <= 0;
    end else begin
        if (new_round_start) begin
            deadlock <= 0;
        end else if (cycles_in_stage > DEADLOCK_THRESHOLD) begin
            deadlock <= 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        iteration_counter <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            iteration_counter <= 0;
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER && delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY && !has_messages_flying_both_sides) begin
            iteration_counter <= iteration_counter + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        cycle_counter <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            cycle_counter <= 1;
        end else if (!result_valid) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
end

reg [$clog2(ADDRESS_WIDTH+2) : 0] result_data_frame;

always @(posedge clk) begin
    if (reset) begin
        stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
        result_data_frame <= 0;
    end else begin
        case (stage)
            STAGE_IDLE: begin
                if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b1) begin
                    stage <= STAGE_MEASUREMENT_LOADING;
                    sc_fifo_in_ready_internal <= 1'b1;
                end
            end
            STAGE_SPREAD_CLUSTER:   begin
                if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b1) begin
                    stage <= STAGE_SYNC_IS_ODD_CLUSTER;
                    sc_fifo_in_ready_internal <= 1'b1;
                end else if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b10) begin
                    stage <= STAGE_IDLE;
                    sc_fifo_in_ready_internal <= 1'b1;
                end
            end
            STAGE_GROW_BOUNDARY: begin
                if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b1) begin
                    stage <= STAGE_SPREAD_CLUSTER;
                    sc_fifo_in_ready_internal <= 1'b1;
                end
            end
            STAGE_SYNC_IS_ODD_CLUSTER: begin
                if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b1) begin
                    stage <= STAGE_GROW_BOUNDARY;
                    sc_fifo_in_ready_internal <= 1'b1;
                end else if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b10) begin
                    stage <= STAGE_RESULT_CALCULATING;
                    sc_fifo_in_ready_internal <= 1'b1;
                end else if(sc_fifo_in_empty_internal == 0 && sc_fifo_in_data_internal[2:0] == 3'b11) begin
                    stage <= STAGE_IDLE;
                    sc_fifo_in_ready_internal <= 1'b1;
                end
            end
        STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                stage <= STAGE_SPREAD_CLUSTER;
                delay_counter <= 0;
                result_valid <= 0; // for safety
            end
            STAGE_RESULT_CALCULATING: begin
                if(sc_fifo_out_full_internal != 1'b1) begin
                    sc_fifo_out_valid_internal <= 1'b1;
                    // Make sure there's enough space in result_data_frame
                    result_data_frame <= (result_data_frame+1) % (CODE_DISTANCE*2 + 1);
                    if(result_data_frame == CODE_DISTANCE*2) begin
                        sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:3] <= 32'b0;
                        sc_fifo_out_data_internal[2:0] <= 32'd4;
                        stage <= STAGE_IDLE;
                    end else begin
                        if(result_data_frame%2 == 0) begin
                            sc_fifo_out_data_internal[ADDRESS_WIDTH-1:0] <= roots[LEFT_BLOCK*ADDRESS_WIDTH + (RIGHT_BLOCK+LEFT_BLOCK)*ADDRESS_WIDTH*result_data_frame +: RIGHT_BLOCK*ADDRESS_WIDTH];
                            sc_fifo_out_data_internal[ADDRESS_WIDTH:ADDRESS_WIDTH] <= is_odd_cardinalities[LEFT_BLOCK + (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1];
                            sc_fifo_out_data_internal[ADDRESS_WIDTH+1:ADDRESS_WIDTH+1] <= is_touching_boundaries[LEFT_BLOCK + (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1];
                            sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:ADDRESS_WIDTH+2] <= 32'b0;
                        end else begin
                            sc_fifo_out_data_internal[ADDRESS_WIDTH-1:0] <= roots[(LEFT_BLOCK+1)*ADDRESS_WIDTH + (RIGHT_BLOCK+LEFT_BLOCK)*ADDRESS_WIDTH*result_data_frame +: RIGHT_BLOCK*ADDRESS_WIDTH];
                            sc_fifo_out_data_internal[ADDRESS_WIDTH+:1] <= is_odd_cardinalities[(LEFT_BLOCK + 1) + (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1];
                            sc_fifo_out_data_internal[ADDRESS_WIDTH+1+:1] <= is_touching_boundaries[(LEFT_BLOCK + 1)+ (RIGHT_BLOCK+LEFT_BLOCK)*result_data_frame+:1];
                            sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:ADDRESS_WIDTH+2] <= 32'b0;
                        end
                    end
////                    sc_fifo_out_data_internal <= {MASTER_FIFO_WIDTH{1'b0}};
//                    result_data_frame <= (result_data_frame+1) % 6;
//                    if( result_data_frame == 0 ) begin
//                        sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:6] <= 32'b0;
//                        sc_fifo_out_data_internal[5:0] <=  is_odd_cardinalities;
//                    end else if( result_data_frame == 1) begin
//                        sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:6] <= 32'b0;
//                        sc_fifo_out_data_internal[5:0] <=  is_touching_boundaries;
//                    end else if( result_data_frame < 5) begin
//                        sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:ADDRESS_WIDTH*2] <= 32'b0;
//                        sc_fifo_out_data_internal[ADDRESS_WIDTH*2-1:0] <= roots[ADDRESS_WIDTH*4+(result_data_frame-2)*ADDRESS_WIDTH*6+:ADDRESS_WIDTH*2-1];
//                    end else begin
//                        sc_fifo_out_data_internal[MASTER_FIFO_WIDTH-1:3] <= 32'b0;
//                        sc_fifo_out_data_internal[2:0] <= 32'd4;
//                        stage <= STAGE_IDLE;
//                    end
//                end else begin
//                    sc_fifo_out_valid_internal <= 1'b0;
//                end
//                result_valid <= 0; // for safety
//             end
            result_valid <= 0;
            end
            end
        endcase
    end
end

endmodule
