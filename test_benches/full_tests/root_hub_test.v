module root_hub_test #(
    parameter CODE_DISTANCE = 5,
    parameter NUM_LEAVES = 1,
    parameter MAX_COUNT = 1000,
    parameter MULTI_FPGA_RUN = 0
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

wire [64*NUM_LEAVES-1 : 0] rx_data_d;
wire [NUM_LEAVES-1 : 0] rx_valid_d;
wire [NUM_LEAVES-1 : 0] rx_ready_d;

wire [64*NUM_LEAVES-1 : 0] tx_data_d;
wire [NUM_LEAVES-1 : 0] tx_valid_d;
wire [NUM_LEAVES-1 : 0] tx_ready_d;

reg [3:0] root_hub_state;

reg [31:0] count;
reg [31:0] fpga_count;

localparam IDLE = 4'd0;
localparam START_DECODING = 4'd1;
localparam MEASUREMENT_DATA = 4'd2;
localparam WAIT_FOR_RESULT = 4'd3;

reg multi_fpga_run;


always@(posedge clk) begin
    if(reset) begin
        root_hub_state <= 0;
        count <= 0;
        fpga_count <= 0;
        multi_fpga_run <= MULTI_FPGA_RUN;
    end else begin
        case(root_hub_state)
            IDLE: begin //Send the start decoding msg
                if(local_tx_ready_d && count < MAX_COUNT) begin
                    root_hub_state <= START_DECODING;
                    fpga_count <= 0;
                    count <= count + 1;
                    // this is just a fun workaround
                    // if(count >= MAX_COUNT/3 && count < 2*MAX_COUNT/3) begin
                    //     multi_fpga_run <= 1;
                    // end else begin
                    //     multi_fpga_run <= 0;
                    // end
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
                    if(multi_fpga_run == 1'b0) begin
                        if(fpga_count == NUM_LEAVES - 1) begin
                            root_hub_state <= IDLE;
                        end
                    end else begin
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
            local_tx_data_d = {8'hff, 8'hff, START_DECODING_MSG, 8'b0, 8'b0, 8'b0, 8'b0, 7'b0, multi_fpga_run};
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

// FIFO buffers for the fpgas
generate
    genvar i;
    for(i = 0; i < NUM_LEAVES; i = i + 1) begin: fpga
        fifo_wrapper #(
            .WIDTH(64),
            .DEPTH(128)
        ) input_fifo (
            .clk(clk),
            .reset(reset),
            .input_data(up_rx_data[64*i+:64]),
            .input_valid(up_rx_valid[i]),
            .input_ready(up_rx_ready[i]),
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
            .output_data(down_tx_data[64*i+:64]),
            .output_valid(down_tx_valid[i]),
            .output_ready(down_tx_ready[i])
        );
    end
endgenerate

wire [63 : 0] tx_data_1;
wire tx_valid_1;
wire tx_ready_1;

wire [63 : 0] rx_data_1;
wire rx_valid_1;
wire rx_ready_1;

wire [63 : 0] tx_data_2;
wire tx_valid_2;
wire tx_ready_2;

wire [63 : 0] rx_data_2;
wire rx_valid_2;
wire rx_ready_2;

wire [63 : 0] tx_data_3;
wire tx_valid_3;
wire tx_ready_3;

wire [63 : 0] rx_data_3;
wire rx_valid_3;
wire rx_ready_3;

wire [63 : 0] tx_data_4;
wire tx_valid_4;
wire tx_ready_4;

wire [63 : 0] rx_data_4;
wire rx_valid_4;
wire rx_ready_4;

`define CONNECT_NODE_TB(id, tx_data_i, tx_valid_i, tx_ready_i, rx_data_i, rx_valid_i, rx_ready_i) \
    assign rx_data_i = rx_data_d[64*id+:64]; \
    assign rx_valid_i = rx_valid_d[id]; \
    assign rx_ready_d[id] = rx_ready_i; \
    assign tx_data_d[64*id+:64] = tx_data_i; \
    assign tx_valid_d[id] = tx_valid_i; \
    assign tx_ready_i = tx_ready_d[id];

    generate
        if(NUM_LEAVES > 0) begin
            `CONNECT_NODE_TB(0, tx_data_1, tx_valid_1, tx_ready_1, rx_data_1, rx_valid_1, rx_ready_1)
        end else begin
            assign rx_valid_1 = 0;
            assign tx_ready_1 = 1;
        end
        if(NUM_LEAVES > 1) begin
            `CONNECT_NODE_TB(1, tx_data_2, tx_valid_2, tx_ready_2, rx_data_2, rx_valid_2, rx_ready_2)
        end else begin
            assign rx_valid_2 = 0;
            assign tx_ready_2 = 1;
        end
        if(NUM_LEAVES > 2) begin
            `CONNECT_NODE_TB(2, tx_data_3, tx_valid_3, tx_ready_3, rx_data_3, rx_valid_3, rx_ready_3)
        end else begin
            assign rx_valid_3 = 0;
            assign tx_ready_3 = 1;
        end
        if(NUM_LEAVES > 3) begin
            `CONNECT_NODE_TB(3, tx_data_4, tx_valid_4, tx_ready_4, rx_data_4, rx_valid_4, rx_ready_4)
        end else begin
            assign rx_valid_4 = 0;
            assign tx_ready_4 = 1;
        end
    endgenerate

root_hub_core #(
    .NUM_FPGAS(NUM_LEAVES+1),
    .MAXIMUM_DELAY(3),
    .CHANNEL_WIDTH(64),
    .DEST_WIDTH(8)
) root_hub (
    .clk(clk),
    .reset(reset),

    // The ports are swapped because it is the way the root_hub is instantiated in the root_hub_core_split
    .tx_0_dout(local_rx_data),
    .tx_0_wr_en(local_rx_valid),
    .tx_0_full(!local_rx_ready),

    .rx_0_din(local_tx_data),
    .rx_0_empty(!local_tx_valid),
    .rx_0_rd_en(local_tx_ready),

    .tx_1_dout(tx_data_1),
    .tx_1_wr_en(tx_valid_1),
    .tx_1_full(!tx_ready_1),

    .rx_1_din(rx_data_1),
    .rx_1_empty(!rx_valid_1),
    .rx_1_rd_en(rx_ready_1),

    .tx_2_dout(tx_data_2),
    .tx_2_wr_en(tx_valid_2),
    .tx_2_full(!tx_ready_2),

    .rx_2_din(rx_data_2),
    .rx_2_empty(!rx_valid_2),
    .rx_2_rd_en(rx_ready_2),

    .tx_3_dout(tx_data_3),
    .tx_3_wr_en(tx_valid_3),
    .tx_3_full(!tx_ready_3),

    .rx_3_din(rx_data_3),
    .rx_3_empty(!rx_valid_3),
    .rx_3_rd_en(rx_ready_3),

    .tx_4_dout(tx_data_4),
    .tx_4_wr_en(tx_valid_4),
    .tx_4_full(!tx_ready_4),

    .rx_4_din(rx_data_4),
    .rx_4_empty(!rx_valid_4),
    .rx_4_rd_en(rx_ready_4)
);

endmodule