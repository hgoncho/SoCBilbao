/*
 *  PicoSoC - A simple example SoC using PicoRV32
 *
 *  Copyright (C) 2017  Claire Xenia Wolf <claire@yosyshq.com>
 *
 *  Permission to use, copy, modify, and/or distribute this software for any
 *  purpose with or without fee is hereby granted, provided that the above
 *  copyright notice and this permission notice appear in all copies.
 *
 *  THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 *  WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 *  MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 *  ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 *  WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 *  ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 *  OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */

`ifndef PICORV32_REGS
`ifdef PICORV32_V
//`error "picosoc.v must be read before picorv32.v!"
`endif

`define PICORV32_REGS picosoc_regs
`endif

`ifndef PICOSOC_MEM
`define PICOSOC_MEM picosoc_mem
`endif

// this macro can be used to check if the verilog files in your
// design are read in the correct order.
`define PICOSOC_V

module picosoc_SoCBilbao_minimac2(
	input clk,
	input resetn,

	output        iomem_valid,
	input         iomem_ready,
	output [ 3:0] iomem_wstrb,
	output [31:0] iomem_addr,
	output [31:0] iomem_wdata,
	input  [31:0] iomem_rdata,

	input  irq_7,
	input  irq_8,
	input  irq_9,
	input  irq_10,
	input  irq_11,

	output ser_tx,
	input  ser_rx,

    // Salidas Flash
	output flash_csb,
	output flash_clk,

	output flash_io0_oe,
	output flash_io1_oe,
	output flash_io2_oe,
	output flash_io3_oe,

	output flash_io0_do,
	output flash_io1_do,
	output flash_io2_do,
	output flash_io3_do,

	input  flash_io0_di,
	input  flash_io1_di,
	input  flash_io2_di,
	input  flash_io3_di,
	
    // RX (Entradas desde el PHY)
    input           phy_rx_clk,
    input  [3:0]    phy_rx_data,
    input           phy_dv,
    input           phy_rx_er,
    input           phy_col,
    input           phy_crs,

    // TX (Salidas hacia el PHY)
    input           phy_tx_clk, 
    output [3:0]    phy_tx_data,   
    output          phy_tx_en,
    output          phy_tx_er,
 
    // Management (MDIO/MDC)
    output          phy_mii_clk,
    output          phy_rst_n, 
    //inout           phy_mii_data,
    output mii_data_oe,     
    output mii_data_do,     
    input  mii_data_di_raw, 
    
    // PPS 
    output          pps_pin_1cycle,
    output          pps_led_100ms
    

);

//---------------------------------------------------------------
//Parametros de configuración
//---------------------------------------------------------------
	parameter [0:0] BARREL_SHIFTER = 1;
	parameter [0:0] ENABLE_MUL = 1;
	parameter [0:0] ENABLE_DIV = 1;
	parameter [0:0] ENABLE_FAST_MUL = 1;
	parameter [0:0] ENABLE_COMPRESSED = 1;
	parameter [0:0] ENABLE_COUNTERS = 1;
	parameter [0:0] ENABLE_IRQ_QREGS = 1;

	parameter integer MEM_WORDS = 512;
	parameter [31:0] STACKADDR = (4*MEM_WORDS);       // end of memory
	parameter [31:0] PROGADDR_RESET = 32'h 0030_0000; // 3 MB into flash
	parameter [31:0] PROGADDR_IRQ = 32'h 0030_0010;
	

//---------------------------------------------------------------
//Señales del maestro wb (internos CPU)
//---------------------------------------------------------------
	wire [31:0] wb_m_adr_o;
	wire [31:0] wb_m_dat_o;
	reg  [31:0] wb_m_dat_i;
	wire        wb_m_we_o;
	wire [3:0]  wb_m_sel_o;
	wire        wb_m_stb_o;
	wire        wb_m_cyc_o;
	reg         wb_m_ack_i;
	wire        wb_m_err_o;


//--------------------------------------------------------------- 
//Señales del esclavo wb minimac2 (mm2)                         
//--------------------------------------------------------------- 
	wire [31:0] wb_mm2_adr_i;
	wire [31:0] wb_mm2_dat_i;
	wire [31:0] wb_mm2_dat_o;
	wire        wb_mm2_we_i;
	wire [3:0]  wb_mm2_sel_i;
	reg         wb_mm2_stb_i;
	wire        wb_mm2_cyc_i;
	wire        wb_mm2_ack_o;
	wire        wb_mm2_err_i;   
	
	wire mii_data_oe, mii_data_do, mii_data_di_raw; 
	
	
//--------------------------------------------------------------- 
//Señales del esclavo wb ha1588 (ha)                         
//--------------------------------------------------------------- 
	wire [31:0] wb_ha_adr_i;
	wire [31:0] wb_ha_dat_i;
	wire [31:0] wb_ha_dat_o;
	wire        wb_ha_we_i;
	wire [3:0]  wb_ha_sel_i;
	reg         wb_ha_stb_i;
	wire        wb_ha_cyc_i;
	wire        wb_ha_ack_o;
	wire        wb_ha_err_i;
	
	
//---------------------------------------------------------------
//Señales PTP para el RTC (conexión a oscilador?)
//--------------------------------------------------------------
    wire [31:0] ptp_ns;
    wire [47:0] ptp_sec;
    wire        ptp_pps;
    
	
//---------------------------------------------------------------
//Señales nativas del core (internos CPU)
//--------------------------------------------------------------
	wire mem_valid;
	wire mem_instr;
	wire mem_ready;
	wire [31:0] mem_addr;
	wire [31:0] mem_wdata;
	wire [3:0] mem_wstrb;
	wire [31:0] mem_rdata;
	
	
//---------------------------------------------------------------
//Señales SPI (FLASH)
//---------------------------------------------------------------
	wire spimem_ready;
	wire [31:0] spimem_rdata;


//---------------------------------------------------------------
//Señales RAM 
//---------------------------------------------------------------
	reg ram_ready;
	wire [31:0] ram_rdata;
	
	
//---------------------------------------------------------------
//ADAPT ADOR CSR (BUS NATIVO to CSR)
//--------------------------------------------------------------- 	
    //Decodificador de direcciones para Minimac2 (Rango 0x0200_0020 - 0x0200_003F) 
    //Mapa de registros
    //  0x0200_0020: PHY_RST    (Registro 0)
    //  0x0200_0024: MII_MGMT   (Registro 1)
    //  0x0200_0028: SLOT0_CTL  (Registro 2)
    //  0x0200_002C: RX_COUNT0  (Registro 3)
    //  0x0200_0030: SLOT1_CTL  (Registro 4)
    //  0x0200_0034: RX_COUNT1  (Registro 5)
    //  0x0200_0038: TX_COUNT   (Registro 6)
    
    wire minimac2_csr_sel = mem_valid && (mem_addr >= 32'h 0200_0020 && mem_addr <= 32'h 0200_0038);
    
	//Solo si esta seleccionado y hay stb 
    wire minimac2_csr_we = minimac2_csr_sel && |mem_wstrb;           
        
    wire [31:0] minimac2_csr_do;    
    wire [31:0] minimac2_csr_di= minimac2_csr_sel ? mem_wdata : 32'h 0000_0000;
    wire [13:0] minimac2_csr_a = minimac2_csr_sel ? {11'b0, mem_addr[4:2]} : 32'h 0000_0000;

    // Usamos mem_addr[4:2] para convertir el paso de 4 bytes en paso de 1 registro    
   
    // Delay para la lectura de registros del minimac2
    reg minimac_wait;
    always @(posedge clk) begin
        if (!resetn) 
            minimac_wait <= 0;
        else 
            minimac_wait <= minimac2_csr_sel && !minimac_wait;
    end

                                                                                                                                      
//---------------------------------------------------------------
//SELECTOR WB (BUS NATIVO to WB) 
//---------------------------------------------------------------                                                                      
// Rango: 0x0400_0000 hasta 0x0400_2FFF (12KB) 

// Minimac2 2Kb + 2Kb + 2Kb (0x0400_0000 hasta 0x0400_1FFF)

// HA1588  (0x0400_2000 hasta 0x0400_2FFF)
//      0x0400_2000 - 0x0400_203C: Regsitros RTC 
//      0x0400_2040 - 0x0400_207C: Regsitros TSU

    wire wb_mem_ready; 
	wire [31:0] wb_mem_rdata; 
	wire wb_periph_sel = mem_valid && (mem_addr >= 32'h 0400_0000 && mem_addr <= 32'h 0400_2FFF);  
	
	//Case 01 seleccion minimac2
	wire wb_periph_mm2 = mem_valid && (mem_addr >= 32'h 0400_0000 && mem_addr <= 32'h 0400_1FFF);
	
	//Case 10 seleccion ha1588
	wire wb_periph_ha  = mem_valid && (mem_addr >= 32'h 0400_2000 && mem_addr <= 32'h 0400_2FFF);
	
	wire [2:0] wb_selector;
	assign wb_selector = {1'b0, wb_periph_ha, wb_periph_mm2};
	
	// Selector de ack
	always @ (wb_selector, wb_ha_ack_o, wb_mm2_ack_o)
    begin
        case (wb_selector)
        3'b001    : wb_m_ack_i = wb_mm2_ack_o;
        3'b010    : wb_m_ack_i = wb_ha_ack_o;
        default   : wb_m_ack_i = 1'b0;
        endcase
    end
    
    // Selector de dat_i
	always @ (wb_selector, wb_ha_dat_o, wb_mm2_dat_o)
    begin
        case (wb_selector)
        3'b001    : wb_m_dat_i = wb_mm2_dat_o;
        3'b010    : wb_m_dat_i = wb_ha_dat_o;
        default   : wb_m_dat_i = 32'h0000_0000;
        endcase
    end
    
    // Activador de stb
	always @ (wb_selector, wb_m_stb_o)
    begin
        wb_mm2_stb_i = 1'b0;
        wb_ha_stb_i  = 1'b0;
        
        case (wb_selector)
        3'b001    : wb_mm2_stb_i = wb_m_stb_o;
        3'b010    : wb_ha_stb_i  = wb_m_stb_o;
        default   : 
            begin
                    wb_ha_stb_i  = 1'b0;
                    wb_mm2_stb_i = 1'b0;
            end             
        endcase
    end
    
    assign wb_mm2_dat_i = wb_m_dat_o;
    assign wb_mm2_adr_i = wb_m_adr_o;
    assign wb_mm2_we_i  = wb_m_we_o;
    assign wb_mm2_sel_i = wb_m_sel_o;
    assign wb_mm2_cyc_i = wb_m_cyc_o;
    assign wb_mm2_err_i = wb_m_err_o;
    
    assign wb_ha_dat_i = wb_m_dat_o;
    assign wb_ha_adr_i = wb_m_adr_o;
    assign wb_ha_we_i  = wb_m_we_o;
    assign wb_ha_sel_i = wb_m_sel_o;
    assign wb_ha_cyc_i = wb_m_cyc_o;
    assign wb_ha_err_i = wb_m_err_o;        
       
	
//---------------------------------------------------------------
//INTERRUPCIONES
//---------------------------------------------------------------
	wire [31:0] irq;
	
	wire irq_stall = 0;
	wire irq_uart = 0;
    wire irq_rx_minimac2;
    wire irq_tx_minimac2;
    
    wire [31:0] irq_sources;
    assign irq_sources[0]  = 0;               // Reservado
    assign irq_sources[1]  = 0;               // Reservado
    assign irq_sources[2]  = 0;               // Reservado
    assign irq_sources[3]  = irq_stall;       // IRQ Stall (Interna)
    assign irq_sources[4]  = irq_uart;        // 
    assign irq_sources[5]  = irq_tx_minimac2; // IRQ MINIMAC TX
    assign irq_sources[6]  = irq_rx_minimac2; // IRQ MINIMAC RX
    assign irq_sources[7]  = irq_7;           // Externa
    assign irq_sources[8]  = irq_8;           // Externa
    assign irq_sources[9]  = irq_9;           // Externa
    assign irq_sources[10] = irq_10;          // Externa
    assign irq_sources[11] = irq_11;          // Externa
    assign irq_sources[31:12] = 20'b0;        // Resto a cero
    
    reg [31:0] irq_status; // Regsitro de estado permanente
    reg [31:0] irq_mask;   // Máscara de habilitación
    
    // Direccion de registro
    wire irq_status_sel = mem_valid && (mem_addr == 32'h 0200_0010);
    wire irq_mask_sel   = mem_valid && (mem_addr == 32'h 0200_0014);
    
    //Gestion registro IRQ
    always @(posedge clk) begin
        if (!resetn) begin
            irq_status <= 32'b0;
            irq_mask   <= 32'b0;
        end else begin
            // --- CAPTURA (SET) --- Activamos las interrupciones cuando detectamos flanco
            irq_status <= irq_status | irq_sources;

            // --- LIMPIEZA (CLEAR) --- Enviamos desde sw un 1 a las IRQ atendidas
            if (irq_status_sel && |mem_wstrb) begin
                irq_status <= irq_status & ~mem_wdata; 
            end

            // --- MÁSCARA (WRITE) ---
            if (irq_mask_sel && |mem_wstrb) begin
                 if (mem_wstrb[0]) irq_mask[7:0]   <= mem_wdata[7:0];
                 if (mem_wstrb[1]) irq_mask[15:8]  <= mem_wdata[15:8];
                 if (mem_wstrb[2]) irq_mask[23:16] <= mem_wdata[23:16];
                 if (mem_wstrb[3]) irq_mask[31:24] <= mem_wdata[31:24];
            end
        end
    end
    
    //Envio de IRQ a la CPU
    assign irq = irq_status & irq_mask;
    
    //Variables de control
    wire [31:0] irq_ctrl_rdata = 
        irq_status_sel ? irq_status :
        irq_mask_sel   ? irq_mask   : 32'd0;
    
    wire irq_ctrl_sel = irq_status_sel || irq_mask_sel;

/*
	always @* begin
		irq = 0;
		irq[3] = irq_stall;
		irq[4] = irq_uart;
		irq[5] = irq_rx_minimac2;
		irq[6] = irq_tx_minimac2;
		irq[7] = irq_7;
		irq[8] = irq_8;
		irq[9] = irq_9;
		irq[10] = irq_10;
		irq[11] = irq_11;
	end*/


//---------------------------------------------------------------   
// PIN PPT Y LED PPT
//--------------------------------------------------------------- 
// Pîn activo un flanco de reloj cada segundo
// Led activo 100 ms despues de la señal pin ppt

	// contar hasta 5 000 000 * 20 ns = 100 ms
    reg [24:0] led_timer;       
    reg pps_led;
    
    always @(posedge clk) begin
        if (!resetn) begin
            led_timer <= 24'd0;
            pps_led <= 1'b0;
        end else begin
            if (ptp_pps) begin
                pps_led <= 1'b1;          
                led_timer <= 24'd5_000_000;       
            end 
            
            else if (led_timer > 0) begin
                led_timer <= led_timer - 1'b1;    
            end 
            
            else begin
                pps_led <= 1'b0;          
            end
        end
    end
    
    assign pps_pin_1cycle = ptp_pps;
    assign pps_led_100ms = pps_led;

                                                                   
//---------------------------------------------------------------   
//PERIFERICOS (BUS NATIVO)
//--------------------------------------------------------------- 
	assign iomem_valid = mem_valid && (mem_addr[31:24] > 8'h 01);
	assign iomem_wstrb = mem_wstrb;
	assign iomem_addr = mem_addr;
	assign iomem_wdata = mem_wdata;

	wire spimemio_cfgreg_sel = mem_valid && (mem_addr == 32'h 0200_0000);
	wire [31:0] spimemio_cfgreg_do;

	wire        simpleuart_reg_div_sel = mem_valid && (mem_addr == 32'h 0200_0004);
	wire [31:0] simpleuart_reg_div_do;

	wire        simpleuart_reg_dat_sel = mem_valid && (mem_addr == 32'h 0200_0008);
	wire [31:0] simpleuart_reg_dat_do;
	wire        simpleuart_reg_dat_wait;

	assign mem_ready = wb_periph_sel ? wb_mem_ready :
	        (iomem_valid && iomem_ready) || spimem_ready || ram_ready || spimemio_cfgreg_sel ||
			simpleuart_reg_div_sel || (simpleuart_reg_dat_sel && !simpleuart_reg_dat_wait)||
			(minimac2_csr_sel && minimac_wait) || irq_ctrl_sel;

	assign mem_rdata = (iomem_valid && iomem_ready) ? iomem_rdata : spimem_ready ? spimem_rdata : ram_ready ? ram_rdata :
			spimemio_cfgreg_sel ? spimemio_cfgreg_do : simpleuart_reg_div_sel ? simpleuart_reg_div_do :
			simpleuart_reg_dat_sel ? simpleuart_reg_dat_do : 
			minimac2_csr_sel ? minimac2_csr_do : 
			wb_periph_sel ? wb_mem_rdata :
			irq_ctrl_sel ? irq_ctrl_rdata :
			32'h 0000_0000;
			
			

//---------------------------------------------------------------
//INSTANCIA PICORV32 (señales en nativo)
//---------------------------------------------------------------
	picorv32 #(
		.STACKADDR(STACKADDR),
		.PROGADDR_RESET(PROGADDR_RESET),
		.PROGADDR_IRQ(PROGADDR_IRQ),
		.BARREL_SHIFTER(BARREL_SHIFTER),
		.COMPRESSED_ISA(ENABLE_COMPRESSED),
		.ENABLE_COUNTERS(ENABLE_COUNTERS),
		.ENABLE_MUL(ENABLE_MUL),
		.ENABLE_DIV(ENABLE_DIV),
		.ENABLE_FAST_MUL(ENABLE_FAST_MUL),
		.ENABLE_IRQ(1),
		.LATCHED_IRQ (32'h00000000),
		.ENABLE_IRQ_QREGS(ENABLE_IRQ_QREGS)
	) cpu (
		.clk         (clk        ),
		.resetn      (resetn     ),
		.mem_valid   (mem_valid  ),
		.mem_instr   (mem_instr  ),
		.mem_ready   (mem_ready  ),
		.mem_addr    (mem_addr   ),
		.mem_wdata   (mem_wdata  ),
		.mem_wstrb   (mem_wstrb  ),
		.mem_rdata   (mem_rdata  ),
		.irq         (irq        )
	);


//---------------------------------------------------------------
//INSTANCIA wb adapter (wb 2 native)
//---------------------------------------------------------------
	picorv32_wb_adapter wb_adapter (
		.clk(clk),
		.resetn(resetn),
		
		// Wishbone Master Interface
		.wb_stb_o(wb_m_stb_o),
		.wb_cyc_o(wb_m_cyc_o),
		.wb_we_o (wb_m_we_o),
		.wb_adr_o(wb_m_adr_o),
		.wb_dat_o(wb_m_dat_o),
		.wb_sel_o(wb_m_sel_o),
		.wb_ack_i(wb_m_ack_i),
		.wb_dat_i(wb_m_dat_i),
		
		// Native PicoRV32 Interface
		.mem_valid(wb_periph_sel),
		.mem_instr(mem_instr),    
		.mem_ready(wb_mem_ready),
		.mem_addr (mem_addr),
		.mem_wdata(mem_wdata),
		.mem_wstrb(mem_wstrb),
		.mem_rdata(wb_mem_rdata)
	);


//---------------------------------------------------------------
//INSTANCIA minimac2 (señales en wb y CSR)
//---------------------------------------------------------------
    minimac2 #(
	   .csr_addr (4'b0000)	
	)minimac2core (
        .sys_clk      (clk),
        .sys_rst      (!resetn),
                      
        .csr_a        (minimac2_csr_a),
        .csr_we       (minimac2_csr_we), 
        .csr_di       (minimac2_csr_di),
        .csr_do       (minimac2_csr_do),
                      
        /* IRQ */     
        .irq_rx       (irq_rx_minimac2),
        .irq_tx       (irq_tx_minimac2),
        
        /* WISHBONE to access RAM */
       .wb_adr_i          (wb_mm2_adr_i),
       .wb_dat_o          (wb_mm2_dat_o),
       .wb_dat_i          (wb_mm2_dat_i),
       .wb_sel_i          (wb_mm2_sel_i),
       .wb_stb_i          (wb_mm2_stb_i),
       .wb_cyc_i          (wb_mm2_cyc_i),
       .wb_ack_o          (wb_mm2_ack_o),
       .wb_we_i           (wb_mm2_we_i),
                          
        /* To PHY */      
        .phy_tx_clk       (phy_tx_clk   ),
        .phy_tx_data      (phy_tx_data  ),
        .phy_tx_en        (phy_tx_en    ),
        .phy_tx_er        (phy_tx_er    ), 
          
        .phy_rx_clk       (phy_rx_clk   ), 
        .phy_rx_data      (phy_rx_data  ),
        .phy_dv           (phy_dv       ),
        .phy_rx_er        (phy_rx_er    ),
        .phy_col          (phy_col      ),
        .phy_crs          (phy_crs      ),
        
        .phy_mii_clk      (phy_mii_clk  ),
        //.phy_mii_data     (phy_mii_data ),
        .mii_data_oe      (mii_data_oe    ),
        .mii_data_do      (mii_data_do    ),
        .mii_data_di_raw  (mii_data_di_raw),
        .phy_rst_n        (phy_rst_n    )
	);
 
 
//---------------------------------------------------------------
//INSTANCIA PTP HA1588 (wrapper wishbone) 
//---------------------------------------------------------------
//    u_rgs    -> Resgitros internos del sistema
//    
//    u_rtc    -> Real Time Clock
//    
//    u_rx_tsu -> Captura de las tramas enviadas por rx
//        parse -> Control de formato de trama
//        queue -> Control de colas FIFO
//            dcfifo -> FIFO opensource     
//            
//    u_tx_tsu -> Captura de las tramas enviadas por tx
//        parse -> Control de formato de trama
//        queue -> Control de colas FIFO
//            dcfifo -> FIFO opensource 


     ha1588_wb PTP_HA1588(
          // reg_interface
          .rst_i                (!resetn),
          .clk_i                (clk),
          .stb_i                (wb_ha_stb_i),
          .we_i                 (wb_ha_we_i),
          .ack_o                (wb_ha_ack_o),
          .adr_i                ({24'h000000, wb_ha_adr_i[7:0]}),  // in byte
          .dat_i                (wb_ha_dat_i),
          .dat_o                (wb_ha_dat_o),
          // rtc_interface       
          .rtc_clk              (clk),
          .rtc_time_ptp_ns      (ptp_ns),
          .rtc_time_ptp_sec     (ptp_sec),
          .rtc_time_one_pps     (ptp_pps),
          
          // tsu_interface
          .rx_gmii_clk          (phy_rx_clk),
          .rx_gmii_ctrl         (phy_dv),
          .rx_gmii_data         ({4'b0000, phy_rx_data}),
          .rx_giga_mode         (1'b0),                     //Modo 10/100Mbps
          
          .tx_gmii_clk          (phy_tx_clk),
          .tx_gmii_ctrl         (phy_tx_en),    
          .tx_gmii_data         ({4'b0000, phy_tx_data}),
          .tx_giga_mode         (1'b0)
    );  
    
    
//---------------------------------------------------------------
//INSTANCIA SPI para flash 
//---------------------------------------------------------------   
	spimemio spimemio (
		.clk    (clk),
		.resetn (resetn),
		.valid  (mem_valid && mem_addr >= 4*MEM_WORDS && mem_addr < 32'h 0200_0000),
		.ready  (spimem_ready),
		.addr   (mem_addr[23:0]),
		.rdata  (spimem_rdata),

		.flash_csb    (flash_csb   ),
		.flash_clk    (flash_clk   ),

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

		.cfgreg_we(spimemio_cfgreg_sel ? mem_wstrb : 4'b 0000),
		.cfgreg_di(mem_wdata),
		.cfgreg_do(spimemio_cfgreg_do)
	);


//---------------------------------------------------------------
//INSTANCIA UART
//--------------------------------------------------------------- 
	simpleuart simpleuart (
		.clk         (clk         ),
		.resetn      (resetn      ),

		.ser_tx      (ser_tx      ),
		.ser_rx      (ser_rx      ),

		.reg_div_we  (simpleuart_reg_div_sel ? mem_wstrb : 4'b 0000),
		.reg_div_di  (mem_wdata),
		.reg_div_do  (simpleuart_reg_div_do),

		.reg_dat_we  (simpleuart_reg_dat_sel ? mem_wstrb[0] : 1'b 0),
		.reg_dat_re  (simpleuart_reg_dat_sel && !mem_wstrb),
		.reg_dat_di  (mem_wdata),
		.reg_dat_do  (simpleuart_reg_dat_do),
		.reg_dat_wait(simpleuart_reg_dat_wait)
	);


//---------------------------------------------------------------
//INSTANCIA RAM 
//--------------------------------------------------------------- 
	always @(posedge clk)
		ram_ready <= mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS;

	`PICOSOC_MEM #(
		.WORDS(MEM_WORDS)
	) memory (
		.clk(clk),
		.wen((mem_valid && !mem_ready && mem_addr < 4*MEM_WORDS) ? mem_wstrb : 4'b0),
		.addr(mem_addr[23:2]),
		.wdata(mem_wdata),
		.rdata(ram_rdata)
	);
	
endmodule


//---------------------------------------------------------------
//CORE REGISTROS 64x32 2P IHP (macro)
//--------------------------------------------------------------- 
`ifdef ASIC
module picosoc_regs (
		input clk, wen,
		input [5:0] waddr,
		input [5:0] raddr1,
		input [5:0] raddr2,
		input [31:0] wdata,
		output [31:0] rdata1,
		output [31:0] rdata2
	);
	
		reg [5:0] port_a_addr;

		always @(*) begin
		    if (wen) begin
			     port_a_addr = waddr;
		    end else begin
			     port_a_addr = raddr1;
		    end
		end
		
	
		RM_IHPSG13_2P_64x32_c2 reg_sram(
		    .A_CLK(!clk),
		    .A_MEN(1'b1),
		    .A_WEN(wen),
		    .A_REN(!wen),
		    .A_ADDR(port_a_addr),
		    .A_DIN(wdata),
		    .A_DLY(1'b1),
		    .A_DOUT(rdata1),

		    .B_CLK(!clk),
		    .B_MEN(1'b1),
		    .B_WEN(1'b0),
		    .B_REN(1'b1),
		    .B_ADDR(raddr2),
		    .B_DIN(32'b0),
		    .B_DLY(1'b1),
		    .B_DOUT(rdata2)
		);
endmodule

`else
module picosoc_regs (
	input clk, wen,
	input [5:0] waddr,
	input [5:0] raddr1,
	input [5:0] raddr2,
	input [31:0] wdata,
	output [31:0] rdata1,
	output [31:0] rdata2
);
	reg [31:0] regs [0:31];

	always @(posedge clk)
		if (wen) regs[waddr[4:0]] <= wdata;

	assign rdata1 = regs[raddr1[4:0]];
	assign rdata2 = regs[raddr2[4:0]];
endmodule
`endif


//---------------------------------------------------------------
//CORE RAM 512x32 IHP (macro)
//--------------------------------------------------------------- 
`ifdef ASIC
module picosoc_mem #(
	    parameter integer WORDS = 512   // 512x32 
	) (
	    input         clk,
	    input  [3:0]  wen,      // byte write enable
	    input  [21:0] addr,     // viene de mem_addr[23:2]
	    input  [31:0] wdata,
	    output [31:0] rdata     
	);

	    wire wen_any = |wen;   // vale 1 si algún bit de wen es 1

	    // Máscara de bytes: expandimos wen[3:0] a 32 bits (8 bits por byte)
	    wire [31:0] A_BM = { {8{wen[3]}}, {8{wen[2]}}, {8{wen[1]}}, {8{wen[0]}} };
		

		RM_IHPSG13_1P_512x32_c2_bm_bist sram (  
	    .A_CLK    (clk),        
	    .A_MEN    (1'b1),       //  siempre habilitada
	    .A_WEN    (wen_any),      
	    .A_REN    (~wen_any),   
	    .A_ADDR   (addr[8:0]),  //  9 bits: [8:0] = 512 words
	    .A_DIN    (wdata),      
	    .A_DLY    (1'b0),       //  constante
	    .A_DOUT   (rdata),     
	    .A_BM     (A_BM),       //  expandimos para mascara de cada byte

		// BIST desactivado
	    .A_BIST_CLK  (1'b0),
	    .A_BIST_EN   (1'b0),
	    .A_BIST_MEN  (1'b0),
	    .A_BIST_WEN  (1'b0),
	    .A_BIST_REN  (1'b0),
	    .A_BIST_ADDR (9'b0),
	    .A_BIST_DIN  (32'b0),
	    .A_BIST_BM   (32'b0)
	);

	endmodule
	
`else
	module picosoc_mem #(
		parameter integer WORDS = 512
	) (
		input clk,
		input [3:0] wen,
		input [21:0] addr,
		input [31:0] wdata,
		output reg [31:0] rdata
	);
		reg [31:0] mem [0:WORDS-1];

		always @(posedge clk) begin
			rdata <= mem[addr];
			if (wen[0]) mem[addr][ 7: 0] <= wdata[ 7: 0];
			if (wen[1]) mem[addr][15: 8] <= wdata[15: 8];
			if (wen[2]) mem[addr][23:16] <= wdata[23:16];
			if (wen[3]) mem[addr][31:24] <= wdata[31:24];
		end
	endmodule
`endif
