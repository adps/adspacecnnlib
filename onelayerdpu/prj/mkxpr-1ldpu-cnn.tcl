
create_project -part xcku060-ffva1517-1-i -force project-1ldpu-cnn

import_files -flat -force ../cnn_defs_pkg.vhd
import_files -flat -force ../cnn_tools_pkg.vhd
import_files -flat -force ../conv_neuron_drl.vhd
import_files -flat -force ../conv_neuron_layer_drl.vhd
import_files -flat -force ../dpu_core_tb.vhd
import_files -flat -force ../dpu_core.vhd
import_files -flat -force ../feature_buffer_dynamic_3x3.vhd
import_files -flat -force ../maxpool22_dynamic.vhd
import_files -flat -force ../prog_length_sr.vhd
import_files -flat -force ../zero_pad_dynamic.vhd

set_property used_in_synthesis false [get_files project-1ldpu-cnn.srcs/sources_1/imports/dpu_core_tb.vhd]

set_property top dpu_core [current_fileset]
set_property top dpu_core_tb [get_filesets sim_1]


