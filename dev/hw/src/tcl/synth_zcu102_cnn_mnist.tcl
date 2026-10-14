# Run in Vivado batch mode from any directory:
# vivado -mode batch -source synth_zcu102_cnn_mnist.tcl
# Creates a dated copy under .synth at the repository root; does not synthesize in ai_fpga.xpr.
# To rerun synthesis in a previous copy, pass its directory after -tclargs.
set hw_dir [file normalize [file join [file dirname [info script]] .. ..]]
set repo_dir [file normalize [file join $hw_dir .. ..]]
set source_xpr [file join $hw_dir vivado ai_fpga.xpr]
set led_xdc [file join $hw_dir src constrs zcu102_leds.xdc]
if {[llength $argv] == 1} {
    set run_dir [file normalize [lindex $argv 0]]
    set resume 1
} elseif {[llength $argv] == 0} {
    set run_name "[clock format [clock seconds] -format %Y%m%d_%H%M%S]_[pid]"
    set run_dir [file join $repo_dir .synth $run_name]
    set resume 0
} else {
    error "Uso: vivado -mode batch -source synth_zcu102_cnn_mnist.tcl ?-tclargs DIRETORIO_DA_COPIA?"
}
set report_dir [file join $run_dir reports]

foreach required [list $source_xpr $led_xdc] {
    if {![file exists $required]} { error "Arquivo ausente: $required" }
}
file mkdir $report_dir

if {!$resume} {
    open_project $source_xpr
    if {[get_property PART [current_project]] ne "xczu9eg-ffvb1156-2-e"} {
        error "Projeto aberto para dispositivo diferente da ZCU102."
    }
    save_project_as -exclude_run_results cnn $run_dir
    close_project
}
open_project [file join $run_dir cnn.xpr]

set bd [get_files -quiet *mpsoc_preset.bd]
if {[llength $bd] != 1} { error "Esperado um mpsoc_preset.bd na copia." }
open_bd_design [lindex $bd 0]
foreach cell {zcu102_cnn_mnist_axis_0 axis_data_fifo_0 axis_data_fifo_1 axi_dma_0} {
    if {![llength [get_bd_cells -quiet $cell]]} { error "Celula ausente no BD: $cell" }
}
validate_bd_design
save_bd_design
generate_target all $bd

# Use a wrapper regenerated from the current BD, instead of an imported snapshot.
set wrapper_files [make_wrapper -files $bd -top]
if {[llength $wrapper_files] != 1} {
    error "Esperado um HDL wrapper gerado para mpsoc_preset.bd."
}
set previous_wrappers [get_files -quiet *mpsoc_preset_wrapper.v]
if {[llength $previous_wrappers]} {
    remove_files $previous_wrappers
}
add_files -fileset sources_1 -norecurse $wrapper_files
set_property top mpsoc_preset_wrapper [get_filesets sources_1]
if {![llength [get_files -quiet -all *zcu102_leds.xdc]]} {
    add_files -fileset constrs_1 -norecurse $led_xdc
}
update_compile_order -fileset sources_1

if {![llength [get_files -quiet -all *zcu102_cnn_mnist_axis.v]]} {
    error "Top RTL da CNN nao consta em Sources."
}
set rtl_dir [file join $hw_dir src rtl cnn_mnist]
set mem_files [glob -directory $rtl_dir *.mem]
if {[llength $mem_files] != 16} {
    error "Esperados 16 arquivos de pesos no diretorio da CNN; encontrados [llength $mem_files]."
}
foreach mem $mem_files {
    if {![llength [get_files -quiet -all *[file tail $mem]]]} {
        error "Memoria [file tail $mem] nao consta em Sources."
    }
}
puts "SYNTH_PROJECT=[file join $run_dir cnn.xpr]"
puts "REPORT_DIR=$report_dir"
report_ip_status -file [file join $report_dir ip_status.rpt]

if {$resume} {
    reset_run synth_1
}
launch_runs synth_1 -jobs 4
wait_on_run synth_1
set status [get_property STATUS [get_runs synth_1]]
puts "SYNTH_STATUS=$status"
if {![string match "*Complete*" $status]} {
    error "Sintese nao concluida. Consulte $run_dir/cnn.runs/synth_1/runme.log e os logs dos IPs."
}

open_run synth_1
report_utilization -file [file join $report_dir utilization_synth.rpt]
report_timing_summary -report_unconstrained -file [file join $report_dir timing_synth.rpt]
check_timing -verbose -file [file join $report_dir check_timing.rpt]
report_drc -file [file join $report_dir drc_synth.rpt]
report_methodology -file [file join $report_dir methodology_synth.rpt]
puts "CLOCKS=[get_clocks]"
puts "SYNTH_REPORTS=$report_dir"
close_project
