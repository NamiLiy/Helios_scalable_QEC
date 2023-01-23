module arm_communicator (
    clk,
    reset,
    new_round_start,
    result_valid,
    total_test_case_counter,
    downstream_busy,
    duration,
    error_detected,
    we,
    en,
    addr,
    di,
    dout
);

input clk;
input reset;
output reg new_round_start;
input result_valid;
output reg[31:0] total_test_case_counter;
input [31:0] duration;
input error_detected;
input downstream_busy;


parameter reset_threshold = 32'hb0000000; // This is around 30s
parameter number_of_runs = 32'd10000;
reg [1:0] stage;
reg [31:0] reset_counter;



output reg [3:0] we;
output en;
output reg [31:0] addr;
output reg [31:0] di;
input [31:0] dout;

reg [31:0] old_read_val;
reg result_valid_delayed;

assign en = 1'b1;

    
always@(posedge clk) begin
    if (reset) begin
        reset_counter <= 32'b0;
        stage <= 0;
        new_round_start <= 0;
        result_valid_delayed <= 0;
    end else begin
        result_valid_delayed <= result_valid;
        if (stage == 0) begin
            reset_counter <= reset_counter + 32'b1;
            if(reset_counter >= reset_threshold && !downstream_busy) begin
                stage <= 1;
                new_round_start <= 1;
            end
        end else if (stage == 1) begin
            reset_counter <= 32'b0;
            new_round_start <= 0;
            if(result_valid == 1 && result_valid_delayed == 0) begin
                if(total_test_case_counter < number_of_runs) begin
                    stage <= 2;
                end else begin
                    stage <= 3;
                end
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

always@(posedge clk) begin
    if (reset) begin
        total_test_case_counter <= 32'b0;
    end else begin
        if(new_round_start == 1'b1) begin
            total_test_case_counter <= total_test_case_counter + 1;
        end
    end
end

reg [2:0] mem_stage;

always@(posedge clk) begin
    if (reset) begin
        mem_stage <= 0;
    end else begin
        if (mem_stage == 0) begin
            if(stage == 1 && result_valid == 1 && new_round_start == 0) begin
                mem_stage <= 1;
            end
        end else if (mem_stage == 1) begin
            old_read_val <= dout;
            mem_stage <= 2;
        end else if (mem_stage == 2) begin
           if(stage == 3) begin
                mem_stage <= 3;
           end else begin
                mem_stage <= 0;
           end
        end else if (mem_stage ==3) begin
            mem_stage<=4;
        end 
    end
end

always@(*) begin
    we = 0;
    addr = 32'b0;
    di = 32'b0;
    if (mem_stage == 0) begin
       addr = duration*4;     
    end else if (mem_stage == 1) begin
        addr = duration*4;
    end else if (mem_stage == 2) begin
//       if(duration < 128) begin
            di = old_read_val + 32'b1;
//       end else begin
//           di[23:0] = old_read_val[23:0] + 24'b1;
//           if(error_detected) begin
//            di[31:24] = old_read_val[31:24] + 24'b1;
//           end else begin
//            di[31:24] = old_read_val[31:24];
//           end
//       end
       we = 4'b1111;
       addr = duration*4;
    end else if (mem_stage == 3) begin
       di = 32'hffffffff;
       we = 4'b1111;
       addr = 32'b0;
    end
end

endmodule