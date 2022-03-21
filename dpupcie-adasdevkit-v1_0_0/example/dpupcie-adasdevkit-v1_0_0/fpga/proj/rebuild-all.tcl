# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]

set script_prefix {rebuild}

set scripts [lsort -ascii [glob -directory $origin_dir -tails -types {f} "${script_prefix}-*_1i.tcl"]]
foreach script $scripts {
  source "$origin_dir/$script"
}
