`timescale 1 ns / 1 ps

module tb_zedboard_top;

    reg sys_clk;
    reg sys_rst_n;
    reg uart_rx_stim; 
    wire uart_tx_mon; 
    wire [7:0] leds;
     
    // RX (Salidas desde el PHY)   
    reg          phy_rx_clk;
    reg [3:0]    phy_rx_data_reg;
    wire[3:0]    phy_rx_data;
    reg          phy_dv_reg;   
    reg          phy_rx_er_reg;
    reg          phy_col_reg;
    reg          phy_crs_reg;
    
    assign phy_rx_data = phy_rx_data_reg;
    assign phy_dv      = phy_dv_reg;
    assign phy_rx_er   = phy_rx_er_reg;
    assign phy_col     = phy_col_reg;
    assign phy_crs     = phy_crs_reg;

    // TX (Salidas hacia el PHY)
    reg         phy_tx_clk;
    wire [3:0]  phy_tx_data;   
    wire        phy_tx_en;
    wire        phy_tx_er;
 
    // Management (MDIO/MDC)
    wire         phy_mii_clk;
    wire         phy_rst_n;
    
    wire         phy_mii_data_internal;  
    assign (weak1, weak0) phy_mii_data_internal = 1'b1;  
//    wire        pmd_pad_i  ;
//    wire        pmd_pad_o  ;
//    wire        pmd_padoe_o;
    

    // --- Generación de Reloj de 25MHz  ----------------------------------------------------------
    always #20 phy_rx_clk = (phy_rx_clk === 1'b0);
    always #20 phy_tx_clk = (phy_tx_clk === 1'b0);
    
    // --- Generacion de reloj de 50 MHz  ---------------------------------------------------------
    always #10 sys_clk = (sys_clk === 1'b0);

    // localparam ser_half_period = 217;        //115200
    localparam ser_half_period = 20;            //Simulacion
    event ser_sample; // Evento para sincronizar la impresión en consola
    
    // --- main  --------------------------------------------------------------------------------
    initial begin
        $dumpfile("zedboard/zedboard_sim.vcd");
        $dumpvars(0, tb_zedboard_top);
    
        sys_rst_n = 0;  
        uart_rx_stim = 1;
        sys_clk = 0;
        phy_dv_reg = 0;
        phy_rx_data_reg = 0;
        phy_rx_er_reg = 0;
        phy_col_reg = 0;
        phy_crs_reg = 0;
        
    
        $display("TestBench -> Iniciando Simulación ZedBoard ");       
        repeat (20) @(posedge sys_clk);
        sys_rst_n = 1;
        $display("TestBench -> Reset Liberado ");

        repeat (9) begin
			repeat (50000) @(posedge sys_clk);
		end

        send_char(8'h0D); 
        
        repeat (2) begin
			repeat (50000) @(posedge sys_clk);
		end
		
        send_char(8'h53); 
		      
		repeat (12) begin
			repeat (50000) @(posedge sys_clk);
		end
		
		$display("TestBench -> Inicio envio paquete 1 ");
		send_packet1();
		repeat (25000) @(posedge sys_clk);
		
		$display("TestBench -> Inicio envio paquete 2 ");
		send_packet2();
		repeat (5000) @(posedge sys_clk);
		
		$display("TestBench -> Inicio envio paquete 3 ");	
		send_packet3();
        repeat (30000) @(posedge sys_clk);

		$display("TestBench -> Inicio envio paquete 1 ");
		send_packet1();
		repeat (5000) @(posedge sys_clk);
		
		$display("TestBench -> Inicio envio paquete 2 ");
		send_packet2();
		repeat (25000) @(posedge sys_clk);
		

	    repeat (2) begin
			repeat (50000) @(posedge sys_clk);
		end

		
		send_char(8'h49); 
		
		repeat (25) begin
			repeat (50000) @(posedge sys_clk);
		end
		
		send_char(8'h50);
		repeat (5000) @(posedge sys_clk);
		send_char(8'h32); 
           
        repeat (40) begin
			repeat (50000) @(posedge sys_clk);
		end
		
		send_char(8'h50);
		repeat (5000) @(posedge sys_clk);
		send_char(8'h33);
           
        repeat (80) begin
			repeat (50000) @(posedge sys_clk);
		end
    
        repeat (50000) @(posedge sys_clk);
        $display("TestBench -> Simulación Finalizada ");
        $finish;
    end
    
    // --- Contador de ciclos ----------------------------------------
    integer cycle_cnt = 0;
	always @(posedge sys_clk) begin
		cycle_cnt <= cycle_cnt + 1;
	end
    
    
    zedboard_top uut (
        .sys_clk   (sys_clk),
        .sys_rst_n (sys_rst_n),
        .uart_tx   (uart_tx_mon), // Salida de la FPGA -> Entrada del Monitor
        .uart_rx   (uart_rx_stim),// Entrada de la FPGA <- Salida del Stimulus
        .led       (leds),
        .phy_rx_clk   (phy_rx_clk ),  .phy_rx_data  (phy_rx_data), .phy_dv       (phy_dv     ),
        .phy_rx_er    (phy_rx_er  ),  .phy_col      (phy_col    ), .phy_crs      (phy_crs    ),
                      
        .phy_tx_clk   (phy_tx_clk ), .phy_tx_data  (phy_tx_data),
        .phy_tx_en    (phy_tx_en  ), .phy_tx_er    (phy_tx_er  ),
                         
        .phy_mii_clk  (phy_mii_clk), .phy_rst_n    (phy_rst_n  ),
        
        .phy_mii_data     (phy_mii_data_internal )
                      
//        .pmd_pad_i    (pmd_pad_i   ),
//        .pmd_pad_o    (pmd_pad_o   ),
//        .pmd_padoe_o  (pmd_padoe_o )
        
    );
    
    // --- Tarea para enviar un Byte (2 nibbles de 4 bits) -----------------------------
    task send_byte(input [7:0] data);
        begin
            @(negedge phy_rx_clk);
            phy_rx_data_reg = data[3:0]; // Nibble bajo
            phy_dv_reg = 1;
            @(negedge phy_rx_clk);
            phy_rx_data_reg = data[7:4]; // Nibble alto
            //$display("TestBench -> Envio");
        end
    endtask
   

    // --- Tarea para enviar un paquete Ethernet VÁLIDO (con Padding y CRC) ---
    task send_packet1();
        integer i;
        begin
            // ---------------------------------------------------------
            // 1. PREÁMBULO (8 bytes)
            // ---------------------------------------------------------
            repeat (7) send_byte(8'h55);
            send_byte(8'hD5); // SFD

            // ---------------------------------------------------------
            // 2. CABECERA ETHERNET (14 bytes)
            // ---------------------------------------------------------
            send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF);   // MAC Destino (Broadcast)
            send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF); 
            
            send_byte(8'h02); send_byte(8'h00); send_byte(8'h00);   // MAC Origen
            send_byte(8'h00); send_byte(8'h00); send_byte(8'h01);

            send_byte(8'h88); send_byte(8'hF7);                     // EtherType PTP (1588)


            // ---------------------------------------------------------
            // 3. CABECERA PTP (34 bytes)
            // ---------------------------------------------------------
            send_byte(8'h00); send_byte(8'h02);                     // MessageType (Sync), Version (2)
            send_byte(8'h00); send_byte(8'h2C);                     // Message Length (44 bytes PTP)
            send_byte(8'h00); send_byte(8'h00);                     // Domain, Reserved
            send_byte(8'h02); send_byte(8'h00);                     // Flags (Two-Step)
            repeat (8) send_byte(8'h00);                            // Correction Field
            repeat (4) send_byte(8'h00);                            // Reserved
            repeat (8) send_byte(8'h00);                            // Clock ID (Source Port)
            send_byte(8'h00); send_byte(8'h01);                     // Port ID
            send_byte(8'h00); send_byte(8'h2A);                     // Sequence ID (Ej: 42)
            send_byte(8'h00); send_byte(8'h00);                     // Control Field, LogMessageInterval

            // ---------------------------------------------------------
            // 4. PAYLOAD PTP (10 bytes)
            // ---------------------------------------------------------
            // Origin Timestamp para Sync
            repeat (10) send_byte(8'h00);

            // ---------------------------------------------------------
            // 5. PADDING ETHERNET (2 bytes)
            // ---------------------------------------------------------
            // ¡CRÍTICO! Este padding hace que el tamaño (sin preámbulo) sea de 60 bytes exactos.
            // 60 bytes + 4 (CRC) + 8 (Preámbulo) = 72 bytes totales en la red.
            // 72 es múltiplo perfecto de 4. ¡El gearbox activará el int_eop!
            repeat (2) send_byte(8'h00);

            // ---------------------------------------------------------
            // 6. CRC32 (Frame Check Sequence)
            // ---------------------------------------------------------
            // NOTA: Debes agregar los 4 bytes del CRC correspondiente 
            // a los 60 bytes anteriores (Cabecera MAC + Cabecera PTP + Payload PTP + Padding).
             send_byte(8'h04);
             send_byte(8'hF3);
             send_byte(8'h4E);
             send_byte(8'hF3);

            // ---------------------------------------------------------
            // 6. Fin de transmisión
            // ---------------------------------------------------------
            @(negedge phy_rx_clk);
            phy_dv_reg = 0;
            phy_rx_data_reg = 0;
            #100;
        end
    endtask
    
    
    task send_packet2();
        integer i;
        begin
            // ---------------------------------------------------------
            // 1. PREÁMBULO (8 bytes)
            // ---------------------------------------------------------
            repeat (7) send_byte(8'h55);
            send_byte(8'hD5); // SFD

            // ---------------------------------------------------------
            // 2. CABECERA ETHERNET (14 bytes)
            // ---------------------------------------------------------
            send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF);   // MAC Destino (Broadcast)
            send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF); 
            
            send_byte(8'h02); send_byte(8'h00); send_byte(8'h00);   // MAC Origen
            send_byte(8'h00); send_byte(8'h00); send_byte(8'h01);

            send_byte(8'h88); send_byte(8'hF7);                     // EtherType PTP (1588)


            // ---------------------------------------------------------
            // 3. CABECERA PTP (34 bytes)
            // ---------------------------------------------------------
            send_byte(8'h00); send_byte(8'h02);                     // MessageType (Sync), Version (2)
            send_byte(8'h00); send_byte(8'h2C);                     // Message Length (44 bytes PTP)
            send_byte(8'h00); send_byte(8'h00);                     // Domain, Reserved
            send_byte(8'h02); send_byte(8'h00);                     // Flags (Two-Step)
            repeat (8) send_byte(8'h00);                            // Correction Field
            repeat (4) send_byte(8'h00);                            // Reserved
            repeat (8) send_byte(8'h00);                            // Clock ID (Source Port)
            send_byte(8'h00); send_byte(8'h01);                     // Port ID
            send_byte(8'h00); send_byte(8'h2B);                     // Sequence ID (Ej: 42)
            send_byte(8'h00); send_byte(8'h00);                     // Control Field, LogMessageInterval

            // ---------------------------------------------------------
            // 4. PAYLOAD PTP (10 bytes)
            // ---------------------------------------------------------
            // Origin Timestamp para Sync
            repeat (10) send_byte(8'h00);

            // ---------------------------------------------------------
            // 5. PADDING ETHERNET (2 bytes)
            // ---------------------------------------------------------
            // ¡CRÍTICO! Este padding hace que el tamaño (sin preámbulo) sea de 60 bytes exactos.
            // 60 bytes + 4 (CRC) + 8 (Preámbulo) = 72 bytes totales en la red.
            // 72 es múltiplo perfecto de 4. ¡El gearbox activará el int_eop!
            repeat (2) send_byte(8'h00);

            // ---------------------------------------------------------
            // 6. CRC32 (Frame Check Sequence)
            // ---------------------------------------------------------
            // NOTA: Debes agregar los 4 bytes del CRC correspondiente 
            // a los 60 bytes anteriores (Cabecera MAC + Cabecera PTP + Payload PTP + Padding).
             send_byte(8'h04);
             send_byte(8'hF3);
             send_byte(8'h4E);
             send_byte(8'hF3);

            // ---------------------------------------------------------
            // 6. Fin de transmisión
            // ---------------------------------------------------------
            @(negedge phy_rx_clk);
            phy_dv_reg = 0;
            phy_rx_data_reg = 0;
            #100;
        end
    endtask
    
    
    task send_packet3();
        integer i;
        begin
            // ---------------------------------------------------------
            // 1. PREÁMBULO (8 bytes)
            // ---------------------------------------------------------
            repeat (7) send_byte(8'h55);
            send_byte(8'hD5); // SFD

            // ---------------------------------------------------------
            // 2. CABECERA ETHERNET (14 bytes)
            // ---------------------------------------------------------
            send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF);   // MAC Destino (Broadcast)
            send_byte(8'hFF); send_byte(8'hFF); send_byte(8'hFF); 
            
            send_byte(8'h02); send_byte(8'h00); send_byte(8'h00);   // MAC Origen
            send_byte(8'h00); send_byte(8'h00); send_byte(8'h01);

            send_byte(8'h88); send_byte(8'hF7);                     // EtherType PTP (1588)


            // ---------------------------------------------------------
            // 3. CABECERA PTP (34 bytes)
            // ---------------------------------------------------------
            send_byte(8'h00); send_byte(8'h02);                     // MessageType (Sync), Version (2)
            send_byte(8'h00); send_byte(8'h2C);                     // Message Length (44 bytes PTP)
            send_byte(8'h00); send_byte(8'h00);                     // Domain, Reserved
            send_byte(8'h02); send_byte(8'h00);                     // Flags (Two-Step)
            repeat (8) send_byte(8'h00);                            // Correction Field
            repeat (4) send_byte(8'h00);                            // Reserved
            repeat (8) send_byte(8'h00);                            // Clock ID (Source Port)
            send_byte(8'h00); send_byte(8'h01);                     // Port ID
            send_byte(8'h00); send_byte(8'h2C);                     // Sequence ID (Ej: 42)
            send_byte(8'h00); send_byte(8'h00);                     // Control Field, LogMessageInterval

            // ---------------------------------------------------------
            // 4. PAYLOAD PTP (10 bytes)
            // ---------------------------------------------------------
            // Origin Timestamp para Sync
            repeat (10) send_byte(8'h00);

            // ---------------------------------------------------------
            // 5. PADDING ETHERNET (2 bytes)
            // ---------------------------------------------------------
            // ¡CRÍTICO! Este padding hace que el tamaño (sin preámbulo) sea de 60 bytes exactos.
            // 60 bytes + 4 (CRC) + 8 (Preámbulo) = 72 bytes totales en la red.
            // 72 es múltiplo perfecto de 4. ¡El gearbox activará el int_eop!
            repeat (2) send_byte(8'h00);

            // ---------------------------------------------------------
            // 6. CRC32 (Frame Check Sequence)
            // ---------------------------------------------------------
            // NOTA: Debes agregar los 4 bytes del CRC correspondiente 
            // a los 60 bytes anteriores (Cabecera MAC + Cabecera PTP + Payload PTP + Padding).
             send_byte(8'h04);
             send_byte(8'hF3);
             send_byte(8'h4E);
             send_byte(8'hF3);

            // ---------------------------------------------------------
            // 6. Fin de transmisión
            // ---------------------------------------------------------
            @(negedge phy_rx_clk);
            phy_dv_reg = 0;
            phy_rx_data_reg = 0;
            #100;
        end
    endtask

 
   
   // --- Envio UART TX --------------------------------------------------------------------
    reg [7:0] buffer;
	always begin
		@(negedge uart_tx_mon);

		repeat (ser_half_period) @(posedge sys_clk);
		-> ser_sample; // start bit

		repeat (8) begin
			repeat (ser_half_period) @(posedge sys_clk);
			repeat (ser_half_period) @(posedge sys_clk);
			buffer = {uart_tx_mon, buffer[7:1]};
			-> ser_sample; // data bit
		end

		repeat (ser_half_period) @(posedge sys_clk);
		repeat (ser_half_period) @(posedge sys_clk);
		-> ser_sample; // stop bit

		if (buffer == 8'h0A) begin
			$display(""); // Si es salto de línea, bajar de renglón
		end else if (buffer >= 32 && buffer < 127) begin
			$write("%c", buffer); // Imprimir carácter ASCII
			$fflush();            // Forzar salida a consola
		end
	end


    //--- Funcion para escribir por UART(RX) -------------------------------------------------
	task send_char;
	    input [7:0] char;
	    integer i;
	    begin
		// Bit de inicio (Start bit)
		uart_rx_stim = 0;
		repeat (2 * ser_half_period) @(posedge sys_clk);

		// 8 Bits de datos (LSB first)
		for (i = 0; i < 8; i = i + 1) begin
		    uart_rx_stim = char[i];
		    repeat (2 * ser_half_period) @(posedge sys_clk);
		end

		// Bit de parada (Stop bit)
		uart_rx_stim = 1;
		repeat (2 * ser_half_period) @(posedge sys_clk);
		
		$display("Sent character: '%c' (0x%h)", char, char);
	    end
	endtask


    


endmodule
