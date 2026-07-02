module SoCBILBAO_top (
    input clk,
    input resetn,

    // UART
    output ser_tx,
    input  ser_rx,

    // Interfaz Flash (Señales Lógicas Puras)
    output flash_csb,
    output flash_clk,
    
    output flash_io0_oe, // Output Enable para IO0
    output flash_io0_do, // Data Out para IO0
    input  flash_io0_di, // Data In para IO0

    output flash_io1_oe,
    output flash_io1_do,
    input  flash_io1_di,

    output flash_io2_oe,
    output flash_io2_do,
    input  flash_io2_di,

    output flash_io3_oe,
    output flash_io3_do,
    input  flash_io3_di,

    // Bus de Memoria / GPIOs (Para LEDs o control)
    output [31:0] gpio_out,
    
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
    
    //inout  wire         phy_mii_data,     
    output mii_data_oe,     
    output mii_data_do,     
    input  mii_data_di_raw, 
//    output        pmd_pad_i  ,
//    output        pmd_pad_o  ,
//    input         pmd_padoe_o 

    output          pps_pin_1cycle,
    output          pps_led_100ms 
);

    parameter integer MEM_WORDS = 512; 

    wire [31:0] iomem_addr;
    wire [31:0] iomem_wdata;
    wire [3:0]  iomem_wstrb;
    wire        iomem_valid;
    reg         iomem_ready;
    reg  [31:0] iomem_rdata;
    
    wire mii_data_oe, mii_data_do, mii_data_di_raw; 

    reg  [31:0] gpio_reg;
    assign gpio_out = gpio_reg;

    // Lógica de periféricos (GPIO en dirección 0x03000000)
    always @(posedge clk) begin
        if (!resetn) begin
            gpio_reg <= 0;
        end else begin
            iomem_ready <= 0;
            // Mapa de memoria básico
            if (iomem_valid && !iomem_ready && iomem_addr[31:24] == 8'h03) begin
                iomem_ready <= 1;
                iomem_rdata <= gpio_reg;
                if (iomem_wstrb[0]) gpio_reg[ 7: 0] <= iomem_wdata[ 7: 0];
                if (iomem_wstrb[1]) gpio_reg[15: 8] <= iomem_wdata[15: 8];
                if (iomem_wstrb[2]) gpio_reg[23:16] <= iomem_wdata[23:16];
                if (iomem_wstrb[3]) gpio_reg[31:24] <= iomem_wdata[31:24];
            end
        end
    end


    picosoc_SoCBilbao_minimac2 #(
        .MEM_WORDS(MEM_WORDS)
    ) soc (
        .clk          (clk),
        .resetn       (resetn),
        .ser_tx       (ser_tx),
        .ser_rx       (ser_rx),
        .flash_csb    (flash_csb),
        .flash_clk    (flash_clk),

        .flash_io0_oe (flash_io0_oe),
        .flash_io1_oe (flash_io1_oe),
        .flash_io2_oe (flash_io2_oe),
        .flash_io3_oe (flash_io3_oe),

        .flash_io0_do (flash_io0_do),
        .flash_io1_do (flash_io1_do),
        .flash_io2_do (flash_io2_do),
        .flash_io3_do (flash_io3_do),

        .flash_io0_di (flash_io0_di),
        .flash_io1_di (flash_io1_di),
        .flash_io2_di (flash_io2_di),
        .flash_io3_di (flash_io3_di),

        .iomem_valid  (iomem_valid),
        .iomem_ready  (iomem_ready),
        .iomem_wstrb  (iomem_wstrb),
        .iomem_addr   (iomem_addr),
        .iomem_wdata  (iomem_wdata),
        .iomem_rdata  (iomem_rdata),
        
        .irq_7         (1'b0),
        .irq_8         (1'b0),
        .irq_9         (1'b0),
        .irq_10        (1'b0),
        .irq_11        (1'b0),
        
        .phy_rx_clk   (phy_rx_clk ),
        .phy_rx_data  (phy_rx_data),
        .phy_dv       (phy_dv     ),
        .phy_rx_er    (phy_rx_er  ),
        .phy_col      (phy_col    ),
        .phy_crs      (phy_crs    ),
                      
        .phy_tx_clk   (phy_tx_clk ),
        .phy_tx_data  (phy_tx_data),
        .phy_tx_en    (phy_tx_en  ),
        .phy_tx_er    (phy_tx_er  ),
                         
        .phy_mii_clk  (phy_mii_clk),
        .phy_rst_n    (phy_rst_n  ),
        
        //.phy_mii_data     (phy_mii_data ),    
        .mii_data_oe        (mii_data_oe    )  ,     
        .mii_data_do        (mii_data_do    ),     
        .mii_data_di_raw    (mii_data_di_raw),          
//        .pmd_pad_i    (pmd_pad_i   ),
//        .pmd_pad_o    (pmd_pad_o   ),
//        .pmd_padoe_o  (pmd_padoe_o )

        .pps_pin_1cycle (pps_pin_1cycle),
        .pps_led_100ms  (pps_led_100ms)
    );

endmodule
