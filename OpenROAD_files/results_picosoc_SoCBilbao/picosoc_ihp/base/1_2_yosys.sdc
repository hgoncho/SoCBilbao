current_design picosoc_ihp
set_units -time ns -resistance kOhm -capacitance pF -voltage V -current uA
set_max_fanout 8 [current_design]
set_max_capacitance 0.5 [current_design]
set_max_transition 3 [current_design]
set_max_area 0
set_ideal_network [get_pins sg13g2_IOPad_io_clock/p2c]

create_clock [get_pins sg13g2_IOPad_io_clock/p2c] -name clk_core -period 20.0 -waveform {0 10.0}
set_clock_uncertainty 0.15 [get_clocks clk_core]
set_clock_transition 0.25 [get_clocks clk_core]

set clock_ports [get_ports { 
io_clk_PAD 
}]
set_driving_cell -lib_cell sg13g2_IOPadIn -pin pad $clock_ports


set clk_core_input_ports [get_ports { 
io_resetn_PAD 

io_ser_rx_PAD

io_phy_rx_data_0_PAD
io_phy_rx_data_1_PAD
io_phy_rx_data_2_PAD
io_phy_rx_data_3_PAD
io_phy_dv_PAD
io_phy_rx_er_PAD
io_phy_col_PAD
io_phy_crs_PAD

io_phy_tx_clk_PAD

}] 
set_driving_cell -lib_cell sg13g2_IOPadIn -pin pad $clk_core_input_ports
set_input_delay 3 -clock clk_core $clk_core_input_ports


set clk_core_output_4mA_ports [get_ports { 
io_ser_tx_PAD

io_phy_tx_data_0_PAD
io_phy_tx_data_1_PAD
io_phy_tx_data_2_PAD
io_phy_tx_data_3_PAD
io_phy_tx_en_PAD
io_phy_tx_er_PAD

io_phy_mii_clk_PAD
io_phy_rst_n_PAD

io_pps_pin_1cycle_PAD
io_pps_led_100ms_PAD

io_flash_csb_PAD
io_flash_clk_PAD

}] 
set_driving_cell -lib_cell sg13g2_IOPadOut4mA -pin pad $clk_core_output_4mA_ports
set_output_delay 3 -clock clk_core $clk_core_output_4mA_ports

set clk_core_inoutput_4mA_ports [get_ports { 
io_flash_io0_PAD
io_flash_io1_PAD
io_flash_io2_PAD
io_flash_io3_PAD

io_phy_mii_data_PAD

}] 
set_driving_cell -lib_cell sg13g2_IOPadInOut4mA -pin pad $clk_core_inoutput_4mA_ports
set_output_delay 3 -clock clk_core $clk_core_inoutput_4mA_ports



set_load -pin_load 1 [all_inputs]
set_load -pin_load 1 [all_outputs]
