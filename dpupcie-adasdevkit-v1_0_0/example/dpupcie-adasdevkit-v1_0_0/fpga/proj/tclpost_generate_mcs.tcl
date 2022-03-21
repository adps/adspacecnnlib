# TCL hook script for STEPS.WRITE_BITSTREAM.TCL.POST
# NOTE: This script cannot be sourced in Vivado TCL console because it expects its environment to be that of a TCL hook script.

proc tclpost_generate_mcs { } {
  set top_name {dpupcie_wrapper}
  write_cfgmem \
    -force \
    -format mcs \
    -interface SPIx8 \
    -loadbit "up 0x0000000 ${top_name}.bit" \
    "${top_name}"
}

tclpost_generate_mcs
