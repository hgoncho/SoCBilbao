`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/10/2026 12:47:27 PM
// Design Name: 
// Module Name: arty_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module arty_top(
    input sys_clk_100MHz,      
    input sys_rst_n,    // Reset (BTNC)
    output status_rst,
    
    output uart_tx,
    input  uart_rx,
    
    output [1:0] led,    // Veremos el estado del GPIO del ASIC aquí
    
    // RX (Entradas desde el PHY)
    input          phy_rx_clk,
    input [3:0]    phy_rx_data,
    input          phy_dv,
    input          phy_rx_er,
    input          phy_col,
    input          phy_crs,

    // TX (Salidas hacia el PHY)
    input          phy_tx_clk, 
    output [3:0]   phy_tx_data,   
    output         phy_tx_en,
    //output         phy_tx_er,
 
    // Management (MDIO/MDC)
    output         phy_mii_clk,
    output         phy_rst_n,
    
    inout  wire         phy_mii_data,
    
    output              phy_ref_clk,
    
    output pps_pin_1cycle,
    output pps_led_100ms ,
    
    // SPI FLASH
    output f_csb,
	inout io0, // MOSI
	inout io1, // MISO
	inout io2,
	inout io3

);

    wire f_clk;
    wire f_io0_oe, f_io0_do, f_io0_di;
    wire f_io1_oe, f_io1_do, f_io1_di;
    wire f_io2_oe, f_io2_do, f_io2_di;
    wire f_io3_oe, f_io3_do, f_io3_di;
    wire [31:0] gpio_output;
    
    wire clk_50MHz;
    
    assign status_rst = sys_rst_n;
    
    
    clk_wiz_0 div_clk(
    // Clock out ports
        .clk_out1(clk_50MHz),
        .clk_out2(phy_ref_clk),
    // Clock in ports
        .clk_in1(sys_clk_100MHz)
    );

   
    SoCBILBAO_top #(
        .MEM_WORDS(512) // Forzamos 2KB para que cuadre con la celda IHP
    ) u_asic (
        .clk(clk_50MHz),
        .resetn(sys_rst_n), 
        
        .ser_tx(uart_tx),
        .ser_rx(uart_rx),
        
        .gpio_out(gpio_output),
        
        // Interfaz Flash Split
        .flash_csb(f_csb),
        .flash_clk(f_clk),
        
        .flash_io0_oe(f_io0_oe), .flash_io0_do(f_io0_do), .flash_io0_di(f_io0_di),
        .flash_io1_oe(f_io1_oe), .flash_io1_do(f_io1_do), .flash_io1_di(f_io1_di),
        .flash_io2_oe(f_io2_oe), .flash_io2_do(f_io2_do), .flash_io2_di(f_io2_di),
        .flash_io3_oe(f_io3_oe), .flash_io3_do(f_io3_do), .flash_io3_di(f_io3_di),
                
        .phy_rx_clk   (phy_rx_clk ),  .phy_rx_data  (phy_rx_data), .phy_dv       (phy_dv     ),
        .phy_rx_er    (phy_rx_er  ),  .phy_col      (phy_col    ), .phy_crs      (phy_crs    ),
                      
        .phy_tx_clk   (phy_tx_clk ), .phy_tx_data  (phy_tx_data),
        .phy_tx_en    (phy_tx_en  ), .phy_tx_er    (phy_tx_er  ),
                         
        .phy_mii_clk  (phy_mii_clk), .phy_rst_n    (phy_rst_n  ),
               
        .phy_mii_data     (phy_mii_data ),
        
        .pps_pin_1cycle (pps_pin_1cycle),
        .pps_led_100ms  (pps_led_100ms )
        
                        
    );
    
    assign led = gpio_output[7:0];
    
    // -----------------------------------------------------------
    // Cables Tri-estado para conectar la Flash
    // -----------------------------------------------------------
    wire io0, io1, io2, io3;

    assign io0 = f_io0_oe ? f_io0_do : 1'bz;
    assign io1 = f_io1_oe ? f_io1_do : 1'bz;
    assign io2 = f_io2_oe ? f_io2_do : 1'bz;
    assign io3 = f_io3_oe ? f_io3_do : 1'bz;

    assign f_io0_di = io0;
    assign f_io1_di = io1;
    assign f_io2_di = io2;
    assign f_io3_di = io3;
    
   // STARTUPE2: STARTUP Block para acceder al reloj de la SPI Flash
   // Artix-7 
   STARTUPE2 #(
      .PROG_USR("FALSE"),  
      .SIM_CCLK_FREQ(0.0)  
   ) STARTUPE2_inst (
      // --- SALIDAS ---
      .CFGCLK(),      
      .CFGMCLK(),     
      .EOS(),         
      .PREQ(),        
      
      // --- ENTRADAS DE CONTROL ---
      .CLK(1'b0),          // No usamos reloj de usuario extra
      .GSR(1'b0),          // Global Set/Reset inactivo
      .GTS(1'b0),          // Global Tri-State inactivo
      .KEYCLEARB(1'b1),    // Clear inactivo (activo a nivel bajo)
      .PACK(1'b0),         // Program Acknowledge inactivo
      
      // --- CONTROL DEL PIN CCLK (EL RELOJ DE LA FLASH) ---
      .USRCCLKO(f_clk),    
      .USRCCLKTS(1'b0),    // Enable del reloj (0 = habilitado, 1 = alta impedancia)
      
      // --- CONTROL DEL PIN DONE  ---
      .USRDONEO(1'b1),    
      .USRDONETS(1'b1)     
   );
   


endmodule
