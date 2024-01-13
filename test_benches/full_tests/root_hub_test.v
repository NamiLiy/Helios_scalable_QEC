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

output [64*NUM_LEAVES - 1 : 0] down_tx_data;
output [NUM_LEAVES - 1 : 0] down_tx_valid;
input [NUM_LEAVES - 1 : 0] down_tx_ready;

input [64*NUM_LEAVES - 1 : 0] up_rx_data;
input [NUM_LEAVES - 1 : 0] up_rx_valid;
output [NUM_LEAVES - 1 : 0] up_rx_ready;


reg [63 : 0] local_tx_data_d;
reg local_tx_valid_d;
wire local_tx_ready_d;

wire [63 : 0] local_rx_data_d;
wire local_rx_valid_d;
reg local_rx_ready_d;

wire [63:0] local_tx_data;
wire local_tx_valid;
wire local_tx_ready;

wire [63:0] local_rx_data;
wire local_rx_valid;
wire local_rx_ready;

reg [3:0] root_hub_state;

reg [31:0] count;
reg [31:0] fpga_count;

localparam IDLE = 4'd0;
localparam START_DECODING = 4'd1;
localparam MEASUREMENT_DATA = 4'd2;
localparam WAIT_FOR_RESULT = 4'd3;


always@(posedge clk) begin
    if(reset) begin
        root_hub_state <= 0;
        count <= 0;
        fpga_count <= 0;
    end else begin
        case(root_hub_state)
            IDLE: begin //Send the start decoding msg
                if(local_tx_ready_d && count < MAX_COUNT) begin
                    root_hub_state <= START_DECODING;
                    fpga_count <= 0;
                    count <= count + 1;
                end
            end
            START_DECODING: begin // Measurement data header
                if(local_tx_ready_d) begin
                    root_hub_state <= MEASUREMENT_DATA;
                end
            end
            MEASUREMENT_DATA: begin // Measurement data
                if(local_tx_ready_d) begin
                    root_hub_state <= WAIT_FOR_RESULT;
                end
            end
            WAIT_FOR_RESULT: begin // Wait for the result
                if(local_rx_valid_d) begin
                    fpga_count <= fpga_count + 1;
                    $display("%t\tID = %d Test case  = %d, %d cycles %d iterations", $time, 0, count, local_rx_data_d[39:24], local_rx_data_d[47:40]);
                    if(fpga_count == NUM_LEAVES - 1) begin
                        root_hub_state <= IDLE;
                    end
                end
            end
        endcase
    end
end

always@(*) begin
    case(root_hub_state)
        IDLE: begin
            local_tx_data_d = {8'hff, 8'hff, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            local_tx_valid_d = 0;
            local_rx_ready_d = 0;
        end
        START_DECODING: begin
            local_tx_data_d = {8'hff, 8'hff, START_DECODING_MSG, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            local_tx_valid_d = 1;
            local_rx_ready_d = 0;
        end
        MEASUREMENT_DATA: begin
            local_tx_data_d = {8'hff, 8'hff, MEASUREMENT_DATA_HEADER, 8'b0, 8'b0, 8'b0, 8'b0, 8'b0};
            local_tx_valid_d = 1;
            local_rx_ready_d = 0;
        end
        WAIT_FOR_RESULT: begin
            local_tx_data_d = 0;
            local_tx_valid_d = 0;
            local_rx_ready_d = 1;
        end
    endcase
end



fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) parent_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(local_rx_data),
    .input_valid(local_rx_valid),
    .input_ready(local_rx_ready),
    .output_data(local_rx_data_d),
    .output_valid(local_rx_valid_d),
    .output_ready(local_rx_ready_d)
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) controller_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(local_tx_data_d),
    .input_valid(local_tx_valid_d),
    .input_ready(local_tx_ready_d),
    .output_data(local_tx_data),
    .output_valid(local_tx_valid),
    .output_ready(local_tx_ready)
);

wire [64*(NUM_LEAVES+1) - 1 : 0] router_tx_data;
wire [NUM_LEAVES+1 - 1 : 0] router_tx_valid;
wire [NUM_LEAVES+1 - 1 : 0] router_tx_ready;

wire [64*(NUM_LEAVES+1) - 1 : 0] router_rx_data;
wire [NUM_LEAVES+1 - 1 : 0] router_rx_valid;
wire [NUM_LEAVES+1 - 1 : 0] router_rx_ready;


root_hub #(
    .NUM_FPGAS(NUM_LEAVES+1),
    .CHANNEL_WIDTH(64),
    .DEST_WIDTH(8)
) root_hub (
    .clk(clk),
    .reset(reset),

    .rx_data(router_rx_data),
    .rx_valid(router_rx_valid),
    .rx_ready(router_rx_ready),

    .tx_data(router_tx_data),
    .tx_valid(router_tx_valid),
    .tx_ready(router_tx_ready)
);

assign down_tx_data = router_tx_data[64+:64*NUM_LEAVES];
assign down_tx_valid = router_tx_valid[1+:NUM_LEAVES];
assign router_tx_ready[1+:NUM_LEAVES] = down_tx_ready;

assign router_rx_data[64+:64*NUM_LEAVES] = up_rx_data;
assign router_rx_valid[1+:NUM_LEAVES] = up_rx_valid;
assign up_rx_ready = router_rx_ready[1+:NUM_LEAVES];

assign local_rx_data = router_tx_data[0+:64];
assign local_rx_valid = router_tx_valid[0];
assign router_tx_ready[0] = local_rx_ready;

assign router_rx_data[0+:64] = local_tx_data;
assign router_rx_valid[0] = local_tx_valid;
assign local_tx_ready = router_rx_ready[0];

endmodule