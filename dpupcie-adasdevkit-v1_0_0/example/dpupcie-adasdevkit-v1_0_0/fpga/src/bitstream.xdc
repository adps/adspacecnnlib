# Configuration from SPI Flash as per XAPP1233
# Enable bitstream compression
set_property BITSTREAM.GENERAL.COMPRESS {TRUE} [ current_design ]

set_property BITSTREAM.CONFIG.EXTMASTERCCLK_EN {DIV-1} [current_design]
set_property BITSTREAM.CONFIG.SPI_32BIT_ADDR {YES} [current_design]
set_property BITSTREAM.CONFIG.SPI_BUSWIDTH {8} [current_design]
set_property BITSTREAM.CONFIG.SPI_FALL_EDGE {YES} [current_design]

# Don't pull unused pins up or down
set_property BITSTREAM.CONFIG.UNUSEDPIN {Pullnone} [current_design]

# Set CFGBVS to GND to match schematics
set_property CFGBVS {GND} [ current_design ]

# Set CONFIG_VOLTAGE to 1.8V to match schematics
set_property CONFIG_VOLTAGE {1.8} [ current_design ]

# Set safety trigger to power down FPGA at 125degC
set_property BITSTREAM.CONFIG.OVERTEMPSHUTDOWN {Enable} [current_design]
