# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]

catch {close_project}
set dir {ku060_1i}
set proj {dpupcie}
open_project "$origin_dir/$dir/${proj}.xpr"
source "$origin_dir/do_build.tcl"
close_project
