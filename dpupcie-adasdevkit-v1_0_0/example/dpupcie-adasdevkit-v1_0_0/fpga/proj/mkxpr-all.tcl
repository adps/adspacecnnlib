# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]

set script_prefix {mkxpr}

set scripts [lsort -ascii [glob -directory $origin_dir -tails -types {f} "${script_prefix}-*_1i.tcl"]]
foreach script $scripts {
  set project [source "$origin_dir/$script"]
  current_project $project; close_project
}
