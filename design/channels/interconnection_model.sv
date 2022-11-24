module interonncetion_model #(
    parameter WIDTH = 128,
    parameter CHANNELS = 4,
    parameter LATENCY = 1
) (
    clk,
    reset,

    upstream_fifo_out_data,
    upstream_fifo_out_valid,
    upstream_fifo_out_ready,
    upstream_fifo_in_data,
    upstream_fifo_in_valid,
    upstream_fifo_in_ready,

    downstream_fifo_out_data,
    downstream_fifo_out_valid,
    downstream_fifo_out_ready,
    downstream_fifo_in_data,
    downstream_fifo_in_valid,
    downstream_fifo_in_ready,

    upstream_has_message_flying,
    upstream_has_odd_clusters,

    downstream_has_message_flying,
    downstream_has_odd_clusters,
);

`include "../../parameters/parameters.sv"


input clk;
input reset;

output [WIDTH*CHANNELS - 1 :0] upstream_fifo_out_data;
output reg [CHANNELS - 1 :0] upstream_fifo_out_valid;
input [CHANNELS - 1 :0] upstream_fifo_out_ready;
input [WIDTH*CHANNELS - 1 :0] upstream_fifo_in_data;
input [CHANNELS - 1 :0] upstream_fifo_in_valid;
output [CHANNELS - 1 :0]upstream_fifo_in_ready;

output [WIDTH*CHANNELS - 1 :0] downstream_fifo_out_data;
output reg [CHANNELS - 1 :0] downstream_fifo_out_valid;
input [CHANNELS - 1 :0] downstream_fifo_out_ready;
input [WIDTH*CHANNELS - 1 :0] downstream_fifo_in_data;
input [CHANNELS - 1 :0] downstream_fifo_in_valid;
output [CHANNELS - 1 :0] downstream_fifo_in_ready;

output reg [CHANNELS - 1 :0] upstream_has_message_flying;
output reg [CHANNELS - 1 :0] upstream_has_odd_clusters;

input [CHANNELS - 1 :0] downstream_has_message_flying;
input [CHANNELS - 1 :0] downstream_has_odd_clusters;

reg[31:0] counter;

always@(posedge clk) begin
    if (reset) begin
        counter <= 0;
    end else begin
        counter <= counter + 32'b1;
    end
end

wire [31:0] read_counter;
assign read_counter = counter + LATENCY;

genvar i;
generate
    if(LATENCY > 0) begin
        for(i=0;i<CHANNELS;i=i+1) begin
            wire interconnect_fifo_up_full;
            wire interconnect_fifo_up_empty;
            wire [31:0] read_counter_returned_up;
            assign downstream_fifo_in_ready[i] = !interconnect_fifo_up_full;

            reg interconnect_fifo_up_rd_en;

            always@(*) begin
                if(!interconnect_fifo_up_empty && read_counter_returned_up <= counter) begin
                    upstream_fifo_out_valid[i] = 1'b1;
                end else begin
                    upstream_fifo_out_valid[i] = 1'b0;
                end
                if(!interconnect_fifo_up_empty && read_counter_returned_up <= counter) begin
                    interconnect_fifo_up_rd_en = upstream_fifo_out_ready[i];
                end else begin
                    interconnect_fifo_up_rd_en = 1'b0;
                end
            end

            fifo_fwft #(.DEPTH(128), .WIDTH(WIDTH + 32)) u_interconnect_fifo_up 
                (
                .clk(clk),
                .srst(reset),
                .wr_en(downstream_fifo_in_valid[i]),
                .din({downstream_fifo_in_data[(i+1)*WIDTH - 1 : i*WIDTH], read_counter}),
                .full(interconnect_fifo_up_full),
                .empty(interconnect_fifo_up_empty),
                .dout({upstream_fifo_out_data[(i+1)*WIDTH - 1 : i*WIDTH], read_counter_returned_up}),
                .rd_en(interconnect_fifo_up_rd_en)
            );

            wire interconnect_fifo_dwn_full;
            wire interconnect_fifo_dwn_empty;
            wire [31:0] read_counter_returned_dwn;
            assign upstream_fifo_in_ready[i] = !interconnect_fifo_dwn_full;

            reg interconnect_fifo_dwn_rd_en;

            always@(*) begin
                if(!interconnect_fifo_dwn_empty && read_counter_returned_dwn <= counter) begin
                    downstream_fifo_out_valid[i] = 1'b1;
                end else begin
                    downstream_fifo_out_valid[i] = 1'b0;
                end
                if(!interconnect_fifo_dwn_empty && read_counter_returned_dwn <= counter) begin
                    interconnect_fifo_dwn_rd_en = downstream_fifo_out_ready[i];
                end else begin
                    interconnect_fifo_dwn_rd_en = 1'b0;
                end
            end

            fifo_fwft #(.DEPTH(128), .WIDTH(WIDTH + 32)) interconnect_fifo_dwn 
                (
                .clk(clk),
                .srst(reset),
                .wr_en(upstream_fifo_in_valid[i]),
                .din({upstream_fifo_in_data[(i+1)*WIDTH - 1 : i*WIDTH], read_counter}),
                .full(interconnect_fifo_dwn_full),
                .empty(interconnect_fifo_dwn_empty),
                .dout({downstream_fifo_out_data[(i+1)*WIDTH - 1 : i*WIDTH], read_counter_returned_dwn}),
                .rd_en(interconnect_fifo_dwn_rd_en)
            );
        end

        reg [CHANNELS - 1 :0] upstream_has_message_flying_d;
        reg [CHANNELS - 1 :0] upstream_has_odd_clusters_d;
        always@(posedge clk) begin
            if(reset) begin
                upstream_has_message_flying <= 0;
                upstream_has_message_flying_d <= 0;
                upstream_has_odd_clusters <= 0;
                upstream_has_odd_clusters_d <= 0;
            end else begin
                upstream_has_message_flying_d <= downstream_has_message_flying;
                upstream_has_message_flying <= upstream_has_message_flying_d;
                upstream_has_odd_clusters <= upstream_has_odd_clusters_d;
                upstream_has_odd_clusters_d <= downstream_has_odd_clusters;
            end
        end
    end else begin
        assign upstream_fifo_out_data = downstream_fifo_in_data;
        assign downstream_fifo_in_ready = upstream_fifo_out_ready;
        assign downstream_fifo_out_data = upstream_fifo_in_data;
        assign upstream_fifo_in_ready = downstream_fifo_out_ready;

        always@(*) begin
            upstream_fifo_out_valid = downstream_fifo_in_valid;
            downstream_fifo_out_valid = upstream_fifo_in_valid;
            upstream_has_message_flying = downstream_has_message_flying;
            upstream_has_odd_clusters = downstream_has_odd_clusters;
        end
    end

endgenerate

// assign upstream_fifo_out_data = downstream_fifo_in_data;
// assign upstream_fifo_out_valid = downstream_fifo_in_valid;
// assign downstream_fifo_in_ready = upstream_fifo_out_ready;
// assign downstream_fifo_out_data = upstream_fifo_in_data;
// assign downstream_fifo_out_valid = upstream_fifo_in_valid;
// assign upstream_fifo_in_ready = downstream_fifo_out_ready;



// assign upstream_has_message_flying = downstream_has_message_flying;
// assign upstream_has_odd_clusters = downstream_has_odd_clusters;

endmodule