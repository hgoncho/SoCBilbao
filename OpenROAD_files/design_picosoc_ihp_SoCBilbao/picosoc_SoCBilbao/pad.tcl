set IO_LENGTH 180
set IO_WIDTH 80
set BONDPAD_SIZE 70
set SEALRING_OFFSET 70
set IO_OFFSET [expr { $BONDPAD_SIZE + $SEALRING_OFFSET }]

proc calc_horizontal_pad_location { index total IO_LENGTH IO_WIDTH BONDPAD_SIZE SEALRING_OFFSET } {
 set DIE_WIDTH [expr { [lindex $::env(DIE_AREA) 2] - [lindex $::env(DIE_AREA) 0] }]
 set PAD_OFFSET [expr { $IO_LENGTH + $BONDPAD_SIZE + $SEALRING_OFFSET }]
 set PAD_AREA_WIDTH [expr { $DIE_WIDTH - ($PAD_OFFSET * 2) }]
 set HORIZONTAL_PAD_DISTANCE [expr { ($PAD_AREA_WIDTH / $total) - $IO_WIDTH }]

 return [expr {$PAD_OFFSET + (($IO_WIDTH + $HORIZONTAL_PAD_DISTANCE) * $index) + ($HORIZONTAL_PAD_DISTANCE / 2) }]
}

proc calc_vertical_pad_location { index total IO_LENGTH IO_WIDTH BONDPAD_SIZE SEALRING_OFFSET } {
 set DIE_HEIGHT [expr { [lindex $::env(DIE_AREA) 3] - [lindex $::env(DIE_AREA) 1] }]
 set PAD_OFFSET [expr { $IO_LENGTH + $BONDPAD_SIZE + $SEALRING_OFFSET }]
 set PAD_AREA_HEIGHT [expr { $DIE_HEIGHT - ($PAD_OFFSET * 2) }]
 set VERTICAL_PAD_DISTANCE [expr { ($PAD_AREA_HEIGHT / $total) - $IO_WIDTH }]

 return [expr { $PAD_OFFSET + (($IO_WIDTH + $VERTICAL_PAD_DISTANCE) * $index) + ($VERTICAL_PAD_DISTANCE / 2)}]
}

# padframe core power pins
add_global_connection -net {VDD} -pin_pattern {^vdd$} -power
add_global_connection -net {VSS} -pin_pattern {^vss$} -ground

# padframe io power pins
add_global_connection -net {IOVDD} -pin_pattern {^iovdd$} -power
add_global_connection -net {IOVSS} -pin_pattern {^iovss$} -ground
make_fake_io_site -name IOLibSite -width 1 -height $IO_LENGTH
make_fake_io_site -name IOLibCSite -width $IO_LENGTH -height $IO_LENGTH
set IO_OFFSET [expr { $BONDPAD_SIZE + $SEALRING_OFFSET }]

# Create IO Rows
make_io_sites \
 -horizontal_site IOLibSite \
 -vertical_site IOLibSite \
 -corner_site IOLibCSite \
 -offset $IO_OFFSET

# Place Pads
# South
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 0 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVss_south_9} -master sg13g2_IOPadVss
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 2 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_crs} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 4 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rx_data_0} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 6 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rx_data_1} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 1 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rx_data_2} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 3 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rx_data_3} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 5 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_dv} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 7 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rx_er} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 8 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_col} -master sg13g2_IOPadIn
place_pad -row IO_SOUTH -location [calc_horizontal_pad_location 9 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVdd_south_0} -master sg13g2_IOPadVss


