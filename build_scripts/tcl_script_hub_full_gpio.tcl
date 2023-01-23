
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

file mkdir /home/heterofpga/hub_1/hub_1.srcs/sources_1/new
close [ open /home/heterofpga/hub_1/hub_1.srcs/sources_1/new/loopback_hub_1.v w ]
add_files /home/heterofpga/hub_1/hub_1.srcs/sources_1/new/loopback_hub_1.v
update_compile_order -fileset sources_1

add_files -norecurse -scan_for_includes {/home/heterofpga/Desktop/qec_hardware/design/generics/many_to_one_mux.sv /home/heterofpga/Desktop/qec_hardware/design/generated/routing_table_.1.sv /home/heterofpga/Desktop/qec_hardware/design/generics/fifo_fwft.v /home/heterofpga/Desktop/qec_hardware/design/channels/serdes.sv /home/heterofpga/Desktop/qec_hardware/design/generated/top_module_hub_1.sv /home/heterofpga/Desktop/qec_hardware/design/channels/blocking_channel.sv}
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
connect_bd_net [get_bd_pins util_vector_logic_2/Res] [get_bd_pins loopback_file_0/input_valid_1]
connect_bd_net [get_bd_pins fifo_generator_0/dout] [get_bd_pins loopback_file_0/input_line_1]
connect_bd_net [get_bd_pins fifo_generator_0/rd_en] [get_bd_pins loopback_file_0/input_ready_1]

connect_bd_net [get_bd_pins simple_reset_0/reset_delayed_n] [get_bd_pins loopback_file_0/reset_n]

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_ready_1]
endgroup
set_property name output_ready_1 [get_bd_ports output_ready_1_0]
connect_bd_net [get_bd_pins loopback_file_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_line_1]
endgroup
set_property name output_data_1 [get_bd_ports output_line_1_0]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_valid_1]
endgroup
set_property name output_valid [get_bd_ports output_valid_1_0]

connect_bd_net [get_bd_pins fifo_generator_0/srst] [get_bd_pins proc_sys_reset_0/peripheral_reset]

connect_bd_net [get_bd_pins fifo_generator_0/rd_clk] [get_bd_pins clk_wiz_0/clk_out1]
disconnect_bd_net /clk_wiz_0_clk_out1 [get_bd_pins clk_wiz_0/clk_out1]


connect_bd_net [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins clk_wiz_0/clk_out1]

startgroup
make_bd_pins_external  [get_bd_pins simple_reset_0/light]
endgroup

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_1
endgroup

startgroup
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {5} CONFIG.Output_Data_Width {5} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_bd_cells fifo_generator_1]
endgroup

startgroup
make_bd_pins_external  [get_bd_pins fifo_generator_1/din]
endgroup
set_property name input_data_2 [get_bd_ports din_0]
startgroup
make_bd_pins_external  [get_bd_pins fifo_generator_1/wr_en]
endgroup
copy_bd_objs /  [get_bd_cells {util_vector_logic_0}]
set_property location {0.5 -297 -751} [get_bd_cells util_vector_logic_1]
connect_bd_net [get_bd_pins fifo_generator_1/full] [get_bd_pins util_vector_logic_3/Op1]
startgroup
make_bd_pins_external  [get_bd_pins util_vector_logic_3/Res]
endgroup
set_property name input_valid_2 [get_bd_ports wr_en_0]
set_property name input_ready_2 [get_bd_ports Res_0]

copy_bd_objs /  [get_bd_cells {util_vector_logic_1}]
connect_bd_net [get_bd_pins util_vector_logic_4/Op1] [get_bd_pins fifo_generator_1/empty]
connect_bd_net [get_bd_pins util_vector_logic_4/Res] [get_bd_pins loopback_file_0/input_valid_2]
connect_bd_net [get_bd_pins fifo_generator_1/dout] [get_bd_pins loopback_file_0/input_line_2]
connect_bd_net [get_bd_pins fifo_generator_1/rd_en] [get_bd_pins loopback_file_0/input_ready_2]

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_ready_2]
endgroup

set_property name output_ready_2 [get_bd_ports output_ready_2_0]

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_line_2]
endgroup

