set hw_dir [file normalize [file join [file dirname [info script]] .. ..]]
set rtl_dir [file join $hw_dir src rtl cnn_mnist]
set tb_dir [file join $hw_dir src tb cnn_mnist]
set build_dir [file join $hw_dir build cnn_mnist_sim]
create_project -force cnn_mnist_sim $build_dir -part xczu9eg-ffvb1156-2-e
add_files -norecurse [glob -directory $rtl_dir *.v]
set mem_files [glob -directory $rtl_dir *.mem]
add_files -norecurse $mem_files
set_property file_type {Memory File} [get_files $mem_files]
add_files -fileset sim_1 -norecurse [file join $tb_dir zcu102_cnn_mnist_axis_tb.v]
set vectors [list [file join $tb_dir 1_0.mem] [file join $tb_dir 3_0.mem]]
add_files -fileset sim_1 -norecurse $vectors
set_property file_type {Memory File} [get_files $vectors]
set_property top zcu102_cnn_mnist_axis [get_filesets sources_1]
set_property top zcu102_cnn_mnist_axis_tb [get_filesets sim_1]
set_property xsim.simulate.runtime {0ns} [get_filesets sim_1]
update_compile_order -fileset sim_1
launch_simulation
run all
close_sim
close_project
