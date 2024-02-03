module support_neighbor_link #(
) (
    clk,
    reset,
    global_stage,
    fully_grown,
    fully_grown_in
);

`include "../../parameters/parameters.sv"

input clk;
input reset;
input [STAGE_WIDTH-1:0] global_stage;

output reg fully_grown;
input fully_grown_in;

reg [STAGE_WIDTH - 1 : 0] stage;
reg [STAGE_WIDTH - 1 : 0] last_stage;

// stage is always equal to global_stage
always@(posedge clk) begin
    if(reset) begin
        stage <= STAGE_IDLE;
        last_stage <= STAGE_IDLE;
    end else begin
        stage <= global_stage;
        last_stage <= stage;
    end
end

always@(posedge clk) begin
    if(reset) begin
        fully_grown <= 0;
    end else begin
        if(stage == STAGE_WRITE_TO_MEM) begin
            fully_grown <= fully_grown_in;
        end
    end
end

endmodule


