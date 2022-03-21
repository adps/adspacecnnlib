# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]

# Define versions of dependencies in one convenient place
source "$origin_dir/version.tcl"

# Check that we are using 2018.3 or later (may support previous versions but this is the one tested)
set viv_ver [version -short]
set viv_spl [split $viv_ver .]
set viv_maj [lindex $viv_spl 0]
set viv_min [lindex $viv_spl 1]
set viv_pat [lindex $viv_spl 2]
set viv_pat [expr {$viv_pat ne "" ? $viv_pat : 0}]

if { ($viv_maj < 2018) || ($viv_maj == 2018 && ($viv_min < 3 )) } {
  send_msg_id {AD-MKXPR-001} {ERROR} "Vivado ${viv_ver} is not supported for this FPGA design. Minimum Vivado version is 2018.3"
}





# No Tandem support
set mcap_enablement {None}

# Create project
set dir {ku060_1i}
set part {xcku060-ffva1517-1-i}
set ip_part {ku060_1i}
set name {dpupcie}
set project [create_project -force -part $part $name "$origin_dir/$dir"]
current_project $project

# Get the directory path for the new project
set proj_dir [get_property directory $project]

# Set project properties
set_property "default_lib" "xil_defaultlib" $project
set_property "part" $part $project
set_property "simulator_language" "Mixed" $project
set_property "target_language" "Verilog" $project
set repo_paths [list \
  [file normalize "$origin_dir/ip"] \
]
#  [file normalize "$origin_dir/../../../../fpga/repo/interfaces"] \
#  [file normalize "$origin_dir/../../../../fpga/repo/vivado-2018.2"] \
#]
set_property "ip_repo_paths" $repo_paths $project
update_ip_catalog


# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}
set source_set [get_filesets sources_1]

# Set source set properties
set_property "generic" "" $source_set

# Add HDL source files
set hdl_files [list \
  [file normalize "$origin_dir/../src/led_driver.vhd"] \
]
if { [llength $hdl_files] > 0 } {
  add_files -norecurse -fileset $source_set $hdl_files
}




# Create 'constrs_1' fileset (if not found)
if {[string equal [get_filesets -quiet constrs_1] ""]} {
  create_fileset -constrset constrs_1
}
set constraint_set [get_filesets constrs_1]

# Add constraints files
# Put target .xdc as LAST in list
set constraint_files [list \
  [file normalize "$origin_dir/../src/dma_demo.xdc"] \
  [file normalize "$origin_dir/../src/ddr3sdram_dm_b0_x72ecc.xdc"] \
  [file normalize "$origin_dir/../src/ddr3sdram_locs_b0_x72ecc.xdc"] \
  [file normalize "$origin_dir/../src/bitstream.xdc"] \
  [file normalize "$origin_dir/../src/false_paths.xdc"] \
  [file normalize "$origin_dir/../src/pcie.xdc"] \
  [file normalize "$origin_dir/../src/user_led.xdc"] \
  [file normalize "$origin_dir/../src/usercode.xdc"] \
]

add_files -norecurse -fileset $constraint_set $constraint_files
set_property "target_constrs_file" [lindex $constraint_files 0] $constraint_set
# Avoid warnings due to referenced instances being inside black boxes during synthesis
set_property {used_in_synthesis} {false} [get_files {false_paths.xdc}]




# Add utilities files (Tcl hook scripts etc.)
set utils_set [get_filesets -quiet utils_1]
if {[string equal $utils_set ""]} {
  # Utilities fileset introduced in Vivado 2018.3; fall back to using sources set if not present.
  set utils_set $source_set
}
set utils_files [list \
  [file normalize "$origin_dir/tclpost_generate_mcs.tcl"] \
]
add_files -norecurse -fileset $utils_set $utils_files
# Set used_in_XXX properties so that Vivado 2018.2 and earlier doesn't treat them as design sources.
set_property -dict {
  {used_in_synthesis} {false} \
  {used_in_implementation} {false} \
  {used_in_simulation} {false} \
} [get_files $utils_files]

# Get 'sim_1' fileset
set sim_set [get_filesets sim_1]

