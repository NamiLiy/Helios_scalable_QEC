module router #(
    parameter NUM_CHANNELS = 2,
    parameter CHANNEL_WIDTH = 64,
    parameter DEST_WIDTH = 8
) (
    clk,
    reset,

    rx_data,
    rx_valid,
    rx_ready,

    tx_data,
    tx_valid,
    tx_ready
);

    input clk;
    input reset;

    output reg [CHANNEL_WIDTH*NUM_CHANNELS-1 : 0] tx_data;
    output reg [NUM_CHANNELS-1 : 0] tx_valid;
    input [NUM_CHANNELS-1 : 0] tx_ready;

    input [CHANNEL_WIDTH*NUM_CHANNELS-1 : 0] rx_data;
    input [NUM_CHANNELS-1 : 0] rx_valid;
    output reg [NUM_CHANNELS-1 : 0] rx_ready;
    

    reg [$clog2(NUM_CHANNELS)-1 : 0] selected_idx;
    
    integer i;
    
    always @(*) begin
        selected_idx = 0; // default value if 'in' is all 0's
        for (i=NUM_CHANNELS; i>=0; i=i-1) begin
            if (rx_valid[i]) begin
                selected_idx = i;
            end
        end
    end
    
    wire selected_valid;
    wire [63:0] selected_data;
    wire [DEST_WIDTH-1:0] dest;

    assign selected_valid = rx_valid[selected_idx];
    assign selected_data = rx_data[CHANNEL_WIDTH*selected_idx+:CHANNEL_WIDTH];
    assign dest = selected_data[CHANNEL_WIDTH - 1 :CHANNEL_WIDTH - DEST_WIDTH];

    always @(*) begin
        for (i=NUM_CHANNELS; i>=0; i=i-1) begin
            tx_data[CHANNEL_WIDTH*i +: CHANNEL_WIDTH] = selected_data;
            if(selected_valid) begin
                if(dest == 8'hff) begin
                    if(&tx_ready) begin
                        tx_valid[i] = i != selected_idx;
                        rx_ready[i] = (i == selected_idx ? 1'b1 : 1'b0);
                    end else begin
                        tx_valid[i] = 1'b0;
                        rx_ready[i] = 1'b0;
                    end
                end else begin
                    tx_valid[i] = (dest == i);
                    rx_ready[i] = (i == selected_idx && tx_ready[dest] == 1'b1)? 1'b1 : 1'b0;
                end
            end else begin
                tx_valid[i] = 0;
                rx_ready[i] = 0;
            end
        end
    end
endmodule
