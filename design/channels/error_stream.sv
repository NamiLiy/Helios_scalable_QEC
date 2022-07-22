module error_stream(
    clk,
    reset,
    s0_initial,
    s1_initial,
    update_errors,
    update_valid,
    error_stream
);

parameter MEASUREMENT_ROUNDS = 5;

localparam BIT_WIDTH = 64;

input clk;
input reset;
input update_errors;
output update_valid;
output reg [MEASUREMENT_ROUNDS - 1 : 0]  error_stream;
input [BIT_WIDTH - 1 : 0] s0_initial;
input [BIT_WIDTH - 1 : 0] s1_initial;

reg [31:0] counter;
reg result_valid;
reg [BIT_WIDTH - 1 : 0] r;
reg next_u64;
reg [1:0] state;

rand_gen_stage rg(
    .s0_initial(s0_initial),
    .s1_initial(s1_initial),
    .s0_new(),
    .s1_new(),
    .r(r),
    .next_u64(next_u64),
    .valid(result_valid),
    .clk(clk),
    .reset(reset)
);

always@(posedge clk) begin
    if(reset) begin
        state <= 2'b0;
        counter <= 0;
    end else begin
        case(state)
            2'b00: begin //reset state
                state <= 2'b1;
                counter <= 0;
            end
            2'b01: begin //single pulse state
                state <= 2'b10;
                counter <= 0;
            end
            2'b10: begin
                if(result_valid) begin
                    counter <= counter + 1;
                end
                if(counter == MEASUREMENT_ROUNDS - 1) begin
                    state <= 2'b11;
                end
            end
            2'b11: begin
                if(update_errors) begin
                    state <= 2'b1;
                end
            end
        endcase
    end
end

assign update_valid = state == 2'b11 ? 1 : 0;


always@(*) begin
    if(state == 2'b1) begin
        next_u64 = 1'b1;
    end else if(state == 2'b10) begin
        next_u64 = result_valid;
    end else begin
        next_u64 = 0;
    end
end



always@(posedge clk) begin
    if(result_valid) begin
        error_stream[counter] <= (r[63:54] == 10'b0) ? 1 : 0;
    end
end

endmodule