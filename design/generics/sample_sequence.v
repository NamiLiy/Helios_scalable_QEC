module sample_sequence (
    clk,
    reset,
    input_level,
    output_sample,
    output_pulse
);

    input clk;
    input reset;
    input input_level;
    output reg output_pulse;
    output reg [63:0] output_sample;

    reg [1:0] state;

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= 2'b00;
            output_pulse <= 1'b0;
            output_sample <= 64'b0;
        end else begin
            case (state)
                2'b00: begin
                    if (input_level) begin
                        state <= 2'b01;
                    end
                    output_pulse <= 1'b0;
                    output_sample <= 64'b0;
                end
                2'b01: begin
                    if (output_sample >= 64'd63) begin
                        state <= 2'b10;
                    end
                    output_pulse <= 1'b1;
                    output_sample <= output_sample + 1;
                end
                2'b10: begin
                    if(!input_level) begin
                        state <= 2'b00;
                    end
                    output_sample <= 64'b0;
                    output_pulse <= 1'b0;
                end
            endcase
        end
    end
    
endmodule