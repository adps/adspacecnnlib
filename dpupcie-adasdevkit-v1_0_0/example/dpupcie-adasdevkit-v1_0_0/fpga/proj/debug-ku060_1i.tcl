# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]

# When adapting this script for a different FPGA design or different device, it should be
# necessary to change only the following three variables.

set design {dpupcie}
set top {dpupcie_wrapper}
set device {ku060_1i}
set dir "${device}"
set bit_path [file normalize "${origin_dir}/${dir}/${design}.runs/impl_1/${top}.bit"]

# The logic for this script is that we look for a .bit file in the same directory as this script; if it exists, we use it.
# Otherwise, expect the .bit file in 'bit_relpath', as set above.
set bit_filename [file tail $bit_path]
if { [file exists "${origin_dir}/${bit_filename}" ] } {
  set bit_dirpath $origin_dir
} else {
  set bit_dirpath [file dirname $bit_path]
}

open_hw

set old_hw_server [ get_hw_server ]
if { $old_hw_server ne {} } {
  disconnect_hw_server $old_hw_server
}

connect_hw_server

set target [lindex [get_hw_targets] 0]
open_hw_target $target

set device [lindex [get_hw_devices] 0]
set_property PROBES.FILE "" $device
set_property PROGRAM.FILE "${bit_dirpath}/${bit_filename}" $device
program_hw_devices $device
refresh_hw_device $device