set_property name output_data_2 [get_bd_ports output_line_2_0]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_valid_2]
endgroup
set_property name output_valid_2 [get_bd_ports output_valid_2_0]

connect_bd_net [get_bd_pins fifo_generator_1/srst] [get_bd_pins proc_sys_reset_0/peripheral_reset]

connect_bd_net [get_bd_pins fifo_generator_1/rd_clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins fifo_generator_1/wr_clk] [get_bd_pins clk_wiz_0/clk_out1]

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:fifo_generator:13.2 fifo_generator_2
endgroup

startgroup
set_property -dict [list CONFIG.Fifo_Implementation {Independent_Clocks_Builtin_FIFO} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Input_Data_Width {5} CONFIG.Output_Data_Width {5} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5}] [get_bd_cells fifo_generator_2]
endgroup

startgroup
make_bd_pins_external  [get_bd_pins fifo_generator_2/din]
endgroup
set_property name input_data_up [get_bd_ports din_0]
startgroup
make_bd_pins_external  [get_bd_pins fifo_generator_2/wr_en]
endgroup
copy_bd_objs /  [get_bd_cells {util_vector_logic_0}]
set_property location {0.5 -297 -751} [get_bd_cells util_vector_logic_1]
connect_bd_net [get_bd_pins fifo_generator_2/full] [get_bd_pins util_vector_logic_5/Op1]
startgroup
make_bd_pins_external  [get_bd_pins util_vector_logic_5/Res]
endgroup
set_property name input_valid_up [get_bd_ports wr_en_0]
set_property name input_ready_up [get_bd_ports Res_0]

copy_bd_objs /  [get_bd_cells {util_vector_logic_1}]
connect_bd_net [get_bd_pins util_vector_logic_6/Op1] [get_bd_pins fifo_generator_2/empty]
connect_bd_net [get_bd_pins util_vector_logic_6/Res] [get_bd_pins loopback_file_0/input_valid_up]
connect_bd_net [get_bd_pins fifo_generator_2/dout] [get_bd_pins loopback_file_0/input_line_up]
connect_bd_net [get_bd_pins fifo_generator_2/rd_en] [get_bd_pins loopback_file_0/input_ready_up]

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_ready_up]
endgroup

set_property name output_ready_up [get_bd_ports output_ready_up_0]

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_line_up]
endgroup

set_property name output_data_up [get_bd_ports output_line_up_0]
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/output_valid_up]
endgroup
set_property name output_valid_up [get_bd_ports output_valid_up_0]

connect_bd_net [get_bd_pins fifo_generator_2/srst] [get_bd_pins proc_sys_reset_0/peripheral_reset]

connect_bd_net [get_bd_pins fifo_generator_2/rd_clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins fifo_generator_2/wr_clk] [get_bd_pins clk_wiz_0/clk_out1]

startgroup
make_bd_intf_pins_external  [get_bd_intf_pins clk_wiz_0/CLK_IN1_D]
endgroup

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
create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0
endgroup
set_property -dict [list CONFIG.C_BUF_TYPE {OBUFDS}] [get_bd_cells util_ds_buf_0]
connect_bd_net [get_bd_pins util_ds_buf_0/OBUF_IN] [get_bd_pins clk_wiz_0/clk_out1]
startgroup
make_bd_pins_external  [get_bd_cells util_ds_buf_0]
make_bd_intf_pins_external  [get_bd_cells util_ds_buf_0]
endgroup

startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/upstream_has_message_flying_0]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/upstream_has_odd_clusters_0]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/downstream_has_message_flying_0]
endgroup
startgroup
make_bd_pins_external  [get_bd_pins loopback_file_0/downstream_has_odd_clusters_0]
endgroup
set_property name downstream_has_message_flying [get_bd_ports downstream_has_message_flying_0_0]
set_property name downstream_has_odd_clusters [get_bd_ports downstream_has_odd_clusters_0_0]

connect_bd_net [get_bd_pins fifo_generator_0/wr_clk] [get_bd_pins clk_wiz_0/clk_out1]

