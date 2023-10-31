`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/28/2022 07:08:59 PM
// Design Name: 
// Module Name: ram
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


module rams_sp_nc (clk, we, en, addr, di, dout);

parameter DEPTH = 1023*4;
parameter WIDTH = 32;

localparam LOG_DEPTH = $clog2(DEPTH);

input clk;

input we;

input en;

input [LOG_DEPTH-1:0] addr;

input [WIDTH-1:0] di;

output [WIDTH-1:0] dout;

 

reg [WIDTH-1:0] RAM [DEPTH-1:0];

reg [WIDTH-1:0] dout;

integer j;
initial 
  for(j = 0; j < 1023*4; j = j+1) 
    RAM[j] = 32'b0;

 

always @(posedge clk)

begin

 if (en)

 begin

   if (we)

     RAM[addr] <= di;

   else

     dout <= RAM[addr];

 end

end


////  RAMB36E2   : In order to incorporate this function into the design,
////   Verilog   : the following instance declaration needs to be placed
////  instance   : in the body of the design code.  The instance name
//// declaration : (RAMB36E2_inst) and/or the port declarations within the
////    code     : parenthesis may be changed to properly reference and
////             : connect this function to the design.  All inputs
////             : and outputs must be connected.

////  <-----Cut code below this line---->

//   // RAMB36E2: 36K-bit Configurable Synchronous Block RAM
//   //           Virtex UltraScale+
//   // Xilinx HDL Language Template, version 2022.1

//   RAMB36E2 #(
//      // CASCADE_ORDER_A, CASCADE_ORDER_B: "FIRST", "MIDDLE", "LAST", "NONE" 
//      .CASCADE_ORDER_A("NONE"),
//      .CASCADE_ORDER_B("NONE"),
//      // CLOCK_DOMAINS: "COMMON", "INDEPENDENT" 
//      .CLOCK_DOMAINS("INDEPENDENT"),
//      // Collision check: "ALL", "GENERATE_X_ONLY", "NONE", "WARNING_ONLY" 
//      .SIM_COLLISION_CHECK("ALL"),
//      // DOA_REG, DOB_REG: Optional output register (0, 1)
//      .DOA_REG(1),
//      .DOB_REG(1),
//      // ENADDRENA/ENADDRENB: Address enable pin enable, "TRUE", "FALSE" 
//      .ENADDRENA("FALSE"),
//      .ENADDRENB("FALSE"),
//      // EN_ECC_PIPE: ECC pipeline register, "TRUE"/"FALSE" 
//      .EN_ECC_PIPE("FALSE"),
//      // EN_ECC_READ: Enable ECC decoder, "TRUE"/"FALSE" 
//      .EN_ECC_READ("FALSE"),
//      // EN_ECC_WRITE: Enable ECC encoder, "TRUE"/"FALSE" 
//      .EN_ECC_WRITE("FALSE"),
//      // INITP_00 to INITP_0F: Initial contents of parity memory array
//      .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INITP_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      // INIT_00 to INIT_7F: Initial contents of data memory array
//      .INIT_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_10(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_11(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_12(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_13(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_14(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_15(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_16(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_17(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_18(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_19(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_1A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_1B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_1C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_1D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_1E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_1F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_20(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_21(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_22(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_23(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_24(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_25(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_26(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_27(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_28(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_29(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_2A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_2B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_2C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_2D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_2E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_2F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_30(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_31(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_32(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_33(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_34(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_35(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_36(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_37(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_38(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_39(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_3A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_3B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_3C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_3D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_3E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_3F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_40(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_41(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_42(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_43(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_44(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_45(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_46(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_47(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_48(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_49(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_4A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_4B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_4C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_4D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_4E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_4F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_50(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_51(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_52(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_53(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_54(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_55(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_56(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_57(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_58(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_59(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_5A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_5B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_5C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_5D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_5E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_5F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_60(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_61(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_62(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_63(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_64(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_65(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_66(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_67(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_68(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_69(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_6A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_6B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_6C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_6D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_6E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_6F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_70(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_71(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_72(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_73(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_74(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_75(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_76(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_77(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_78(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_79(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_7A(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_7B(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_7C(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_7D(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_7E(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      .INIT_7F(256'h0000000000000000000000000000000000000000000000000000000000000000),
//      // INIT_A, INIT_B: Initial values on output ports
//      .INIT_A(36'h000000000),
//      .INIT_B(36'h000000000),
//      // Initialization File: RAM initialization file
//      .INIT_FILE("NONE"),
//      // Programmable Inversion Attributes: Specifies the use of the built-in programmable inversion
//      .IS_CLKARDCLK_INVERTED(1'b0),
//      .IS_CLKBWRCLK_INVERTED(1'b0),
//      .IS_ENARDEN_INVERTED(1'b0),
//      .IS_ENBWREN_INVERTED(1'b0),
//      .IS_RSTRAMARSTRAM_INVERTED(1'b0),
//      .IS_RSTRAMB_INVERTED(1'b0),
//      .IS_RSTREGARSTREG_INVERTED(1'b0),
//      .IS_RSTREGB_INVERTED(1'b0),
//      // RDADDRCHANGE: Disable memory access when output value does not change ("TRUE", "FALSE")
//      .RDADDRCHANGEA("FALSE"),
//      .RDADDRCHANGEB("FALSE"),
//      // READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
//      .READ_WIDTH_A(0),                                                                 // 0-9
//      .READ_WIDTH_B(0),                                                                 // 0-9
//      .WRITE_WIDTH_A(0),                                                                // 0-9
//      .WRITE_WIDTH_B(0),                                                                // 0-9
//      // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG", "REGCE")
//      .RSTREG_PRIORITY_A("RSTREG"),
//      .RSTREG_PRIORITY_B("RSTREG"),
//      // SRVAL_A, SRVAL_B: Set/reset value for output
//      .SRVAL_A(36'h000000000),
//      .SRVAL_B(36'h000000000),
//      // Sleep Async: Sleep function asynchronous or synchronous ("TRUE", "FALSE")
//      .SLEEP_ASYNC("FALSE"),
//      // WriteMode: "WRITE_FIRST", "NO_CHANGE", "READ_FIRST" 
//      .WRITE_MODE_A("NO_CHANGE"),
//      .WRITE_MODE_B("NO_CHANGE") 
//   )
//   RAMB36E2_inst (
////      // Cascade Signals outputs: Multi-BRAM cascade signals
////      .CASDOUTA(CASDOUTA),               // 32-bit output: Port A cascade output data
////      .CASDOUTB(CASDOUTB),               // 32-bit output: Port B cascade output data
////      .CASDOUTPA(CASDOUTPA),             // 4-bit output: Port A cascade output parity data
////      .CASDOUTPB(CASDOUTPB),             // 4-bit output: Port B cascade output parity data
////      .CASOUTDBITERR(CASOUTDBITERR),     // 1-bit output: DBITERR cascade output
////      .CASOUTSBITERR(CASOUTSBITERR),     // 1-bit output: SBITERR cascade output
////      // ECC Signals outputs: Error Correction Circuitry ports
////      .DBITERR(DBITERR),                 // 1-bit output: Double bit error status
////      .ECCPARITY(ECCPARITY),             // 8-bit output: Generated error correction parity
////      .RDADDRECC(RDADDRECC),             // 9-bit output: ECC Read Address
////      .SBITERR(SBITERR),                 // 1-bit output: Single bit error status
////      // Port A Data outputs: Port A data
//      .DOUTADOUT(dout),             // 32-bit output: Port A Data/LSB data
////      .DOUTPADOUTP(DOUTPADOUTP),         // 4-bit output: Port A parity/LSB parity
////      // Port B Data outputs: Port B data
////      .DOUTBDOUT(DOUTBDOUT),             // 32-bit output: Port B data/MSB data
////      .DOUTPBDOUTP(DOUTPBDOUTP),         // 4-bit output: Port B parity/MSB parity
////      // Cascade Signals inputs: Multi-BRAM cascade signals
////      .CASDIMUXA(CASDIMUXA),             // 1-bit input: Port A input data (0=DINA, 1=CASDINA)
////      .CASDIMUXB(CASDIMUXB),             // 1-bit input: Port B input data (0=DINB, 1=CASDINB)
////      .CASDINA(CASDINA),                 // 32-bit input: Port A cascade input data
////      .CASDINB(CASDINB),                 // 32-bit input: Port B cascade input data
////      .CASDINPA(CASDINPA),               // 4-bit input: Port A cascade input parity data
////      .CASDINPB(CASDINPB),               // 4-bit input: Port B cascade input parity data
////      .CASDOMUXA(CASDOMUXA),             // 1-bit input: Port A unregistered data (0=BRAM data, 1=CASDINA)
////      .CASDOMUXB(CASDOMUXB),             // 1-bit input: Port B unregistered data (0=BRAM data, 1=CASDINB)
////      .CASDOMUXEN_A(CASDOMUXEN_A),       // 1-bit input: Port A unregistered output data enable
////      .CASDOMUXEN_B(CASDOMUXEN_B),       // 1-bit input: Port B unregistered output data enable
////      .CASINDBITERR(CASINDBITERR),       // 1-bit input: DBITERR cascade input
////      .CASINSBITERR(CASINSBITERR),       // 1-bit input: SBITERR cascade input
////      .CASOREGIMUXA(CASOREGIMUXA),       // 1-bit input: Port A registered data (0=BRAM data, 1=CASDINA)
////      .CASOREGIMUXB(CASOREGIMUXB),       // 1-bit input: Port B registered data (0=BRAM data, 1=CASDINB)
////      .CASOREGIMUXEN_A(CASOREGIMUXEN_A), // 1-bit input: Port A registered output data enable
////      .CASOREGIMUXEN_B(CASOREGIMUXEN_B), // 1-bit input: Port B registered output data enable
////      // ECC Signals inputs: Error Correction Circuitry ports
////      .ECCPIPECE(ECCPIPECE),             // 1-bit input: ECC Pipeline Register Enable
////      .INJECTDBITERR(INJECTDBITERR),     // 1-bit input: Inject a double-bit error
////      .INJECTSBITERR(INJECTSBITERR),
////      // Port A Address/Control Signals inputs: Port A address and control signals
//      .ADDRARDADDR({4'b0,addr}),         // 15-bit input: A/Read port address
//      .ADDRENA(1'b1),                 // 1-bit input: Active-High A/Read port address enable
//      .CLKARDCLK(clk),             // 1-bit input: A/Read port clock
//      .ENARDEN(1'b1),                 // 1-bit input: Port A enable/Read enable
////      .REGCEAREGCE(REGCEAREGCE),         // 1-bit input: Port A register enable/Register enable
////      .RSTRAMARSTRAM(RSTRAMARSTRAM),     // 1-bit input: Port A set/reset
////      .RSTREGARSTREG(RSTREGARSTREG),     // 1-bit input: Port A register set/reset
////      .SLEEP(SLEEP),                     // 1-bit input: Sleep Mode
//      .WEA(we),                         // 4-bit input: Port A write enable
////      // Port A Data inputs: Port A data
//      .DINADIN(din),                 // 32-bit input: Port A data/LSB data
////      .DINPADINP(DINPADINP),             // 4-bit input: Port A parity/LSB parity
////      // Port B Address/Control Signals inputs: Port B address and control signals
////      .ADDRBWRADDR(ADDRBWRADDR),         // 15-bit input: B/Write port address
//      .ADDRENB(1'b0),                 // 1-bit input: Active-High B/Write port address enable
//      .CLKBWRCLK(clk),             // 1-bit input: B/Write port clock
////      .ENBWREN(ENBWREN),                 // 1-bit input: Port B enable/Write enable
////      .REGCEB(REGCEB),                   // 1-bit input: Port B register enable
////      .RSTRAMB(RSTRAMB),                 // 1-bit input: Port B set/reset
////      .RSTREGB(RSTREGB),                 // 1-bit input: Port B register set/reset
//      .WEBWE(1'b0)                     // 8-bit input: Port B write enable/Write enable
////      // Port B Data inputs: Port B data
////      .DINBDIN(DINBDIN),                 // 32-bit input: Port B data/MSB data
//   );

   // End of RAMB36E2_inst instantiation

endmodule