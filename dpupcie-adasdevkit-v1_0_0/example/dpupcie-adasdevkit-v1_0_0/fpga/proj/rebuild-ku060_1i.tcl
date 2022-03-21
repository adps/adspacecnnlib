# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]

catch {close_project}
set dir {ku060_1i}
set proj {dpupcie}
open_project "$origin_dir/$dir/${proj}.xpr"

reset_run synth_1
launch_runs -to_step write_bitstream -jobs 4 impl_1
wait_on_run impl_1

close_project
