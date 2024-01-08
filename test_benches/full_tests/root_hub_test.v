module root_hub_test #(
    parameter CODE_DISTANCE = 5,
    parameter NUM_LEAVES = 1,
    parameter MAX_COUNT = 20
) (
    clk,
    reset,

    down_tx_data,
    down_tx_valid,
    down_tx_ready,

    up_rx_data,
    up_rx_valid,
    up_rx_ready


    // roots // A debug port. Do not use in the real implementation
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

input clk;
input reset;

output [63 : 0] down_tx_data;
output down_tx_valid;
input down_tx_ready;

input [63 : 0] up_rx_data;
input up_rx_valid;
output up_rx_ready;

reg [63 : 0] down_tx_data_d;
reg down_tx_valid_d;
wire down_tx_ready_d;

wire [63 : 0] up_rx_data_d;
wire up_rx_valid_d;
reg up_rx_ready_d;

reg [3:0] root_hub_state;

reg [31:0] count;

localparam IDLE = 4'd0;
localparam START_DECODING = 4'd1;
localparam MEASUREMENT_DATA = 4'd2;
localparam WAIT_FOR_RESULT = 4'd3;


always@(posedge clk) begin
    if(reset) begin
        root_hub_state <= 0;
        count <= 0;
    end else begin
        case(root_hub_state)
            IDLE: begin //Send the start decoding msg
                if(down_tx_ready_d && count < MAX_COUNT) begin
                    root_hub_state <= START_DECODING;
                    count <= count + 1;
                end
            end
            START_DECODING: begin // Measurement data header
                if(down_tx_ready_d) begin
                    root_hub_state <= MEASUREMENT_DATA;
                end
            end
            MEASUREMENT_DATA: begin // Measurement data
                if(down_tx_ready_d) begin
                    root_hub_state <= WAIT_FOR_RESULT;
                end
            end
            WAIT_FOR_RESULT: begin // Wait for the result
                if(up_rx_valid_d) begin
                    root_hub_state <= IDLE;
                    $display("%t\tID = %d Test case  = %d, %d cycles %d iterations", $time, 0, count, up_rx_data_d[39:24], up_rx_data_d[47:40]);
                end
            end
        endcase
    end
end

always@(*) begin
    case(root_hub_state)
        IDLE: begin
            down_tx_data_d = {8'b1, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            down_tx_valid_d = 0;
            up_rx_ready_d = 0;
        end
        START_DECODING: begin
            down_tx_data_d = {8'b1, 8'b0, START_DECODING_MSG, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            down_tx_valid_d = 1;
            up_rx_ready_d = 0;
        end
        MEASUREMENT_DATA: begin
            down_tx_data_d = {8'b1, 8'b0, MEASUREMENT_DATA_HEADER, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            down_tx_valid_d = 1;
            up_rx_ready_d = 0;
        end
        WAIT_FOR_RESULT: begin
            down_tx_data_d = 0;
            down_tx_valid_d = 0;
            up_rx_ready_d = 1;
        end
    endcase
end



fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) parent_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(up_rx_data),
    .input_valid(up_rx_valid),
    .input_ready(up_rx_ready),
    .output_data(up_rx_data_d),
    .output_valid(up_rx_valid_d),
    .output_ready(up_rx_ready_d)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) controller_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(down_tx_data_d),
    .input_valid(down_tx_valid_d),
    .input_ready(down_tx_ready_d),
    .output_data(down_tx_data),
    .output_valid(down_tx_valid),
    .output_ready(down_tx_ready)
);

endmodule