`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module   : tb_dual_core
// Desc     : Testbench de sincronización PTP entre dos SoCs
//
// Sincronización de fases:
//   core0/1_ready    ← "Press ENTER"     firmware pide ENTER
//   core0/1_loop     ← "Esperando coma"  firmware en bucle principal
//   core1_sync_done  ← "PTP_CALC_DONE"   CORE1 completó primer cálculo PTP
//   cmd_done_0/1     ← línea vacía \r\n  firmware terminó respuesta a comando
//
// Secuencia:
//   1. Espera core_ready  → envía \r a cada core
//   2. Espera core_loop   → ambos en bucle principal
//   3. [FASE 1] 'x' CORE0 → @cmd_done_0 → 'x' CORE1 → @cmd_done_1
//   4. [FASE 2] 'z' CORE0 → espera core1_sync_done (sin timeout fijo)
//   5. [FASE 3] 'x' CORE0 → @cmd_done_0 → 'x' CORE1 → @cmd_done_1
//              't' CORE1  → @cmd_done_1
//   6. 'z' CORE0 apaga auto_sync → fin
//////////////////////////////////////////////////////////////////////////////////

module tb_dual_core;

    // =========================================================================
    // Parámetros del test
    // =========================================================================

    localparam integer DESFASE_NS    = 100_000;     // 100 µs desfase CORE1
    localparam integer TIMEOUT_NS    = 800_000_000; // 800 ms timeout global
    localparam integer CICLOS_MARGEN = 10_000;      // margen entre pasos

    localparam LINE_BUF = 128;

    // UART: half_period=20 ciclos
    localparam ser_half_period = 20;

    // Cadenas que detecta el monitor
    localparam [87:0]  TRIG_ENTER     = "Press ENTER";   // 11 chars
    localparam integer TRIG_ENTER_LEN = 11;
    localparam [111:0] TRIG_LOOP      = "Esperando coma"; // 14 chars
    localparam integer TRIG_LOOP_LEN  = 14;
    localparam [95:0]  TRIG_SYNC_DONE = "PTP_CALC_DONE";  // 13 chars
    localparam integer TRIG_SYNC_LEN  = 13;


    // =========================================================================
    // Señales
    // =========================================================================

    reg sys_clk, rx_clk, tx_clk;
    reg rst_n_0, rst_n_1;

    reg  uart_rx_0; wire uart_tx_0;
    reg  uart_rx_1; wire uart_tx_1;

    wire [2:0] leds0, leds1;
    wire       status_rst_0, status_rst_1;

    wire [3:0] mii_txd_0,   mii_txd_1;
    wire       mii_tx_en_0, mii_tx_en_1;

    wire phy_mii_clk_0, phy_rst_n_0, phy_mii_data_0;
    wire phy_mii_clk_1, phy_rst_n_1, phy_mii_data_1;

    wire pps_pin_1cycle_0, pps_led_100ms_0;
    wire pps_pin_1cycle_1, pps_led_100ms_1;

    // Flags de estado del firmware
    reg core0_ready,     core1_ready;      // firmware pidiendo ENTER
    reg core0_loop,      core1_loop;       // firmware en bucle principal
    reg core1_sync_done;                   // CORE1 completó primer cálculo PTP

    // Eventos fin de respuesta a comando
    event cmd_done_0;
    event cmd_done_1;


    // =========================================================================
    // Relojes
    // =========================================================================

    initial sys_clk = 1'b0; always #10 sys_clk = ~sys_clk;
    initial rx_clk  = 1'b0; always #20 rx_clk  = ~rx_clk;
    initial tx_clk  = 1'b0; always #20 tx_clk  = ~tx_clk;


    // =========================================================================
    // Reset escalonado
    // =========================================================================

    initial begin
        uart_rx_0      = 1'b1;  uart_rx_1      = 1'b1;
        rst_n_0        = 1'b0;  rst_n_1        = 1'b0;
        core0_ready    = 1'b0;  core1_ready    = 1'b0;
        core0_loop     = 1'b0;  core1_loop     = 1'b0;
        core1_sync_done = 1'b0;

        #200;
        rst_n_0 = 1'b1;
        $display("[TB] t=%0t ns  CORE0 sale de reset", $time/1000);

        #(DESFASE_NS);
        rst_n_1 = 1'b1;
        $display("[TB] t=%0t ns  CORE1 sale de reset (desfase=%0d ns)",
                 $time/1000, DESFASE_NS);
    end

    // FST en la misma carpeta que el testbench
    // Solo se vuelca durante la FASE 2 (sync PTP) para reducir el tamaño
    // El fichero .fst se abre con GTKWave igual que un .vcd
    initial begin
        $dumpfile("sim/tb_dual_core/dual_core_sim.fst");
        $dumpvars(1, tb_dual_core);   // profundidad 1: solo señales del TB
        $dumpoff;                      // pausado hasta que empiece la FASE 2
    end

    initial begin
        #(TIMEOUT_NS);
        $display("[TB] Timeout global (%0d ms) - fin", TIMEOUT_NS/1_000_000);
        $finish;
    end


    // =========================================================================
    // Instancias SoC
    // =========================================================================

    arty_top_spiflash core0 (
        .clk_50MHz (sys_clk),    .sys_rst_n      (rst_n_0),
        .status_rst     (status_rst_0),
        .uart_tx        (uart_tx_0),  .uart_rx        (uart_rx_0),
        .led            (leds0),
        .phy_rx_clk     (rx_clk),     .phy_rx_data    (mii_txd_1),
        .phy_dv         (mii_tx_en_1),.phy_rx_er      (1'b0),
        .phy_col        (1'b0),        .phy_crs       (1'b0),
        .phy_tx_clk     (tx_clk),     .phy_tx_data    (mii_txd_0),
        .phy_tx_en      (mii_tx_en_0),
        .phy_mii_clk    (phy_mii_clk_0), .phy_rst_n   (phy_rst_n_0),
        .phy_mii_data   (phy_mii_data_0),
        .pps_pin_1cycle (pps_pin_1cycle_0),
        .pps_led_100ms  (pps_led_100ms_0)
    );

    arty_top_spiflash core1 (
        .clk_50MHz (sys_clk),    .sys_rst_n      (rst_n_1),
        .status_rst     (status_rst_1),
        .uart_tx        (uart_tx_1),  .uart_rx        (uart_rx_1),
        .led            (leds1),
        .phy_rx_clk     (rx_clk),     .phy_rx_data    (mii_txd_0),
        .phy_dv         (mii_tx_en_0),.phy_rx_er      (1'b0),
        .phy_col        (1'b0),        .phy_crs       (1'b0),
        .phy_tx_clk     (tx_clk),     .phy_tx_data    (mii_txd_1),
        .phy_tx_en      (mii_tx_en_1),
        .phy_mii_clk    (phy_mii_clk_1), .phy_rst_n   (phy_rst_n_1),
        .phy_mii_data   (phy_mii_data_1),
        .pps_pin_1cycle (pps_pin_1cycle_1),
        .pps_led_100ms  (pps_led_100ms_1)
    );


    // =========================================================================
    // Monitor UART - buffer de línea + detección de cadenas + cmd_done
    // =========================================================================

    // --- CORE0 ---------------------------------------------------------------
    reg [7:0] rx_buf0 [0:LINE_BUF-1];
    integer   rx_pos0;
    reg [7:0] rx_byte0;
    reg       linea_vacia0;

    initial begin rx_pos0 = 0; linea_vacia0 = 0; end

    task check_strings_0;
        integer m;
        reg match_e, match_l;
        reg [7:0] ce, cl, cb;
        begin
            // "Press ENTER"
            match_e = 1'b1;
            if (rx_pos0 >= TRIG_ENTER_LEN) begin
                for (m=0; m<TRIG_ENTER_LEN; m=m+1) begin
                    ce = TRIG_ENTER[((TRIG_ENTER_LEN-1-m)*8) +: 8];
                    cb = rx_buf0[rx_pos0 - TRIG_ENTER_LEN + m];
                    if (ce != cb) match_e = 1'b0;
                end
                if (match_e && !core0_ready) begin
                    core0_ready = 1'b1;
                    $display("[TB] CORE0 listo - detectado 'Press ENTER'");
                end
            end
            // "Esperando coma"
            match_l = 1'b1;
            if (rx_pos0 >= TRIG_LOOP_LEN) begin
                for (m=0; m<TRIG_LOOP_LEN; m=m+1) begin
                    cl = TRIG_LOOP[((TRIG_LOOP_LEN-1-m)*8) +: 8];
                    cb = rx_buf0[rx_pos0 - TRIG_LOOP_LEN + m];
                    if (cl != cb) match_l = 1'b0;
                end
                if (match_l && !core0_loop) begin
                    core0_loop = 1'b1;
                    $display("[TB] CORE0 en bucle principal");
                end
            end
        end
    endtask

    always begin : uart_monitor_0
        @(negedge uart_tx_0);
        repeat (ser_half_period) @(posedge sys_clk);
        repeat (8) begin
            repeat (ser_half_period) @(posedge sys_clk);
            repeat (ser_half_period) @(posedge sys_clk);
            rx_byte0 = {uart_tx_0, rx_byte0[7:1]};
        end
        repeat (ser_half_period) @(posedge sys_clk);
        repeat (ser_half_period) @(posedge sys_clk);

        if (rx_byte0 == 8'h0D) begin
            if (rx_pos0 == 0) begin
                linea_vacia0 = 1'b1;
            end else begin
                linea_vacia0 = 1'b0;
                $write("[CORE0] ");
                begin : pl0
                    integer k0;
                    for (k0=0; k0<rx_pos0; k0=k0+1)
                        $write("%c", rx_buf0[k0]);
                end
                $display("");
                rx_pos0 = 0;
            end
        end else if (rx_byte0 == 8'h0A) begin
            if (linea_vacia0) -> cmd_done_0;
            linea_vacia0 = 1'b0;
        end else if (rx_byte0 >= 8'h20 && rx_byte0 < 8'h7F) begin
            linea_vacia0 = 1'b0;
            if (rx_pos0 < LINE_BUF-1) begin
                rx_buf0[rx_pos0] = rx_byte0;
                rx_pos0 = rx_pos0 + 1;
                check_strings_0;
            end
        end
    end

    // --- CORE1 ---------------------------------------------------------------
    reg [7:0] rx_buf1 [0:LINE_BUF-1];
    integer   rx_pos1;
    reg [7:0] rx_byte1;
    reg       linea_vacia1;

    initial begin rx_pos1 = 0; linea_vacia1 = 0; end

    task check_strings_1;
        integer n;
        reg match_e1, match_l1, match_s1;
        reg [7:0] ce1, cl1, cs1, cb1;
        begin
            // "Press ENTER"
            match_e1 = 1'b1;
            if (rx_pos1 >= TRIG_ENTER_LEN) begin
                for (n=0; n<TRIG_ENTER_LEN; n=n+1) begin
                    ce1 = TRIG_ENTER[((TRIG_ENTER_LEN-1-n)*8) +: 8];
                    cb1 = rx_buf1[rx_pos1 - TRIG_ENTER_LEN + n];
                    if (ce1 != cb1) match_e1 = 1'b0;
                end
                if (match_e1 && !core1_ready) begin
                    core1_ready = 1'b1;
                    $display("[TB] CORE1 listo - detectado 'Press ENTER'");
                end
            end
            // "Esperando coma"
            match_l1 = 1'b1;
            if (rx_pos1 >= TRIG_LOOP_LEN) begin
                for (n=0; n<TRIG_LOOP_LEN; n=n+1) begin
                    cl1 = TRIG_LOOP[((TRIG_LOOP_LEN-1-n)*8) +: 8];
                    cb1 = rx_buf1[rx_pos1 - TRIG_LOOP_LEN + n];
                    if (cl1 != cb1) match_l1 = 1'b0;
                end
                if (match_l1 && !core1_loop) begin
                    core1_loop = 1'b1;
                    $display("[TB] CORE1 en bucle principal");
                end
            end
            // "PTP_CALC_DONE" - solo en CORE1 (esclavo)
            match_s1 = 1'b1;
            if (rx_pos1 >= TRIG_SYNC_LEN) begin
                for (n=0; n<TRIG_SYNC_LEN; n=n+1) begin
                    cs1 = TRIG_SYNC_DONE[((TRIG_SYNC_LEN-1-n)*8) +: 8];
                    cb1 = rx_buf1[rx_pos1 - TRIG_SYNC_LEN + n];
                    if (cs1 != cb1) match_s1 = 1'b0;
                end
                if (match_s1 && !core1_sync_done) begin
                    core1_sync_done = 1'b1;
                    $display("[TB] CORE1 - primer calculo PTP completado");
                end
            end
        end
    endtask

    always begin : uart_monitor_1
        @(negedge uart_tx_1);
        repeat (ser_half_period) @(posedge sys_clk);
        repeat (8) begin
            repeat (ser_half_period) @(posedge sys_clk);
            repeat (ser_half_period) @(posedge sys_clk);
            rx_byte1 = {uart_tx_1, rx_byte1[7:1]};
        end
        repeat (ser_half_period) @(posedge sys_clk);
        repeat (ser_half_period) @(posedge sys_clk);

        if (rx_byte1 == 8'h0D) begin
            if (rx_pos1 == 0) begin
                linea_vacia1 = 1'b1;
            end else begin
                linea_vacia1 = 1'b0;
                $write("[CORE1] ");
                begin : pl1
                    integer k1;
                    for (k1=0; k1<rx_pos1; k1=k1+1)
                        $write("%c", rx_buf1[k1]);
                end
                $display("");
                rx_pos1 = 0;
            end
        end else if (rx_byte1 == 8'h0A) begin
            if (linea_vacia1) -> cmd_done_1;
            linea_vacia1 = 1'b0;
        end else if (rx_byte1 >= 8'h20 && rx_byte1 < 8'h7F) begin
            linea_vacia1 = 1'b0;
            if (rx_pos1 < LINE_BUF-1) begin
                rx_buf1[rx_pos1] = rx_byte1;
                rx_pos1 = rx_pos1 + 1;
                check_strings_1;
            end
        end
    end


    // =========================================================================
    // Tareas de inyección UART
    // =========================================================================

    task send_char_0;
        input [7:0] char;
        integer i;
        begin
            uart_rx_0 = 1'b0;
            repeat (2*ser_half_period) @(posedge sys_clk);
            for (i=0; i<8; i=i+1) begin
                uart_rx_0 = char[i];
                repeat (2*ser_half_period) @(posedge sys_clk);
            end
            uart_rx_0 = 1'b1;
            repeat (2*ser_half_period) @(posedge sys_clk);
        end
    endtask

    task send_char_1;
        input [7:0] char;
        integer i;
        begin
            uart_rx_1 = 1'b0;
            repeat (2*ser_half_period) @(posedge sys_clk);
            for (i=0; i<8; i=i+1) begin
                uart_rx_1 = char[i];
                repeat (2*ser_half_period) @(posedge sys_clk);
            end
            uart_rx_1 = 1'b1;
            repeat (2*ser_half_period) @(posedge sys_clk);
        end
    endtask


    // =========================================================================
    // Secuencia principal del test
    // =========================================================================

    initial begin : test_ptp_sync

        $display("");
        $display("=================================================");
        $display("  tb_dual_core - test de sincronizacion PTP");
        `ifdef FPGA_SIM
                $display("  Target : FPGA");
        `elsif ASIC_SIM
                $display("  Target : ASIC (IHP SG13G2)");
        `else
                $display("  Target : no definido");
        `endif
        $display("  Desfase inicial CORE1 : %0d ns", DESFASE_NS);
        $display("  UART clkdiv           : 40  (1.25 Mbps sim)");
        $display("  Timeout               : %0d ms", TIMEOUT_NS/1_000_000);
        $display("=================================================");
        $display("");

        // ------------------------------------------------------------------
        // Paso 1: esperar "Press ENTER" → enviar \r
        // ------------------------------------------------------------------
        $display("[TB] Esperando arranque de CORE0...");
        wait (core0_ready === 1'b1);
        repeat (CICLOS_MARGEN) @(posedge sys_clk);
        $display("[TB] >>> Enviando ENTER a CORE0");
        send_char_0(8'h0D);

        $display("[TB] Esperando arranque de CORE1...");
        wait (core1_ready === 1'b1);
        repeat (CICLOS_MARGEN) @(posedge sys_clk);
        $display("[TB] >>> Enviando ENTER a CORE1");
        send_char_1(8'h0D);

        // ------------------------------------------------------------------
        // Paso 2: esperar "Esperando comando..." → ambos en bucle principal
        // ------------------------------------------------------------------
        $display("[TB] Esperando bucle principal CORE0...");
        wait (core0_loop === 1'b1);
        $display("[TB] Esperando bucle principal CORE1...");
        wait (core1_loop === 1'b1);
        repeat (CICLOS_MARGEN) @(posedge sys_clk);

        // ==================================================================
        // FASE 1 - Tiempos RTC antes de sincronizar
        // ==================================================================
        $display("");
        $display("[TB] ==============================================");
        $display("[TB] FASE 1: Tiempos RTC ANTES de sincronizar");
        $display("[TB] ==============================================");

        $display("[TB] >>> Comando 'x' → CORE0");
        send_char_0("x");
        @(cmd_done_0);
        repeat (CICLOS_MARGEN) @(posedge sys_clk);

        $display("[TB] >>> Comando 'x' → CORE1");
        send_char_1("x");
        @(cmd_done_1);
        repeat (CICLOS_MARGEN) @(posedge sys_clk);

        // ==================================================================
        // FASE 2 - Sincronización PTP
        // Activa auto_sync en CORE0 y espera a que CORE1 detecte
        // "PTP_CALC_DONE" - sin timeout fijo, avanza en cuanto termina
        // ==================================================================
        $display("");
        $display("[TB] ==============================================");
        $display("[TB] FASE 2: Sincronizacion PTP en curso...");
        $display("[TB]          CORE0 = maestro  |  CORE1 = esclavo");
        $display("[TB] ==============================================");

        $display("[TB] >>> Comando 'z' → CORE0 (activa auto_sync)");
        $dumpon;                       // activar volcado FST al inicio de FASE 2
        send_char_0("z");

        $display("[TB] Esperando primer calculo PTP en CORE1...");
        wait (core1_sync_done === 1'b1);
        repeat (CICLOS_MARGEN) @(posedge sys_clk);
        $dumpoff;                      // parar volcado en cuanto termina la sync
        $display("[TB] t=%0t ns  Sincronizacion completada", $time/1000);
        $display("[TB] >>> Comando 'z' → CORE0 ");
        send_char_0("z");
        repeat (CICLOS_MARGEN) @(posedge sys_clk);

        // ==================================================================
        // FASE 3 - Tiempos RTC después de sincronizar
        // ==================================================================
        $display("");
        $display("[TB] ==============================================");
        $display("[TB] FASE 3: Tiempos RTC DESPUES de sincronizar");
        $display("[TB] ==============================================");

        $display("[TB] >>> Comando 'x' → CORE0 y CORE1");
        send_char_0("x");
        send_char_1("x");
        repeat (CICLOS_MARGEN*100) @(posedge sys_clk);

        $display("[TB] >>> Comando 't' → Envio comando de tiempos");
        send_char_1("t");
        repeat (CICLOS_MARGEN*160) @(posedge sys_clk);

        repeat (7) begin
    	repeat (CICLOS_MARGEN) @(posedge sys_clk);
	    end
        repeat (CICLOS_MARGEN*3) @(posedge sys_clk);

        $display("");
        $display("[TB] ==============================================");
        $display("[TB] Test completado correctamente");
        $display("[TB] ==============================================");
        $display("");
        $finish;

    end

endmodule
