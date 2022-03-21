
# define useful procedure to all TCL to use VHDL package definitions
# to configure Xilinx IP Cores
proc read_vhdl_constant {name filename} {
    set fp [open $filename r]
    set file_data [read $fp]
    close $fp
    set input_list [split $file_data "\n"]
puts $name
    set match [lsearch -inline $input_list "*constant*$name*"]
puts $match
    set x [split $match " "]
    set y [lindex $x end]
    set z [split $y ";"]
    return [lindex $z 0]    
}


# Get the directory containing this script. Source file paths are relative to this.
set origin_dir [file dirname [file normalize [info script]]]
set dpu_src_dir "$origin_dir/../../../../../onelayerdpu_tmr"
set src_dir "$origin_dir/../../../../../dpuwrapper"



create_project -part xcku060-ffva1517-1-i -force dpu_ip_proj ip



import_files -flat -force $origin_dir/../src/dpu_top.vhd
import_files -flat -force $origin_dir/../src/reg_bank_axi4l.vhd
import_files -flat -force $dpu_src_dir/cnn_defs_pkg.vhd
import_files -flat -force $dpu_src_dir/cnn_tools_pkg.vhd
import_files -flat -force $dpu_src_dir/tmr_pkg.vhd
import_files -flat -force $dpu_src_dir/conv_neuron_drl_tmr.vhd
import_files -flat -force $dpu_src_dir/conv_neuron_layer_drl_tmr.vhd
import_files -flat -force $src_dir/dpu_core_2op_tmr.vhd
import_files -flat -force $dpu_src_dir/feature_buffer_dynamic_3x3_tmr.vhd
import_files -flat -force $dpu_src_dir/maxpool22_dynamic_tmr.vhd
import_files -flat -force $dpu_src_dir/prog_length_sr_tmr.vhd
import_files -flat -force $dpu_src_dir/zero_pad_dynamic_tmr.vhd

import_files -flat -force $src_dir/small_sfifo.vhd
import_files -flat -force $src_dir/rescale_2x2x256x13.vhd
import_files -flat -force $src_dir/write_striper.vhd
import_files -flat -force $src_dir/dpu_ctrl_wrs.vhd
import_files -flat -force $src_dir/dpu_ctrl_wrs_wrap.vhd
import_files -flat -force $src_dir/dpu_ctrl_wrs_wrap_tmr.vhd

# Add IP Cores
create_ip -name axi_datamover -vendor xilinx.com -library ip -version 5.1 -module_name axi_datamover_iudm
set_property -dict [list CONFIG.Component_Name {axi_datamover_iudm} CONFIG.c_m_axi_mm2s_data_width {512} CONFIG.c_include_mm2s_dre {true} CONFIG.c_mm2s_burst_size {2} CONFIG.c_mm2s_btt_used {23} CONFIG.c_include_s2mm {Omit} CONFIG.c_include_s2mm_stsfifo {false} CONFIG.c_s2mm_addr_pipe_depth {3} CONFIG.c_s2mm_include_sf {false} CONFIG.c_m_axi_mm2s_arid {0} CONFIG.c_enable_s2mm {0} CONFIG.c_enable_mm2s_adv_sig {0} CONFIG.c_addr_width {64}] [get_ips axi_datamover_iudm]



set weight_width [read_vhdl_constant weight_width "$dpu_src_dir/cnn_defs_pkg.vhd"]
set feature_width [read_vhdl_constant feature_width "$dpu_src_dir/cnn_defs_pkg.vhd"]
puts $weight_width
puts $feature_width

create_ip -name axi_datamover -vendor xilinx.com -library ip -version 5.1 -module_name axi_datamover_wdm
set_property -dict [list CONFIG.Component_Name {axi_datamover_wdm} CONFIG.c_m_axi_mm2s_data_width {512} CONFIG.c_include_mm2s_dre {true} CONFIG.c_mm2s_burst_size {2} CONFIG.c_m_axis_mm2s_tdata_width [expr 8.0 * int(($weight_width+7.0)/8.0) ] CONFIG.c_mm2s_btt_used {23} CONFIG.c_include_s2mm {Omit} CONFIG.c_include_s2mm_stsfifo {false} CONFIG.c_s2mm_addr_pipe_depth {3} CONFIG.c_s2mm_include_sf {false} CONFIG.c_m_axi_mm2s_arid {1} CONFIG.c_enable_s2mm {0} CONFIG.c_enable_mm2s_adv_sig {0} CONFIG.c_addr_width {64}] [get_ips axi_datamover_wdm]



create_ip -name axi_datamover -vendor xilinx.com -library ip -version 5.1 -module_name axi_datamover_idm
set_property -dict [list CONFIG.Component_Name {axi_datamover_idm} CONFIG.c_m_axi_mm2s_data_width {512} CONFIG.c_m_axis_mm2s_tdata_width [expr 8.0 * int(($feature_width+7.0)/8.0) ] CONFIG.c_include_mm2s_dre {true} CONFIG.c_mm2s_burst_size {2} CONFIG.c_mm2s_btt_used {23} CONFIG.c_include_s2mm {Omit} CONFIG.c_include_s2mm_stsfifo {false} CONFIG.c_s2mm_addr_pipe_depth {3} CONFIG.c_s2mm_include_sf {false} CONFIG.c_m_axi_mm2s_arid {2} CONFIG.c_enable_s2mm {0} CONFIG.c_enable_mm2s_adv_sig {0} CONFIG.c_addr_width {64}] [get_ips axi_datamover_idm]

