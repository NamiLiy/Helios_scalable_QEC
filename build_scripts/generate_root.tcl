# Get the current directory (where the script is run)
set project_dir [pwd]

# Set the project name to "root_project"
set project_name root_project

# Create a subfolder named after the project
set project_subdir [file join $project_dir $project_name]

# Create the directory using TCL's 'file mkdir' command
file mkdir $project_subdir

# Create a new project in the current directory with the name "root_project"
create_project $project_name $project_subdir -part xcvm1802-vsva2197-2MP-e-S

#Add design files
add_files -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/stage_controller/root_hub_core.v
update_compile_order -fileset sources_1
add_files -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/generics/fifo_fwft.v /home/helios/Helios_scalable_QEC/design/channels/router.v /home/helios/Helios_scalable_QEC/design/stage_controller/control_node_root_FPGA.v}

#Add simulation files
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/test_benches/full_tests/root_hub_test.sv
update_compile_order -fileset sim_1
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/test_benches/full_tests/overall_verificaton_bench.sv
update_compile_order -fileset sim_1
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/test_benches/full_tests/multi_fpga_verification_test_leaf.sv
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/wrappers/Helios_single_FPGA_core.v
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/wrappers/single_FPGA_decoding_graph_dynamic_rsc.sv
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/stage_controller/control_node_single_FPGA.v /home/helios/Helios_scalable_QEC/design/pe/support_processing_unit.v /home/helios/Helios_scalable_QEC/design/channels/neighbor_link_internal_v2.v /home/helios/Helios_scalable_QEC/design/channels/message_handler.sv /home/helios/Helios_scalable_QEC/design/pe/processing_unit_single_FPGA_v2.v}
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/channels/neighbor_link_internal_external.v /home/helios/Helios_scalable_QEC/design/generics/tree_compare_solver.sv}
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes /home/helios/Helios_scalable_QEC/design/generics/ram.sv
update_compile_order -fileset sim_1
set_property SOURCE_SET sources_1 [get_filesets sim_1]
add_files -fileset sim_1 -norecurse -scan_for_includes {/home/helios/Helios_scalable_QEC/design/channels/simple_combiner.sv /home/helios/Helios_scalable_QEC/design/channels/simple_splitter.sv}
update_compile_order -fileset sim_1

ipx::add_bus_interface FROM_LEAF_1 [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:acc_fifo_read_rtl:1.0 [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:acc_fifo_read:1.0 [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
ipx::add_port_map RD_DATA [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property physical_name rx_0_din [ipx::get_port_maps RD_DATA -of_objects [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]]
ipx::remove_bus_interface FROM_LEAF_1 [ipx::current_core]
ipx::add_bus_interface FROM_LEAF_1 [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:acc_fifo_read_rtl:1.0 [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:acc_fifo_read:1.0 [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
ipx::add_port_map RD_DATA [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property physical_name rx_1_din [ipx::get_port_maps RD_DATA -of_objects [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]]
ipx::add_port_map RD_EN [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property physical_name rx_1_rd_en [ipx::get_port_maps RD_EN -of_objects [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]]
ipx::add_port_map EMPTY_N [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]
set_property physical_name rx_1_empty [ipx::get_port_maps EMPTY_N -of_objects [ipx::get_bus_interfaces FROM_LEAF_1 -of_objects [ipx::current_core]]]
ipx::remove_bus_interface FROM_LEAF_1 [ipx::current_core]
set_property core_revision 2 [ipx::current_core]
ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums [ipx::current_core]
ipx::check_integrity [ipx::current_core]
WARNING: [IP_Flow 19-5661] Bus Interface 'clk' does not have any bus interfaces associated with it.
WARNING: [IP_Flow 19-11770] Clock interface 'clk' has no FREQ_HZ parameter.
WARNING: [IP_Flow 19-731] File Group 'xilinx_anylanguagesynthesis (Synthesis)': "/home/helios/Helios_scalable_QEC/parameters/parameters.sv" file path is not relative to the IP root directory.
WARNING: [IP_Flow 19-4816] The Synthesis file group has two include files that have the same base name. It is not guaranteed which of these two files will be picked up during synthesis/simulation:   src/parameters.sv
  /home/helios/Helios_scalable_QEC/parameters/parameters.sv
WARNING: [IP_Flow 19-731] File Group 'xilinx_anylanguagebehavioralsimulation (Simulation)': "/home/helios/Helios_scalable_QEC/parameters/parameters.sv" file path is not relative to the IP root directory.
WARNING: [IP_Flow 19-4816] The Simulation file group has two include files that have the same base name. It is not guaranteed which of these two files will be picked up during synthesis/simulation:   src/parameters.sv
  /home/helios/Helios_scalable_QEC/parameters/parameters.sv
INFO: [IP_Flow 19-2181] Payment Required is not set for this core.
INFO: [IP_Flow 19-2187] The Product Guide file is missing.
INFO: [Ipptcl 7-1486] check_integrity: Integrity check passed.
ipx::save_core [ipx::current_core]
set_property  ip_repo_paths  /home/helios/Helios_scalable_QEC/ip_repo [current_project]

exit