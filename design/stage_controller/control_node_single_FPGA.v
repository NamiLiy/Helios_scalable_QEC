module unified_controller #(
    parameter GRID_WIDTH_X = 4,
    parameter GRID_WIDTH_Z = 1,
    parameter GRID_WIDTH_U = 3,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter MAXIMUM_DELAY = 3,
    parameter NUM_CONTEXTS = 2,
    parameter CTRL_FIFO_WIDTH = 64,
    parameter NUM_FPGAS = 5,
    parameter ROUTER_DELAY_COUNTER = 18,
    parameter ACTUAL_D = 3,
    parameter FPGA_ID = 1
) (
    clk,
    reset,

    input_data,
    input_valid,
    input_ready,

    output_data,
    output_valid,
    output_ready,

    input_ctrl_rx_data,
    input_ctrl_rx_valid,
    input_ctrl_rx_ready,

    output_ctrl_tx_data,
    output_ctrl_tx_valid,
    output_ctrl_tx_ready,

    busy_PE, 
    odd_clusters_PE,
    measurements,
    correction,
    global_stage,

    router_busy,
    border_continous,
    artificial_boundary,
    fusion_boundary,
    reset_all_edges,

    east_border,
    west_border,
    north_border,
    south_border,

    update_artifical_border,

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


);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

localparam X_BIT_WIDTH = $clog2(GRID_WIDTH_X);
localparam Z_BIT_WIDTH = $clog2(GRID_WIDTH_Z);
localparam U_BIT_WIDTH = $clog2(GRID_WIDTH_U);
localparam FPGA_BIT_WIDTH = $clog2(NUM_FPGAS);
localparam ADDRESS_WIDTH = X_BIT_WIDTH + Z_BIT_WIDTH + U_BIT_WIDTH + FPGA_BIT_WIDTH;

// localparam BYTES_PER_ROUND = ((GRID_WIDTH_X * GRID_WIDTH_Z  + 7) >> 3);
// localparam ALIGNED_PU_PER_ROUND = (BYTES_PER_ROUND << 3);

localparam PU_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam PHYSICAL_GRID_WIDTH_U = (GRID_WIDTH_U % NUM_CONTEXTS == 0) ? 
                                   (GRID_WIDTH_U / NUM_CONTEXTS) : 
                                   (GRID_WIDTH_U / NUM_CONTEXTS + 1);

localparam PU_COUNT = PU_COUNT_PER_ROUND * PHYSICAL_GRID_WIDTH_U;

localparam NS_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z;
localparam EW_ERROR_COUNT_PER_ROUND = (GRID_WIDTH_X-1) * GRID_WIDTH_Z + 1;
localparam UD_ERROR_COUNT_PER_ROUND = GRID_WIDTH_X * GRID_WIDTH_Z;
localparam CORRECTION_COUNT_PER_ROUND = NS_ERROR_COUNT_PER_ROUND + EW_ERROR_COUNT_PER_ROUND + UD_ERROR_COUNT_PER_ROUND;

localparam BORDER_TOP_MSB = PU_COUNT - 1;
localparam BORDER_TOP_LSB = PU_COUNT_PER_ROUND * (PHYSICAL_GRID_WIDTH_U- 1);
localparam BORDER_BOT_MSB = PU_COUNT_PER_ROUND - 1;
localparam BORDER_BOT_LSB = 0;

//localparam CTRL_MSG_MSB = 47;

localparam CONTEXT_COUNTER_WIDTH = $clog2(NUM_CONTEXTS + 1);

localparam logical_qubits_in_j_dim = (GRID_WIDTH_Z + (ACTUAL_D-1)/2 - 1) / ((ACTUAL_D-1)/2); // round up to the nearest integer
localparam logical_qubits_in_i_dim = (GRID_WIDTH_X + ACTUAL_D+1 - 1) / (ACTUAL_D+1); // round up to the nearest integer
localparam borders_in_j_dim = (logical_qubits_in_j_dim + 1)*logical_qubits_in_i_dim;
localparam borders_in_i_dim = (logical_qubits_in_i_dim + 1)*logical_qubits_in_j_dim;
localparam total_borders = borders_in_i_dim + borders_in_j_dim;
// What happens here is we pad it to at least the twice of the data field width so that parameters are not needed to avoid shift when the all the border information fits to one message
localparam total_borders_padded = ((borders_in_i_dim + borders_in_j_dim) > (48*2) ? (borders_in_i_dim + borders_in_j_dim) : (48*2));

