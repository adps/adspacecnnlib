package require math

proc gen_rad_event {scope} {

current_scope $scope
set x [get_objects -r]

set rad_event_occurred 0

while { $rad_event_occurred == 0 } {

set y [lindex $x [::math::random 1 [llength $x]]]

get_property CLASS $y
set n [get_property NAME $y]
get_property RADIX $y
set_property RADIX bin $y
set pr [get_property TYPE $y]
set z [get_property VALUE $y]
set sl [string length $z]
set p [::math::random 0 $sl]
set q [string index $z $p ]

puts $n
puts $z
puts $pr
#puts $sl
#puts $p
#puts $q

set sln [string length $n]
set sln_m3 [expr $sln - 3 ]
#puts $sln
#puts $sln_m3
set is_rst [string first "rst" $n $sln_m3 ]
set is_clk [string first "clk" $n $sln_m3 ]
set is_signal [string equal $pr "signal" ]
set is_multid [string first "," $z ]

if { $is_rst == -1  && $is_clk == -1 && $is_signal == 1 && $is_multid == -1} {
    puts "Signal (not Multi_dim) and Not a reset or Clock"
    
    if { $q == 0 } {
	set z [ string replace $z $p $p 1 ] 
	add_force $n $z -cancel_after 15ns
	set rad_event_occurred 1
    }
    if { $q == 1 } {
	set z [ string replace $z $p $p 0 ] 
	add_force $n $z -cancel_after 15ns
	set rad_event_occurred 1
    }

    puts $z
}
  
}

}


proc run_rad {iterations interval} {

for {set x 0} {$x<$iterations} {incr x} {

# Test Error trap
#add_force /dpu_core_tb/op_overflow_detect 1 -cancel_after 15ns

    run $interval 
    set fd [ exec tail -n 1 vivado.log ]
    set is_finish [ string first "finish called at time" $fd]
    if { $is_finish == -1 } {
      gen_rad_event /dpu_core_tb/DUT
    } else {
	set x $iterations
    }
}

}
