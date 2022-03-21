set bd [create_bd_design {dpupcie}]
current_bd_design $bd


set ip_vlnv {xilinx.com:ip:util_ds_buf:*}
set ip_name {pcie_clk_buf_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict { \
  CONFIG.C_BUF_TYPE {IBUFDSGTE} \
} $cell

set ip_vlnv {xilinx.com:ip:xdma:*}
set ip_name {xdma_224_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list \
  CONFIG.INS_LOSS_NYQ {15} \
  CONFIG.PF0_DEVICE_ID_mqdma {9024} \
  CONFIG.PF2_DEVICE_ID_mqdma {9024} \
  CONFIG.PF3_DEVICE_ID_mqdma {9024} \
  CONFIG.axi_bypass_64bit_en {false} \
  CONFIG.axi_bypass_prefetchable {false} \
  CONFIG.axi_data_width {128_bit} \
  CONFIG.axilite_master_en {true} \
  CONFIG.axilite_master_scale {Kilobytes} \
  CONFIG.axilite_master_size {4} \
  CONFIG.axist_bypass_en {true} \
  CONFIG.axist_bypass_scale {Megabytes} \
  CONFIG.axist_bypass_size {1} \
  CONFIG.cfg_mgmt_if {false} \
  CONFIG.dedicate_perst {true} \
  CONFIG.en_gt_selection {true} \
  CONFIG.gtwiz_in_core_us {1} \
  CONFIG.ins_loss_profile {Add-in_Card} \
  CONFIG.mcap_enablement {None} \
  CONFIG.mode_selection {Advanced} \
  CONFIG.pf0_class_code {1280FF} \
  CONFIG.pf0_class_code_base {12} \
  CONFIG.pf0_class_code_interface {FF} \
  CONFIG.pf0_class_code_sub {80} \
  CONFIG.pf0_device_id {080A} \
  CONFIG.pf0_msi_cap_multimsgcap {8_vectors} \
  CONFIG.pf0_msix_cap_pba_bir {BAR_1} \
  CONFIG.pf0_msix_cap_pba_offset {00008FE0} \
  CONFIG.pf0_msix_cap_table_bir {BAR_1} \
  CONFIG.pf0_msix_cap_table_offset {00008000} \
  CONFIG.pf0_msix_cap_table_size {01F} \
  CONFIG.pf0_msix_enabled {true} \
  CONFIG.pf0_subsystem_id {0003} \
  CONFIG.pf0_subsystem_vendor_id {4144} \
  CONFIG.pl_link_cap_max_link_speed {5.0_GT/s} \
  CONFIG.pl_link_cap_max_link_width {X4} \
  CONFIG.plltype {QPLL1} \
  CONFIG.select_quad {GTH_Quad_224} \
  CONFIG.vendor_id {4144} \
  CONFIG.xdma_pcie_64bit_en {false} \
  CONFIG.xdma_rnum_chnl {2} \
  CONFIG.xdma_wnum_chnl {2} \
] $cell

set ip_vlnv {xilinx.com:ip:smartconnect:*}
set ip_name {smartconnect_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list CONFIG.NUM_SI {3} CONFIG.NUM_CLKS {2}] $cell

set ip_vlnv {xilinx.com:ip:smartconnect:*}
set ip_name {smartconnect_inst2}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list CONFIG.NUM_MI {2} CONFIG.NUM_SI {1} CONFIG.NUM_CLKS {2}] $cell

set ip_vlnv {xilinx.com:ip:util_vector_logic:*}
set ip_name {inverter}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] $cell

set ip_vlnv {xilinx.com:ip:util_vector_logic:*}
set ip_name {inverter2}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list CONFIG.C_SIZE {1} CONFIG.C_OPERATION {not} CONFIG.LOGO_FILE {data/sym_notgate.png}] $cell

# Create instance: util_ds_buf_0, and set properties
#set ip_vlnv {xilinx.com:ip:util_ds_buf:*}
#set ip_name {util_ds_buf_0}
#set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]

# Create DDR3 SDRAM
set ip_vlnv {xilinx.com:ip:ddr3:*}
set ip_name {ddr3_inst}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list \
  CONFIG.C0.DDR3_TimePeriod {1500} \
  CONFIG.C0.DDR3_MemoryType {SODIMMs} \
  CONFIG.C0.DDR3_MemoryPart {MT18KSF1G72HZ-1G6} \
  CONFIG.C0.DDR3_DataWidth {72} \
  CONFIG.C0.DDR3_DataMask {false} \
  CONFIG.C0.DDR3_Ecc {true} \
  CONFIG.C0.DDR3_AxiDataWidth {512} \
  CONFIG.C0.DDR3_AxiAddressWidth {33} \
  CONFIG.C0.DDR3_InputClockPeriod {2500} \
  CONFIG.C0.DDR3_CLKOUT0_DIVIDE {8} \
  CONFIG.Internal_Vref {false} \
] $cell


