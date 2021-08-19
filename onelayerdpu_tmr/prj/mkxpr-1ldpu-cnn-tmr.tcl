
create_project -part xcku060-ffva1517-1-i -force project-1ldpu-cnn-tmr

import_files -flat -force ../cnn_defs_pkg.vhd
import_files -flat -force ../cnn_tools_pkg.vhd
import_files -flat -force ../tmr_pkg.vhd
import_files -flat -force ../conv_neuron_drl_tmr.vhd
import_files -flat -force ../conv_neuron_layer_drl_tmr.vhd
import_files -flat -force ../dpu_core_tmr_tb.vhd
import_files -flat -force ../dpu_core_tmr.vhd
import_files -flat -force ../dpu_core_tmr_flat.vhd
import_files -flat -force ../dpu_core_tmr_wrap.vhd
import_files -flat -force ../feature_buffer_dynamic_3x3_tmr.vhd
import_files -flat -force ../maxpool22_dynamic_tmr.vhd
import_files -flat -force ../prog_length_sr_tmr.vhd
import_files -flat -force ../zero_pad_dynamic_tmr.vhd

set_property used_in_synthesis false [get_files project-1ldpu-cnn-tmr.srcs/sources_1/imports/dpu_core_tmr_tb.vhd]
set_property used_in_synthesis false [get_files project-1ldpu-cnn-tmr.srcs/sources_1/imports/dpu_core_tmr_wrap.vhd]

set_property top dpu_core_tmr_flat [current_fileset]
set_property top dpu_core_tmr_tb [get_filesets sim_1]