#East
place_pad -row IO_EAST -location [calc_vertical_pad_location 9 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVss_east_9} -master sg13g2_IOPadVss
place_pad -row IO_EAST -location [calc_vertical_pad_location 8 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_ser_tx} -master sg13g2_IOPadOut4mA
place_pad -row IO_EAST -location [calc_vertical_pad_location 7 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_ser_rx} -master sg13g2_IOPadIn
place_pad -row IO_EAST -location [calc_vertical_pad_location 6 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_mii_clk} -master sg13g2_IOPadOut4mA
place_pad -row IO_EAST -location [calc_vertical_pad_location 5 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rst_n} -master sg13g2_IOPadOut4mA
place_pad -row IO_EAST -location [calc_vertical_pad_location 4 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_mii_data} -master sg13g2_IOPadInOut4mA
place_pad -row IO_EAST -location [calc_vertical_pad_location 3 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_pps_pin_1cycle} -master sg13g2_IOPadOut4mA
place_pad -row IO_EAST -location [calc_vertical_pad_location 2 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_pps_led_100ms} -master sg13g2_IOPadOut4mA
place_pad -row IO_EAST -location [calc_vertical_pad_location 1 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVdd_east_1} -master sg13g2_IOPadVdd
place_pad -row IO_EAST -location [calc_vertical_pad_location 0 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVss_east_0} -master sg13g2_IOPadVss


#North
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 0 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVss_north_0} -master sg13g2_IOPadVss
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 2 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_clock} -master sg13g2_IOPadIn
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 4 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_reset} -master sg13g2_IOPadIn
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 6 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_flash_csb} -master sg13g2_IOPadOut4mA 
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 1 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_flash_clk} -master sg13g2_IOPadOut4mA 
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 3 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_flash_io0} -master sg13g2_IOPadInOut4mA
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 5 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_flash_io1} -master sg13g2_IOPadInOut4mA
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 7 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_flash_io2} -master sg13g2_IOPadInOut4mA
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 8 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_flash_io3} -master sg13g2_IOPadInOut4mA
place_pad -row IO_NORTH -location [calc_horizontal_pad_location 9 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVdd_north_9} -master sg13g2_IOPadVdd

#West
place_pad -row IO_WEST -location [calc_vertical_pad_location 9 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadVdd_west_9} -master sg13g2_IOPadVdd
place_pad -row IO_WEST -location [calc_vertical_pad_location 8 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_clk} -master sg13g2_IOPadIn
place_pad -row IO_WEST -location [calc_vertical_pad_location 7 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_data_0} -master sg13g2_IOPadOut4mA
place_pad -row IO_WEST -location [calc_vertical_pad_location 6 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_data_1} -master sg13g2_IOPadOut4mA
place_pad -row IO_WEST -location [calc_vertical_pad_location 5 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_data_2} -master sg13g2_IOPadOut4mA
place_pad -row IO_WEST -location [calc_vertical_pad_location 4 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_data_3} -master sg13g2_IOPadOut4mA
place_pad -row IO_WEST -location [calc_vertical_pad_location 3 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_en} -master sg13g2_IOPadOut4mA
place_pad -row IO_WEST -location [calc_vertical_pad_location 2 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_tx_er} -master sg13g2_IOPadOut4mA
place_pad -row IO_WEST -location [calc_vertical_pad_location 1 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPad_io_phy_rx_clk} -master sg13g2_IOPadIn
place_pad -row IO_WEST -location [calc_vertical_pad_location 0 10 $IO_LENGTH $IO_WIDTH $BONDPAD_SIZE $SEALRING_OFFSET] {sg13g2_IOPadIOVss_west_0} -master sg13g2_IOPadIOVss

#Place Corner Cells and Filler
place_corners sg13g2_Corner
set iofill {
 sg13g2_Filler10000
 sg13g2_Filler4000
 sg13g2_Filler2000
 sg13g2_Filler1000
 sg13g2_Filler400
 sg13g2_Filler200
}

place_io_fill -row IO_NORTH {*}$iofill
place_io_fill -row IO_SOUTH {*}$iofill
place_io_fill -row IO_WEST {*}$iofill
place_io_fill -row IO_EAST {*}$iofill
connect_by_abutment
place_bondpad -bond bondpad_70x70 sg13g2_IOPad* -offset {5.0 -70.0}
remove_io_rows
