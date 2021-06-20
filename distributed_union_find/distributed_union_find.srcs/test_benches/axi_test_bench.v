`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 06/20/2021 12:58:57 AM
// Design Name: 
// Module Name: temp_test_bench
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module axi_test_bench(

    );
    
    localparam integer C_S00_AXI_DATA_WIDTH	= 32;
	localparam integer C_S00_AXI_ADDR_WIDTH	= 6;
	
	reg  s00_axi_aclk;
		reg  s00_axi_aresetn;
		reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr;
		reg [2 : 0] s00_axi_awprot;
		reg  s00_axi_awvalid;
		wire  s00_axi_awready;
		reg [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata;
		reg [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb;
		reg  s00_axi_wvalid;
		wire  s00_axi_wready;
		wire [1 : 0] s00_axi_bresp;
		wire  s00_axi_bvalid;
		reg  s00_axi_bready;
		reg [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr;
		reg [2 : 0] s00_axi_arprot;
		reg  s00_axi_arvalid;
		wire  s00_axi_arready;
		wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata;
		wire [1 : 0] s00_axi_rresp;
		 wire  s00_axi_rvalid;
		reg  s00_axi_rready;
		
   always 
begin
    s00_axi_aclk = 1'b1; 
    #5; // high for 20 * timescale = 20 ns

    s00_axi_aclk = 1'b0;
    #5; // low for 20 * timescale = 20 ns
end

initial begin
    s00_axi_aresetn <= 1'b0;
    s00_axi_awaddr <= 0;
    s00_axi_awprot <= 0;
    s00_axi_awvalid <= 0;
    s00_axi_wdata <= 0;
    s00_axi_wstrb <= 4'b1111;
    s00_axi_wvalid <= 0;
    s00_axi_bready <= 1;
    s00_axi_araddr <= 0;
    s00_axi_arprot <= 0;
    s00_axi_arvalid <= 0;
    s00_axi_rready <= 1;
    #112;
    s00_axi_aresetn <= 1'b1;
    #100;
    s00_axi_awaddr <= 32'h4;
    s00_axi_wdata <= 32'b110;
    s00_axi_awvalid <= 1;
    s00_axi_wvalid <= 1;
    #20;
    s00_axi_awvalid <= 0;
    s00_axi_wvalid <= 0;
    #100;
    s00_axi_awaddr <= 32'h0;
    s00_axi_wdata <= 32'b1;
    s00_axi_awvalid <= 1;
    s00_axi_wvalid <= 1;
    #20;
    s00_axi_awvalid <= 0;
    s00_axi_wvalid <= 0;
    #100;
end
    
		
    qec_3_axi_v1_0 # ( 
		.C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
		.C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
	) qec_3_axi_v1_0_inst (
		.s00_axi_aclk(s00_axi_aclk),
		.s00_axi_aresetn(s00_axi_aresetn),
		.s00_axi_awaddr(s00_axi_awaddr),
		.s00_axi_awprot(s00_axi_awprot),
		.s00_axi_awvalid(s00_axi_awvalid),
		.s00_axi_awready(s00_axi_awready),
		.s00_axi_wdata(s00_axi_wdata),
		.s00_axi_wstrb(s00_axi_wstrb),
		.s00_axi_wvalid(s00_axi_wvalid),
		.s00_axi_wready(s00_axi_wready),
		.s00_axi_bresp(s00_axi_bresp),
		.s00_axi_bvalid(s00_axi_bvalid),
		.s00_axi_bready(s00_axi_bready),
		.s00_axi_araddr(s00_axi_araddr),
		.s00_axi_arprot(s00_axi_arprot),
		.s00_axi_arvalid(s00_axi_arvalid),
		.s00_axi_arready(s00_axi_arready),
		.s00_axi_rdata(s00_axi_rdata),
		.s00_axi_rresp(s00_axi_rresp),
		.s00_axi_rvalid(s00_axi_rvalid),
		.s00_axi_rready(s00_axi_rready)
	);
endmodule
