# ZCU102 user LEDs, UG1182 v1.7, Table 3-33 (GPIO_LED_0..7).
# The current BD exposes no LED ports, so these pin constraints are disabled.
# Uncomment the lines below only after restoring led_8bits_tri_o[7:0] in the BD
# and regenerating its HDL wrapper.
# The PS IP defines the pl_clk0 clock (~99.990005 MHz); do not create
# a second clock on this net in the full Block Design.
# set_property -dict {PACKAGE_PIN AG14 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[0]}]
# set_property -dict {PACKAGE_PIN AF13 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[1]}]
# set_property -dict {PACKAGE_PIN AE13 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[2]}]
# set_property -dict {PACKAGE_PIN AJ14 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[3]}]
# set_property -dict {PACKAGE_PIN AJ15 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[4]}]
# set_property -dict {PACKAGE_PIN AH13 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[5]}]
# set_property -dict {PACKAGE_PIN AH14 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[6]}]
# set_property -dict {PACKAGE_PIN AL12 IOSTANDARD LVCMOS33} [get_ports {led_8bits_tri_o[7]}]
