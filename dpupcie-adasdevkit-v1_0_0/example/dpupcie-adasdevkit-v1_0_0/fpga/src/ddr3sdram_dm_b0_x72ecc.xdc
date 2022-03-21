#
# This file contains constraints for the DM pins for DDR3 SDRAM bank 0 that
# are not driven by MIG when it is in an ECC configuration.
#
# The pins referenced in this file are tied off to constant levels in order to
# avoid spurious transitions but must nevertheless be constrained.
#

# Get IOSTANDARD & OUTPUT_IMPEDANCE for BA pins, which are also
# unidirectional and should therefore use the same values as the DM pins.
set c0_dm_iostandard       [ get_property IOSTANDARD       [ get_ports "c0_ddr3_ba[0]" ] ]
set c0_dm_output_impedance [ get_property OUTPUT_IMPEDANCE [ get_ports "c0_ddr3_ba[0]" ] ]

set_property PACKAGE_PIN P13 [ get_ports "c0_ddr3_dm[0]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[0]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[0]" ]

set_property PACKAGE_PIN T23 [ get_ports "c0_ddr3_dm[1]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[1]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[1]" ]

set_property PACKAGE_PIN F15 [ get_ports "c0_ddr3_dm[2]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[2]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[2]" ]

set_property PACKAGE_PIN J13 [ get_ports "c0_ddr3_dm[3]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[3]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[3]" ]

set_property PACKAGE_PIN A13 [ get_ports "c0_ddr3_dm[4]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[4]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[4]" ]

set_property PACKAGE_PIN D24 [ get_ports "c0_ddr3_dm[5]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[5]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[5]" ]

set_property PACKAGE_PIN H21 [ get_ports "c0_ddr3_dm[6]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[6]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[6]" ]

set_property PACKAGE_PIN K21 [ get_ports "c0_ddr3_dm[7]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[7]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[7]" ]

set_property PACKAGE_PIN D19 [ get_ports "c0_ddr3_dm[8]" ]
set_property IOSTANDARD $c0_dm_iostandard [ get_ports "c0_ddr3_dm[8]" ]
set_property OUTPUT_IMPEDANCE $c0_dm_output_impedance [ get_ports "c0_ddr3_dm[8]" ]
