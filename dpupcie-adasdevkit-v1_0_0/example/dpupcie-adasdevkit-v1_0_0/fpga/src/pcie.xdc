##### SYS RESET ###########
set_property PACKAGE_PIN [get_package_pins -filter {PIN_FUNC == IO_T3U_N12_PERSTN0_65}] [get_ports sys_rst_n]
set_property PULLUP true [get_ports sys_rst_n]
set_property IOSTANDARD LVCMOS18 [get_ports sys_rst_n]

##### SYS CLOCK ###########
set_property PACKAGE_PIN AT10 [get_ports sys_clk_p]
set_property PACKAGE_PIN AT9 [get_ports sys_clk_n]
create_clock -name sys_clk -period 10 [get_ports sys_clk_p]

# Not needed
#set_property PACKAGE_PIN AW4 [get_ports {pcie_mgt_rxp[0]}]
#set_property PACKAGE_PIN AW3 [get_ports {pcie_mgt_rxn[0]}]
#set_property PACKAGE_PIN AW8 [get_ports {pcie_mgt_txp[0]}]
#set_property PACKAGE_PIN AW7 [get_ports {pcie_mgt_txn[0]}]
