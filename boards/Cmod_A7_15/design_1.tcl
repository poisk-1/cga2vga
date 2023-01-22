
################################################################
# This is a generated script based on design: design_1
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
set scripts_vivado_version 2021.2
set current_vivado_version [version -short]

if { [string first $scripts_vivado_version $current_vivado_version] == -1 } {
   puts ""
   catch {common::send_gid_msg -ssname BD::TCL -id 2041 -severity "ERROR" "This script was generated using Vivado <$scripts_vivado_version> and is being run in <$current_vivado_version> of Vivado. Please run the script in Vivado <$scripts_vivado_version> then open the design in Vivado <$current_vivado_version>. Upgrade the design by running \"Tools => Report => Report IP Status...\", then run write_bd_tcl to create an updated script."}

   return 1
}

################################################################
# START
################################################################

# To test this script, run the following commands from Vivado Tcl console:
# source design_1_script.tcl


# The design that will be created by this Tcl script contains the following 
# module references:
# Top

# Please add the sources of those modules before sourcing this Tcl script.

# If there is no project opened, this script will create a
# project, but make sure you do not have an existing project
# <./myproj/project_1.xpr> in the current working folder.

set list_projs [get_projects -quiet]
if { $list_projs eq "" } {
   create_project project_1 myproj -part xc7a15tcpg236-1
   set_property BOARD_PART digilentinc.com:cmod_a7-15t:part0:1.1 [current_project]
}


