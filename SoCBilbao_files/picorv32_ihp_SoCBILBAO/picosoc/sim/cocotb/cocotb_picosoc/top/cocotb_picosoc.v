// cocotb_picosoc.v
// Wrapper top para simulación cocotb del SoCBilbao.
// Basado en arty_top_flash.v — instancia SoCBILBAO_top + spiflash,
// y adapta los nombres de puertos a los esperados por el testbench.
//
// Señales esperadas por cocotb_picosoc.py:
//   clk, rst_n
//   uart_0_rx, uart_0_tx
//   mii_0_rxd[3:0], mii_0_rx_er, mii_0_rx_dv, mii_0_rx_clk
//   mii_0_txd[3:0], mii_0_tx_er, mii_0_tx_en, mii_0_tx_clk

`timescale 1ns/1ps

module cocotb_picosoc #(
    parameter integer DATA_WIDTH = 32,
    parameter integer MEM_WORDS  = 512
)(
    // Clock y reset (active low, igual que resetn del SoC)
    input  wire        clk,
    input  wire        rst_n,

    // UART 0
    input  wire        uart_0_rx,
    output wire        uart_0_tx,

    // MII 0 — RX (entradas desde el PHY simulado)
    input  wire        mii_0_rx_clk,
    input  wire [3:0]  mii_0_rxd,
    input  wire        mii_0_rx_dv,
    input  wire        mii_0_rx_er,

    // MII 0 — TX (salidas hacia el PHY simulado)
    input  wire        mii_0_tx_clk,
    output wire [3:0]  mii_0_txd,
    output wire        mii_0_tx_en,
    output wire        mii_0_tx_er,

    output wire flash_csb_mon,
    output wire flash_clk_mon
);

    // ---------------------------------------------------------------
    // Señales internas flash 
    // ---------------------------------------------------------------
    wire        f_csb, f_clk;
    wire        f_io0_oe, f_io0_do, f_io0_di;
    wire        f_io1_oe, f_io1_do, f_io1_di;
    wire        f_io2_oe, f_io2_do, f_io2_di;
    wire        f_io3_oe, f_io3_do, f_io3_di;

    wire        io0, io1, io2, io3;

    assign io0 = f_io0_oe ? f_io0_do : 1'bz;
    assign io1 = f_io1_oe ? f_io1_do : 1'bz;
    assign io2 = f_io2_oe ? f_io2_do : 1'bz;
    assign io3 = f_io3_oe ? f_io3_do : 1'bz;

    assign f_io0_di = io0;
    assign f_io1_di = io1;
    assign f_io2_di = io2;
    assign f_io3_di = io3;

    // ---------------------------------------------------------------
    // Señales internas no expuestas en la TB
    // ---------------------------------------------------------------
    wire [31:0] gpio_output;
    wire        phy_col    = 1'b0;
    wire        phy_crs    = 1'b0;
    wire        phy_mii_clk;
    wire        phy_rst_n_int;
    wire        phy_mii_data;   
    wire        pps_pin_1cycle;
    wire        pps_led_100ms;
    wire        phy_tx_er_int;  

    assign flash_csb_mon = f_csb;
    assign flash_clk_mon = f_clk;

    // ---------------------------------------------------------------
    // Instancia del SoC (igual que arty_top_flash pero con clk directo)
    // ---------------------------------------------------------------
    SoCBILBAO_top #(
        .MEM_WORDS(MEM_WORDS)
    ) u_soc (
        .clk            (clk),
        .resetn         (rst_n),

        .ser_tx         (uart_0_tx),
        .ser_rx         (uart_0_rx),

        .gpio_out       (gpio_output),

        // Flash split
        .flash_csb      (f_csb),
        .flash_clk      (f_clk),
        .flash_io0_oe   (f_io0_oe), .flash_io0_do(f_io0_do), .flash_io0_di(f_io0_di),
        .flash_io1_oe   (f_io1_oe), .flash_io1_do(f_io1_do), .flash_io1_di(f_io1_di),
        .flash_io2_oe   (f_io2_oe), .flash_io2_do(f_io2_do), .flash_io2_di(f_io2_di),
        .flash_io3_oe   (f_io3_oe), .flash_io3_do(f_io3_do), .flash_io3_di(f_io3_di),

        // MII RX
        .phy_rx_clk     (mii_0_rx_clk),
        .phy_rx_data    (mii_0_rxd),
        .phy_dv         (mii_0_rx_dv),
        .phy_rx_er      (mii_0_rx_er),
        .phy_col        (phy_col),
        .phy_crs        (phy_crs),

        // MII TX
        .phy_tx_clk     (mii_0_tx_clk),
        .phy_tx_data    (mii_0_txd),
        .phy_tx_en      (mii_0_tx_en),
        .phy_tx_er      (phy_tx_er_int),

        // MDIO/MDC
        .phy_mii_clk    (phy_mii_clk),
        .phy_rst_n      (phy_rst_n_int),
        .phy_mii_data   (phy_mii_data),

        // PPS
        .pps_pin_1cycle (pps_pin_1cycle),
        .pps_led_100ms  (pps_led_100ms)
    );

    assign mii_0_tx_er = phy_tx_er_int;

    // ---------------------------------------------------------------
    // Modelo de flash SPI con el firmware
    // ---------------------------------------------------------------
    spiflash spiflash (
        .csb  (f_csb),
        .clk  (f_clk),
        .io0  (io0),
        .io1  (io1),
        .io2  (io2),
        .io3  (io3)
    );

endmodule