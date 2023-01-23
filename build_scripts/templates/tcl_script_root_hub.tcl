start_gui
create_project simple_loopback /home/heterofpga/hub_1 -part xc7vx485tffg1157-1
set_property board_part xilinx.com:zcu106:part0:2.6 [current_project]

create_bd_design "loopback"

update_compile_order -fileset sources_1

add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/generated/decoder_stage_controller_master_0.sv /home/heterofpga/Desktop/qec_hardware/design/generated/top_module_hub_0.sv /home/heterofpga/Desktop/qec_hardware/design/generated/root_hub.sv}
update_compile_order -fileset sources_1
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/generics/fifo_fwft.v /home/heterofpga/Desktop/qec_hardware/design/channels/serdes.sv /home/heterofpga/Desktop/qec_hardware/design/generated/routing_table_.0.sv /home/heterofpga/Desktop/qec_hardware/design/channels/blocking_channel.sv /home/heterofpga/Desktop/qec_hardware/design/stage_controller/get_boundry_cardinality_3d.sv}
update_compile_order -fileset sources_1
create_bd_cell -type module -reference root_hub_0 root_hub_0_0
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_pins /root_hub_0_0/reset]

create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_1
set_property -dict [list CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] [get_bd_cells util_vector_logic_1]
set_property -dict [list CONFIG.C_SIZE {1}] [get_bd_cells util_vector_logic_1]

connect_bd_net [get_bd_pins simple_reset_0/reset_delayed_n] [get_bd_pins util_vector_logic_1/Op1]
connect_bd_net [get_bd_pins util_vector_logic_1/Res] [get_bd_pins root_hub_0_0/reset]

add_files -norecurse -scan_for_includes /home/heterofpga/Desktop/qec_hardware/design/channels/simple_rand_setter.v
update_compile_order -fileset sources_1
create_bd_cell -type module -reference arm_communicator arm_communicator_0
set_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_pins /arm_communicator_0/reset]

connect_bd_net [get_bd_pins arm_communicator_0/reset] [get_bd_pins util_vector_logic_1/Res]
connect_bd_net [get_bd_pins arm_communicator_0/clk] [get_bd_pins root_hub_0_0/clk]
connect_bd_net [get_bd_pins root_hub_0_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins root_hub_0_0/new_round_start] [get_bd_pins arm_communicator_0/new_round_start]
connect_bd_net [get_bd_pins arm_communicator_0/result_valid] [get_bd_pins root_hub_0_0/result_valid]
connect_bd_net [get_bd_pins root_hub_0_0/upstream_has_message_flying] [get_bd_pins arm_communicator_0/downstream_busy]
connect_bd_net [get_bd_pins blk_mem_gen_0/addrb] [get_bd_pins arm_communicator_0/addr]
connect_bd_net [get_bd_pins blk_mem_gen_0/clkb] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins blk_mem_gen_0/dinb] [get_bd_pins arm_communicator_0/di]
connect_bd_net [get_bd_pins blk_mem_gen_0/doutb] [get_bd_pins arm_communicator_0/dout]
connect_bd_net [get_bd_pins blk_mem_gen_0/enb] [get_bd_pins arm_communicator_0/en]
connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_reset] [get_bd_pins blk_mem_gen_0/rstb]
connect_bd_net [get_bd_pins blk_mem_gen_0/web] [get_bd_pins arm_communicator_0/we]


make_wrapper -files [get_files /home/heterofpga/hub_0/hub_0.srcs/sources_1/bd/loopback/loopback.bd] -top
add_files -norecurse /home/heterofpga/hub_0/hub_0.gen/sources_1/bd/loopback/hdl/loopback_wrapper.v
update_compile_order -fileset sources_1
set_property top loopback_wrapper [current_fileset]
update_compile_order -fileset sources_1

generate_target all [get_files  /home/heterofpga/hub_0/hub_0.srcs/sources_1/bd/loopback/loopback.bd]
launch_runs synth_1 -jobs 4

# Add constraints file

# temp file for convenience
#....
startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
INFO: [xilinx.com:ip:ila:6.2-6] /ila_0: Xilinx recommends using the System ILA IP in IP Integrator. The System ILA IP is functionally equivalent to an ILA and offers additional benefits in debugging interfaces both within IP Integrator and the Hardware Manager. Consult the Programming and Debug User Guide UG908 for further details.
endgroup
set_property location {4 1210 687} [get_bd_cells ila_0]
WARNING: [IP_Flow 19-4067] Ignoring invalid widget type specified checkbox.Providing a default widget
set_property -dict [list CONFIG.C_NUM_OF_PROBES {6} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_0]
connect_bd_net [get_bd_pins ila_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins arm_communicator_0/en] [get_bd_pins ila_0/probe0]
connect_bd_net [get_bd_pins arm_communicator_0/we] [get_bd_pins ila_0/probe1]
connect_bd_net [get_bd_pins arm_communicator_0/addr] [get_bd_pins ila_0/probe2]
connect_bd_net [get_bd_pins arm_communicator_0/di] [get_bd_pins ila_0/probe3]
connect_bd_net [get_bd_pins ila_0/probe4] [get_bd_pins root_hub_0_0/result_valid]
connect_bd_net [get_bd_pins ila_0/probe5] [get_bd_pins blk_mem_gen_0/doutb]
WARNING: [IP_Flow 19-4067] Ignoring invalid widget type specified checkbox.Providing a default widget
startgroup
set_property -dict [list CONFIG.C_NUM_OF_PROBES {7}] [get_bd_cells ila_0]
endgroup
connect_bd_net [get_bd_pins ila_0/probe6] [get_bd_pins arm_communicator_0/new_round_start]
WARNING: [IP_Flow 19-4067] Ignoring invalid widget type specified checkbox.Providing a default widget
startgroup
set_property -dict [list CONFIG.C_PROBE5_TYPE {1} CONFIG.C_PROBE3_TYPE {1} CONFIG.C_PROBE5_WIDTH {32} CONFIG.C_PROBE3_WIDTH {32}] [get_bd_cells ila_0]
endgroup
WARNING: [IP_Flow 19-4067] Ignoring invalid widget type specified checkbox.Providing a default widget
startgroup
set_property -dict [list CONFIG.C_PROBE2_TYPE {1} CONFIG.C_PROBE2_WIDTH {32} CONFIG.C_PROBE1_WIDTH {4}] [get_bd_cells ila_0]
endgroup