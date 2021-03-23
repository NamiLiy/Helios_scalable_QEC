`timescale 1ns / 1ps

`include "parameters.sv"

module decoder_stage_controller #(
    parameter ITERATION_COUNTER_WIDTH = 8,  // counts to 255 iterations
    parameter BOUNDARY_GROW_DELAY = 3,  // clock cycles
    parameter SPREAD_CLUSTER_DELAY = 2,  // clock cycles
    parameter SYNC_IS_ODD_CLUSTER_DELAY = 2  // clock cycles
) (
    input clk,
    input reset,
    input new_round_start,
    input has_message_flying,
    input has_odd_clusters,
    output reg [STAGE_WIDTH-1:0] stage,
    output reg result_valid,
    output reg [ITERATION_COUNTER_WIDTH-1:0] iteration_counter
);

`define MAX(a, b) (((a) > (b)) ? (a) : (b))
`define MAX3(a, b, c) (((a) > `MAX((b), (c))) ? (a) : `MAX((b), (c)))
localparam MAXIMUM_DELAY = `MAX3(BOUNDARY_GROW_DELAY, SPREAD_CLUSTER_DELAY, SYNC_IS_ODD_CLUSTER_DELAY);
localparam COUNTER_WIDTH = $clog2(MAXIMUM_DELAY + 1);
reg [COUNTER_WIDTH-1:0] delay_counter;

always @(posedge clk) begin
    if (reset) begin
        iteration_counter <= 0;
    end else begin
        if (stage == STAGE_MEASUREMENT_LOADING) begin
            iteration_counter <= 0;
        end
        if (stage == STAGE_SYNC_IS_ODD_CLUSTER && delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY && !has_message_flying) begin
            iteration_counter <= iteration_counter + 1;
        end
    end
end

always @(posedge clk) begin
    if (reset) begin
        stage <= STAGE_IDLE;
        delay_counter <= 0;
    end else begin
        case (stage)
            STAGE_IDLE: begin
                if (new_round_start) begin
                    stage <= STAGE_MEASUREMENT_LOADING;
                    delay_counter <= 0;
                end
            end
            STAGE_SPREAD_CLUSTER: begin
                if (delay_counter >= SPREAD_CLUSTER_DELAY) begin
                    if (!has_message_flying) begin
                        stage <= STAGE_SYNC_IS_ODD_CLUSTER;
                        delay_counter <= 0;
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
                    if (!has_message_flying) begin
                        if (has_odd_clusters) begin
                            stage <= STAGE_GROW_BOUNDARY;
                            delay_counter <= 0;
                        end else begin
                            stage <= STAGE_IDLE;
                            delay_counter <= 0;
                        end
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
            end
        endcase
    end
end

always @(posedge clk) begin
    if (reset) begin
        result_valid <= 0;
    end else begin
        if (new_round_start) begin
            result_valid <= 0;
        end else if (stage == STAGE_SYNC_IS_ODD_CLUSTER && delay_counter >= SYNC_IS_ODD_CLUSTER_DELAY && !has_message_flying && !has_odd_clusters) begin
            result_valid <= 1;
        end else if(stage == STAGE_MEASUREMENT_LOADING) begin
            result_valid <= 0;
        end
    end
end

endmodule
