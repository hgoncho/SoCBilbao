`timescale 1ns/1ps
// definimos las señales que estarán conectadas a los I/O
module picosoc_ihp (
 inout wire io_clk_PAD,
 inout wire io_resetn_PAD,

 inout wire io_ser_tx_PAD,
 inout wire io_ser_rx_PAD, 

 inout wire io_flash_csb_PAD,
 inout wire io_flash_clk_PAD,
 inout wire io_flash_io0_PAD,
 inout wire io_flash_io1_PAD,
 inout wire io_flash_io2_PAD,
 inout wire io_flash_io3_PAD,

 inout wire io_phy_rx_clk_PAD,
 inout wire io_phy_rx_data_0_PAD,
 inout wire io_phy_rx_data_1_PAD,
 inout wire io_phy_rx_data_2_PAD,
 inout wire io_phy_rx_data_3_PAD,
 inout wire io_phy_dv_PAD,
 inout wire io_phy_rx_er_PAD,
 inout wire io_phy_col_PAD,
 inout wire io_phy_crs_PAD,

 inout wire io_phy_tx_clk_PAD,
 inout wire io_phy_tx_data_0_PAD,
 inout wire io_phy_tx_data_1_PAD,
 inout wire io_phy_tx_data_2_PAD,
 inout wire io_phy_tx_data_3_PAD,
 inout wire io_phy_tx_en_PAD,
 inout wire io_phy_tx_er_PAD,

 inout wire io_phy_mii_clk_PAD,
 inout wire io_phy_rst_n_PAD,
 inout wire io_phy_mii_data_PAD,

 inout wire io_pps_pin_1cycle_PAD,
 inout wire io_pps_led_100ms_PAD
);


wire sg13g2_IOPad_io_clock_p2c;
wire sg13g2_IOPad_io_reset_p2c;
wire clock;
wire reset;

// FLASH
wire sg13g2_IOPad_io_flash_csb_c2p;
wire sg13g2_IOPad_io_flash_clk_c2p;

wire sg13g2_IOPad_io_flash_io0_oe_c2p;
wire sg13g2_IOPad_io_flash_io1_oe_c2p;
wire sg13g2_IOPad_io_flash_io2_oe_c2p;
wire sg13g2_IOPad_io_flash_io3_oe_c2p;

wire sg13g2_IOPad_io_flash_io0_do_c2p;
wire sg13g2_IOPad_io_flash_io1_do_c2p;
wire sg13g2_IOPad_io_flash_io2_do_c2p;
wire sg13g2_IOPad_io_flash_io3_do_c2p;

wire sg13g2_IOPad_io_flash_io0_di_p2c;
wire sg13g2_IOPad_io_flash_io1_di_p2c;
wire sg13g2_IOPad_io_flash_io2_di_p2c;
wire sg13g2_IOPad_io_flash_io3_di_p2c;

// PHY RX
wire sg13g2_IOPad_io_phy_rx_clk_p2c;
wire [0:3] sg13g2_IOPad_io_phy_rx_data_p2c;
wire sg13g2_IOPad_io_phy_dv_p2c;
wire sg13g2_IOPad_io_phy_rx_er_p2c;
wire sg13g2_IOPad_io_phy_col_p2c;
wire sg13g2_IOPad_io_phy_crs_p2c;

// PHY TX
wire sg13g2_IOPad_io_phy_tx_clk_p2c;
wire [0:3] sg13g2_IOPad_io_phy_tx_data_c2p;
wire sg13g2_IOPad_io_phy_tx_en_c2p;
wire sg13g2_IOPad_io_phy_tx_er_c2p;

// PPS
wire sg13g2_IOPad_io_pps_pin_1cycle_c2p;
wire sg13g2_IOPad_io_pps_led_100ms_c2p;



// Clock
sg13g2_IOPadIn sg13g2_IOPad_io_clock (.p2c (sg13g2_IOPad_io_clock_p2c), .pad (io_clk_PAD));

// Reset
sg13g2_IOPadIn sg13g2_IOPad_io_reset (.p2c (sg13g2_IOPad_io_reset_p2c), .pad (io_resetn_PAD));

// PHY RX
sg13g2_IOPadIn sg13g2_IOPad_io_phy_rx_clk       (.p2c (sg13g2_IOPad_io_phy_rx_clk_p2c), .pad (io_phy_rx_clk_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_rx_data_0    (.p2c (sg13g2_IOPad_io_phy_rx_data_p2c[0]), .pad (io_phy_rx_data_0_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_rx_data_1    (.p2c (sg13g2_IOPad_io_phy_rx_data_p2c[1]), .pad (io_phy_rx_data_1_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_rx_data_2    (.p2c (sg13g2_IOPad_io_phy_rx_data_p2c[2]), .pad (io_phy_rx_data_2_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_rx_data_3    (.p2c (sg13g2_IOPad_io_phy_rx_data_p2c[3]), .pad (io_phy_rx_data_3_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_dv           (.p2c (sg13g2_IOPad_io_phy_dv_p2c), .pad (io_phy_dv_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_rx_er        (.p2c (sg13g2_IOPad_io_phy_rx_er_p2c), .pad (io_phy_rx_er_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_col          (.p2c (sg13g2_IOPad_io_phy_col_p2c), .pad (io_phy_col_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_phy_crs          (.p2c (sg13g2_IOPad_io_phy_crs_p2c), .pad (io_phy_crs_PAD));

// PHY TX
sg13g2_IOPadIn sg13g2_IOPad_io_phy_tx_clk (.p2c (sg13g2_IOPad_io_phy_tx_clk_p2c), .pad (io_phy_tx_clk_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_tx_data_0 (.c2p (sg13g2_IOPad_io_phy_tx_data_c2p[0]), .pad (io_phy_tx_data_0_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_tx_data_1 (.c2p (sg13g2_IOPad_io_phy_tx_data_c2p[1]), .pad (io_phy_tx_data_1_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_tx_data_2 (.c2p (sg13g2_IOPad_io_phy_tx_data_c2p[2]), .pad (io_phy_tx_data_2_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_tx_data_3 (.c2p (sg13g2_IOPad_io_phy_tx_data_c2p[3]), .pad (io_phy_tx_data_3_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_tx_en (.c2p (sg13g2_IOPad_io_phy_tx_en_c2p), .pad (io_phy_tx_en_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_tx_er (.c2p (sg13g2_IOPad_io_phy_tx_er_c2p), .pad (io_phy_tx_er_PAD));

// PHY MII
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_mii_clk (.c2p (sg13g2_IOPad_io_phy_mii_clk_c2p), .pad (io_phy_mii_clk_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_phy_rst_n (.c2p (sg13g2_IOPad_io_phy_rst_n_c2p), .pad (io_phy_rst_n_PAD));
sg13g2_IOPadInOut4mA sg13g2_IOPad_io_mii_data (.c2p (sg13g2_IOPad_io_mii_data_do_c2p), .c2p_en (sg13g2_IOPad_io_mii_data_oe_c2p), .p2c (sg13g2_IOPad_io_fmii_data_di_p2c), .pad (io_phy_mii_data_PAD));


// PPS
sg13g2_IOPadOut4mA sg13g2_IOPad_io_pps_pin_1cycle (.c2p (sg13g2_IOPad_io_pps_pin_1cycle_c2p), .pad (io_pps_pin_1cycle_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_pps_led_100ms  (.c2p (sg13g2_IOPad_io_pps_led_100ms_c2p), .pad (io_pps_led_100ms_PAD));


// UART
sg13g2_IOPadOut4mA sg13g2_IOPad_io_ser_tx (.c2p (sg13g2_IOPad_io_ser_tx_c2p), .pad (io_ser_tx_PAD));
sg13g2_IOPadIn sg13g2_IOPad_io_ser_rx (.p2c (sg13g2_IOPad_io_ser_rx_p2c), .pad (io_ser_rx_PAD));

// Flash controllers
sg13g2_IOPadOut4mA sg13g2_IOPad_io_flash_csb (.c2p (sg13g2_IOPad_io_flash_csb_c2p), .pad (io_flash_csb_PAD));
sg13g2_IOPadOut4mA sg13g2_IOPad_io_flash_clk (.c2p (sg13g2_IOPad_io_flash_clk_c2p), .pad (io_flash_clk_PAD));

sg13g2_IOPadInOut4mA sg13g2_IOPad_io_flash_io0 (.c2p (sg13g2_IOPad_io_flash_io0_do_c2p), .c2p_en (sg13g2_IOPad_io_flash_io0_oe_c2p), .p2c (sg13g2_IOPad_io_flash_io0_di_p2c), .pad (io_flash_io0_PAD));
sg13g2_IOPadInOut4mA sg13g2_IOPad_io_flash_io1 (.c2p (sg13g2_IOPad_io_flash_io1_do_c2p), .c2p_en (sg13g2_IOPad_io_flash_io1_oe_c2p), .p2c (sg13g2_IOPad_io_flash_io1_di_p2c), .pad (io_flash_io1_PAD));
sg13g2_IOPadInOut4mA sg13g2_IOPad_io_flash_io2 (.c2p (sg13g2_IOPad_io_flash_io2_do_c2p), .c2p_en (sg13g2_IOPad_io_flash_io2_oe_c2p), .p2c (sg13g2_IOPad_io_flash_io2_di_p2c), .pad (io_flash_io2_PAD));
sg13g2_IOPadInOut4mA sg13g2_IOPad_io_flash_io3 (.c2p (sg13g2_IOPad_io_flash_io3_do_c2p), .c2p_en (sg13g2_IOPad_io_flash_io3_oe_c2p), .p2c (sg13g2_IOPad_io_flash_io3_di_p2c), .pad (io_flash_io3_PAD));

// async signals
assign clock = sg13g2_IOPad_io_clock_p2c;
assign reset = sg13g2_IOPad_io_reset_p2c;

SoCBILBAO_top picosoc_core (
    .clk(clock),
    .resetn(reset),

    .ser_tx(sg13g2_IOPad_io_ser_tx_c2p),
    .ser_rx(sg13g2_IOPad_io_ser_rx_p2c),

    .flash_csb      (sg13g2_IOPad_io_flash_csb_c2p),
    .flash_clk      (sg13g2_IOPad_io_flash_clk_c2p),
    .flash_io0_oe   (sg13g2_IOPad_io_flash_io0_oe_c2p),
    .flash_io1_oe   (sg13g2_IOPad_io_flash_io1_oe_c2p),
    .flash_io2_oe   (sg13g2_IOPad_io_flash_io2_oe_c2p),
    .flash_io3_oe   (sg13g2_IOPad_io_flash_io3_oe_c2p),
    .flash_io0_do   (sg13g2_IOPad_io_flash_io0_do_c2p),
    .flash_io1_do   (sg13g2_IOPad_io_flash_io1_do_c2p),
    .flash_io2_do   (sg13g2_IOPad_io_flash_io2_do_c2p),
    .flash_io3_do   (sg13g2_IOPad_io_flash_io3_do_c2p),
    .flash_io0_di   (sg13g2_IOPad_io_flash_io0_di_p2c),
    .flash_io1_di   (sg13g2_IOPad_io_flash_io1_di_p2c),
    .flash_io2_di   (sg13g2_IOPad_io_flash_io2_di_p2c),
    .flash_io3_di   (sg13g2_IOPad_io_flash_io3_di_p2c),


    .phy_rx_clk (sg13g2_IOPad_io_phy_rx_clk_p2c),
    .phy_rx_data(sg13g2_IOPad_io_phy_rx_data_p2c),
    .phy_dv     (sg13g2_IOPad_io_phy_dv_p2c),    
    .phy_rx_er  (sg13g2_IOPad_io_phy_rx_er_p2c), 
    .phy_col    (sg13g2_IOPad_io_phy_col_p2c),
    .phy_crs    (sg13g2_IOPad_io_phy_crs_p2c),

    .phy_tx_clk (sg13g2_IOPad_io_phy_tx_clk_p2c),    
    .phy_tx_data(sg13g2_IOPad_io_phy_tx_data_c2p),
    .phy_tx_en  (sg13g2_IOPad_io_phy_tx_en_c2p),
    .phy_tx_er  (sg13g2_IOPad_io_phy_tx_er_c2p),

    

    .phy_mii_clk    (sg13g2_IOPad_io_phy_mii_clk_c2p),
    .phy_rst_n      (sg13g2_IOPad_io_phy_rst_n_c2p),
    //.phy_mii_data (sg13g2_IOPad_io_phy_mii_data_inout),
    .mii_data_oe    (sg13g2_IOPad_io_mii_data_oe_c2p),
    .mii_data_do    (sg13g2_IOPad_io_mii_data_do_c2p),
    .mii_data_di_raw(sg13g2_IOPad_io_fmii_data_di_p2c),

    .pps_pin_1cycle (sg13g2_IOPad_io_pps_pin_1cycle_c2p),
    .pps_led_100ms  (sg13g2_IOPad_io_pps_led_100ms_c2p),

);
endmodule