set ip_vlnv {xilinx.com:ip:xlconstant:*}
set ip_name {ddr3_dm_driver}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]
set_property -dict [list CONFIG.CONST_WIDTH {9} CONFIG.CONST_VAL {0}] $cell
make_bd_pins_external  [get_bd_pins ddr3_dm_driver/dout]
set_property name c0_ddr3_dm [get_bd_ports dout_0]


#create_bd_cell -type module -reference dpu_top dpu_top0
set ip_vlnv {alpha-data.com:user:dpu_top:*.*}
set ip_name {dpu_top0}
set cell [create_bd_cell -type ip -vlnv $ip_vlnv $ip_name]


create_bd_cell -type module -reference led_driver led_driver_g0
set_property -dict [list CONFIG.invert {true}] [get_bd_cells led_driver_g0]

create_bd_cell -type module -reference led_driver led_driver_g1
set_property -dict [list CONFIG.invert {true}] [get_bd_cells led_driver_g1]

# Create interface ports
create_bd_intf_port -mode Master -vlnv {xilinx.com:interface:pcie_7x_mgt_rtl:1.0} pcie_mgt

# Create ports

set port [ create_bd_port -dir O -type data test_led_g0_l ]
set port [ create_bd_port -dir O -type data test_led_g1_l ]
set port [ create_bd_port -dir O -type data test_led_g2_l ]
set port [ create_bd_port -dir O -type data test_led_g3_l ]
set port [ create_bd_port -dir O -type data test_led_g4_l ]
set port [ create_bd_port -dir O -type data test_led_g5_l ]


set port [create_bd_port -dir I -type clk sys_clk_n]
set_property CONFIG.FREQ_HZ {100000000} $port
connect_bd_net [get_bd_port sys_clk_n] [get_bd_pins pcie_clk_buf_inst/IBUF_DS_N]

set port [create_bd_port -dir I -type clk sys_clk_p]
set_property CONFIG.FREQ_HZ {100000000} $port
connect_bd_net [get_bd_port sys_clk_p] [get_bd_pins pcie_clk_buf_inst/IBUF_DS_P]
 
create_bd_port -dir I -type rst sys_rst_n
connect_bd_net [get_bd_ports sys_rst_n] [get_bd_pins xdma_224_inst/sys_rst_n]



make_bd_intf_pins_external  [get_bd_intf_pins ddr3_inst/C0_SYS_CLK]
set_property CONFIG.FREQ_HZ 400000000 [get_bd_intf_ports /C0_SYS_CLK_0]

# Create interface connections
connect_bd_intf_net -intf_net xdma_224_inst_M_AXI [get_bd_intf_pins smartconnect_inst/S01_AXI] [get_bd_intf_pins xdma_224_inst/M_AXI]
connect_bd_intf_net -intf_net xdma_224_inst_M_AXI_BYPASS [get_bd_intf_pins smartconnect_inst/S00_AXI] [get_bd_intf_pins xdma_224_inst/M_AXI_BYPASS]
connect_bd_intf_net -intf_net xdma_224_inst_pcie_mgt [get_bd_intf_ports pcie_mgt] [get_bd_intf_pins xdma_224_inst/pcie_mgt]
connect_bd_intf_net [get_bd_intf_pins dpu_top0/m_axi] [get_bd_intf_pins smartconnect_inst/S02_AXI]
connect_bd_intf_net [get_bd_intf_pins smartconnect_inst/M00_AXI] [get_bd_intf_pins ddr3_inst/C0_DDR3_S_AXI]

connect_bd_intf_net [get_bd_intf_pins smartconnect_inst2/M00_AXI] [get_bd_intf_pins dpu_top0/reg_axi]
connect_bd_intf_net [get_bd_intf_pins smartconnect_inst2/M01_AXI] [get_bd_intf_pins ddr3_inst/C0_DDR3_S_AXI_CTRL]
connect_bd_intf_net [get_bd_intf_pins xdma_224_inst/M_AXI_LITE] [get_bd_intf_pins smartconnect_inst2/S00_AXI]

connect_bd_net [get_bd_pins dpu_top0/m_axi_aresetn] [get_bd_pins xdma_224_inst/axi_aresetn]
connect_bd_net [get_bd_pins dpu_top0/m_axi_aclk] [get_bd_pins xdma_224_inst/axi_aclk]
connect_bd_net [get_bd_pins dpu_top0/reg_axi_aresetn] [get_bd_pins xdma_224_inst/axi_aresetn]
connect_bd_net [get_bd_pins dpu_top0/reg_axi_aclk] [get_bd_pins xdma_224_inst/axi_aclk]
connect_bd_net [get_bd_pins smartconnect_inst2/aclk] [get_bd_pins xdma_224_inst/axi_aclk]
connect_bd_net [get_bd_pins smartconnect_inst2/aresetn] [get_bd_pins xdma_224_inst/axi_aresetn]
connect_bd_net [get_bd_pins ddr3_inst/c0_ddr3_ui_clk] [get_bd_pins smartconnect_inst/aclk1]
connect_bd_net [get_bd_pins ddr3_inst/c0_ddr3_ui_clk] [get_bd_pins smartconnect_inst2/aclk1]

