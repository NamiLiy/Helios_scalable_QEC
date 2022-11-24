start_gui
create_project simple_loopback /home/heterofpga/leaf_7 -part xc7vx485tffg1157-1
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

# Add the design here
# add_files -norecurse -scan_for_includes /home/heterofpga/Xilinx/Vitis/2022.1/scripts/simple_reset/simple_reset.srcs/sources_1/new/loopback_file.v

file mkdir /home/heterofpga/leaf_3/leaf_3.srcs/sources_1/new
close [ open /home/heterofpga/leaf_3/leaf_3.srcs/sources_1/new/loopback_leaf_3.v w ]
add_files /home/heterofpga/leaf_3/leaf_3.srcs/sources_1/new/loopback_leaf_3.v
update_compile_order -fileset sources_1

add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/channels/interconnection_model.sv /home/heterofpga/Desktop/qec_hardware/design/channels/rand_generator.sv /home/heterofpga/Desktop/qec_hardware/design/channels/serdes.sv /home/heterofpga/Desktop/qec_hardware/design/generics/fifo_fwft.v /home/heterofpga/Desktop/qec_hardware/design/channels/final_arbitration.sv /home/heterofpga/Desktop/qec_hardware/design/channels/nonoblockingchannel_fifo.sv /home/heterofpga/Desktop/qec_hardware/design/pe/processing_unit.sv /home/heterofpga/Desktop/qec_hardware/design/channels/blocking_channel.sv {/home/heterofpga/Desktop/qec_hardware/design/channels/final_arbitration _ll_connected.sv} /home/heterofpga/Desktop/qec_hardware/design/channels/neighbor_link.sv /home/heterofpga/Desktop/qec_hardware/design/stage_controller/get_boundry_cardinality_3d.sv /home/heterofpga/Desktop/qec_hardware/design/generics/many_to_one_mux.sv /home/heterofpga/Desktop/qec_hardware/design/channels/simple_rand_setter.sv /home/heterofpga/Desktop/qec_hardware/design/generics/tree_compare_solver.sv /home/heterofpga/Desktop/qec_hardware/design/channels/error_stream.sv /home/heterofpga/Desktop/qec_hardware/design/channels/neigbor_link_fifo.sv /home/heterofpga/Desktop/qec_hardware/design/generated/decoder_stage_controller_dummy_3.sv /home/heterofpga/Desktop/qec_hardware/design/generated/top_module_for_leaf_3.sv /home/heterofpga/Desktop/qec_hardware/design/generated/rand_gen_top.sv /home/heterofpga/Desktop/qec_hardware/design/channels/nonblocking_channel.sv /home/heterofpga/Desktop/qec_hardware/design/generics/ram.sv /home/heterofpga/Desktop/qec_hardware/design/generated/standard_planar_code_2d_3.sv /home/heterofpga/Desktop/qec_hardware/design/channels/pu_arbitration.sv /home/heterofpga/Desktop/qec_hardware/design/generics/tree_distance_3d_solver.sv}
update_compile_order -fileset sources_1


update_compile_order -fileset sources_1
create_bd_cell -type module -reference loopback_file loopback_file_0

startgroup
# apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {user_si570_sysclk ( User Programmable differential clock ) } Manual_Source {Auto}}  [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
apply_bd_automation -rule xilinx.com:bd_rule:board -config { Board_Interface {reset ( FPGA Reset ) } Manual_Source {New External Port (ACTIVE_HIGH)}}  [get_bd_pins clk_wiz_0/reset]
apply_bd_automation -rule xilinx.com:bd_rule:clkrst -config { Clk {/clk_wiz_0/clk_out1 (100 MHz)} Freq {100} Ref_Clk0 {} Ref_Clk1 {} Ref_Clk2 {}}  [get_bd_pins simple_reset_0/clk]
endgroup

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins simple_reset_0/reset_n]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_0
endgroup

startgroup
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {5} CONFIG.Output_Data_Width {5} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_bd_cells fifo_generator_0]
endgroup



startgroup
make_bd_pins_external  [get_bd_pins fifo_generator_0/din]
endgroup
set_property name input_data [get_bd_ports din_0]
startgroup
make_bd_pins_external  [get_bd_pins fifo_generator_0/wr_en]
endgroup
copy_bd_objs /  [get_bd_cells {util_vector_logic_0}]
set_property location {0.5 -297 -751} [get_bd_cells util_vector_logic_1]
connect_bd_net [get_bd_pins fifo_generator_0/full] [get_bd_pins util_vector_logic_1/Op1]
startgroup
make_bd_pins_external  [get_bd_pins util_vector_logic_1/Res]
endgroup
set_property name input_valid [get_bd_ports wr_en_0]
set_property name input_ready [get_bd_ports Res_0]

