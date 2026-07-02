module zedboard_top (
    input sys_clk,      
    input sys_rst_n,    // Reset (BTNC)
    output uart_tx,
    input  uart_rx,
    output [7:0] led,    // Veremos el estado del GPIO del ASIC aquí
    
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
    output         phy_tx_er,
 
    // Management (MDIO/MDC)
    output         phy_mii_clk,
    output         phy_rst_n,
    
    inout  wire         phy_mii_data     
//    output         pmd_pad_i , 
//    output         pmd_pad_o  ,
//    input          pmd_padoe_o
);

    wire f_csb, f_clk;
    wire f_io0_oe, f_io0_do, f_io0_di;
    wire f_io1_oe, f_io1_do, f_io1_di;
    wire f_io2_oe, f_io2_do, f_io2_di;
    wire f_io3_oe, f_io3_do, f_io3_di;
    wire [31:0] gpio_output;


    SoCBILBAO_top #(
        .MEM_WORDS(512)
    ) u_asic (
        .clk(sys_clk),
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
               
        .phy_mii_data     (phy_mii_data )            
//        .pmd_pad_i    (pmd_pad_i   ),
//        .pmd_pad_o    (pmd_pad_o   ),
//        .pmd_padoe_o  (pmd_padoe_o )
        
    );
        
    
    assign led = gpio_output[7:0];
   

    // -----------------------------------------------------------
    // 2. Cables Tri-estado para conectar la Flash
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

    // -----------------------------------------------------------
    // 3. La Memoria Flash con tu firmware
    // -----------------------------------------------------------
    spiflash spiflash (
        .csb(f_csb),
        .clk(f_clk),
        .io0(io0),
        .io1(io1),
        .io2(io2),
        .io3(io3)
    );

endmodule