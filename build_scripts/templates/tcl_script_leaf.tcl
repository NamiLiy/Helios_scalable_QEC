add_files -norecurse -scan_for_includes /home/heterofpga/Desktop/qec_hardware/design/generated/top_module_for_leaf_1.v
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/generated/standard_planar_code_2d_1.sv /home/heterofpga/Desktop/qec_hardware/design/generated/decoder_stage_controller_dummy_1.sv /home/heterofpga/Desktop/qec_hardware/design/channels/final_arbitration.sv /home/heterofpga/Desktop/qec_hardware/design/generated/rand_gen_top.sv}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/pe/processing_unit.sv /home/heterofpga/Desktop/qec_hardware/design/channels/simple_rand_setter.v}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/generics/tree_compare_solver.sv /home/heterofpga/Desktop/qec_hardware/design/channels/neighbor_link.sv /home/heterofpga/Desktop/qec_hardware/design/generics/tree_distance_3d_solver.sv}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/channels/neigbor_link_fifo.sv /home/heterofpga/Desktop/qec_hardware/design/channels/pu_arbitration.sv}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes /home/heterofpga/Desktop/qec_hardware/design/channels/error_stream.sv

create_bd_cell -type module -reference top_module_for_leaf_with_rand_err_gen_1 top_module_for_leaf_0

et_property CONFIG.POLARITY ACTIVE_HIGH [get_bd_pins /top_module_for_leaf_0/reset]
connect_bd_net [get_bd_pins top_module_for_leaf_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins top_module_for_leaf_0/reset] [get_bd_pins util_vector_logic_1/Res]
connect_bd_net [get_bd_pins root_hub_0_0/roots] [get_bd_pins top_module_for_leaf_0/roots]
connect_bd_net [get_bd_pins root_hub_0_0/is_touching_boundaries] [get_bd_pins top_module_for_leaf_0/is_touching_boundaries]
connect_bd_net [get_bd_pins root_hub_0_0/is_odd_cardinalities] [get_bd_pins top_module_for_leaf_0/is_odd_cardinalities]
connect_bd_net [get_bd_pins top_module_for_leaf_0/has_message_flying] [get_bd_pins root_hub_0_0/downstream_has_message_flying]
connect_bd_net [get_bd_pins top_module_for_leaf_0/has_odd_clusters] [get_bd_pins root_hub_0_0/downstream_has_odd_clusters]
connect_bd_net [get_bd_pins top_module_for_leaf_0/state_signal] [get_bd_pins root_hub_0_0/downstream_state_signal]

add_files -norecurse -scan_for_includes /home/heterofpga/Xilinx/Vitis/2022.1/scripts/simple_reset/simple_reset.srcs/sources_1/new/simple_mem_reader.v
update_compile_order -fileset sources_1
create_bd_cell -type module -reference simple_mem_reader simple_mem_reader_0
connect_bd_net [get_bd_pins simple_mem_reader_0/roots] [get_bd_pins top_module_for_leaf_0/roots]
connect_bd_net [get_bd_pins simple_mem_reader_0/clk] [get_bd_pins clk_wiz_0/clk_out1]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_5
set_property -dict [list CONFIG.DIN_TO {5} CONFIG.DIN_FROM {5} CONFIG.DIN_WIDTH {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_5]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_4
set_property -dict [list CONFIG.DIN_TO {4} CONFIG.DIN_FROM {4} CONFIG.DIN_WIDTH {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_4]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_3
set_property -dict [list CONFIG.DIN_TO {3} CONFIG.DIN_FROM {3} CONFIG.DIN_WIDTH {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_3]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_2
set_property -dict [list CONFIG.DIN_TO {2} CONFIG.DIN_FROM {2} CONFIG.DIN_WIDTH {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_2]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_1
set_property -dict [list CONFIG.DIN_TO {1} CONFIG.DIN_FROM {1} CONFIG.DIN_WIDTH {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_1]
create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice:1.0 xlslice_0
set_property -dict [list CONFIG.DIN_TO {0} CONFIG.DIN_FROM {0} CONFIG.DIN_WIDTH {6} CONFIG.DOUT_WIDTH {1}] [get_bd_cells xlslice_0]

connect_bd_net [get_bd_pins simple_mem_reader_0/output_root] [get_bd_pins xlslice_0/Din]
connect_bd_net [get_bd_pins simple_mem_reader_0/output_root] [get_bd_pins xlslice_1/Din]
connect_bd_net [get_bd_pins simple_mem_reader_0/output_root] [get_bd_pins xlslice_2/Din]
connect_bd_net [get_bd_pins simple_mem_reader_0/output_root] [get_bd_pins xlslice_3/Din]
connect_bd_net [get_bd_pins simple_mem_reader_0/output_root] [get_bd_pins xlslice_4/Din]
connect_bd_net [get_bd_pins simple_mem_reader_0/output_root] [get_bd_pins xlslice_5/Din]
connect_bd_net [get_bd_pins xlslice_0/Dout] [get_bd_pins util_ds_buf_0/BUFG_I]
connect_bd_net [get_bd_pins xlslice_1/Dout] [get_bd_pins util_ds_buf_1/BUFG_I]
connect_bd_net [get_bd_pins xlslice_2/Dout] [get_bd_pins util_ds_buf_2/BUFG_I]
connect_bd_net [get_bd_pins xlslice_3/Dout] [get_bd_pins util_ds_buf_3/BUFG_I]
connect_bd_net [get_bd_pins xlslice_4/Dout] [get_bd_pins util_ds_buf_4/BUFG_I]
connect_bd_net [get_bd_pins xlslice_5/Dout] [get_bd_pins util_ds_buf_5/BUFG_I]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
endgroup
set_property -dict [list CONFIG.NUM_PORTS {6}] [get_bd_cells xlconcat_0]
connect_bd_net [get_bd_pins xlconcat_0/In0] [get_bd_pins util_ds_buf_6/BUFG_O]
connect_bd_net [get_bd_pins xlconcat_0/In1] [get_bd_pins util_ds_buf_7/BUFG_O]
connect_bd_net [get_bd_pins xlconcat_0/In2] [get_bd_pins util_ds_buf_8/BUFG_O]
connect_bd_net [get_bd_pins xlconcat_0/In3] [get_bd_pins util_ds_buf_9/BUFG_O]
connect_bd_net [get_bd_pins xlconcat_0/In4] [get_bd_pins util_ds_buf_10/BUFG_O]
connect_bd_net [get_bd_pins xlconcat_0/In5] [get_bd_pins util_ds_buf_11/BUFG_O]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins simple_mem_reader_0/read_address]