copy_bd_objs /  [get_bd_cells {util_vector_logic_1}]
connect_bd_net [get_bd_pins util_vector_logic_2/Op1] [get_bd_pins fifo_generator_0/empty]
connect_bd_net [get_bd_pins util_vector_logic_2/Res] [get_bd_pins loopback_file_0/input_valid]
connect_bd_net [get_bd_pins fifo_generator_0/dout] [get_bd_pins loopback_file_0/input_line]
connect_bd_net [get_bd_pins fifo_generator_0/rd_en] [get_bd_pins loopback_file_0/input_ready]

connect_bd_net [get_bd_pins simple_reset_0/reset_delayed_n] [get_bd_pins loopback_file_0/reset_n]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_ready]
endgroup
set_property name output_ready [get_bd_ports output_ready_0]
connect_bd_net [get_bd_pins loopback_file_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_line]
endgroup
set_property name output_data [get_bd_ports output_line_0]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_valid]
endgroup
set_property name output_valid [get_bd_ports output_valid_0]

connect_bd_net [get_bd_pins fifo_generator_0/srst] [get_bd_pins proc_sys_reset_0/peripheral_reset]

connect_bd_net [get_bd_pins fifo_generator_0/rd_clk] [get_bd_pins clk_wiz_0/clk_out1]
disconnect_bd_net /clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1]
startgroup
make_bd_pins_external  [get_bd_pins clk_wiz_0/clk_out1]
endgroup
connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins clk_wiz_0/clk_out1]

startgroup
make_bd_pins_external  [get_bd_pins simple_reset_0/light]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
endgroup

set_property -dict [list CONFIG.C_PROBE2_TYPE {1} CONFIG.C_PROBE0_TYPE {1} CONFIG.C_PROBE2_WIDTH {5} CONFIG.C_PROBE0_WIDTH {5} CONFIG.C_NUM_OF_PROBES {5} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_0]
connect_bd_net [get_bd_pins fifo_generator_0/dout] [get_bd_pins ila_0/probe0]
connect_bd_net [get_bd_pins util_vector_logic_2/Res] [get_bd_pins ila_0/probe1]
connect_bd_net [get_bd_pins loopback_file_0/output_line] [get_bd_pins ila_0/probe2]
connect_bd_net [get_bd_pins loopback_file_0/output_valid] [get_bd_pins ila_0/probe3]
connect_bd_net [get_bd_ports input_valid] [get_bd_pins ila_0/probe4]
connect_bd_net [get_bd_pins ila_0/clk] [get_bd_pins clk_wiz_0/clk_out1]

startgroup
make_bd_intf_pins_external  [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
endgroup
connect_bd_net [get_bd_pins fifo_generator_0/wr_clk] [get_bd_pins clk_wiz_0/clk_out1]

startgroup
set_property -dict [list CONFIG.PRIM_IN_FREQ.VALUE_SRC USER] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.PRIM_IN_FREQ {100} CONFIG.CLKIN1_JITTER_PS {100.0} CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} CONFIG.MMCM_CLKIN1_PERIOD {10.000} CONFIG.MMCM_CLKIN2_PERIOD {10.000} CONFIG.CLKOUT1_JITTER {115.831} CONFIG.CLKOUT1_PHASE_ERROR {87.180}] [get_bd_cells clk_wiz_0]
endgroup
set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_ports /CLK_IN1_D_0]

startgroup
set_property CONFIG.FREQ_HZ 100000000 [get_bd_intf_ports /CLK_IN1_D_0]
set_property -dict [list CONFIG.PRIM_IN_FREQ.VALUE_SRC USER] [get_bd_cells clk_wiz_0]
set_property -dict [list CONFIG.PRIM_SOURCE {Differential_clock_capable_pin} CONFIG.PRIM_IN_FREQ {100.000} CONFIG.CLKIN1_JITTER_PS {100.0} CONFIG.MMCM_CLKFBOUT_MULT_F {12.000} CONFIG.MMCM_CLKIN1_PERIOD {10.000} CONFIG.MMCM_CLKIN2_PERIOD {10.000} CONFIG.CLKOUT1_JITTER {115.831} CONFIG.CLKOUT1_PHASE_ERROR {87.180}] [get_bd_cells clk_wiz_0]
endgroup

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/has_message_flying]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/has_odd_clusters]
endgroup

regenerate_bd_layout

## Use this or

add_files -fileset constrs_1 -norecurse /home/heterofpga/simple_loopback/simple_loopback.srcs/constrs_1/new/constraints_loopback.xdc
set_property target_constrs_file /home/heterofpga/simple_loopback/simple_loopback.srcs/constrs_1/new/constraints_loopback.xdc [current_fileset -constrset]

## this

add_files -fileset constrs_1 -norecurse /home/heterofpga/simple_loopback_support/simple_loopback.srcs/constrs_1/new/constraints.xdc
set_property target_constrs_file /home/heterofpga/simple_loopback_support/simple_loopback.srcs/constrs_1/new/constraints.xdc [current_fileset -constrset]



# This line has an issue
make_wrapper -files [get_files /home/heterofpga/simple_loopback/simple_loopback.srcs/sources_1/bd/loopback/loopback.bd] -top
