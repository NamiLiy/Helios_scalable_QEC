module child_controller #(
    parameter CODE_DISTANCE_X = 3,
    parameter CODE_DISTANCE_Z = 2,
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter MAXIMUM_INITIAL_DELAY = 3,
    parameter MAXIMUM_BUSY_DELAY = 1
) (
    clk,
    reset,

    busy_PE, 
    odd_clusters_PE,
    global_stage,

    result_valid,
    iteration_counter, 
    cycle_counter,

    decoding_start,
    next_iteration,

    busy_to_parent,
    odd_clusters_to_parent
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
localparam MEASUREMENT_ROUNDS = `MAX(CODE_DISTANCE_X, CODE_DISTANCE_Z);
localparam PER_DIM_BIT_WIDTH = $clog2(MEASUREMENT_ROUNDS);
localparam ADDRESS_WIDTH = PER_DIM_BIT_WIDTH * 3;

localparam PU_COUNT = CODE_DISTANCE_X * CODE_DISTANCE_Z * MEASUREMENT_ROUNDS;

input clk;
input reset;
output reg [STAGE_WIDTH-1:0] global_stage;
reg [STAGE_WIDTH-1:0] global_stage_previous;

input [CHILD_COUNT - 1 : 0]  busy_child;
input [CHILD_COUNT - 1 : 0]  odd_clusters_child;
input new_round_start;

output reg result_valid;
output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter;
output reg [31:0] cycle_counter;

input decoding_start;
input next_iteration;

output busy_to_parent;
output odd_clusters_to_parent;


reg busy;
reg odd_clusters;

always@(posedge clk) begin
    busy <= |busy_PE;
    odd_clusters <= |odd_clusters_PE;
end

assign busy_to_parent = busy;
assign odd_clusters_to_parent = odd_clusters;   

always @(posedge clk) begin
    if (reset) begin
        cycle_counter <= 0;
    end else begin
        if (global_stage == STAGE_MEASUREMENT_LOADING) begin
            cycle_counter <= 1;
        end else if (!result_valid && global_stage != STAGE_IDLE) begin
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

localparam DELAY_COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 1);
reg [DELAY_COUNTER_WIDTH-1:0] delay_counter;
reg next_iteration_saved;

always @(posedge clk) begin
    if (reset) begin
        global_stage <= STAGE_IDLE;
        delay_counter <= 0;
        result_valid <= 0;
        next_iteration_saved <= 0;
    end else begin
        case (global_stage)
            STAGE_IDLE: begin // 0
                if (decoding_start) begin
                    global_stage <= STAGE_MEASUREMENT_LOADING;
                    delay_counter <= 0;
                    result_valid <= 0;
                end
                next_iteration_saved <= 0;
                // else begin
                //     result_valid <= 1;
                // end
            end

            STAGE_MEASUREMENT_LOADING: begin
                // Currently this is single cycle as only from external buffer happens.
                // In future might need multiple
                global_stage <= STAGE_GROW;
                delay_counter <= 0;
                result_valid <= 0; // for safety
            end

            STAGE_GROW: begin //2
                global_stage <= STAGE_MERGE;
                delay_counter <= 0;
            end

            STAGE_MERGE: begin //3
                if (delay_counter >= MAXIMUM_INITIAL_DELAY) begin
                    if(!decoding_start) begin
                        global_stage <= STAGE_PEELING;
                        delay_counter <= 0;
                    end else if(next_iteration_saved != next_iteration) begin
                        global_stage <= STAGE_GROW;
                        next_iteration_saved <= next_iteration;
                        delay_counter <= 0;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
            end           

            STAGE_PEELING: begin //4
                if (delay_counter >= MAXIMUM_INITIAL_DELAY) begin
                    if (next_iteration) begin
                        global_stage <= STAGE_RESULT_VALID;
                        delay_counter <= 0;
                    end
                end else begin
                    delay_counter <= delay_counter + 1;
                end
                next_iteration_saved <= 0;
            end

            STAGE_RESULT_VALID: begin //5
                global_stage <= STAGE_IDLE;
                result_valid <= 1;
            end


            
            default: begin
                global_stage <= STAGE_IDLE;
            end
        endcase
    end
end

endmodule