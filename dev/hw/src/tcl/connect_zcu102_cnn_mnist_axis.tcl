# Fonte este arquivo no Tcl Console do projeto ai_fpga aberto no Vivado.
# Acrescenta a CNN como Module Reference entre os dois AXIS Data FIFOs existentes.
if {[catch {current_project}]} {
    error "Abra dev/hw/vivado/ai_fpga.xpr antes de executar este script."
}
set hw_dir [file normalize [file join [file dirname [info script]] .. ..]]
set rtl_dir [file join $hw_dir src rtl cnn_mnist]
set bd_files [get_files -quiet *mpsoc_preset.bd]
if {[llength $bd_files] != 1} {
    error "Esperado exatamente um Block Design mpsoc_preset.bd no projeto atual."
}
open_bd_design [lindex $bd_files 0]
foreach pin {axis_data_fifo_0/M_AXIS axis_data_fifo_1/S_AXIS axis_data_fifo_0/s_axis_aclk axis_data_fifo_0/s_axis_aresetn} {
    if {[llength [get_bd_intf_pins -quiet $pin]] == 0 && [llength [get_bd_pins -quiet $pin]] == 0} {
        error "Pino $pin ausente: este script foi feito para o BD ai_fpga da ZCU102."
    }
}
if {[llength [get_bd_cells -quiet zcu102_cnn_mnist_axis_0]]} {
    error "O modulo zcu102_cnn_mnist_axis_0 ja existe; revise o BD antes de repetir."
}
if {[llength [get_bd_intf_nets -quiet -of_objects [get_bd_intf_pins axis_data_fifo_0/M_AXIS]]]} {
    error "FIFO de entrada ja esta conectado; nenhuma alteracao foi feita."
}
if {[llength [get_bd_intf_nets -quiet -of_objects [get_bd_intf_pins axis_data_fifo_1/S_AXIS]]]} {
    error "FIFO de saida ja esta conectado; nenhuma alteracao foi feita."
}

foreach rtl_file [glob -directory $rtl_dir *.v] {
    # O Vivado pode ter importado os .v como copias no diretorio do projeto.
    if {![llength [get_files -quiet -all *[file tail $rtl_file]]]} {
        add_files -norecurse $rtl_file
    }
}
foreach mem_file [glob -directory $rtl_dir *.mem] {
    set found [get_files -quiet -all *[file tail $mem_file]]
    if {![llength $found]} {
        add_files -norecurse $mem_file
        set found [get_files -quiet -all *[file tail $mem_file]]
    }
    if {[llength $found] != 1 || [file normalize [lindex $found 0]] ne [file normalize $mem_file]} {
        error "Memoria [file tail $mem_file] deve apontar para $mem_file; revise fontes antigas no Vivado."
    }
    set_property file_type {Memory File} $found
}
update_compile_order -fileset sources_1

create_bd_cell -type module -reference zcu102_cnn_mnist_axis zcu102_cnn_mnist_axis_0
set cnn_in  [get_bd_intf_pins zcu102_cnn_mnist_axis_0/S_AXIS]
set cnn_out [get_bd_intf_pins zcu102_cnn_mnist_axis_0/M_AXIS]
if {[llength $cnn_in] != 1 || [llength $cnn_out] != 1} {
    error "Vivado nao inferiu as interfaces AXI4-Stream do modulo."
}
connect_bd_intf_net [get_bd_intf_pins axis_data_fifo_0/M_AXIS] $cnn_in
connect_bd_intf_net $cnn_out [get_bd_intf_pins axis_data_fifo_1/S_AXIS]
connect_bd_net [get_bd_pins axis_data_fifo_0/s_axis_aclk] [get_bd_pins zcu102_cnn_mnist_axis_0/aclk]
connect_bd_net [get_bd_pins axis_data_fifo_0/s_axis_aresetn] [get_bd_pins zcu102_cnn_mnist_axis_0/aresetn]
validate_bd_design
save_bd_design
update_compile_order -fileset sources_1
puts "CNN conectada: FIFO_0/M_AXIS -> CNN/S_AXIS -> FIFO_1/S_AXIS."
