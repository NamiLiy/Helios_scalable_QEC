
################################################################
# This is a generated script based on design: versal_hsdp
#
# Though there are limitations about the generated script,
# the main purpose of this utility is to make learning
# IP Integrator Tcl commands easier.
################################################################

namespace eval _tcl {
proc get_script_folder {} {
   set script_path [file normalize [info script]]
   set script_folder [file dirname $script_path]
   return $script_folder
}
}
variable script_folder
set script_folder [_tcl::get_script_folder]

################################################################
# Check if script is running in correct Vivado version.
################################################################
set scripts_vivado_version 2023.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   if { [string compare $scripts_vivado_version $current_vivado_version] > 0 } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2042 -severity "ERROR" " This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Sourcing the script failed since it was created with a future version of Vivado."}

   } else {
     catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   }

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source versal_hsdp_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# level_to_pulse, sample_sequence

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xcvm1802-vsva2197-2MP-e-S
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name versal_hsdp

# If you do not already have an existing IP Integrator design open,
# you can create a design using the following command:
#    create_bd_design $design_name

# Creating design if needed
set errMsg ""
set nRet 0

set cur_design [current_bd_design -quiet]
set list_cells [get_bd_cells -quiet]

if { ${design_name} eq "" } {
   # USE CASES:
   #    1) Design_name not set

   set errMsg "Please set the variable <design_name> to a non-empty value."
   set nRet 1

} elseif { ${cur_design} ne "" && ${list_cells} eq "" } {
   # USE CASES:
   #    2): Current design opened AND is empty AND names same.
   #    3): Current design opened AND is empty AND names diff; design_name NOT in project.
   #    4): Current design opened AND is empty AND names diff; design_name exists in project.

   if { $cur_design ne $design_name } {
      common::send_gid_msg -ssname BD::TCL -id 2001 -severity "INFO" "Changing value of <design_name> from <$design_name> to <$cur_design> since current design is empty."
      set design_name [get_property NAME $cur_design]
   }
   common::send_gid_msg -ssname BD::TCL -id 2002 -severity "INFO" "Constructing design in IPI design <$cur_design>..."

} elseif { ${cur_design} ne "" && $list_cells ne "" && $cur_design eq $design_name } {
   # USE CASES:
   #    5) Current design opened AND has components AND same names.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 1
} elseif { [get_files -quiet ${design_name}.bd] ne "" } {
   # USE CASES: 
   #    6) Current opened design, has components, but diff names, design_name exists in project.
   #    7) No opened design, design_name exists in project.

   set errMsg "Design <$design_name> already exists in your project, please set the variable <design_name> to another value."
   set nRet 2

} else {
   # USE CASES:
   #    8) No opened design, design_name not in project.
   #    9) Current opened design, has components, but diff names, design_name not in project.

   common::send_gid_msg -ssname BD::TCL -id 2003 -severity "INFO" "Currently there is no design <$design_name> in project, so creating one..."

   create_bd_design $design_name

   common::send_gid_msg -ssname BD::TCL -id 2004 -severity "INFO" "Making design <$design_name> as current_bd_design."
   current_bd_design $design_name

}

common::send_gid_msg -ssname BD::TCL -id 2005 -severity "INFO" "Currently the variable <design_name> is equal to \"$design_name\"."

if { $nRet != 0 } {
   catch {common::send_gid_msg -ssname BD::TCL -id 2006 -severity "ERROR" $errMsg}
   return $nRet
}

set bCheckIPsPassed 1
##################################################################
# CHECK IPs
##################################################################
set bCheckIPs 1
if { $bCheckIPs == 1 } {
   set list_check_ips "\ 
xilinx.com:ip:aurora_64b66b:12.0\
xilinx.com:ip:axi_dbg_hub:2.0\
xilinx.com:ip:axis_vio:1.0\
xilinx.com:ip:bufg_gt:1.0\
xilinx.com:ip:gt_quad_base:1.1\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:util_ds_buf:2.2\
xilinx.com:ip:versal_cips:3.4\
xilinx.com:ip:axis_ila:1.2\
xilinx.com:ip:emb_fifo_gen:1.0\
xilinx.com:ip:util_vector_logic:2.0\
"

   set list_ips_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2011 -severity "INFO" "Checking if the following IPs exist in the project's IP catalog: $list_check_ips ."

   foreach ip_vlnv $list_check_ips {
      set ip_obj [get_ipdefs -all $ip_vlnv]
      if { $ip_obj eq "" } {
         lappend list_ips_missing $ip_vlnv
      }
   }

   if { $list_ips_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2012 -severity "ERROR" "The following IPs are not found in the IP Catalog:\n  $list_ips_missing\n\nResolution: Please add the repository containing the IP(s) to the project." }
      set bCheckIPsPassed 0
   }

}

