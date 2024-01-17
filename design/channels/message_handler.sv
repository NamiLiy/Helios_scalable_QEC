module message_handler #(
    parameter FPGA_FIFO_SIZE = 32,
    parameter FPGA_FIFO_COUNT = 5,
    parameter GT_FIFO_SIZE = 64,
    parameter FIFO_TAG_MSB = 55,
    parameter FIFO_TAG_LSB = 48
) (
    clk,
    reset,

    in_data,
    in_valid,
    in_ready,

    out_data,
    out_valid,
    out_ready,

    border_input_data,
    border_input_valid,
    border_input_ready,

    border_output_data,
    border_output_valid,
    border_output_ready,

    control_to_handler_data,
    control_to_handler_valid,
    control_to_handler_ready,

    handler_to_control_data,
    handler_to_control_valid,
    handler_to_control_ready,

    fpga_id,
    router_busy
);

    input clk;
    input reset;

    input [GT_FIFO_SIZE-1 : 0] in_data;
    input in_valid;
    output in_ready;

    output [GT_FIFO_SIZE-1 : 0] out_data;
    output out_valid;
    input out_ready;

    input [2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0] border_input_data;
    input [2*FPGA_FIFO_COUNT-1:0] border_input_valid;
    output [2*FPGA_FIFO_COUNT-1:0] border_input_ready;

    output [2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0] border_output_data;
    output [2*FPGA_FIFO_COUNT-1:0] border_output_valid;
    input [2*FPGA_FIFO_COUNT-1:0] border_output_ready;

    input [GT_FIFO_SIZE-1:0] control_to_handler_data;
    input control_to_handler_valid;
    output reg control_to_handler_ready;

    output reg [GT_FIFO_SIZE-1:0] handler_to_control_data;
    output reg handler_to_control_valid;
    input handler_to_control_ready;
    
    input [7:0] fpga_id;
    output router_busy;

    // we buffer the in_data using a FIFO
    wire [GT_FIFO_SIZE-1 : 0] in_data_buffered;
    wire in_valid_buffered;
    reg in_ready_buffered;

    assign router_busy = |border_input_valid;

    fifo_wrapper #(
        .WIDTH(GT_FIFO_SIZE),
        .DEPTH(64)
    ) in_data_buffer (
        .clk(clk),
        .reset(reset),
        .input_data(in_data),
        .input_valid(in_valid),
        .input_ready(in_ready),
        .output_data(in_data_buffered),
        .output_valid(in_valid_buffered),
        .output_ready(in_ready_buffered)
    );

    // we buffer the out_data using a FIFO
    reg [GT_FIFO_SIZE-1 : 0] out_data_buffered;
    reg out_valid_buffered;
    wire out_ready_buffered;

    fifo_wrapper #(
        .WIDTH(GT_FIFO_SIZE),
        .DEPTH(64)
    ) out_data_buffer (
        .clk(clk),
        .reset(reset),
        .input_data(out_data_buffered),
        .input_valid(out_valid_buffered),
        .input_ready(out_ready_buffered),
        .output_data(out_data),
        .output_valid(out_valid),
        .output_ready(out_ready)
    );

    // we use a combiner to filter the data_to_be_send_to_hub

    wire [GT_FIFO_SIZE-1:0] northern_border_input_data;
    wire northern_border_input_valid;
    reg northern_border_input_ready;

    simple_combiner #(
        .NUM_CHANNELS(FPGA_FIFO_COUNT),
        .CHANNEL_WIDTH_IN(FPGA_FIFO_SIZE),
        .CHANNEL_WIDTH_OUT(GT_FIFO_SIZE),
        .TAG_MSB(FIFO_TAG_MSB),
        .TAG_LSB(FIFO_TAG_LSB)
    ) north_combiner (
        .clk(clk),
        .reset(reset),

        .in_data(border_input_data[FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0]),
        .in_valid(border_input_valid[FPGA_FIFO_COUNT-1:0]),
        .in_ready(border_input_ready[FPGA_FIFO_COUNT-1:0]),

        .out_data(northern_border_input_data),
        .out_valid(northern_border_input_valid),
        .out_ready(northern_border_input_ready)
    );

    wire [GT_FIFO_SIZE-1:0] southern_border_input_data;
    wire southern_border_input_valid;
    reg southern_border_input_ready;

    simple_combiner #(
        .NUM_CHANNELS(FPGA_FIFO_COUNT),
        .CHANNEL_WIDTH_IN(FPGA_FIFO_SIZE),
        .CHANNEL_WIDTH_OUT(GT_FIFO_SIZE),
        .TAG_MSB(FIFO_TAG_MSB),
        .TAG_LSB(FIFO_TAG_LSB)
    ) south_combiner (
        .clk(clk),
        .reset(reset),

        .in_data(border_input_data[2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:FPGA_FIFO_SIZE*FPGA_FIFO_COUNT]),
        .in_valid(border_input_valid[2*FPGA_FIFO_COUNT-1:FPGA_FIFO_COUNT]),
        .in_ready(border_input_ready[2*FPGA_FIFO_COUNT-1:FPGA_FIFO_COUNT]),

        .out_data(southern_border_input_data),
        .out_valid(southern_border_input_valid),
        .out_ready(southern_border_input_ready)
    );

    reg north_fpga_id;
    reg south_fpga_id;
    reg [GT_FIFO_SIZE - 1 : 0] modified_northern_border_input_data;
    reg [GT_FIFO_SIZE -1 : 0] modified_southern_border_input_data;

    always @(posedge clk) begin
        if (reset) begin
            north_fpga_id <= 0;
            south_fpga_id <= 0;
        end else begin
            north_fpga_id <= fpga_id - 1;
            south_fpga_id <= fpga_id + 1;
        end
    end

    always @(*) begin
        modified_northern_border_input_data = northern_border_input_data;
        modified_southern_border_input_data = southern_border_input_data;
        modified_northern_border_input_data[63:56] = north_fpga_id;
        modified_southern_border_input_data[63:56] = south_fpga_id;
        modified_northern_border_input_data[FIFO_TAG_MSB+1] = 1'b0;
        modified_southern_border_input_data[FIFO_TAG_MSB+1] = 1'b1;
    end

    always@(*) begin
        out_data_buffered = modified_northern_border_input_data;
        out_valid_buffered = 1'b0;
        northern_border_input_ready = 1'b0;
        southern_border_input_ready = 1'b0;
        control_to_handler_ready = 1'b0;
        if (out_ready_buffered) begin
            if(northern_border_input_valid) begin
                out_data_buffered = modified_northern_border_input_data;
                out_valid_buffered = 1'b1;
                northern_border_input_ready = 1'b1;
            end else if(southern_border_input_valid) begin
                out_data_buffered = modified_southern_border_input_data;
                out_valid_buffered = 1'b1;
                southern_border_input_ready = 1'b1;
            end else if(control_to_handler_valid) begin
                out_data_buffered = control_to_handler_data;
                out_valid_buffered = 1'b1;
                control_to_handler_ready = 1'b1;
            end
        end 
    end

    // we use a splitter to filter the direction of incoming data
    
    reg [GT_FIFO_SIZE-1:0] northern_border_output_data;
    reg northern_border_output_valid;
    wire northern_border_output_ready;

    reg [GT_FIFO_SIZE-1:0] southern_border_output_data;
    reg southern_border_output_valid;
    wire southern_border_output_ready;

    always@(*) begin
        northern_border_output_data = in_data_buffered;
        northern_border_output_valid = 1'b0;
        southern_border_output_data = in_data_buffered;
        southern_border_output_valid = 1'b0;
        handler_to_control_data = in_data_buffered;
        handler_to_control_valid = 1'b0;
        if(in_valid_buffered) begin
            if(in_data_buffered[55:48] == 8'hff) begin
                handler_to_control_valid = 1'b1;
                in_ready_buffered = handler_to_control_ready;
            end else if(in_data_buffered[FIFO_TAG_MSB+1] == 1'b0) begin
                northern_border_output_valid = 1'b1;
                in_ready_buffered = 1'b1;
            end else if(in_data_buffered[FIFO_TAG_MSB+1] == 1'b1) begin
                southern_border_output_valid = 1'b1;
                in_ready_buffered = 1'b1;
            end
        end
    end

    simple_splitter #(
        .NUM_CHANNELS(FPGA_FIFO_COUNT),
        .CHANNEL_WIDTH_IN(GT_FIFO_SIZE),
        .CHANNEL_WIDTH_OUT(FPGA_FIFO_SIZE),
        .TAG_MSB(FIFO_TAG_MSB),
        .TAG_LSB(FIFO_TAG_LSB)
    ) north_splitter (
        .clk(clk),
        .reset(reset),

        .in_data(northern_border_output_data),
        .in_valid(northern_border_output_valid),
        .in_ready(northern_border_output_ready),

        .out_data(border_output_data[FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:0]),
        .out_valid(border_output_valid[FPGA_FIFO_COUNT-1:0]),
        .out_ready(border_output_ready[FPGA_FIFO_COUNT-1:0])
    );

    simple_splitter #(
        .NUM_CHANNELS(FPGA_FIFO_COUNT),
        .CHANNEL_WIDTH_IN(GT_FIFO_SIZE),
        .CHANNEL_WIDTH_OUT(FPGA_FIFO_SIZE),
        .TAG_MSB(FIFO_TAG_MSB),
        .TAG_LSB(FIFO_TAG_LSB)
    ) south_splitter (
        .clk(clk),
        .reset(reset),

        .in_data(southern_border_output_data),
        .in_valid(southern_border_output_valid),
        .in_ready(southern_border_output_ready),

        .out_data(border_output_data[2*FPGA_FIFO_SIZE*FPGA_FIFO_COUNT-1:FPGA_FIFO_SIZE*FPGA_FIFO_COUNT]),
        .out_valid(border_output_valid[2*FPGA_FIFO_COUNT-1:FPGA_FIFO_COUNT]),
        .out_ready(border_output_ready[2*FPGA_FIFO_COUNT-1:FPGA_FIFO_COUNT])
    );

endmodule