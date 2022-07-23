module arm_communicator (
    clk,
    reset,
    new_round_start,
    result_valid,
    total_test_case_counter
);

input clk;
input reset;
output reg new_round_start;
input result_valid;
output reg[31:0] total_test_case_counter;

parameter reset_threshold = 32'hb0000000; // This is around 30s
reg [1:0] stage;
reg [31:0] reset_counter;

reg[31:0] total_test_case_counter;
    
always@(posedge clk) begin
    if (reset) begin
        reset_counter <= 32'b0;
        stage <= 0;
        new_round_start <= 0;
        total_test_case_counter <= 32'b0;
    end else begin
        if (stage == 0) begin
            reset_counter <= reset_counter + 32'b1;
            if(reset_counter >= reset_threshold) begin
                stage <= 1;
                new_round_start <= 1;
            end
        end else if (stage == 1) begin
            reset_counter <= 32'b0;
            new_round_start <= 0;
            if(result_valid == 1) begin
                stage <= 2;
                total_test_case_counter <= total_test_case_counter + 1;
            end
        end else if(stage == 2)begin
            reset_counter <= reset_counter + 32'b1;
            if(reset_counter >= 32'd10) begin
                stage <= 1;
                new_round_start <= 1;
            end
        end
    end
end

endmodule