##################################################################
# CHECK Modules
##################################################################
set bCheckModules 1
if { $bCheckModules == 1 } {
   set list_check_mods "\ 
level_to_pulse\
sample_sequence\
"

   set list_mods_missing ""
   common::send_gid_msg -ssname BD::TCL -id 2020 -severity "INFO" "Checking if the following modules exist in the project's sources: $list_check_mods ."

   foreach mod_vlnv $list_check_mods {
      if { [can_resolve_reference $mod_vlnv] == 0 } {
         lappend list_mods_missing $mod_vlnv
      }
   }

   if { $list_mods_missing ne "" } {
      catch {common::send_gid_msg -ssname BD::TCL -id 2021 -severity "ERROR" "The following module(s) are not found in the project: $list_mods_missing" }
      common::send_gid_msg -ssname BD::TCL -id 2022 -severity "INFO" "Please add source files for the missing module(s) above."
      set bCheckIPsPassed 0
   }
}

if { $bCheckIPsPassed != 1 } {
  common::send_gid_msg -ssname BD::TCL -id 2023 -severity "WARNING" "Will not continue with creation of design due to the error(s) above."
  return 3
}

##################################################################
# DESIGN PROCs
##################################################################



# Procedure to create entire design; Provide argument to make
# procedure reusable. If parentCell is "", will use root.
proc create_root_design { parentCell } {

  variable script_folder
  variable design_name

  if { $parentCell eq "" } {
     set parentCell [get_bd_cells /]
  }

  # Get object for parentCell
  set parentObj [get_bd_cells $parentCell]
  if { $parentObj == "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2090 -severity "ERROR" "Unable to find parent cell <$parentCell>!"}
     return
  }

  # Make sure parentObj is hier blk
  set parentType [get_property TYPE $parentObj]
  if { $parentType ne "hier" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2091 -severity "ERROR" "Parent <$parentObj> has TYPE = <$parentType>. Expected to be <hier>."}
     return
  }

  # Save current instance; Restore later
  set oldCurInst [current_bd_instance .]

  # Set parent object as current
  current_bd_instance $parentObj


  # Create interface ports
  set GT_Serial_0 [ create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gt_rtl:1.0 GT_Serial_0 ]

  set aurora_64b66b_0_diff_gt_ref_clock [ create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 aurora_64b66b_0_diff_gt_ref_clock ]
  set_property -dict [ list \
   CONFIG.FREQ_HZ {156250000} \
   ] $aurora_64b66b_0_diff_gt_ref_clock


  # Create ports

  # Create instance: aurora_64b66b_0, and set properties
  set aurora_64b66b_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:aurora_64b66b:12.0 aurora_64b66b_0 ]
  set_property -dict [list \
    CONFIG.C_LINE_RATE {10.0} \
    CONFIG.C_USE_BYTESWAP {true} \
    CONFIG.dataflow_config {TX/RX_Simplex} \
    CONFIG.interface_mode {Streaming} \
  ] $aurora_64b66b_0


  # Create instance: axi_dbg_hub_0, and set properties
  set axi_dbg_hub_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_dbg_hub:2.0 axi_dbg_hub_0 ]
  set_property -dict [list \
    CONFIG.C_AXI_ADDR_WIDTH {44} \
    CONFIG.C_AXI_DATA_WIDTH {32} \
    CONFIG.C_AXI_ID_WIDTH {16} \
    CONFIG.C_NUM_DEBUG_CORES {0} \
  ] $axi_dbg_hub_0


  # Create instance: axis_vio_0, and set properties
  set axis_vio_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_vio:1.0 axis_vio_0 ]
  set_property -dict [list \
    CONFIG.C_EN_AXIS_IF {0} \
    CONFIG.C_NUM_PROBE_IN {19} \
    CONFIG.C_NUM_PROBE_OUT {7} \
    CONFIG.C_PROBE_IN10_WIDTH {1} \
    CONFIG.C_PROBE_IN11_WIDTH {1} \
    CONFIG.C_PROBE_IN12_WIDTH {1} \
    CONFIG.C_PROBE_IN15_WIDTH {64} \
    CONFIG.C_PROBE_IN16_WIDTH {8} \
    CONFIG.C_PROBE_OUT0_WIDTH {1} \
    CONFIG.C_PROBE_OUT1_WIDTH {3} \
    CONFIG.C_PROBE_OUT3_WIDTH {64} \
    CONFIG.C_PROBE_OUT4_WIDTH {8} \
  ] $axis_vio_0


  # Create instance: bufg_gt, and set properties
  set bufg_gt [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt ]

  # Create instance: bufg_gt_1, and set properties
  set bufg_gt_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:bufg_gt:1.0 bufg_gt_1 ]

  # Create instance: gt_quad_base, and set properties
  set gt_quad_base [ create_bd_cell -type ip -vlnv xilinx.com:ip:gt_quad_base:1.1 gt_quad_base ]
  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY {149.998505} \
    CONFIG.CHANNEL_ORDERING {/gt_quad_base/TX2_GT_IP_Interface versal_hsdp_aurora_64b66b_0_0./aurora_64b66b_0/TX_LANE0.0 /gt_quad_base/RX2_GT_IP_Interface versal_hsdp_aurora_64b66b_0_0./aurora_64b66b_0/RX_LANE0.0}\