localparam CORRECTION_COUNT_PER_ROUND_PADDED = (CORRECTION_COUNT_PER_ROUND + 7) & (~3'b111);
localparam CORRECTION_COUNT_PER_ROUND_PADDED_BYTES = CORRECTION_COUNT_PER_ROUND_PADDED >> 3;

localparam EW_BORDER_WIDTH = GRID_WIDTH_X / 2;
localparam NS_BORDER_WIDTH = GRID_WIDTH_Z;

input clk;
input reset;
output reg [STAGE_WIDTH-1:0] global_stage;
reg [STAGE_WIDTH-1:0] global_stage_previous;
reg [STAGE_WIDTH-1:0] global_stage_d;
reg [STAGE_WIDTH-1:0] global_stage_saved;
input [PU_COUNT - 1 : 0]  odd_clusters_PE;
input [PU_COUNT - 1 : 0]  busy_PE;
output reg [PU_COUNT_PER_ROUND-1:0] measurements;
input [CORRECTION_COUNT_PER_ROUND-1:0] correction;

input [31 : 0] input_data;
input input_valid;
output reg input_ready;

output reg [31 : 0] output_data;
output reg output_valid;
input output_ready;

input [CTRL_FIFO_WIDTH-1:0] input_ctrl_rx_data;
input input_ctrl_rx_valid;
output reg input_ctrl_rx_ready;

output reg [CTRL_FIFO_WIDTH-1:0] output_ctrl_tx_data;
output reg output_ctrl_tx_valid;
input output_ctrl_tx_ready;

input router_busy;
output reg [1:0] border_continous;
output reg artificial_boundary;
output [total_borders - 1 : 0] fusion_boundary;
output reg reset_all_edges;
 

// These ports are to the decoding graph
input [EW_BORDER_WIDTH-1:0] east_border;
output reg [EW_BORDER_WIDTH-1:0] west_border;
output reg [NS_BORDER_WIDTH-1:0] north_border;
input [NS_BORDER_WIDTH-1:0] south_border;
output reg update_artifical_border;

output reg [63 : 0] grid_1_out_data;
output reg grid_1_out_valid;
input grid_1_out_ready;

input [63 : 0] grid_1_in_data;
input grid_1_in_valid;
output reg grid_1_in_ready;

output reg [63 : 0] grid_2_out_data;
output reg grid_2_out_valid;
input grid_2_out_ready;

input [63 : 0] grid_2_in_data;
input grid_2_in_valid;
output reg grid_2_in_ready;

reg [total_borders_padded - 1 : 0] fusion_boundary_reg;
assign fusion_boundary = fusion_boundary_reg[total_borders-1:0];

reg result_valid;
reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
reg [15:0] cycle_counter;
reg [31:0] lower_half_counter;

reg busy;
reg odd_clusters;
reg border_busy;
reg [CONTEXT_COUNTER_WIDTH-1:0] current_context;

reg [PU_COUNT_PER_ROUND-1:0] measurement_internal;

reg [1:0] measurement_fusion_stage; // 0 : First block, 1 : Second block, 3 : Merged block

always@(posedge clk) begin
    busy <= |busy_PE;
    odd_clusters <= |odd_clusters_PE;
    border_busy <= |(busy_PE[BORDER_TOP_MSB : BORDER_TOP_LSB]) || |(busy_PE[BORDER_BOT_MSB : BORDER_BOT_LSB]);
end

reg[$clog2(ROUTER_DELAY_COUNTER+1)-1 : 0] router_busy_reg;



always@(posedge clk) begin
    if (reset) begin
        router_busy_reg <= 0;
    end else begin
        if(global_stage == STAGE_MERGE) begin
            if(router_busy) begin
                router_busy_reg <= ROUTER_DELAY_COUNTER;
            end else if( router_busy_reg > 0) begin
                router_busy_reg <= router_busy_reg - 1;
            end
        end else begin
            router_busy_reg <= 0;
        end
    end
end

// global_stage_d delayed logic
always @(posedge clk) begin
    if (reset) begin
        global_stage_d <= STAGE_IDLE;
    end else begin
        global_stage_d <= global_stage;
    end
end

reg cycle_counter_on;
reg cycle_counter_reset;

always @(posedge clk) begin
    if (reset) begin
        cycle_counter <= 0;
    end else begin
        if(cycle_counter_reset) begin
            cycle_counter <= 1; // By setting counter to 1 in a given cycle, we can ensure that the cycle counter always display the current cycle count instead of cycles elapsed. 
        end else if(cycle_counter_on) begin
            cycle_counter <= cycle_counter + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        global_stage_previous <= STAGE_IDLE;
    end else begin
        global_stage_previous <= global_stage;
    end
end

always@(*) begin
    if(global_stage == STAGE_GROW || global_stage == STAGE_MERGE || global_stage == STAGE_PEELING || global_stage == STAGE_RESET_ROOTS) begin
        cycle_counter_on = 1;
    end else if(global_stage == STAGE_WRITE_TO_MEM) begin
        if(global_stage_saved == STAGE_GROW || global_stage_saved == STAGE_MERGE || global_stage_saved == STAGE_PEELING || global_stage_saved == STAGE_RESET_ROOTS) begin
            cycle_counter_on = 1;
        end else begin
            cycle_counter_on = 0;
        end
    end else begin
        cycle_counter_on = 0;
    end
end

always@(*) begin
    // Laksheen
    if(global_stage == STAGE_IDLE && input_ctrl_rx_valid && input_ctrl_rx_ready && input_ctrl_rx_data [MSG_HEADER_MSB : MSG_HEADER_LSB] == HEADER_DECODE_BLOCK && input_ctrl_rx_data [0] == 1'b1) begin // The last 0 is to ensure only to set it in the first stage
        cycle_counter_reset = 1;
    end else begin
        cycle_counter_reset = 0;
    end
end

always @(posedge clk) begin
    if (reset) begin
        iteration_counter <= 0;
    end else begin
        if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            iteration_counter <= 0;
        end else if (global_stage == STAGE_GROW && global_stage_previous != STAGE_GROW) begin
            iteration_counter <= iteration_counter + 1;
        end
    end
end

always@(*) begin
    // Laksheen
    // if(measurement_fusion_stage == 2'b10) begin
    if(measurement_fusion_stage == 2'b01) begin
        artificial_boundary = 0;
    end else begin
        artificial_boundary = 1;
    end
end

localparam DELAY_COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 2);
reg [DELAY_COUNTER_WIDTH-1:0] delay_counter;

reg [CORRECTION_COUNT_PER_ROUND - 1 : 0] output_fifo_data;
reg output_fifo_valid;
wire output_fifo_ready;

wire [CORRECTION_COUNT_PER_ROUND - 1 : 0] output_fifo_data_d;
wire output_fifo_valid_d;
reg output_fifo_ready_d;

reg [NUM_CONTEXTS -1 : 0] unsynced_merge;
reg [NUM_CONTEXTS -1 : 0] odd_clusters_in_context;

reg peel_and_finish;
reg report_latency;


reg measurement_fusion_on;

reg fusion_on;
always@(*) begin
    if (reset) begin
        fusion_on = 0;
    end else begin
        if(NUM_CONTEXTS > 1 && (measurement_fusion_on==0 || (measurement_fusion_on == 1'b1 && measurement_fusion_stage == 2'b10))) begin
            fusion_on = 1;
        end else begin
            fusion_on = 0;
        end
    end
end


reg growing_incomplete; //Todo : In an optimized version use this. For the current version I'm not using it.

reg multi_fpga_mode;

reg [U_BIT_WIDTH:0] message_measurement_round; // we have extra bit since wee need the last round to indicate completion (-1 removed)
reg [U_BIT_WIDTH:0] current_measurement_round; // Laksheen : maybe we need to divide this in half when loading with fusion
reg [PU_COUNT_PER_ROUND-1 :0] defect_pu_address;


always@(*) begin
    input_ready = 0;
    if (reset) begin
        input_ready = 0;
    end else begin 
        if(global_stage == STAGE_MEASUREMENT_PREPARING) begin
            if(input_valid && current_measurement_round == message_measurement_round) begin
                input_ready = 1;
            end
        end else if(global_stage == STAGE_MEASUREMENT_LOADING) begin
            if(current_measurement_round == GRID_WIDTH_U-1) begin //Pull the 32FFs from the external buffer
                input_ready = 1;
            end
        end
    end
end

always@(*) begin
    message_measurement_round = 32'b0;
    if (input_data == 32'hffffffff) begin
        message_measurement_round  = GRID_WIDTH_U; //Laksheen : this should be half when measurement fusion is included
    end else begin
        message_measurement_round  = input_data[U_BIT_WIDTH + X_BIT_WIDTH + Z_BIT_WIDTH - 1 : X_BIT_WIDTH + Z_BIT_WIDTH];
    end
    defect_pu_address = input_data[X_BIT_WIDTH + Z_BIT_WIDTH - 1 : Z_BIT_WIDTH]*GRID_WIDTH_Z + input_data[Z_BIT_WIDTH - 1 : 0];
end

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
        growing_incomplete <= 0;
        multi_fpga_mode <= 0;
        border_continous <= 2'b0;
        measurement_fusion_on <= 0;
        measurement_fusion_stage <= 0;
        current_measurement_round <= 0;
        peel_and_finish <= 0;
        report_latency <= 0;
        west_border <= 0;
        north_border <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (input_ctrl_rx_valid && input_ctrl_rx_ready) begin
                    if(input_ctrl_rx_data [MSG_HEADER_MSB : MSG_HEADER_LSB] == HEADER_INITIALIZE_DECODING) begin
                        global_stage <= STAGE_PARAMETERS_LOADING;
                        delay_counter <= 0;
                        result_valid <= 0;
                        multi_fpga_mode <= 0;
                        measurement_fusion_on <= 0;
                        current_context <= 0;
                        fusion_boundary_reg[total_borders_padded-1 : 0] <= {total_borders_padded{1'b0}}; 
                        // if(input_ctrl_rx_data[0] == 1'b1) begin
                        //     if(FPGA_ID != 1) begin
                        //         border_continous[0] <= 1'b1;
                        //     end
                        //     if(FPGA_ID != NUM_FPGAS - 1) begin
                        //         border_continous[1] <= 1'b1;
                        //     end
                        // end
                    end else if(input_ctrl_rx_data [MSG_HEADER_MSB : MSG_HEADER_LSB] == HEADER_DECODE_BLOCK) begin
                        global_stage <= STAGE_MEASUREMENT_PREPARING;
                        measurement_fusion_stage <= 0;
                        current_context <= 0;
                        delay_counter <= 0;
                        result_valid <= 0;
                        current_measurement_round <= 0;
                        measurement_internal <= {PU_COUNT_PER_ROUND{1'b0}};
                        peel_and_finish <= input_ctrl_rx_data[0];
                        report_latency <= input_ctrl_rx_data[1];
                    end else if (input_ctrl_rx_data [MSG_HEADER_MSB : MSG_HEADER_LSB] == HEADER_SET_BOUNDARIES) begin
                        global_stage <= STAGE_IDLE;
                        delay_counter <= 0;
                        result_valid <= 0;
                        fusion_boundary_reg[47:0] <= input_ctrl_rx_data[47:0];
                        fusion_boundary_reg[total_borders_padded-1 : 48] <= fusion_boundary_reg[total_borders_padded-48-1 : 0];
                    end
                    // else if(input_ctrl_rx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == MOVE_TO_STAGE) begin
                    //     global_stage <= STAGE_GROW;
                    //     delay_counter <= 0;
                    //     result_valid <= 0;
                    // end
                end
                current_measurement_round <= 0;
            end

            STAGE_PARAMETERS_LOADING: begin // 6
                global_stage <= STAGE_IDLE;
                current_measurement_round <= 0;
            end

            STAGE_MEASUREMENT_PREPARING: begin // 7
                if (input_valid) begin
                    if(input_data == 32'hffffffff) begin
                        global_stage <= STAGE_MEASUREMENT_LOADING;
                    end else if(message_measurement_round != current_measurement_round) begin //Laksheen : this should be half when measurement fusion is included
                        global_stage <= STAGE_MEASUREMENT_LOADING;
                    end else begin
                        measurement_internal[defect_pu_address] <= 1'b1;
                    end
                end
                unsynced_merge <= 0;
                odd_clusters_in_context <= 0;
                delay_counter <= 0;
            end

            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle per measurement round as only from external buffer happens.
                if(current_measurement_round ==  GRID_WIDTH_U-1) begin //Now here we have to be careful whether it's physical_grid_width or simply_grid_width
                    if(!fusion_on) begin
                        if(FPGA_ID == 1) begin
                            global_stage <= STAGE_GROW;
                        end else begin
                            global_stage <= STAGE_LOAD_ARTIFICAL_DEFECTS;
                        end
                        current_measurement_round <= 0;
                    end else begin
                        global_stage <= STAGE_WRITE_TO_MEM;
                    end
                end else begin
                    current_measurement_round <= current_measurement_round + 1;
                    if(current_measurement_round ==  message_measurement_round-1) begin //So this means that the next round has some errors we need to load
                        global_stage <= STAGE_MEASUREMENT_PREPARING;
                    end
                end
                delay_counter <= 0;
                result_valid <= 0;
                measurement_internal <= {PU_COUNT_PER_ROUND{1'b0}};
            end

            STAGE_LOAD_ARTIFICAL_DEFECTS: begin
                if(FPGA_ID == 2) begin
                    if(grid_1_in_valid) begin
                        if(current_measurement_round ==  GRID_WIDTH_U-1) begin
                            global_stage <= STAGE_GROW;
                            current_measurement_round <= 0;
                        end else begin
                            current_measurement_round <= current_measurement_round + 1;
                        end
                        west_border <= grid_1_in_data[EW_BORDER_WIDTH-1:0];
                        update_artifical_border <= 1;
                    end else begin
                        update_artifical_border <= 0;
                    end
                end else if (FPGA_ID == 3) begin
                    if(grid_2_in_valid) begin
                        if(current_measurement_round ==  GRID_WIDTH_U-1) begin
                            global_stage <= STAGE_GROW;
                            current_measurement_round <= 0;
                        end else begin
                            current_measurement_round <= current_measurement_round + 1;
                        end
                        north_border <= grid_2_in_data[NS_BORDER_WIDTH-1:0];
                        update_artifical_border <= 1;
                    end else begin
                        update_artifical_border <= 0;
                    end
                end else begin
                    if(grid_1_in_valid && grid_2_in_valid) begin
                        if(current_measurement_round ==  GRID_WIDTH_U-1) begin
                            global_stage <= STAGE_GROW;
                            current_measurement_round <= 0;
                        end else begin
                            current_measurement_round <= current_measurement_round + 1;
                        end
                        west_border <= grid_1_in_data[EW_BORDER_WIDTH-1:0];
                        north_border <= grid_2_in_data[NS_BORDER_WIDTH-1:0];
                        update_artifical_border <= 1;
                    end else begin
                        update_artifical_border <= 0;
                    end
                end
            end

            STAGE_GROW: begin //2
                if(!fusion_on) begin
                    global_stage <= STAGE_MERGE;
                end else begin
                    global_stage <= STAGE_WRITE_TO_MEM;
                end
                global_stage_saved <= STAGE_GROW;
                delay_counter <= 0;
                current_measurement_round <= 0;
                growing_incomplete <= 1;
                update_artifical_border <= 0;
            end

            STAGE_MERGE: begin //3
                if (delay_counter >= MAXIMUM_DELAY) begin
                    //if(multi_fpga_mode == 1'b0) begin
                    if(!busy) begin
                        delay_counter <= 0;
                        if(NUM_CONTEXTS == 1) begin
                            if(|odd_clusters == 1'b0) begin // everybody is even
                                // Laksheen
                                if(peel_and_finish) begin
                                    // global_stage <= STAGE_PEELING;
                                    if(measurement_fusion_stage == 2'b00) begin
                                        global_stage <= STAGE_RESET_ROOTS;
                                    end else begin
                                        global_stage <= STAGE_PEELING;
                                    end
                                end
                            end else begin // somebody is odd
                                global_stage <= STAGE_GROW;
                            end
                        end else if(measurement_fusion_on && (measurement_fusion_stage == 2'b00 || measurement_fusion_stage == 2'b01)) begin
                            if(|odd_clusters == 1'b0) begin // everybody is even
                                global_stage <= STAGE_WRITE_TO_MEM;
                            end else begin // somebody is odd
                                global_stage <= STAGE_GROW;
                            end
                        end else begin
                            global_stage <= STAGE_WRITE_TO_MEM;
                        end
                        global_stage_saved <= STAGE_MERGE;
                        if(fusion_on) begin
                            odd_clusters_in_context[current_context] <= odd_clusters;
                        end  
                    end
                    if(border_busy) begin
                        if(fusion_on) begin
                            unsynced_merge[current_context] <= 1'b1;
                        end
                    end
                    //end 
                    // else begin
                    //     if (input_ctrl_rx_valid && input_ctrl_rx_ready && input_ctrl_rx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == MOVE_TO_STAGE) begin
                    //         if(input_ctrl_rx_data[0] == 1'b0) begin
                    //             global_stage <= STAGE_PEELING;
                    //         end else begin
                    //             global_stage <= STAGE_GROW;
                    //         end
                    //     end
                    // end
                end else begin
                    delay_counter <= delay_counter + 1;
                    unsynced_merge[current_context] <= 1'b0;
                end

            end           

            STAGE_PEELING: begin //4
                global_stage <= (NUM_CONTEXTS == 1 ? STAGE_RESULT_VALID : STAGE_WRITE_TO_MEM);
                global_stage_saved <= STAGE_PEELING;
            end

            STAGE_RESULT_VALID: begin //5
                current_measurement_round <= current_measurement_round + 1;
                if(current_measurement_round >= PHYSICAL_GRID_WIDTH_U - 1) begin
                    global_stage_saved <= STAGE_RESULT_VALID;
                    if(NUM_CONTEXTS == 1) begin
                        global_stage <= STAGE_IDLE;
                    end else begin
                        global_stage <= STAGE_WRITE_TO_MEM;
                    end
                    current_measurement_round <= 0;
                end
                delay_counter <= 0;
                result_valid <= 1;
            end

            STAGE_RESET_ROOTS: begin //8
                // Laksheen
                // global_stage <= STAGE_WRITE_TO_MEM;
                global_stage <= STAGE_MERGE;
                global_stage_saved <= STAGE_RESET_ROOTS;
                measurement_fusion_stage <= 2'b01;
            end

            STAGE_WRITE_TO_MEM: begin //1
                if(fusion_on) begin
                    if(current_context < NUM_CONTEXTS -1) begin
                        if(global_stage_saved == STAGE_MERGE) begin
                            // if(growing_incomplete == 1'b1) begin
                            //     global_stage <= STAGE_GROW;
                            // end else begin
                            //     global_stage <= STAGE_MERGE;
                            // end
                            global_stage <= STAGE_MERGE;
                        end else if(global_stage_saved == STAGE_MEASUREMENT_LOADING) begin
                            global_stage <= STAGE_MEASUREMENT_PREPARING;
                        end else if(global_stage_saved == STAGE_PEELING) begin
                            global_stage <= STAGE_PEELING;
                        end else if(global_stage_saved == STAGE_RESULT_VALID) begin
                            global_stage <= STAGE_RESULT_VALID;
                        end else if(global_stage_saved == STAGE_GROW) begin
                            global_stage <= STAGE_GROW;
                        end else if(global_stage_saved == STAGE_RESET_ROOTS) begin
                            global_stage <= STAGE_RESET_ROOTS;
                        end
                        current_context <= current_context + 1;
                    end else begin
                        current_context <= 0;
                        growing_incomplete <= 0;
                        if(global_stage_saved == STAGE_MERGE) begin
                            if(|unsynced_merge == 1'b0) begin // everybody is synced
                                if(|odd_clusters_in_context == 1'b0) begin // everybody is even
                                    global_stage <= STAGE_PEELING;
                                end else begin // somebody is odd
                                    global_stage <= STAGE_GROW;
                                end
                            end else begin
                                global_stage <= STAGE_MERGE;
                            end
                        end else if(global_stage_saved == STAGE_MEASUREMENT_LOADING) begin
                            global_stage <= STAGE_GROW;
                        end else if(global_stage_saved == STAGE_PEELING) begin
                            global_stage <= STAGE_RESULT_VALID;
                        end else if(global_stage_saved == STAGE_RESULT_VALID) begin
                            global_stage <= STAGE_IDLE;
                        end else if(global_stage_saved == STAGE_GROW) begin
                            global_stage <= STAGE_MERGE;
                        end else if(global_stage_saved == STAGE_RESET_ROOTS) begin
                            global_stage <= STAGE_MERGE;
                        end
                    end
                // end else begin
                    delay_counter <= 0;
                // end
                end else begin
                    if(measurement_fusion_stage == 2'b00) begin
                        if(global_stage_saved == STAGE_MERGE) begin
                            global_stage <= STAGE_IDLE;
                            lower_half_counter <= cycle_counter;
                            current_context <= current_context + 1;
                        end
                    end else if(measurement_fusion_stage == 2'b01) begin
                        if(global_stage_saved == STAGE_MERGE) begin
                            global_stage <= STAGE_RESET_ROOTS;
                            measurement_fusion_stage <= 2'b10;
                            current_context <= 0;
                        end
                    end
                end
            end
            //Laksheen
            STAGE_TEMPORARY: begin
                global_stage <=STAGE_GROW;
            end
            
            default: begin
                global_stage <= STAGE_IDLE;
            end
        endcase
    end
end

always@(posedge clk) begin
    measurements <= measurement_internal;
end

always@(*) begin
    if(global_stage == STAGE_MEASUREMENT_LOADING) begin
        if(measurement_fusion_on && measurement_fusion_stage != 2'b0) begin
            reset_all_edges = 0;
        end else begin
            reset_all_edges = 1;
        end
    end else begin
        reset_all_edges = 0;
    end
end

always@(*) begin
    if (reset) begin
        output_fifo_valid = 0;
    end else begin 
        if(global_stage_d == STAGE_RESULT_VALID) begin
            output_fifo_valid = 1;
            output_fifo_data = correction;
        end else if(global_stage == STAGE_RESULT_VALID) begin
            output_fifo_valid = 1; // One added cycle to send the cycle counter and iteration counter
            output_fifo_data = {iteration_counter,cycle_counter};
        end else begin
            output_fifo_valid = 0;
            output_fifo_data = correction;
        end
    end
end

// assign output_fifo_data = correction;

always@(*) begin
    if (reset) begin
        input_ctrl_rx_ready = 0;
    end else begin 
        if(global_stage == STAGE_IDLE) begin
            input_ctrl_rx_ready = 1;
        // end else if(global_stage == STAGE_MERGE) begin
        //     if(multi_fpga_mode && delay_counter >= MAXIMUM_DELAY) begin
        //         input_ctrl_rx_ready = 1;
        //     end else begin
        //         input_ctrl_rx_ready = 0;
        //     end
        end else begin
            input_ctrl_rx_ready = 0;
        end
    end
end

reg result_is_send;

always@(posedge clk) begin
    if (reset) begin
        result_is_send <= 0;
    end else begin
        if(global_stage == STAGE_RESULT_VALID && current_context == 0) begin
            result_is_send <= 1;
        end else if(global_stage == STAGE_IDLE) begin
            result_is_send <= 0;
        end
    end
end

always@(*) begin
    output_ctrl_tx_valid = 0;
    output_ctrl_tx_valid = 0;
    output_ctrl_tx_data = 64'h0;
    if(reset) begin
        output_ctrl_tx_valid = 0;
    end else begin
        // if(multi_fpga_mode == 1'b0) begin
        if(global_stage == STAGE_RESULT_VALID && result_is_send == 0) begin
            output_ctrl_tx_valid = 1;
            // if(measurement_fusion_on) begin
            //     output_ctrl_tx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] = lower_half_counter[7:0];
            // end else begin
            //     output_ctrl_tx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] = iteration_counter;
            // end
            output_ctrl_tx_data [MSG_DEST_MSB : MSG_DEST_LSB] = 8'h0;
            output_ctrl_tx_data [MSG_HEADER_MSB : MSG_HEADER_LSB] = HEADER_RESULT;
            output_ctrl_tx_data [15:0] = cycle_counter;
        end
        // end 
        // else begin
        //     if(global_stage == STAGE_MERGE && delay_counter >= MAXIMUM_DELAY) begin
        //         if(input_ctrl_rx_valid && input_ctrl_rx_ready && input_ctrl_rx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] == SEND_ODD_AND_BUSY) begin
        //             output_ctrl_tx_valid = 1;
        //             output_ctrl_tx_data [CTRL_MSG_MSB : CTRL_MSG_MSB - 7] = NODE_RESULT_MSG;
        //             output_ctrl_tx_data [1] = odd_clusters;
        //             if(busy || router_busy_reg > 0) begin
        //                 output_ctrl_tx_data [0] = 1;
        //             end else begin
        //                 output_ctrl_tx_data [0] = 0;
        //             end
        //         end
        //     end
        // end
    end
end

// FIFO
fifo_wrapper #(
    .WIDTH(CORRECTION_COUNT_PER_ROUND),
    .DEPTH(128)
) output_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(output_fifo_data),
    .input_valid(output_fifo_valid),
    .input_ready(output_fifo_ready),
    .output_data(output_fifo_data_d),
    .output_valid(output_fifo_valid_d),
    .output_ready(output_fifo_ready_d)
);


reg [U_BIT_WIDTH + 1:0] output_u; //The +1 comes from the need to send iteration counter and the data counter
reg [CORRECTION_COUNT_PER_ROUND_PADDED-1 :0] intermediate_out_data_reg;
reg [CORRECTION_COUNT_PER_ROUND_PADDED-1 :0] intermediate_out_data_wire;
reg intermediate_out_valid_reg;
reg [$clog2(CORRECTION_COUNT_PER_ROUND_PADDED_BYTES) -1:0] current_word_byte_count;

always@(*) begin
    intermediate_out_data_wire = {CORRECTION_COUNT_PER_ROUND_PADDED{1'b0}};
    intermediate_out_data_wire = output_fifo_data_d;
end

always@(posedge clk) begin
    if (reset) begin
        output_u <= 0;
    end else begin
        if(output_ready) begin
            if(output_u == 0) begin
                if(output_fifo_valid_d) begin
                    output_u <= output_u + 1;
                end
                intermediate_out_valid_reg <= 0;
            end else if(output_u == GRID_WIDTH_U + 1) begin
                output_u <= 0;
            end else if(output_fifo_valid_d && |output_fifo_data_d == 1'b0) begin
                output_u <= output_u + 1;
            end else begin
                if(intermediate_out_valid_reg && |intermediate_out_data_reg == 1'b0) begin
                    output_u <= output_u + 1;
                    intermediate_out_valid_reg <= 0;
                end else if(output_fifo_valid_d) begin
                    intermediate_out_valid_reg <= 1;
                end
            end
            if(intermediate_out_valid_reg) begin
                if(intermediate_out_data_reg[7:0] == 8'h0)begin
                    intermediate_out_data_reg <= {8'b0,intermediate_out_data_reg[CORRECTION_COUNT_PER_ROUND_PADDED-1:8]};
                    current_word_byte_count <= current_word_byte_count + 1;
                end else begin
                    if(intermediate_out_data_reg[0] == 1'b1) begin
                        intermediate_out_data_reg[0] <= 1'b0;
                    end else if(intermediate_out_data_reg[1] == 1'b1) begin
                        intermediate_out_data_reg[1] <= 1'b0;
                    end else if(intermediate_out_data_reg[2] == 1'b1) begin
                        intermediate_out_data_reg[2] <= 1'b0;
                    end else if(intermediate_out_data_reg[3] == 1'b1) begin
                        intermediate_out_data_reg[3] <= 1'b0;
                    end else if(intermediate_out_data_reg[4] == 1'b1) begin
                        intermediate_out_data_reg[4] <= 1'b0;
                    end else if(intermediate_out_data_reg[5] == 1'b1) begin
                        intermediate_out_data_reg[5] <= 1'b0;
                    end else if(intermediate_out_data_reg[6] == 1'b1) begin
                        intermediate_out_data_reg[6] <= 1'b0;
                    end else if(intermediate_out_data_reg[7] == 1'b1) begin
                        intermediate_out_data_reg[7] <= 1'b0;
                    end
                end
            end else if(output_fifo_valid_d) begin
                intermediate_out_data_reg <= intermediate_out_data_wire;
                current_word_byte_count <= 0;
            end
        end
    end
end

always@(*) begin
    output_data = 32'b0;
    output_valid = 1'b0;
    output_fifo_ready_d = 1'b0;

    case(output_u)
        0: begin
            output_data = output_fifo_data_d;
            output_valid = output_fifo_valid_d;
            output_fifo_ready_d = output_ready;
        end
        GRID_WIDTH_U + 1 : begin
            output_data = 32'hffffffff;
            output_valid = 1'b1;
            output_fifo_ready_d = 1'b0;
        end
        default: begin
            if(|output_fifo_data_d == 1'b0) begin
                output_valid = 1'b0;
                output_fifo_ready_d = 1'b1;
            end else begin
                if(intermediate_out_valid_reg) begin
                    if(|intermediate_out_data_reg == 1'b0) begin
                        output_fifo_ready_d = 1'b1;
                    end else begin
                        output_fifo_ready_d = 1'b0;
                    end
                    
                    if(intermediate_out_data_reg[7:0] == 8'h0) begin
                        output_valid = 1'b0;
                    end else begin
                        output_valid = 1'b1;
                    end

                    if(intermediate_out_data_reg[0] == 1'b1) begin
                        output_data[2:0] = 3'b000;
                    end else if(intermediate_out_data_reg[1] == 1'b1) begin
                        output_data[2:0] = 3'b001;
                    end else if(intermediate_out_data_reg[2] == 1'b1) begin
                        output_data[2:0] = 3'b010;
                    end else if(intermediate_out_data_reg[3] == 1'b1) begin
                        output_data[2:0] = 3'b011;
                    end else if(intermediate_out_data_reg[4] == 1'b1) begin
                        output_data[2:0] = 3'b100;
                    end else if(intermediate_out_data_reg[5] == 1'b1) begin
                        output_data[2:0] = 3'b101;
                    end else if(intermediate_out_data_reg[6] == 1'b1) begin
                        output_data[2:0] = 3'b110;
                    end else if(intermediate_out_data_reg[7] == 1'b1) begin
                        output_data[2:0] = 3'b111;
                    end
                    output_data[$clog2(CORRECTION_COUNT_PER_ROUND_PADDED_BYTES) + 3 - 1 : 3] = current_word_byte_count;
                    output_data[U_BIT_WIDTH +1 + $clog2(CORRECTION_COUNT_PER_ROUND_PADDED_BYTES) + 3 - 1 : $clog2(CORRECTION_COUNT_PER_ROUND_PADDED_BYTES) + 3] = output_u - 1;
                end else begin
                    output_valid = 1'b0;
                    output_fifo_ready_d = 1'b0;
                end
            end
        end
    endcase
end

always@(posedge clk) begin
    if(reset) begin
        grid_1_out_valid <= 0;
        grid_2_out_valid <= 0;
    end else begin
        if(global_stage_d == STAGE_RESULT_VALID) begin
            if(FPGA_ID == 1 || FPGA_ID == 3) begin
                grid_1_out_valid <= 1;
                grid_1_out_data[63:56] <= FPGA_ID + 1;
                grid_1_out_data[55:0] <= east_border;
            end else begin
                grid_1_out_valid <= 0;
            end
            if(FPGA_ID == 1 || FPGA_ID == 2) begin
                grid_2_out_valid <= 1;
                grid_2_out_data[63:56] <= FPGA_ID + 2;
                grid_2_out_data[55:0] <= south_border;
            end else begin
                grid_2_out_valid <= 0;
            end
        end else begin
            grid_1_out_valid <= 0;
            grid_2_out_valid <= 0;
        end
    end
end

always@(*) begin
    grid_1_in_ready = 0;
    grid_2_in_ready = 0;
    if(global_stage == STAGE_LOAD_ARTIFICAL_DEFECTS) begin
        if(FPGA_ID == 2) begin
            grid_1_in_ready = 1;
        end else if(FPGA_ID == 3) begin
            grid_2_in_ready = 1;
        end else if(FPGA_ID == 4) begin
            if(grid_1_in_valid && grid_2_in_valid) begin
                grid_1_in_ready = 1;
                grid_2_in_ready = 1;
            end
        end
    end
end

endmodule