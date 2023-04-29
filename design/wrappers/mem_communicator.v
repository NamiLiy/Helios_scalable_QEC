module mem_communicator (
    clk,
    reset,
    we,
    en,
    addr,
    di,
    dout,
    to_helios_data,
    to_helios_valid,
    to_helios_ready,
    from_helios_data,
    from_helios_valid,
    from_helios_ready
);

input clk;
input reset;
output reg [3:0] we;
output en;
output reg [31:0] addr;
output reg [31:0] di;
input [31:0] dout;

output reg [7:0] to_helios_data;
output reg to_helios_valid;
input to_helios_ready;

input [7:0] from_helios_data;
input from_helios_valid;
output reg from_helios_ready;

reg [3:0] stage;

assign en = 1'b1;
reg [15:0] number_of_messages;
reg [15:0] number_of_returns;

reg [31:0] addr_saved;

always @(posedge clk) begin
    if (reset) begin
        stage <= 0;
        addr_saved <= 0;
    end else begin
        addr_saved <= addr;
        case (stage)
            0: begin
                if(dout == 32'h00000001) begin
                    stage <= 1;
                end
            end
            1: begin
                stage <= 2;
            end
            2: begin
                stage <= 3;
                number_of_messages <= dout[15:0];
                number_of_returns <= dout[31:16];
            end
            3: begin
                number_of_messages <= number_of_messages - 1;
                if(number_of_messages == 1) begin
                    stage <= 4;
                end
            end
            4: begin
                if(from_helios_valid) begin
                    stage <= 5;
                end
            end
            5: begin
                if(number_of_returns == 1) begin
                    stage <= 6;
                end
                if(from_helios_valid) begin
                    number_of_returns <= number_of_returns - 1;
                end
            end
            6: begin
                stage <= 7;
            end
            7: begin
                stage <= 0;
            end
        endcase
    end
end



always@(*) begin
    di = 32'h00000000;
    addr = addr_saved;
    we = 4'b0000;
    to_helios_data = 8'h00;
    to_helios_valid = 1'b0;
    from_helios_ready = 1'b0;
    case (stage)
        0: begin
            addr = 32'h00000000;
        end
        1: begin
            addr = 32'h00000004;
        end
        2: begin
            addr = 32'h00000008;
        end
        3: begin
            addr = addr_saved + 32'h00000004;
            to_helios_data = dout[7:0];
            to_helios_valid = 1'b1;
        end
        5: begin
            from_helios_ready = 1'b1;
            if(from_helios_valid) begin
                addr = addr_saved + 32'h00000004;
                di = {24'b0, from_helios_data};
                we = 4'b1111;
            end else begin
                addr = addr_saved;
            end
        end
        6: begin
            di = 32'h00000002;
            addr = 32'h00000000;
            we = 4'b1111;
        end
    endcase
end

endmodule