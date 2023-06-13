//`timescale 1ns / 10ps //siona added

module serializer#(
    parameter HUB_FIFO_WIDTH = 32,
    parameter HUB_FIFO_PHYSICAL_WIDTH = 8 //this should exclude valid and ready or out of band signals
)(
    clk,
    reset,
    wide_fifo_data,
    wide_fifo_valid,
    wide_fifo_ready,
    narrow_fifo_valid,
    narrow_fifo_ready,
    narrow_fifo_data
);


localparam MUX_MAX_VALUE = (HUB_FIFO_WIDTH + HUB_FIFO_PHYSICAL_WIDTH - 1) / HUB_FIFO_PHYSICAL_WIDTH;

input clk;
input reset;
input [HUB_FIFO_WIDTH-1 : 0] wide_fifo_data;
input wide_fifo_valid;
output reg wide_fifo_ready;
output [HUB_FIFO_PHYSICAL_WIDTH-1 : 0] narrow_fifo_data;
output narrow_fifo_valid;
input narrow_fifo_ready;

generate
  if (HUB_FIFO_PHYSICAL_WIDTH < HUB_FIFO_WIDTH) begin

    reg intermediate_out_valid_reg;
    reg [7:0] mux_counter;
    reg [HUB_FIFO_WIDTH-1 : 0] intermediate_out_data_reg;

    always@(posedge clk) begin
        if (reset) begin
            mux_counter <= 0;
        end else begin
            if(intermediate_out_valid_reg && narrow_fifo_ready && mux_counter == MUX_MAX_VALUE-1) begin
                mux_counter <= 0;
            end else if(intermediate_out_valid_reg && narrow_fifo_ready) begin
                mux_counter <= mux_counter + 32'b1;
            end
        end
    end

    always@(posedge clk) begin
        if (reset) begin
            intermediate_out_valid_reg <= 0;
        end else begin
            if(!intermediate_out_valid_reg && mux_counter == 0) begin
                intermediate_out_valid_reg <= wide_fifo_valid;
            end else if (intermediate_out_valid_reg && narrow_fifo_ready && mux_counter == MUX_MAX_VALUE-1) begin
                intermediate_out_valid_reg <= 0; //changed to get rid of multiple output_valids in one cycle
            end 
        end
    end

    always@(posedge clk) begin
        if(!intermediate_out_valid_reg && mux_counter == 0) begin
            intermediate_out_data_reg <= wide_fifo_data;
        end else if (intermediate_out_valid_reg && narrow_fifo_ready && mux_counter == MUX_MAX_VALUE-1) begin
            intermediate_out_data_reg <= wide_fifo_data;
        end else if (intermediate_out_valid_reg && narrow_fifo_ready) begin
            intermediate_out_data_reg <= intermediate_out_data_reg << HUB_FIFO_PHYSICAL_WIDTH;
        end
    end

    always@(*) begin
        if (reset) begin
            wide_fifo_ready = 0;
        end else begin
            if(!intermediate_out_valid_reg) begin
                wide_fifo_ready = 1;
            end else begin
                if(narrow_fifo_ready && mux_counter == MUX_MAX_VALUE-1) begin
                    wide_fifo_ready = 1;
                end else begin
                    wide_fifo_ready = 0;
                end
            end
        end
    end

    assign narrow_fifo_data = intermediate_out_data_reg[HUB_FIFO_WIDTH - 1 : HUB_FIFO_WIDTH - HUB_FIFO_PHYSICAL_WIDTH];
    assign narrow_fifo_valid = intermediate_out_valid_reg;
  end
  else begin
    assign narrow_fifo_valid = wide_fifo_valid;
    assign narrow_fifo_data = wide_fifo_data;

    always@(*) begin
        wide_fifo_ready = narrow_fifo_ready;
    end

  end
endgenerate 

endmodule

module deserializer#(
    parameter HUB_FIFO_WIDTH = 32,
    parameter HUB_FIFO_PHYSICAL_WIDTH = 8 //this should exclude valid and ready or out of band signals
)(
    clk,
    reset,
    wide_fifo_data,
    wide_fifo_valid,
    wide_fifo_ready,
    narrow_fifo_valid,
    narrow_fifo_ready,
    narrow_fifo_data
);

localparam MUX_MAX_VALUE = (HUB_FIFO_WIDTH + HUB_FIFO_PHYSICAL_WIDTH - 1) / HUB_FIFO_PHYSICAL_WIDTH;
localparam INTERMEDIATE_FIFO_WIDTH = HUB_FIFO_PHYSICAL_WIDTH*MUX_MAX_VALUE;

input clk;
input reset;
output [HUB_FIFO_WIDTH-1 : 0] wide_fifo_data;
output reg wide_fifo_valid;
input wide_fifo_ready;
input [HUB_FIFO_PHYSICAL_WIDTH-1 : 0] narrow_fifo_data;
input narrow_fifo_valid;
output reg narrow_fifo_ready;

generate
  if (HUB_FIFO_PHYSICAL_WIDTH < HUB_FIFO_WIDTH) begin

    reg [7:0] mux_counter;
    reg [INTERMEDIATE_FIFO_WIDTH -1 : 0] intermediate_out_data_reg;

    always@(posedge clk) begin
        if (reset) begin
            mux_counter <= 0;
        end else begin
            if(mux_counter == MUX_MAX_VALUE) begin
                if(wide_fifo_ready && narrow_fifo_valid) begin
                    mux_counter <= 1;
                end else if(wide_fifo_ready) begin
                    mux_counter <= 0;
                end
            end else begin
                if(narrow_fifo_valid) begin
                    mux_counter <= mux_counter + 32'b1;
                end
            end
        end
    end

    always@(*) begin
        if(mux_counter == MUX_MAX_VALUE) begin
            wide_fifo_valid = 1'b1;
        end else begin
            wide_fifo_valid = 1'b0;
        end
    end

    always@(posedge clk) begin
        if(mux_counter == MUX_MAX_VALUE) begin
            if(wide_fifo_ready) begin
                intermediate_out_data_reg <= narrow_fifo_data;
            end
        end else if (narrow_fifo_valid) begin
            intermediate_out_data_reg[INTERMEDIATE_FIFO_WIDTH-1:HUB_FIFO_PHYSICAL_WIDTH] <= intermediate_out_data_reg[INTERMEDIATE_FIFO_WIDTH-HUB_FIFO_PHYSICAL_WIDTH-1:0];
            intermediate_out_data_reg[HUB_FIFO_PHYSICAL_WIDTH-1:0] <= narrow_fifo_data;
        end
    end

    always@(*) begin
        narrow_fifo_ready = 1;
        if(mux_counter == MUX_MAX_VALUE) begin
            if(!wide_fifo_ready) begin
                narrow_fifo_ready = 0;
            end
        end
    end

    assign wide_fifo_data = intermediate_out_data_reg[INTERMEDIATE_FIFO_WIDTH -1 : INTERMEDIATE_FIFO_WIDTH-HUB_FIFO_WIDTH];
  end else begin
    assign wide_fifo_data = narrow_fifo_data;

    always@(*) begin
        wide_fifo_valid = narrow_fifo_valid;
        narrow_fifo_ready = wide_fifo_ready;
    end
  end
endgenerate

endmodule

