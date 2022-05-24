module routing_table_/*$$ID*/(
    dest_fpga_id,
     destination_index
);

localparam FPGAID_WIDTH = /*$$FPGAID_WIDTH*/;
localparam DOWNSTREAM_FIFO_COUNT = /*$$DOWNSTREAM_FIFO_COUNT*/;

input [FPGAID_WIDTH-1 : 0] dest_fpga_id;
output reg [DOWNSTREAM_FIFO_COUNT : 0] destination_index;

always@(*) begin
    case(dest_fpga_id)
        

