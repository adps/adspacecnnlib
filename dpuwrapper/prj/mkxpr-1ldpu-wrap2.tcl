
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


create_project -part xcku060-ffva1517-1-i -force project-1ldpu-wrap2

set dpu_src_dir "../../onelayerdpu"
set src_dir ".."

import_files -flat -force $dpu_src_dir/cnn_defs_pkg.vhd
import_files -flat -force $dpu_src_dir/cnn_tools_pkg.vhd
import_files -flat -force $dpu_src_dir/conv_neuron_drl.vhd
import_files -flat -force $dpu_src_dir/conv_neuron_layer_drl.vhd
#import_files -flat -force $dpu_src_dir/dpu_core_tb.vhd
import_files -flat -force $src_dir/dpu_core_2op.vhd
import_files -flat -force $dpu_src_dir/feature_buffer_dynamic_3x3.vhd
import_files -flat -force $dpu_src_dir/maxpool22_dynamic.vhd
import_files -flat -force $dpu_src_dir/prog_length_sr.vhd
import_files -flat -force $dpu_src_dir/zero_pad_dynamic.vhd

import_files -flat -force $src_dir/small_sfifo.vhd
import_files -flat -force $src_dir/rescale_2x2x256x13.vhd
import_files -flat -force $src_dir/write_striper.vhd
import_files -flat -force $src_dir/dpu_ctrl_wrs.vhd
import_files -flat -force $src_dir/dpu_ctrl_wrs_wrap.vhd
import_files -flat -force $src_dir/sim_memory.vhd
import_files -flat -force $src_dir/sim_dpu_ctrl_wrs.vhd

set_property used_in_synthesis false [get_files project-1ldpu-wrap2.srcs/sources_1/imports/sim_dpu_ctrl_wrs.vhd]
set_property used_in_synthesis false [get_files project-1ldpu-wrap2.srcs/sources_1/imports/sim_memory.vhd]

set_property top dpu_ctrl_wrs_wrap [current_fileset]
set_property top sim_dpu_ctrl_wrs [get_filesets sim_1]

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


create_ip -name axi_bram_ctrl -vendor xilinx.com -library ip -version 4.1 -module_name axi_bram_ctrl_0
set_property -dict [list CONFIG.DATA_WIDTH {512} CONFIG.ID_WIDTH {6} CONFIG.SINGLE_PORT_BRAM {1} CONFIG.ECC_TYPE {0}] [get_ips axi_bram_ctrl_0]