set_property name output_ready [get_bd_ports output_ready_1]
set_property name output_data [get_bd_ports output_data_1]

add_files -norecurse /home/heterofpga/hub_2/simple_loopback.gen/sources_1/bd/loopback/hdl/loopback_wrapper.v

startgroup
create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0
endgroup
set_property -dict [list CONFIG.C_PROBE10_TYPE {1} CONFIG.C_PROBE8_TYPE {1} CONFIG.C_PROBE6_TYPE {1} CONFIG.C_PROBE4_TYPE {1} CONFIG.C_PROBE2_TYPE {1} CONFIG.C_PROBE0_TYPE {1} CONFIG.C_PROBE10_WIDTH {5} CONFIG.C_PROBE8_WIDTH {5} CONFIG.C_PROBE6_WIDTH {5} CONFIG.C_PROBE4_WIDTH {5} CONFIG.C_PROBE2_WIDTH {5} CONFIG.C_PROBE0_WIDTH {5} CONFIG.C_NUM_OF_PROBES {12} CONFIG.C_ENABLE_ILA_AXI_MON {false} CONFIG.C_MONITOR_TYPE {Native}] [get_bd_cells ila_0]
set_property location {3 693 -642} [get_bd_cells ila_0]
connect_bd_net [get_bd_pins ila_0/clk] [get_bd_pins clk_wiz_0/clk_out1]
connect_bd_net [get_bd_pins ila_0/probe0] [get_bd_pins fifo_generator_0/dout]
connect_bd_net [get_bd_pins ila_0/probe1] [get_bd_pins util_vector_logic_2/Res]
connect_bd_net [get_bd_pins ila_0/probe2] [get_bd_pins loopback_file_0/output_line_1]
connect_bd_net [get_bd_pins ila_0/probe3] [get_bd_pins loopback_file_0/output_valid_1]
connect_bd_net [get_bd_pins ila_0/probe4] [get_bd_pins fifo_generator_1/dout]
connect_bd_net [get_bd_pins ila_0/probe5] [get_bd_pins util_vector_logic_4/Res]
connect_bd_net [get_bd_pins ila_0/probe6] [get_bd_pins loopback_file_0/output_line_2]
connect_bd_net [get_bd_pins ila_0/probe7] [get_bd_pins loopback_file_0/output_valid_2]
connect_bd_net [get_bd_pins ila_0/probe8] [get_bd_pins fifo_generator_2/dout]
connect_bd_net [get_bd_pins ila_0/probe9] [get_bd_pins util_vector_logic_6/Res]
connect_bd_net [get_bd_pins ila_0/probe10] [get_bd_pins loopback_file_0/output_line_up]
connect_bd_net [get_bd_pins ila_0/probe11] [get_bd_pins loopback_file_0/output_valid_up]
startgroup
set_property -dict [list CONFIG.C_NUM_OF_PROBES {15}] [get_bd_cells ila_0]
endgroup
startgroup
set_property -dict [list CONFIG.C_PROBE16_WIDTH {2} CONFIG.C_PROBE15_WIDTH {2} CONFIG.C_PROBE13_WIDTH {2} CONFIG.C_PROBE12_WIDTH {2} CONFIG.C_NUM_OF_PROBES {18}] [get_bd_cells ila_0]
endgroup
startgroup
set_property -dict [list CONFIG.C_PROBE16_WIDTH {1} CONFIG.C_PROBE15_WIDTH {1} CONFIG.C_PROBE13_WIDTH {1} CONFIG.C_NUM_OF_PROBES {16}] [get_bd_cells ila_0]
endgroup
connect_bd_net [get_bd_ports downstream_has_message_flying] [get_bd_pins ila_0/probe12]
connect_bd_net [get_bd_pins ila_0/probe13] [get_bd_pins loopback_file_0/upstream_has_message_flying_0]
connect_bd_net [get_bd_ports downstream_has_odd_clusters] [get_bd_pins ila_0/probe14]
connect_bd_net [get_bd_pins ila_0/probe15] [get_bd_pins loopback_file_0/upstream_has_odd_clusters_0]

update_compile_order -fileset sources_1
set_property top loopback_wrapper [current_fileset]