connect_bd_net [get_bd_pins inverter/Op1] [get_bd_pins xdma_224_inst/axi_aresetn]
connect_bd_net [get_bd_pins inverter2/Op1] [get_bd_pins ddr3_inst/c0_ddr3_ui_clk_sync_rst]
connect_bd_net [get_bd_pins inverter2/Res] [get_bd_pins ddr3_inst/c0_ddr3_aresetn]
connect_bd_net [get_bd_pins inverter/Res] [get_bd_pins ddr3_inst/sys_rst]
connect_bd_net [get_bd_pins ddr3_inst/c0_init_calib_complete] [get_bd_pins led_driver_g0/d]
connect_bd_net [get_bd_ports test_led_g1_l] [get_bd_pins led_driver_g1/q]
connect_bd_net [get_bd_ports test_led_g0_l] [get_bd_pins led_driver_g0/q]
connect_bd_net [get_bd_pins led_driver_g1/clk] [get_bd_pins xdma_224_inst/axi_aclk]
connect_bd_net [get_bd_pins led_driver_g0/clk] [get_bd_pins xdma_224_inst/axi_aclk]

connect_bd_net [get_bd_ports test_led_g2_l] [get_bd_pins dpu_top0/led0]
connect_bd_net [get_bd_ports test_led_g3_l] [get_bd_pins dpu_top0/led1]
connect_bd_net [get_bd_ports test_led_g4_l] [get_bd_pins dpu_top0/led2]
connect_bd_net [get_bd_ports test_led_g5_l] [get_bd_pins dpu_top0/led3]
# Create port connections
connect_bd_net -net pcie_clk_buf_inst_IBUF_DS_ODIV2 [get_bd_pins pcie_clk_buf_inst/IBUF_DS_ODIV2] [get_bd_pins xdma_224_inst/sys_clk]
connect_bd_net -net pcie_clk_buf_inst_IBUF_OUT [get_bd_pins pcie_clk_buf_inst/IBUF_OUT] [get_bd_pins xdma_224_inst/sys_clk_gt]
connect_bd_net -net xdma_224_inst_axi_aclk [get_bd_pins smartconnect_inst/aclk] [get_bd_pins xdma_224_inst/axi_aclk]
connect_bd_net -net xdma_224_inst_axi_aresetn [get_bd_pins smartconnect_inst/aresetn] [get_bd_pins xdma_224_inst/axi_aresetn]
connect_bd_net -net xdma_224_inst_user_lnk_up [get_bd_pins led_driver_g1/d] [get_bd_pins xdma_224_inst/user_lnk_up]


#Fix auto assigned clocks
set_property CONFIG.FREQ_HZ 250000000 [get_bd_intf_pins /dpu_top0/reg_axi]


# Create address segments
create_bd_addr_seg -range 0x1000 -offset 0x0 [get_bd_addr_spaces xdma_224_inst/M_AXI_LITE] [get_bd_addr_segs dpu_top0/reg_axi/reg0] SEG_dpu_top_reg0
create_bd_addr_seg -range 0x1000 -offset 0x1000 [get_bd_addr_spaces xdma_224_inst/M_AXI_LITE] [get_bd_addr_segs ddr3_inst/C0_DDR3_MEMORY_MAP_CTRL/C0_REG] SEG_ddr3_ctrl_reg0
create_bd_addr_seg -range 0x400000000 -offset 0x0 [get_bd_addr_spaces xdma_224_inst/M_AXI] [get_bd_addr_segs ddr3_inst/C0_DDR3_MEMORY_MAP/C0_DDR3_ADDRESS_BLOCK] SEG_ddr3_inst_Mem0
create_bd_addr_seg -range 0x400000000 -offset 0x0 [get_bd_addr_spaces xdma_224_inst/M_AXI_BYPASS] [get_bd_addr_segs ddr3_inst/C0_DDR3_MEMORY_MAP/C0_DDR3_ADDRESS_BLOCK] SEG_ddr3_Mem0
create_bd_addr_seg -range 0x400000000 -offset 0x0 [get_bd_addr_spaces dpu_top0/m_axi] [get_bd_addr_segs ddr3_inst/C0_DDR3_MEMORY_MAP/C0_DDR3_ADDRESS_BLOCK] SEG_ddr3_Mem0

regenerate_bd_layout

make_bd_intf_pins_external  [get_bd_intf_pins ddr3_inst/C0_DDR3]


set_property name c0_sys [get_bd_intf_ports C0_SYS_CLK_0]
set_property name c0_ddr3 [get_bd_intf_ports C0_DDR3_0]

save_bd_design
return $bd
