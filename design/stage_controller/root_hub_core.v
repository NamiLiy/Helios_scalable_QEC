module root_hub #(
    parameter NUM_FPGAS = 5
) (,
    clk,
    reset,

    tx_data,
    tx_valid,
    tx_ready,

    rx_data,
    rx_valid,
    rx_ready


    // roots // A debug port. Do not use in the real implementation
);

`include "../../parameters/parameters.sv"

`define MAX(a, b) (((a) > (b)) ? (a) : (b))

input clk;
input reset;

output [64*NUM_FPGAS-1 : 0] tx_data;
output [NUM_FPGAS-1 : 0] tx_valid;
input [NUM_FPGAS-1 : 0] tx_ready;

input [64*NUM_FPGAS-1 : 0] rx_data;
input [NUM_FPGAS-1 : 0] rx_valid;
output [NUM_FPGAS-1 : 0] rx_ready;

wire [64*NUM_FPGAS-1 : 0] rx_data_d;
wire [NUM_FPGAS-1 : 0] rx_valid_d;
wire [NUM_FPGAS-1 : 0] rx_ready_d;

wire [64*NUM_FPGAS-1 : 0] tx_data_d;
wire [NUM_FPGAS-1 : 0] tx_valid_d;
wire [NUM_FPGAS-1 : 0] tx_ready_d;

generate
    genvar i;
    for(i = 1; i < NUM_FPGAS; i = i + 1) begin: fpga
        fifo_wrapper #(
            .WIDTH(64),
            .DEPTH(128)
        ) input_fifo (
            .clk(clk),
            .reset(reset),
            .input_data(rx_data[64*i+:64]),
            .input_valid(rx_valid[i]),
            .input_ready(rx_ready[i]),
            .output_data(rx_data_d[64*i+:64]),
            .output_valid(rx_valid_d[i]),
            .output_ready(rx_ready_d[i])
        );

        fifo_wrapper #(
            .WIDTH(64),
            .DEPTH(128)
        ) output_fifo (
            .clk(clk),
            .reset(reset),
            .input_data(tx_data_d[64*i+:64]),
            .input_valid(tx_valid_d[i]),
            .input_ready(tx_ready_d[i]),
            .output_data(tx_data[64*i+:64]),
            .output_valid(tx_valid[i]),
            .output_ready(tx_ready[i])
        );
    end
endgenerate

wire [63 : 0] local_rx_data;
wire local_rx_valid;
reg local_rx_ready;

reg [63 : 0] local_tx_data;
reg local_tx_valid;
wire local_tx_ready;

always@(*) begin
    local_tx_data = rx_data[0+:64];
    local_tx_valid = rx_valid[0];
    local_rx_ready = tx_ready[0];
end

assign rx_ready[0] = local_tx_ready;
assign tx_data[0+:64] = local_rx_data;
assign tx_valid[0] = local_rx_valid;

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) local_input_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(local_tx_data),
    .input_valid(local_tx_valid),
    .input_ready(local_tx_ready),
    .output_data(rx_data_d[0+:64]),
    .output_valid(rx_valid_d[0]),
    .output_ready(rx_ready_d[0])
);

fifo_wrapper #(
    .WIDTH(64),
    .DEPTH(128)
) local_output_fifo (
    .clk(clk),
    .reset(reset),
    .input_data(tx_data_d[0+:64]),
    .input_valid(tx_valid_d[0]),
    .input_ready(tx_ready_d[0]),
    .output_data(local_rx_data),
    .output_valid(local_rx_valid),
    .output_ready(local_rx_ready)
);

router #(
    .NUM_CHANNELS(NUM_FPGAS),
    .CHANNEL_WIDTH(64),
    .DEST_WIDTH(8)
) router (
    .clk(clk),
    .reset(reset),

    .rx_data(rx_data_d),
    .rx_valid(rx_valid_d),
    .rx_ready(rx_ready_d),

    .tx_data(tx_data_d),
    .tx_valid(tx_valid_d),
    .tx_ready(tx_ready_d)
);

endmodule