# Corrected 100 MHz Clock Constraints for Arty S7
set_property PACKAGE_PIN R2 [get_ports clk]
set_property IOSTANDARD SSTL135 [get_ports clk]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports clk]

#red
set_property PACKAGE_PIN U15 [get_ports red]
set_property IOSTANDARD LVCMOS33 [get_ports red]

#green
set_property PACKAGE_PIN V16 [get_ports green]
set_property IOSTANDARD LVCMOS33 [get_ports green]

#blue
set_property PACKAGE_PIN U17 [get_ports blue]
set_property IOSTANDARD LVCMOS33 [get_ports blue]

#hsync
set_property PACKAGE_PIN U16 [get_ports hsync]
set_property IOSTANDARD LVCMOS33 [get_ports hsync]

#vsync
set_property PACKAGE_PIN P13 [get_ports vsync]
set_property IOSTANDARD LVCMOS33 [get_ports vsync]

#reset
set_property PACKAGE_PIN H14 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]