# CHANGE DESIGN NAME HERE
variable design_name
set design_name design_1

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
xilinx.com:ip:clk_wiz:6.0\
xilinx.com:ip:ila:6.2\
xilinx.com:ip:proc_sys_reset:5.0\
xilinx.com:ip:xlconstant:1.1\
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
Top\
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

  # Create ports
  set dout_0 [ create_bd_port -dir O -from 2 -to 0 dout_0 ]
  set io_capRgbi_0_0 [ create_bd_port -dir IO io_capRgbi_0_0 ]
  set io_capRgbi_1_0 [ create_bd_port -dir IO io_capRgbi_1_0 ]
  set io_capRgbi_2_0 [ create_bd_port -dir IO io_capRgbi_2_0 ]
  set io_capRgbi_3_0 [ create_bd_port -dir IO io_capRgbi_3_0 ]
  set io_capSync_0_0 [ create_bd_port -dir IO io_capSync_0_0 ]
  set io_capSync_1_0 [ create_bd_port -dir IO io_capSync_1_0 ]
  set io_genRgb0_0_0 [ create_bd_port -dir IO io_genRgb0_0_0 ]
  set io_genRgb0_1_0 [ create_bd_port -dir IO io_genRgb0_1_0 ]
  set io_genRgb0_2_0 [ create_bd_port -dir IO io_genRgb0_2_0 ]
  set io_genRgb1_0_0 [ create_bd_port -dir IO io_genRgb1_0_0 ]
  set io_genRgb1_1_0 [ create_bd_port -dir IO io_genRgb1_1_0 ]
  set io_genRgb1_2_0 [ create_bd_port -dir IO io_genRgb1_2_0 ]
  set io_genSync_0_0 [ create_bd_port -dir IO io_genSync_0_0 ]
  set io_genSync_1_0 [ create_bd_port -dir IO io_genSync_1_0 ]
  set io_pushButtons_0_0 [ create_bd_port -dir IO io_pushButtons_0_0 ]
  set io_valid_0 [ create_bd_port -dir O io_valid_0 ]
  set reset [ create_bd_port -dir I -type rst reset ]
  set_property -dict [ list \
   CONFIG.POLARITY {ACTIVE_HIGH} \
 ] $reset
  set sys_clock [ create_bd_port -dir I -type clk -freq_hz 12000000 sys_clock ]
  set_property -dict [ list \
   CONFIG.PHASE {0.000} \
 ] $sys_clock

  # Create instance: Top_0, and set properties
  set block_name Top
  set block_cell_name Top_0
  if { [catch {set Top_0 [create_bd_cell -type module -reference $block_name $block_cell_name] } errmsg] } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2095 -severity "ERROR" "Unable to add referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   } elseif { $Top_0 eq "" } {
     catch {common::send_gid_msg -ssname BD::TCL -id 2096 -severity "ERROR" "Unable to referenced block <$block_name>. Please add the files for ${block_name}'s definition into the project."}
     return 1
   }
  
  # Create instance: clk_wiz_0, and set properties
  set clk_wiz_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0 ]
  set_property -dict [ list \
   CONFIG.CLKIN1_JITTER_PS {833.33} \
   CONFIG.CLKOUT1_JITTER {510.698} \
   CONFIG.CLKOUT1_PHASE_ERROR {668.310} \
   CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {60} \
   CONFIG.CLKOUT2_JITTER {586.500} \
   CONFIG.CLKOUT2_PHASE_ERROR {668.310} \
   CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {25} \
   CONFIG.CLKOUT2_USED {true} \
   CONFIG.CLK_IN1_BOARD_INTERFACE {sys_clock} \
   CONFIG.CLK_OUT1_PORT {clk_cap_pixel} \
   CONFIG.CLK_OUT2_PORT {clk_gen_pixel} \
   CONFIG.MMCM_CLKFBOUT_MULT_F {62.500} \
   CONFIG.MMCM_CLKIN1_PERIOD {83.333} \
   CONFIG.MMCM_CLKIN2_PERIOD {10.0} \
   CONFIG.MMCM_CLKOUT0_DIVIDE_F {12.500} \
   CONFIG.MMCM_CLKOUT1_DIVIDE {30} \
   CONFIG.NUM_OUT_CLKS {2} \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
   CONFIG.USE_LOCKED {false} \
 ] $clk_wiz_0

  # Create instance: ila_0, and set properties
  set ila_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:ila:6.2 ila_0 ]
  set_property -dict [ list \
   CONFIG.C_DATA_DEPTH {4096} \
   CONFIG.C_ENABLE_ILA_AXI_MON {false} \
   CONFIG.C_MONITOR_TYPE {Native} \
   CONFIG.C_NUM_OF_PROBES {5} \
   CONFIG.C_PROBE0_WIDTH {17} \
   CONFIG.C_PROBE2_WIDTH {4} \
 ] $ila_0

  # Create instance: proc_sys_reset_0, and set properties
  set proc_sys_reset_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0 ]
  set_property -dict [ list \
   CONFIG.RESET_BOARD_INTERFACE {reset} \
   CONFIG.USE_BOARD_FLOW {true} \
 ] $proc_sys_reset_0

  # Create instance: xlconstant_0, and set properties
  set xlconstant_0 [ create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 xlconstant_0 ]
  set_property -dict [ list \
   CONFIG.CONST_VAL {7} \
   CONFIG.CONST_WIDTH {3} \
 ] $xlconstant_0

  # Create port connections
  connect_bd_net -net Net [get_bd_ports io_genSync_0_0] [get_bd_pins Top_0/io_genSync_0]
  connect_bd_net -net Net1 [get_bd_ports io_genSync_1_0] [get_bd_pins Top_0/io_genSync_1]
  connect_bd_net -net Net2 [get_bd_ports io_genRgb1_1_0] [get_bd_pins Top_0/io_genRgb1_1]
  connect_bd_net -net Net3 [get_bd_ports io_genRgb0_2_0] [get_bd_pins Top_0/io_genRgb0_2]
  connect_bd_net -net Net4 [get_bd_ports io_genRgb1_0_0] [get_bd_pins Top_0/io_genRgb1_0]
  connect_bd_net -net Net5 [get_bd_ports io_genRgb0_0_0] [get_bd_pins Top_0/io_genRgb0_0]
  connect_bd_net -net Net6 [get_bd_ports io_genRgb0_1_0] [get_bd_pins Top_0/io_genRgb0_1]
  connect_bd_net -net Net7 [get_bd_ports io_genRgb1_2_0] [get_bd_pins Top_0/io_genRgb1_2]
  connect_bd_net -net Net14 [get_bd_ports io_capSync_0_0] [get_bd_pins Top_0/io_capSync_0]
  connect_bd_net -net Net15 [get_bd_ports io_capSync_1_0] [get_bd_pins Top_0/io_capSync_1]
  connect_bd_net -net Net16 [get_bd_ports io_capRgbi_0_0] [get_bd_pins Top_0/io_capRgbi_0]
  connect_bd_net -net Net17 [get_bd_ports io_capRgbi_1_0] [get_bd_pins Top_0/io_capRgbi_1]
  connect_bd_net -net Net18 [get_bd_ports io_capRgbi_2_0] [get_bd_pins Top_0/io_capRgbi_2]
  connect_bd_net -net Net19 [get_bd_ports io_capRgbi_3_0] [get_bd_pins Top_0/io_capRgbi_3]
  connect_bd_net -net Net20 [get_bd_ports io_pushButtons_0_0] [get_bd_pins Top_0/io_pushButtons_0]
  connect_bd_net -net Top_0_io_address [get_bd_pins Top_0/io_address] [get_bd_pins ila_0/probe0]
  connect_bd_net -net Top_0_io_hSync [get_bd_pins Top_0/io_hSync] [get_bd_pins ila_0/probe3]
  connect_bd_net -net Top_0_io_rgbi [get_bd_pins Top_0/io_rgbi] [get_bd_pins ila_0/probe2]
  connect_bd_net -net Top_0_io_vSync [get_bd_pins Top_0/io_vSync] [get_bd_pins ila_0/probe4]
  connect_bd_net -net Top_0_io_valid [get_bd_ports io_valid_0] [get_bd_pins Top_0/io_valid] [get_bd_pins ila_0/probe1]
  connect_bd_net -net clk_wiz_0_clk_cap_pixel [get_bd_pins Top_0/io_capClock] [get_bd_pins clk_wiz_0/clk_cap_pixel] [get_bd_pins ila_0/clk]
  connect_bd_net -net clk_wiz_0_clk_gen_pixel [get_bd_pins Top_0/io_genClock] [get_bd_pins clk_wiz_0/clk_gen_pixel]
  connect_bd_net -net proc_sys_reset_0_peripheral_reset [get_bd_pins Top_0/io_reset] [get_bd_pins proc_sys_reset_0/peripheral_reset]
  connect_bd_net -net reset_1 [get_bd_ports reset] [get_bd_pins clk_wiz_0/reset] [get_bd_pins proc_sys_reset_0/ext_reset_in]
  connect_bd_net -net sys_clock_1 [get_bd_ports sys_clock] [get_bd_pins clk_wiz_0/clk_in1] [get_bd_pins proc_sys_reset_0/slowest_sync_clk]
  connect_bd_net -net xlconstant_0_dout [get_bd_ports dout_0] [get_bd_pins xlconstant_0/dout]

  # Create address segments


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