create_ip -name axi_datamover -vendor xilinx.com -library ip -version 5.1 -module_name axi_datamover_odm
set_property -dict [list CONFIG.Component_Name {axi_datamover_odm} CONFIG.c_addr_width {64} CONFIG.c_include_s2mm {Full} CONFIG.c_m_axi_s2mm_data_width {512} CONFIG.c_s_axis_s2mm_tdata_width [expr 8.0 * int(($feature_width+7.0)/8.0) ] CONFIG.c_include_s2mm_dre {true} CONFIG.c_s2mm_burst_size {2} CONFIG.c_include_s2mm_stsfifo {true} CONFIG.c_s2mm_btt_used {23} CONFIG.c_s2mm_include_sf {true} CONFIG.c_m_axi_s2mm_awid {3} CONFIG.c_enable_mm2s {0} CONFIG.c_enable_s2mm {1}] [get_ips axi_datamover_odm]

create_ip -name axi_crossbar -vendor xilinx.com -library ip -version 2.1 -module_name axi_crossbar_1
set_property -dict [list CONFIG.NUM_SI {6} CONFIG.NUM_MI {1} CONFIG.ADDR_WIDTH {64} CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {6} CONFIG.M00_S03_READ_CONNECTIVITY {0} CONFIG.M00_S00_WRITE_CONNECTIVITY {0} CONFIG.M00_S01_WRITE_CONNECTIVITY {0} CONFIG.M00_S02_WRITE_CONNECTIVITY {0} CONFIG.S00_THREAD_ID_WIDTH {3} CONFIG.S01_THREAD_ID_WIDTH {3} CONFIG.S02_THREAD_ID_WIDTH {3} CONFIG.S03_THREAD_ID_WIDTH {3} CONFIG.S04_THREAD_ID_WIDTH {3} CONFIG.S05_THREAD_ID_WIDTH {3} CONFIG.S06_THREAD_ID_WIDTH {3} CONFIG.S07_THREAD_ID_WIDTH {3} CONFIG.S08_THREAD_ID_WIDTH {3} CONFIG.S09_THREAD_ID_WIDTH {3} CONFIG.S10_THREAD_ID_WIDTH {3} CONFIG.S11_THREAD_ID_WIDTH {3} CONFIG.S12_THREAD_ID_WIDTH {3} CONFIG.S13_THREAD_ID_WIDTH {3} CONFIG.S14_THREAD_ID_WIDTH {3} CONFIG.S15_THREAD_ID_WIDTH {3} CONFIG.S00_SINGLE_THREAD {1} CONFIG.S01_SINGLE_THREAD {1} CONFIG.S02_SINGLE_THREAD {1} CONFIG.S03_SINGLE_THREAD {1} CONFIG.S04_SINGLE_THREAD {1} CONFIG.S05_SINGLE_THREAD {1} CONFIG.S01_BASE_ID {0x00000010} CONFIG.S02_BASE_ID {0x00000020} CONFIG.S03_BASE_ID {0x00000030} CONFIG.S04_BASE_ID {0x00000040} CONFIG.S05_BASE_ID {0x00000050} CONFIG.S06_BASE_ID {0x00000060} CONFIG.S07_BASE_ID {0x00000070} CONFIG.S08_BASE_ID {0x00000080} CONFIG.S09_BASE_ID {0x00000090} CONFIG.S10_BASE_ID {0x000000a0} CONFIG.S11_BASE_ID {0x000000b0} CONFIG.S12_BASE_ID {0x000000c0} CONFIG.S13_BASE_ID {0x000000d0} CONFIG.S14_BASE_ID {0x000000e0} CONFIG.S15_BASE_ID {0x000000f0} CONFIG.M00_A00_ADDR_WIDTH {64}] [get_ips axi_crossbar_1]

create_ip -name fifo_generator -vendor xilinx.com -library ip -version 13.2 -module_name fifo_generator_0
set_property -dict [list CONFIG.Fifo_Implementation {Common_Clock_Block_RAM} CONFIG.Performance_Options {First_Word_Fall_Through} CONFIG.Use_Dout_Reset {true} CONFIG.Use_Extra_Logic {true} CONFIG.Data_Count {true} CONFIG.Data_Count_Width {11} CONFIG.Write_Data_Count_Width {11} CONFIG.Read_Data_Count_Width {11} CONFIG.Empty_Threshold_Assert_Value {4} CONFIG.Empty_Threshold_Negate_Value {5} CONFIG.Almost_Full_Flag {true}] [get_ips fifo_generator_0]


update_compile_order -fileset [current_fileset]
set_property top dpu_top [current_fileset]
set_property library dpu_lib [get_files -filter {FILE_TYPE == VHDL}]




ipx::package_project -import_files


set_property vendor {alpha-data.com} [ipx::current_core]
set_property version {1.0} [ipx::current_core]
set_property vendor_display_name {Alpha Data} [ipx::current_core]
set_property company_url {https://www.alpha-data.com} [ipx::current_core]
set today [clock format [clock seconds] -format "%y%m%d"]
set_property core_revision $today [ipx::current_core]
set_property display_name DPU_TOP [ipx::current_core]
set_property description {Top Level DPU Wrapper for IPI Use} [ipx::current_core]

ipx::save_core [ipx::current_core]
update_ip_catalog
ipx::check_integrity -quiet [ipx::current_core]
ipx::archive_core {ip/dpu_top_v1_0.zip} [ipx::current_core]
