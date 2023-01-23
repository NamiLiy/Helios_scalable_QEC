start_gui
create_project hub_0 /home/heterofpga/hub_0 -part xczu7ev-ffvc1156-2-e
set_property board_part xilinx.com:zcu106:part0:2.6 [current_project]
set_property board_part xilinx.com:zcu106:part0:2.6 [current_project]

create_bd_design "loopback"

update_compile_order -fileset sources_1

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
endgroup
set_property -dict [list CONFIG.PRIM_SOURCE {Differential_clock_capable_pin}] [get_bd_cells clk_wiz_0]

startgroup
set_property -dict [list CONFIG.RESET_BOARD_INTERFACE {reset}] [get_bd_cells clk_wiz_0]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
endgroup

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0
endgroup
set_property location {0.5 -168 -565} [get_bd_cells util_vector_logic_0]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells util_vector_logic_0]
connect_bd_net [get_bd_pins util_vector_logic_0/Res] [get_bd_pins proc_sys_reset_0/ext_reset_in]
startgroup
make_bd_pins_external  [get_bd_pins util_vector_logic_0/Op1]
endgroup
set_property name ext_reset [get_bd_ports Op1_0]

add_files -norecurse -scan_for_includes /home/heterofpga/Xilinx/Vitis/2022.1/scripts/simple_reset/simple_reset.srcs/sources_1/new/simple_reset.v
update_compile_order -fileset sources_1
create_bd_cell -type module -reference simple_reset simple_reset_0

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {user_si570_sysclk ( User Programmable differential clock ) } Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]

apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_0/reset]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins simple_reset_0/clk]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins simple_reset_0/reset_n]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:zynq_ultra_ps_e:3.4 zynq_ultra_ps_e_0
endgroup
apply_bd_automation -rule xilinx.com:bd_rule:zynq_ultra_ps_e -config {apply_board_preset "1" }  [get_bd_cells zynq_ultra_ps_e_0] 
set_property -dict [list CONFIG.PSU__USE__M_AXI_GP1 {0}] [get_bd_cells zynq_ultra_ps_e_0]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
endgroup
set_property -dict [list CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_0]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/S00_AXI] [get_bd_intf_pins zynq_ultra_ps_e_0/M_AXI_HPM0_FPD]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1
endgroup
set_property location {3 1131 -90} [get_bd_cells proc_sys_reset_1]
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl:4.1 axi_bram_ctrl_0
endgroup
set_property -dict [list CONFIG.SINGLE_PORT_BRAM {1}] [get_bd_cells axi_bram_ctrl_0]


connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_resetn0] [get_bd_pins proc_sys_reset_1/ext_reset_in]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins proc_sys_reset_1/slowest_sync_clk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins zynq_ultra_ps_e_0/maxihpm0_fpd_aclk]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_bram_ctrl_0/s_axi_aclk]
connect_bd_net [get_bd_pins proc_sys_reset_1/interconnect_aresetn] [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] [get_bd_pins axi_bram_ctrl_0/s_axi_aresetn]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins zynq_ultra_ps_e_0/pl_clk0] [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_intf_net -boundary_type upper [get_bd_intf_pins axi_interconnect_0/M00_AXI] [get_bd_intf_pins axi_bram_ctrl_0/S_AXI]
regenerate_bd_layout

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen:8.4 blk_mem_gen_0
endgroup
WARNING: [IP_Flow 19-4067] Ignoring invalid widget type specified checkbox.Providing a default widget
WARNING: [IP_Flow 19-4067] Ignoring invalid widget type specified checkbox.Providing a default widget
set_property -dict [list CONFIG.Memory_Type {True_Dual_Port_RAM} CONFIG.Enable_B {Use_ENB_Pin} CONFIG.Use_RSTB_Pin {true} CONFIG.Port_B_Clock {100} CONFIG.Port_B_Write_Rate {50} CONFIG.Port_B_Enable_Rate {100}] [get_bd_cells blk_mem_gen_0]
set_property location {3 1243 -59} [get_bd_cells blk_mem_gen_0]
connect_bd_intf_net [get_bd_intf_pins axi_bram_ctrl_0/BRAM_PORTA] [get_bd_intf_pins blk_mem_gen_0/BRAM_PORTA]

startgroup
make_bd_pins_external  [get_bd_pins simple_reset_0/light]
endgroup

assign_bd_address -target_address_space /zynq_ultra_ps_e_0/Data [get_bd_addr_segs axi_bram_ctrl_0/S_AXI/Mem0] -force

create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0
set_property -dict [list CONFIG.C_BUF_TYPE {BUFG}] [get_bd_cells util_ds_buf_0]
copy_bd_objs /  [get_bd_cells {util_ds_buf_0}]
set_property location {1 631 991} [get_bd_cells util_ds_buf_1]
copy_bd_objs /  [get_bd_cells {util_ds_buf_1}]
set_property location {1 541 1079} [get_bd_cells util_ds_buf_2]
copy_bd_objs /  [get_bd_cells {util_ds_buf_2}]
set_property location {1 607 1186} [get_bd_cells util_ds_buf_3]
copy_bd_objs /  [get_bd_cells {util_ds_buf_3}]
set_property location {1 637 1296} [get_bd_cells util_ds_buf_4]
copy_bd_objs /  [get_bd_cells {util_ds_buf_4}]
set_property location {1 672 1410} [get_bd_cells util_ds_buf_5]

startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_0/BUFG_O]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_1/BUFG_O]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_2/BUFG_O]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_3/BUFG_O]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_4/BUFG_O]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_5/BUFG_O]
endgroup

copy_bd_objs /  [get_bd_cells {util_ds_buf_0 util_ds_buf_1 util_ds_buf_2 util_ds_buf_3 util_ds_buf_4 util_ds_buf_5}]
startgroup
make_bd_pins_external  [get_bd_pins util_ds_buf_9/BUFG_I] [get_bd_pins util_ds_buf_11/BUFG_I] [get_bd_pins util_ds_buf_7/BUFG_I] [get_bd_pins util_ds_buf_6/BUFG_I] [get_bd_pins util_ds_buf_10/BUFG_I] [get_bd_pins util_ds_buf_8/BUFG_I]
endgroup

delete_bd_objs [get_bd_nets BUFG_I_3_1] [get_bd_nets util_ds_buf_6_BUFG_O] [get_bd_cells util_ds_buf_6]
delete_bd_objs [get_bd_nets BUFG_I_2_1] [get_bd_nets util_ds_buf_7_BUFG_O] [get_bd_cells util_ds_buf_7]
delete_bd_objs [get_bd_nets BUFG_I_5_1] [get_bd_nets util_ds_buf_8_BUFG_O] [get_bd_cells util_ds_buf_8]
delete_bd_objs [get_bd_nets BUFG_I_0_1] [get_bd_nets util_ds_buf_9_BUFG_O] [get_bd_cells util_ds_buf_9]
delete_bd_objs [get_bd_nets BUFG_I_4_1] [get_bd_nets util_ds_buf_10_BUFG_O] [get_bd_cells util_ds_buf_10]
delete_bd_objs [get_bd_nets BUFG_I_1_1] [get_bd_nets util_ds_buf_11_BUFG_O] [get_bd_cells util_ds_buf_11]

save_bd_design