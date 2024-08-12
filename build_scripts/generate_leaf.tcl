# Get the current directory (where the script is run)
set project_dir [pwd]

# Set the project name to "root_project"
set project_name leaf_project_1

# Create a subfolder named after the project
set project_subdir [file join $project_dir $project_name]

# Create the directory using TCL's 'file mkdir' command
file mkdir $project_subdir

# Create a new project in the current directory with the name "root_project"
create_project $project_name $project_subdir -part xcvm1802-vsva2197-2MP-e-S

#Add design files
add_files -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/wrappers/Helios_single_FPGA_core.v
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/wrappers/single_FPGA_decoding_graph_dynamic_rsc.sv
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/stage_controller/control_node_single_FPGA.v /home/helios/Helios_scalable_QEC/design/pe/support_processing_unit.v /home/helios/Helios_scalable_QEC/design/channels/neighbor_link_internal_v2.v /home/helios/Helios_scalable_QEC/design/channels/message_handler.sv /home/helios/Helios_scalable_QEC/design/pe/processing_unit_single_FPGA_v2.v}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/channels/neighbor_link_internal_external.v /home/helios/Helios_scalable_QEC/design/generics/tree_compare_solver.sv}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/generics/ram.sv
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/channels/simple_combiner.sv /home/helios/Helios_scalable_QEC/design/channels/simple_splitter.sv}
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/generics/fifo_fwft.v

#Add simulation files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/test_benches/full_tests/root_hub_test.sv
update_compile_order -fileset sim_1
add_files -fileset sim_1  -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/stage_controller/root_hub_core.v
update_compile_order -fileset sim_1
add_files -fileset sim_1  -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/channels/router.v /home/helios/Helios_scalable_QEC/design/stage_controller/control_node_root_FPGA.v}
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/test_benches/full_tests/overall_verificaton_bench.sv
update_compile_order -fileset sim_1
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/test_benches/full_tests/multi_fpga_verification_test_leaf.sv
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
update_compile_order -fileset sim_1


exit