module level_to_pulse (
    clk,
    reset,
    input_level,
    output_pulse
);

    input clk;
    input reset;
    input input_level;
    output reg output_pulse;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 2'b00;
            output_pulse <= 1'b0;
        end else begin
            case (state)
                2'b00: begin
                    if (input_level) begin
                        state <= 2'b01;
                    end
                    output_pulse <= 1'b0;
                end
                2'b01: begin
                    state <= 2'b10;
                    output_pulse <= 1'b1;
                end
                2'b10: begin
                    if(!input_level) begin
                        state <= 2'b00;
                    end
                    output_pulse <= 1'b0;
                end
            endcase
        end
    end
    
endmodule