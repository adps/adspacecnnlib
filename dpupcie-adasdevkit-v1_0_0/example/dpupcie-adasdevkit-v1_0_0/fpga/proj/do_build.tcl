# Expects to be source'd in Vivado with a project already open

set synth_progress [ get_property PROGRESS [ get_run synth_1 ] ]
set synth_needs_refresh [ get_property NEEDS_REFRESH [ get_run synth_1 ] ]
puts "synth_progress=$synth_progress synth_needs_refresh=$synth_needs_refresh"
if { $synth_progress ne "100%" || $synth_needs_refresh != 0 } {
  reset_run synth_1
  launch_runs -jobs 4 synth_1
  wait_on_run synth_1
}

set impl_progress [ get_property PROGRESS [ get_run impl_1] ]
set impl_needs_refresh [ get_property NEEDS_REFRESH [ get_run impl_1 ] ]
puts "impl_progress=$impl_progress impl_needs_refresh=$impl_needs_refresh"
if { $impl_progress ne "100%" || $impl_needs_refresh != 0 } {
  launch_runs -to_step write_bitstream -jobs 4 impl_1
  wait_on_run impl_1
}