\
    CONFIG.GT_TYPE {GTY} \
    CONFIG.PORTS_INFO_DICT {LANE_SEL_DICT {unconnected {RX0 RX1 RX3 TX0 TX1 TX3} PROT0 {RX2 TX2}} GT_TYPE GTY REG_CONF_INTF APB3_INTF BOARD_PARAMETER { }} \
    CONFIG.PROT0_ENABLE {true} \
    CONFIG.PROT0_GT_DIRECTION {DUPLEX} \
    CONFIG.PROT0_LR0_SETTINGS {GT_DIRECTION DUPLEX TX_PAM_SEL NRZ TX_HD_EN 0 TX_GRAY_BYP true TX_GRAY_LITTLEENDIAN true TX_PRECODE_BYP true TX_PRECODE_LITTLEENDIAN false TX_LINE_RATE 10.0 TX_PLL_TYPE LCPLL\
TX_REFCLK_FREQUENCY 156.250 TX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 TX_FRACN_ENABLED false TX_FRACN_OVRD false TX_FRACN_NUMERATOR 0 TX_REFCLK_SOURCE R0 TX_DATA_ENCODING 64B66B_SYNC TX_USER_DATA_WIDTH\
64 TX_INT_DATA_WIDTH 64 TX_BUFFER_MODE 1 TX_BUFFER_BYPASS_MODE Fast_Sync TX_PIPM_ENABLE false TX_OUTCLK_SOURCE TXOUTCLKPMA TXPROGDIV_FREQ_ENABLE false TXPROGDIV_FREQ_SOURCE LCPLL TXPROGDIV_FREQ_VAL 156.250000\
TX_DIFF_SWING_EMPH_MODE CUSTOM TX_64B66B_SCRAMBLER false TX_64B66B_ENCODER false TX_64B66B_CRC false TX_RATE_GROUP A TX_LANE_DESKEW_HDMI_ENABLE false TX_BUFFER_RESET_ON_RATE_CHANGE ENABLE PRESET GTY-Aurora_64B66B\
RX_PAM_SEL NRZ RX_HD_EN 0 RX_GRAY_BYP true RX_GRAY_LITTLEENDIAN true RX_PRECODE_BYP true RX_PRECODE_LITTLEENDIAN false INTERNAL_PRESET Aurora_64B66B RX_LINE_RATE 10.0 RX_PLL_TYPE LCPLL RX_REFCLK_FREQUENCY\
156.250 RX_ACTUAL_REFCLK_FREQUENCY 156.250000000000 RX_FRACN_ENABLED false RX_FRACN_OVRD false RX_FRACN_NUMERATOR 0 RX_REFCLK_SOURCE R0 RX_DATA_DECODING 64B66B_SYNC RX_USER_DATA_WIDTH 64 RX_INT_DATA_WIDTH\
64 RX_BUFFER_MODE 1 RX_OUTCLK_SOURCE RXOUTCLKPMA RXPROGDIV_FREQ_ENABLE false RXPROGDIV_FREQ_SOURCE LCPLL RXPROGDIV_FREQ_VAL 156.250000 RXRECCLK_FREQ_ENABLE false RXRECCLK_FREQ_VAL 0 INS_LOSS_NYQ 20 RX_EQ_MODE\
AUTO RX_COUPLING AC RX_TERMINATION PROGRAMMABLE RX_RATE_GROUP A RX_TERMINATION_PROG_VALUE 800 RX_PPM_OFFSET 0 RX_64B66B_DESCRAMBLER false RX_64B66B_DECODER false RX_64B66B_CRC false OOB_ENABLE false RX_COMMA_ALIGN_WORD\
1 RX_COMMA_SHOW_REALIGN_ENABLE true PCIE_ENABLE false RX_COMMA_P_ENABLE false RX_COMMA_M_ENABLE false RX_COMMA_DOUBLE_ENABLE false RX_COMMA_P_VAL 0101111100 RX_COMMA_M_VAL 1010000011 RX_COMMA_MASK 0000000000\
RX_SLIDE_MODE OFF RX_SSC_PPM 0 RX_CB_NUM_SEQ 0 RX_CB_LEN_SEQ 1 RX_CB_MAX_SKEW 1 RX_CB_MAX_LEVEL 1 RX_CB_MASK 00000000 RX_CB_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000\
RX_CB_K 00000000 RX_CB_DISP 00000000 RX_CB_MASK_0_0 false RX_CB_VAL_0_0 00000000 RX_CB_K_0_0 false RX_CB_DISP_0_0 false RX_CB_MASK_0_1 false RX_CB_VAL_0_1 00000000 RX_CB_K_0_1 false RX_CB_DISP_0_1 false\
RX_CB_MASK_0_2 false RX_CB_VAL_0_2 00000000 RX_CB_K_0_2 false RX_CB_DISP_0_2 false RX_CB_MASK_0_3 false RX_CB_VAL_0_3 00000000 RX_CB_K_0_3 false RX_CB_DISP_0_3 false RX_CB_MASK_1_0 false RX_CB_VAL_1_0\
00000000 RX_CB_K_1_0 false RX_CB_DISP_1_0 false RX_CB_MASK_1_1 false RX_CB_VAL_1_1 00000000 RX_CB_K_1_1 false RX_CB_DISP_1_1 false RX_CB_MASK_1_2 false RX_CB_VAL_1_2 00000000 RX_CB_K_1_2 false RX_CB_DISP_1_2\
false RX_CB_MASK_1_3 false RX_CB_VAL_1_3 00000000 RX_CB_K_1_3 false RX_CB_DISP_1_3 false RX_CC_NUM_SEQ 0 RX_CC_LEN_SEQ 1 RX_CC_PERIODICITY 5000 RX_CC_KEEP_IDLE DISABLE RX_CC_PRECEDENCE ENABLE RX_CC_REPEAT_WAIT\
0 RX_CC_MASK 00000000 RX_CC_VAL 00000000000000000000000000000000000000000000000000000000000000000000000000000000 RX_CC_K 00000000 RX_CC_DISP 00000000 RX_CC_MASK_0_0 false RX_CC_VAL_0_0 00000000 RX_CC_K_0_0\
false RX_CC_DISP_0_0 false RX_CC_MASK_0_1 false RX_CC_VAL_0_1 00000000 RX_CC_K_0_1 false RX_CC_DISP_0_1 false RX_CC_MASK_0_2 false RX_CC_VAL_0_2 00000000 RX_CC_K_0_2 false RX_CC_DISP_0_2 false RX_CC_MASK_0_3\
false RX_CC_VAL_0_3 00000000 RX_CC_K_0_3 false RX_CC_DISP_0_3 false RX_CC_MASK_1_0 false RX_CC_VAL_1_0 00000000 RX_CC_K_1_0 false RX_CC_DISP_1_0 false RX_CC_MASK_1_1 false RX_CC_VAL_1_1 00000000 RX_CC_K_1_1\
false RX_CC_DISP_1_1 false RX_CC_MASK_1_2 false RX_CC_VAL_1_2 00000000 RX_CC_K_1_2 false RX_CC_DISP_1_2 false RX_CC_MASK_1_3 false RX_CC_VAL_1_3 00000000 RX_CC_K_1_3 false RX_CC_DISP_1_3 false PCIE_USERCLK2_FREQ\
250 PCIE_USERCLK_FREQ 250 RX_JTOL_FC 5.9988002 RX_JTOL_LF_SLOPE -20 RX_BUFFER_BYPASS_MODE Fast_Sync RX_BUFFER_BYPASS_MODE_LANE MULTI RX_BUFFER_RESET_ON_CB_CHANGE ENABLE RX_BUFFER_RESET_ON_COMMAALIGN DISABLE\
RX_BUFFER_RESET_ON_RATE_CHANGE ENABLE RESET_SEQUENCE_INTERVAL 0 RX_COMMA_PRESET NONE RX_COMMA_VALID_ONLY 0 GT_TYPE GTY} \
    CONFIG.PROT0_LR10_SETTINGS {NA NA} \
    CONFIG.PROT0_LR11_SETTINGS {NA NA} \
    CONFIG.PROT0_LR12_SETTINGS {NA NA} \
    CONFIG.PROT0_LR13_SETTINGS {NA NA} \
    CONFIG.PROT0_LR14_SETTINGS {NA NA} \
    CONFIG.PROT0_LR15_SETTINGS {NA NA} \
    CONFIG.PROT0_LR1_SETTINGS {NA NA} \
    CONFIG.PROT0_LR2_SETTINGS {NA NA} \
    CONFIG.PROT0_LR3_SETTINGS {NA NA} \
    CONFIG.PROT0_LR4_SETTINGS {NA NA} \
    CONFIG.PROT0_LR5_SETTINGS {NA NA} \
    CONFIG.PROT0_LR6_SETTINGS {NA NA} \
    CONFIG.PROT0_LR7_SETTINGS {NA NA} \
    CONFIG.PROT0_LR8_SETTINGS {NA NA} \
    CONFIG.PROT0_LR9_SETTINGS {NA NA} \
    CONFIG.PROT0_NO_OF_LANES {1} \
    CONFIG.PROT0_RX_MASTERCLK_SRC {RX2} \
    CONFIG.PROT0_TX_MASTERCLK_SRC {TX2} \
    CONFIG.QUAD_USAGE {TX_QUAD_CH {TXQuad_0_/gt_quad_base {/gt_quad_base undef,undef,versal_hsdp_aurora_64b66b_0_0.IP_CH0,undef MSTRCLK 0,0,1,0 IS_CURRENT_QUAD 1}} RX_QUAD_CH {RXQuad_0_/gt_quad_base {/gt_quad_base\
undef,undef,versal_hsdp_aurora_64b66b_0_0.IP_CH0,undef MSTRCLK 0,0,1,0 IS_CURRENT_QUAD 1}}} \
    CONFIG.REFCLK_LIST {{/aurora_64b66b_0_diff_gt_ref_clock_clk_p[0]}} \
    CONFIG.REFCLK_STRING {HSCLK1_LCPLLGTREFCLK0 refclk_PROT0_R0_156.25_MHz_unique1} \
    CONFIG.RX0_LANE_SEL {unconnected} \
    CONFIG.RX1_LANE_SEL {unconnected} \
    CONFIG.RX2_LANE_SEL {PROT0} \
    CONFIG.RX3_LANE_SEL {unconnected} \
    CONFIG.TX0_LANE_SEL {unconnected} \
    CONFIG.TX1_LANE_SEL {unconnected} \
    CONFIG.TX2_LANE_SEL {PROT0} \
    CONFIG.TX3_LANE_SEL {unconnected} \
  ] $gt_quad_base

  set_property -dict [list \
    CONFIG.APB3_CLK_FREQUENCY.VALUE_MODE {auto} \
    CONFIG.CHANNEL_ORDERING.VALUE_MODE {auto} \
    CONFIG.GT_TYPE.VALUE_MODE {auto} \
    CONFIG.PROT0_ENABLE.VALUE_MODE {auto} \
    CONFIG.PROT0_GT_DIRECTION.VALUE_MODE {auto} \
    CONFIG.PROT0_LR0_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR10_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR11_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR12_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR13_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR14_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR15_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR1_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR2_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR3_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR4_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR5_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR6_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR7_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR8_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_LR9_SETTINGS.VALUE_MODE {auto} \
    CONFIG.PROT0_NO_OF_LANES.VALUE_MODE {auto} \
    CONFIG.PROT0_RX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.PROT0_TX_MASTERCLK_SRC.VALUE_MODE {auto} \
    CONFIG.QUAD_USAGE.VALUE_MODE {auto} \
    CONFIG.RX0_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX2_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.RX3_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX0_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX1_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX2_LANE_SEL.VALUE_MODE {auto} \
    CONFIG.TX3_LANE_SEL.VALUE_MODE {auto} \
  ] $gt_quad_base


  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]

  # Create instance: util_ds_buf, and set properties
  set util_ds_buf [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf ]
  set_property CONFIG.C_BUF_TYPE {IBUFDSGTE} $util_ds_buf


  # Create instance: util_ds_buf_0, and set properties
  set util_ds_buf_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_ds_buf:2.2 util_ds_buf_0 ]
  set_property CONFIG.C_BUF_TYPE {BUFG} $util_ds_buf_0


  # Create instance: versal_cips_0, and set properties
  set versal_cips_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:versal_cips:3.4 versal_cips_0 ]
  set_property -dict [list \
    CONFIG.CPM_CONFIG { \
      CPM_PCIE0_ARI_CAP_ENABLED {0} \
      CPM_PCIE0_MODE0_FOR_POWER {NONE} \
      CPM_PCIE0_MODES {None} \
      CPM_PCIE0_PF0_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE0_PF1_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE0_PF2_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE0_PF3_MSIX_CAP_TABLE_SIZE {001} \
      CPM_PCIE1_ARI_CAP_ENABLED {0} \
      CPM_PCIE1_MODE1_FOR_POWER {NONE} \
      PS_HSDP_EGRESS_TRAFFIC {PL} \
      PS_HSDP_INGRESS_TRAFFIC {PL} \
    } \
    CONFIG.PS_PMC_CONFIG { \
      DESIGN_MODE {1} \
      PMC_CRP_DFT_OSC_REF_CTRL_ACT_FREQMHZ {400} \
      PMC_CRP_EFUSE_REF_CTRL_ACT_FREQMHZ {100.000000} \
      PMC_CRP_EFUSE_REF_CTRL_FREQMHZ {100.000000} \
      PMC_CRP_NOC_REF_CTRL_ACT_FREQMHZ {949.990479} \
      PMC_CRP_NOC_REF_CTRL_FREQMHZ {950} \
      PMC_CRP_NPLL_CTRL_FBDIV {114} \
      PMC_CRP_PL0_REF_CTRL_ACT_FREQMHZ {149.998505} \
      PMC_CRP_PL0_REF_CTRL_DIVISOR0 {8} \
      PMC_CRP_PL0_REF_CTRL_FREQMHZ {156.25} \
      PMC_CRP_PL0_REF_CTRL_SRCSEL {PPLL} \
      PMC_CRP_PL5_REF_CTRL_FREQMHZ {400} \
      PMC_CRP_SWITCH_TIMEOUT_CTRL_DIVISOR0 {100} \
      PMC_CRP_TEST_PATTERN_REF_CTRL_ACT_FREQMHZ {200} \
      PMC_CRP_USB_SUSPEND_CTRL_DIVISOR0 {500} \
      PMC_MIO37 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA high} {PULL pulldown} {SCHMITT 0} {SLEW slow} {USAGE GPIO}} \
      PMC_MIO43 {{AUX_IO 0} {DIRECTION out} {DRIVE_STRENGTH 8mA} {OUTPUT_DATA default} {PULL pullup} {SCHMITT 1} {SLEW slow} {USAGE Reserved}} \
      PMC_MIO_TREE_PERIPHERALS {#####################################GPIO 1#####UART 0#UART 0##################################} \
      PMC_MIO_TREE_SIGNALS {#####################################gpio_1_pin[37]#####rxd#txd##################################} \
      PS_BOARD_INTERFACE {Custom} \
      PS_CRL_CAN0_REF_CTRL_FREQMHZ {100} \
      PS_CRL_CAN0_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_CAN1_REF_CTRL_FREQMHZ {100} \
      PS_CRL_CAN1_REF_CTRL_SRCSEL {PPLL} \
      PS_CRL_CPM_TOPSW_REF_CTRL_ACT_FREQMHZ {474.995239} \
      PS_CRL_CPM_TOPSW_REF_CTRL_FREQMHZ {475} \
      PS_CRL_CPM_TOPSW_REF_CTRL_SRCSEL {NPLL} \
      PS_CRL_IOU_SWITCH_CTRL_ACT_FREQMHZ {239.997604} \
      PS_CRL_IOU_SWITCH_CTRL_DIVISOR0 {5} \
      PS_CRL_IOU_SWITCH_CTRL_SRCSEL {PPLL} \
      PS_CRL_UART0_REF_CTRL_ACT_FREQMHZ {99.999001} \
      PS_CRL_USB3_DUAL_REF_CTRL_ACT_FREQMHZ {100} \
      PS_CRL_USB3_DUAL_REF_CTRL_DIVISOR0 {100} \
      PS_CRL_USB3_DUAL_REF_CTRL_FREQMHZ {100} \
      PS_HSDP_EGRESS_TRAFFIC {PL} \
      PS_HSDP_INGRESS_TRAFFIC {PL} \
      PS_M_AXI_LPD_DATA_WIDTH {32} \
      PS_NUM_FABRIC_RESETS {1} \
      PS_TTC0_PERIPHERAL_ENABLE {0} \
      PS_UART0_PERIPHERAL {{ENABLE 1} {IO {PMC_MIO 42 .. 43}}} \
      PS_USE_M_AXI_FPD {0} \
      PS_USE_M_AXI_LPD {1} \
      PS_USE_PMCPL_CLK0 {1} \
      PS_USE_S_AXI_FPD {0} \
      PS_USE_S_AXI_GP2 {0} \
      PS_USE_S_AXI_LPD {0} \
      SMON_ALARMS {Set_Alarms_On} \
      SMON_ENABLE_TEMP_AVERAGING {0} \
      SMON_TEMP_AVERAGING_SAMPLES {0} \
    } \
    CONFIG.PS_PMC_CONFIG_APPLIED {1} \
  ] $versal_cips_0


  # Create instance: axis_ila_0, and set properties
  set axis_ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:axis_ila:1.2 axis_ila_0 ]
  set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {10} \
    CONFIG.C_PROBE6_WIDTH {64} \
    CONFIG.C_PROBE8_WIDTH {64} \
  ] $axis_ila_0


  # Create instance: emb_fifo_gen_0, and set properties
  set emb_fifo_gen_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_fifo_gen:1.0 emb_fifo_gen_0 ]
  set_property -dict [list \
    CONFIG.FIFO_WRITE_DEPTH {128} \
    CONFIG.READ_MODE {FWFT} \
    CONFIG.WRITE_DATA_WIDTH {64} \
  ] $emb_fifo_gen_0


  # Create instance: level_to_pulse_0, and set properties
  set block_name level_to_pulse
  set block_cell_name level_to_pulse_0
  if { [catch {set level_to_pulse_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $level_to_pulse_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /level_to_pulse_0/reset]

  # Create instance: util_vector_logic_0, and set properties
  set util_vector_logic_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic:2.0 util_vector_logic_0 ]
  set_property -dict [list \
    CONFIG.C_OPERATION {not} \
    CONFIG.C_SIZE {1} \
  ] $util_vector_logic_0


  # Create instance: emb_fifo_gen_1, and set properties
  set emb_fifo_gen_1 [ create_bd_cell -type ip -vlnv xilinx.com:ip:emb_fifo_gen:1.0 emb_fifo_gen_1 ]
  set_property -dict [list \
    CONFIG.FIFO_WRITE_DEPTH {128} \
    CONFIG.READ_MODE {FWFT} \
    CONFIG.WRITE_DATA_WIDTH {64} \
  ] $emb_fifo_gen_1


  # Create instance: sample_sequence_0, and set properties
  set block_name sample_sequence
  set block_cell_name sample_sequence_0
  if { [catch {set sample_sequence_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $sample_sequence_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] [get_bd_pins /sample_sequence_0/reset]

  # Create interface connections
  connect_bd_intf_net -intf_net aurora_64b66b_0_RX_LANE0 [get_bd_intf_pins aurora_64b66b_0/RX_LANE0] [get_bd_intf_pins gt_quad_base/RX2_GT_IP_Interface]
  connect_bd_intf_net -intf_net aurora_64b66b_0_TX_LANE0 [get_bd_intf_pins gt_quad_base/TX2_GT_IP_Interface] [get_bd_intf_pins aurora_64b66b_0/TX_LANE0]
  connect_bd_intf_net -intf_net aurora_64b66b_0_diff_gt_ref_clock_1 [get_bd_intf_ports aurora_64b66b_0_diff_gt_ref_clock] [get_bd_intf_pins util_ds_buf/CLK_IN_D]
  connect_bd_intf_net -intf_net gt_quad_base_GT_Serial [get_bd_intf_ports GT_Serial_0] [get_bd_intf_pins gt_quad_base/GT_Serial]
  connect_bd_intf_net -intf_net versal_cips_0_M_AXI_GP2 [get_bd_intf_pins axi_dbg_hub_0/S_AXI] [get_bd_intf_pins versal_cips_0/M_AXI_LPD]

  # Create port connections
  connect_bd_net -net aurora_64b66b_0_link_reset_out [get_bd_pins aurora_64b66b_0/link_reset_out] [get_bd_pins axis_vio_0/probe_in7]
  connect_bd_net -net aurora_64b66b_0_m_axi_rx_tdata [get_bd_pins aurora_64b66b_0/m_axi_rx_tdata] [get_bd_pins emb_fifo_gen_1/din]
  connect_bd_net -net aurora_64b66b_0_m_axi_rx_tvalid [get_bd_pins aurora_64b66b_0/m_axi_rx_tvalid] [get_bd_pins axis_ila_0/probe2] [get_bd_pins emb_fifo_gen_1/wr_en]
  connect_bd_net -net aurora_64b66b_0_reset2fg [get_bd_pins aurora_64b66b_0/reset2fg] [get_bd_pins axis_vio_0/probe_in12]
  connect_bd_net -net aurora_64b66b_0_rx_channel_up [get_bd_pins aurora_64b66b_0/rx_channel_up] [get_bd_pins axis_vio_0/probe_in1]
  connect_bd_net -net aurora_64b66b_0_rx_hard_err [get_bd_pins aurora_64b66b_0/rx_hard_err] [get_bd_pins axis_vio_0/probe_in4]
  connect_bd_net -net aurora_64b66b_0_rx_lane_up [get_bd_pins aurora_64b66b_0/rx_lane_up] [get_bd_pins axis_vio_0/probe_in5]
  connect_bd_net -net aurora_64b66b_0_rx_soft_err [get_bd_pins aurora_64b66b_0/rx_soft_err] [get_bd_pins axis_vio_0/probe_in6]
  connect_bd_net -net aurora_64b66b_0_rx_sys_reset_out [get_bd_pins aurora_64b66b_0/rx_sys_reset_out] [get_bd_pins axis_vio_0/probe_in11]
  connect_bd_net -net aurora_64b66b_0_s_axi_tx_tready [get_bd_pins aurora_64b66b_0/s_axi_tx_tready] [get_bd_pins axis_vio_0/probe_in14] [get_bd_pins axis_ila_0/probe1] [get_bd_pins emb_fifo_gen_0/rd_en]
  connect_bd_net -net aurora_64b66b_0_tx_channel_up [get_bd_pins aurora_64b66b_0/tx_channel_up] [get_bd_pins axis_vio_0/probe_in8]
  connect_bd_net -net aurora_64b66b_0_tx_lane_up [get_bd_pins aurora_64b66b_0/tx_lane_up] [get_bd_pins axis_vio_0/probe_in9]
  connect_bd_net -net aurora_64b66b_0_tx_sys_reset_out [get_bd_pins aurora_64b66b_0/tx_sys_reset_out] [get_bd_pins axis_vio_0/probe_in10]
  connect_bd_net -net axis_vio_0_probe_out3 [get_bd_pins axis_vio_0/probe_out3] [get_bd_pins emb_fifo_gen_0/din]
  connect_bd_net -net axis_vio_0_probe_out5 [get_bd_pins axis_vio_0/probe_out5] [get_bd_pins level_to_pulse_0/input_level] [get_bd_pins axis_ila_0/probe3] [get_bd_pins sample_sequence_0/input_level]
  connect_bd_net -net axis_vio_0_probe_out6 [get_bd_pins axis_vio_0/probe_out6] [get_bd_pins axis_ila_0/probe0] [get_bd_pins emb_fifo_gen_1/rd_en]
  connect_bd_net -net bufg_gt_1_usrclk [get_bd_pins bufg_gt_1/usrclk] [get_bd_pins aurora_64b66b_0/rxusrclk_in] [get_bd_pins gt_quad_base/ch0_rxusrclk] [get_bd_pins gt_quad_base/ch1_rxusrclk] [get_bd_pins gt_quad_base/ch2_rxusrclk] [get_bd_pins gt_quad_base/ch3_rxusrclk]
  connect_bd_net -net bufg_gt_usrclk [get_bd_pins bufg_gt/usrclk] [get_bd_pins aurora_64b66b_0/user_clk] [get_bd_pins gt_quad_base/ch0_txusrclk] [get_bd_pins gt_quad_base/ch1_txusrclk] [get_bd_pins gt_quad_base/ch2_txusrclk] [get_bd_pins gt_quad_base/ch3_txusrclk] [get_bd_pins versal_cips_0/hsdp_ref_clk] [get_bd_pins axis_vio_0/clk] [get_bd_pins axis_ila_0/clk] [get_bd_pins level_to_pulse_0/clk] [get_bd_pins emb_fifo_gen_0/wr_clk] [get_bd_pins emb_fifo_gen_1/wr_clk] [get_bd_pins sample_sequence_0/clk]
  connect_bd_net -net clk_wizard_0_clk_out1 [get_bd_pins util_ds_buf_0/BUFG_O] [get_bd_pins aurora_64b66b_0/init_clk] [get_bd_pins axi_dbg_hub_0/aclk] [get_bd_pins gt_quad_base/altclk] [get_bd_pins gt_quad_base/apb3clk] [get_bd_pins proc_sys_reset_0/slowest_sync_clk] [get_bd_pins versal_cips_0/m_axi_lpd_aclk]
  connect_bd_net -net emb_fifo_gen_0_dout [get_bd_pins emb_fifo_gen_0/dout] [get_bd_pins aurora_64b66b_0/s_axi_tx_tdata] [get_bd_pins axis_ila_0/probe6]
  connect_bd_net -net emb_fifo_gen_0_empty [get_bd_pins emb_fifo_gen_0/empty] [get_bd_pins axis_ila_0/probe5] [get_bd_pins util_vector_logic_0/Op1]
  connect_bd_net -net emb_fifo_gen_0_full [get_bd_pins emb_fifo_gen_0/full] [get_bd_pins axis_ila_0/probe9]
  connect_bd_net -net emb_fifo_gen_1_dout [get_bd_pins emb_fifo_gen_1/dout] [get_bd_pins axis_vio_0/probe_in15] [get_bd_pins axis_ila_0/probe8]
  connect_bd_net -net emb_fifo_gen_1_empty [get_bd_pins emb_fifo_gen_1/empty] [get_bd_pins axis_ila_0/probe7] [get_bd_pins axis_vio_0/probe_in17]
  connect_bd_net -net gt_quad_base_ch2_rxbyteisaligned [get_bd_pins gt_quad_base/ch2_rxbyteisaligned] [get_bd_pins axis_vio_0/probe_in2]
  connect_bd_net -net gt_quad_base_ch2_rxoutclk [get_bd_pins gt_quad_base/ch2_rxoutclk] [get_bd_pins bufg_gt_1/outclk]
  connect_bd_net -net gt_quad_base_ch2_txoutclk [get_bd_pins gt_quad_base/ch2_txoutclk] [get_bd_pins bufg_gt/outclk]
  connect_bd_net -net gt_quad_base_gtpowergood [get_bd_pins gt_quad_base/gtpowergood] [get_bd_pins aurora_64b66b_0/gt_powergood_in]
  connect_bd_net -net hsclk0_lcplllock [get_bd_pins gt_quad_base/hsclk0_lcplllock] [get_bd_pins axis_vio_0/probe_in3]
  connect_bd_net -net loopback [get_bd_pins axis_vio_0/probe_out1] [get_bd_pins gt_quad_base/ch0_loopback] [get_bd_pins gt_quad_base/ch1_loopback] [get_bd_pins gt_quad_base/ch2_loopback] [get_bd_pins gt_quad_base/ch3_loopback]
  connect_bd_net -net pma_init_1 [get_bd_pins axis_vio_0/probe_out0] [get_bd_pins aurora_64b66b_0/pma_init] [get_bd_pins axis_vio_0/probe_in0]
  connect_bd_net -net proc_sys_reset_0_mb_reset [get_bd_pins proc_sys_reset_0/mb_reset] [get_bd_pins axis_vio_0/probe_in13] [get_bd_pins level_to_pulse_0/reset] [get_bd_pins emb_fifo_gen_0/rst] [get_bd_pins emb_fifo_gen_1/rst] [get_bd_pins sample_sequence_0/reset]
  connect_bd_net -net proc_sys_reset_0_peripheral_aresetn [get_bd_pins proc_sys_reset_0/peripheral_aresetn] [get_bd_pins axi_dbg_hub_0/aresetn]
  connect_bd_net -net sample_sequence_0_output_pulse [get_bd_pins level_to_pulse_0/output_pulse] [get_bd_pins axis_ila_0/probe4] [get_bd_pins emb_fifo_gen_0/wr_en]
  connect_bd_net -net tx_rx_reset [get_bd_pins axis_vio_0/probe_out2] [get_bd_pins aurora_64b66b_0/rx_reset_pb] [get_bd_pins aurora_64b66b_0/tx_reset_pb]
  connect_bd_net -net util_ds_buf_IBUF_OUT [get_bd_pins util_ds_buf/IBUF_OUT] [get_bd_pins gt_quad_base/GT_REFCLK0]
  connect_bd_net -net util_vector_logic_0_Res [get_bd_pins util_vector_logic_0/Res] [get_bd_pins aurora_64b66b_0/s_axi_tx_tvalid]
  connect_bd_net -net versal_cips_0_pl_clk0 [get_bd_pins versal_cips_0/pl0_ref_clk] [get_bd_pins util_ds_buf_0/BUFG_I]
  connect_bd_net -net versal_cips_0_pl_resetn0 [get_bd_pins versal_cips_0/pl0_resetn] [get_bd_pins proc_sys_reset_0/ext_reset_in]

  # Create address segments
  assign_bd_address -offset 0x80000000 -range 0x00200000 -target_address_space [get_bd_addr_spaces versal_cips_0/M_AXI_LPD] [get_bd_addr_segs axi_dbg_hub_0/S_AXI_DBG_HUB/Mem0] -force


  # Restore current instance
  current_bd_instance $oldCurInst

  validate_bd_design
  save_bd_design
}
# End of create_root_design()


##################################################################
# MAIN FLOW
##################################################################

create_root_design ""


