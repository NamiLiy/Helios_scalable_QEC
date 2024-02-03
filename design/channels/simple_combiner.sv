// E Pluribus Unum
// Verilog source selecting one of multiple input channels to output.

module simple_combiner #(
    parameter NUM_CHANNELS = 2,
    parameter CHANNEL_WIDTH_IN = 32,
    parameter CHANNEL_WIDTH_OUT = 64,
    parameter TAG_MSB = 55,
    parameter TAG_LSB = 48
) (
    clk,
    reset,

    in_data,
    in_valid,
    in_ready,

    out_data,
    out_valid,
    out_ready
);

    input clk;
    input reset;

    input [CHANNEL_WIDTH_IN*NUM_CHANNELS-1 : 0] in_data;
    input [NUM_CHANNELS-1 : 0] in_valid;
    output reg [NUM_CHANNELS-1 : 0] in_ready;

    output reg  [CHANNEL_WIDTH_OUT-1 : 0] out_data;
    output reg out_valid;
    input out_ready;
    

    reg [$clog2(NUM_CHANNELS)-1 : 0] selected_idx;
    
    integer i;
    
    always @(*) begin
        selected_idx = 0; // default value if 'in' is all 0's
        for (i=NUM_CHANNELS; i>=0; i=i-1) begin
            if (in_valid[i]) begin
                selected_idx = i;
            end
        end
    end
    
    wire selected_valid;
    wire [CHANNEL_WIDTH_IN-1:0] selected_data;

    assign selected_valid = in_valid[selected_idx];
    assign selected_data = in_data[CHANNEL_WIDTH_IN*selected_idx+:CHANNEL_WIDTH_IN];

    always @(*) begin
        out_data = 64'b0;
        out_data[CHANNEL_WIDTH_IN -1 : 0] = selected_data;
        out_data[TAG_MSB : TAG_LSB] = selected_idx;
        out_valid = selected_valid;
        for (i=NUM_CHANNELS; i>=0; i=i-1) begin            
            if(selected_valid) begin
                in_ready[i] = (i == selected_idx && out_ready == 1'b1)? 1'b1 : 1'b0;
            end else begin
                in_ready[i] = 1'b0;
            end
        end
    end
endmodule