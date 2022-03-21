set_property PACKAGE_PIN H19        [get_ports {fabric_clk_p}]
set_property IOSTANDARD DIFF_HSTL_I [get_ports {fabric_clk_p}]

set_property PACKAGE_PIN G19        [get_ports {fabric_clk_n}]
set_property IOSTANDARD DIFF_HSTL_I [get_ports {fabric_clk_n}]

create_clock -period 5.000 -name fabric_clk [get_ports {fabric_clk_p}]