# Add simulation HDL source files
set sim_files [list \
  [file normalize "$origin_dir/../src/xilinx/board.v"] \
  [file normalize "$origin_dir/../src/xilinx/board_common.vh"] \
  [file normalize "$origin_dir/../src/xilinx/pci_exp_expect_tasks.vh"] \
  [file normalize "$origin_dir/../src/xilinx/pci_exp_usrapp_cfg.v"] \
  [file normalize "$origin_dir/../src/xilinx/pci_exp_usrapp_com.v"] \
  [file normalize "$origin_dir/../src/xilinx/pci_exp_usrapp_pl.v"] \
  [file normalize "$origin_dir/../src/xilinx/pci_exp_usrapp_rx.v"] \
  [file normalize "$origin_dir/../src/xilinx/pci_exp_usrapp_tx.v"] \
  [file normalize "$origin_dir/../src/xilinx/pcie3_uscale_rp_core_top.v"] \
  [file normalize "$origin_dir/../src/xilinx/pcie3_uscale_rp_top.v"] \
  [file normalize "$origin_dir/../src/xilinx/sample_tests.vh"] \
  [file normalize "$origin_dir/../src/xilinx/sys_clk_gen.v"] \
  [file normalize "$origin_dir/../src/xilinx/sys_clk_gen_ds.v"] \
  [file normalize "$origin_dir/../src/xilinx/tests.vh"] \
  [file normalize "$origin_dir/../src/xilinx/xilinx_pcie_uscale_rp.v"] \
]
add_files -norecurse -fileset $sim_set $sim_files

# Set fileset properties
set_property "source_set" "sources_1" $sim_set
# Need to `define SIMULATION so that the XDMA (mcap_enablement=Tandem_PROM) instance asserts the mcap_design_switch signal.
set_property "verilog_define" {SIMULATION=1} $sim_set
# XSIM incremental compilation seems unreliable for large projects
set_property "incremental" "false" $sim_set
set_property "runtime" "500 us" $sim_set

set_property "target_simulator" "ModelSim" $project
# Incremental compilation seems unreliable ("unknown signal" caught) for large projects
set_property "modelsim.compile.incremental" "false" $sim_set
set_property "modelsim.simulate.runtime" "500 us" $sim_set

set_property "target_simulator" "Questa" $project
set_property "questa.simulate.runtime" "500us" $sim_set

set_property "target_simulator" "Riviera" $project
set_property "riviera.simulate.runtime" "500us" $sim_set

# ActiveHDL is not supported in the Linux version of Vivado.
if { [string compare -nocase $tcl_platform(os) "Linux"] != 0 } {
  set_property "target_simulator" "ActiveHDL" $project
  set_property "activehdl.simulate.runtime" "500us" $sim_set
}

set_property "target_simulator" "XSim" $project
# Incremental compilation seems unreliable (runaway xvlog process) for large projects
set_property "xsim.compile.incremental" "false" $sim_set
set_property "xsim.simulate.runtime" "500 us" $sim_set

set_property "simulator_language" "Mixed" $project

update_compile_order -fileset $sim_set

# Configure 'synth_1' run
set synth_run [get_runs synth_1]
set_property {needs_refresh} {1} $synth_run
set_property {part} $part $synth_run
#set_property {strategy} {Flow_PerfOptimized_high} $synth_run
current_run -synthesis $synth_run

# Configure 'impl_1' run
set impl_run [get_runs impl_1]
set_property {needs_refresh} {1} $impl_run
set_property {part} $part $impl_run
set_property {STEPS.WRITE_BITSTREAM.TCL.POST} [get_files "tclpost_generate_mcs.tcl"] $impl_run

current_run -implementation $impl_run



# Create the Block Diagram design
set bd [source "$origin_dir/mkbd.tcl"]
set bd_basename [get_property {NAME} $bd]
set bd_filetail [get_property {FILE_NAME} $bd]
set bd_file [get_files -of_objects $source_set $bd_filetail]
set bd_dirname [file dirname [get_property {NAME} $bd_file]]
# Make an HDL wrapper for it (let Vivado manage it => use add_files instead of import_files)
make_wrapper -files $bd_file -top
add_files -norecurse -fileset $source_set "${bd_dirname}/hdl/${bd_basename}_wrapper.v"

set_property top dpupcie_wrapper [current_fileset]


update_compile_order -fileset $source_set
if { [info exists sim_set] } {
  update_compile_order -fileset $sim_set
}




#close_project

return $project
