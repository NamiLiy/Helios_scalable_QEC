module single_port_ram
(
	data,
	addr,
	we, 
    clk,
	q
);

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 6;
    parameter RAM_DEPTH = 64;

    input [DATA_WIDTH - 1:0] data;
	input [ADDR_WIDTH - 1:0] addr;
	input we; 
    input clk;
	output [DATA_WIDTH - 1:0] q;
    
	// Declare the RAM variable
	reg [DATA_WIDTH -1 :0] ram[RAM_DEPTH - 1:0];
	
	// Variable to hold the registered read address
	reg [5:0] addr_reg;
	
	always @ (posedge clk)
	begin
	// Write
		if (we)
			ram[addr] <= data;
		
		addr_reg <= addr;
		
	end
		
	// Continuous assignment implies read returns NEW data.
	// This is the natural behavior of the TriMatrix memory
	// blocks in Single Port mode.  
	assign q = ram[addr_reg];
	
endmodule