`timescale 1ns / 1ps

module RAMB16BWER_arty #(
    parameter integer DATA_WIDTH_A = 36,
    parameter integer DATA_WIDTH_B = 36,
    parameter integer DOA_REG = 0,
    parameter integer DOB_REG = 0,
    parameter [35:0] INIT_A = 36'h0,
    parameter [35:0] INIT_B = 36'h0,
    parameter [35:0] SRVAL_A = 36'h0,
    parameter [35:0] SRVAL_B = 36'h0,
    parameter WRITE_MODE_A = "WRITE_FIRST",
    parameter WRITE_MODE_B = "WRITE_FIRST",
    parameter INIT_FILE = "NONE",
    parameter EN_RSTRAM_A = "TRUE",
    parameter EN_RSTRAM_B = "TRUE",
    parameter SIM_DEVICE = "SPARTAN6"
)(
    input  wire [31:0] DIA, DIB,
    input  wire [3:0]  DIPA, DIPB,
    input  wire [13:0] ADDRA, ADDRB,
    input  wire [3:0]  WEA, WEB,
    input  wire        ENA, ENB, RSTA, RSTB, CLKA, CLKB,
    
    // ATENCIÓN: Cambiados a 'wire' para poder conectarlos a los submódulos
    output wire [31:0] DOA, DOB,
    output wire [3:0]  DOPA, DOPB
);

    assign DOPA = 4'd0;
    assign DOPB = 4'd0;
`ifdef FPGA
    `ifndef SYNTHESIS
        // =======================================================
        // 1. MODO SIMULACIÓN (Icarus Verilog / ModelSim)
        // =======================================================
        reg [31:0] ram_data [0:511];
        wire [8:0] addr_b_word = ADDRB[13:5];
        wire [1:0] addr_b_byte = ADDRB[4:3];
    
        reg [31:0] doa_reg, dob_reg;
        assign DOA = doa_reg;
        assign DOB = dob_reg;
    
        integer i;
        initial begin
            for (i = 0; i < 512; i = i + 1) ram_data[i] = 0;
            doa_reg = 0; 
            dob_reg = 0;
        end
    
        // Puerto A (32 bits)
        always @(posedge CLKA) begin
            if (ENA) begin
                if (WEA[0]) ram_data[ADDRA[13:5]][7:0]   <= DIA[7:0];
                if (WEA[1]) ram_data[ADDRA[13:5]][15:8]  <= DIA[15:8];
                if (WEA[2]) ram_data[ADDRA[13:5]][23:16] <= DIA[23:16];
                if (WEA[3]) ram_data[ADDRA[13:5]][31:24] <= DIA[31:24];
                doa_reg <= ram_data[ADDRA[13:5]];
            end
        end
    
        // Puerto B (8 bits asimétrico)
        always @(posedge CLKB) begin
            if (ENB) begin
                if (WEB[0]) begin
                    case (addr_b_byte)
                        2'b00: ram_data[addr_b_word][7:0]   <= DIB[7:0];
                        2'b01: ram_data[addr_b_word][15:8]  <= DIB[7:0];
                        2'b10: ram_data[addr_b_word][23:16] <= DIB[7:0];
                        2'b11: ram_data[addr_b_word][31:24] <= DIB[7:0];
                    endcase
                end
                case (addr_b_byte)
                    2'b00: dob_reg <= {24'd0, ram_data[addr_b_word][7:0]};
                    2'b01: dob_reg <= {24'd0, ram_data[addr_b_word][15:8]};
                    2'b10: dob_reg <= {24'd0, ram_data[addr_b_word][23:16]};
                    2'b11: dob_reg <= {24'd0, ram_data[addr_b_word][31:24]};
                endcase
            end
        end
    `endif // !SYNTHESIS

`ifdef SYNTHESIS
    // =======================================================
    // 2. MODO SÍNTESIS (Vivado - FPGA Arty)
    // =======================================================
    wire [7:0] dob_8bit;
    assign DOB = {24'd0, dob_8bit};

    // Macro oficial de Xilinx para memorias de ancho mixto
    xpm_memory_tdpram #(
        .ADDR_WIDTH_A(9),               // 512 posiciones (Procesador PicoRV)
        .ADDR_WIDTH_B(11),              // 2048 posiciones (Minimac2 Ethernet)
        .AUTO_SLEEP_TIME(0),
        .BYTE_WRITE_WIDTH_A(8),         // WSTRB de 1 byte (Procesador)
        .BYTE_WRITE_WIDTH_B(8),         // Escritura de 1 byte (Red)
        .CLOCKING_MODE("independent_clock"),
        .ECC_MODE("no_ecc"),
        .MEMORY_INIT_FILE("none"),
        .MEMORY_INIT_PARAM("0"),
        .MEMORY_OPTIMIZATION("true"),
        .MEMORY_PRIMITIVE("block"),     // Fuerza el uso de BRAM física
        .MEMORY_SIZE(16384),            
        .MESSAGE_CONTROL(0),
        .READ_DATA_WIDTH_A(32),         // Lectura a 32 bits
        .READ_DATA_WIDTH_B(8),          // Lectura asimétrica a 8 bits
        .READ_LATENCY_A(1),             
        .READ_LATENCY_B(1),
        .READ_RESET_VALUE_A("0"),
        .READ_RESET_VALUE_B("0"),
        .USE_MEM_INIT(1),
        .WAKEUP_TIME("disable_sleep"),
        .WRITE_DATA_WIDTH_A(32),        // Escritura a 32 bits
        .WRITE_DATA_WIDTH_B(8),         // Escritura a 8 bits
        .WRITE_MODE_A("write_first"),
        .WRITE_MODE_B("write_first")
    ) xpm_bram_inst (
        .douta(DOA),
        .doutb(dob_8bit),
        .addra(ADDRA[13:5]),      // Direcciones de palabras de 32b
        .addrb(ADDRB[13:3]),      // Direcciones de bytes
        .clka(CLKA),
        .clkb(CLKB),
        .dina(DIA),
        .dinb(DIB[7:0]),
        .ena(ENA),
        .enb(ENB),
        .regcea(1'b1),
        .regceb(1'b1),
        .rsta(RSTA),
        .rstb(RSTB),
        .sleep(1'b0),
        .wea(WEA),                // 4 bits de byte enable
        .web(|WEB),               // 1 bit de write enable (reducción OR)
        
        // Pines de corrección de errores (ECC) no usados
        .injectdbiterra(1'b0), .injectdbiterrb(1'b0),
        .injectsbiterra(1'b0), .injectsbiterrb(1'b0),
        .dbiterra(), .dbiterrb(), .sbiterra(), .sbiterrb()
    );
  `endif // SYNTHESIS

`endif // FPGA

`ifdef ASIC
    // =======================================================
    // 3. MODO ASIC (RM_IHPSG13_2P_512x32_c2_bm_bist: el modelo de
    //    comportamiento para simulación, o caja negra para Yosys/OpenROAD.)
    // =======================================================

    // Sanitización de direcciones en X para simulación
    `ifndef SYNTHESIS
    wire addra_unknown = (^ADDRA === 1'bx);
    wire addrb_unknown = (^ADDRB === 1'bx);
    wire [13:0] addra_safe = addra_unknown ? 14'd0 : ADDRA;
    wire [13:0] addrb_safe = addrb_unknown ? 14'd0 : ADDRB;
    `else
    wire [13:0] addra_safe = ADDRA;
    wire [13:0] addrb_safe = ADDRB;
    `endif

    // Puerto B: minimac2 accede en bytes (8 bits, addr de 14 bits)
    // -> se descompone en palabra [13:5] y byte dentro de ella [4:3]
    wire [8:0] b_addr_word = addrb_safe[13:5];
    wire [1:0] b_addr_byte = addrb_safe[4:3];

    wire [31:0] b_din_32 = {DIB[7:0], DIB[7:0], DIB[7:0], DIB[7:0]};
    wire [31:0] b_bm_byte = (b_addr_byte == 2'b00) ? 32'h0000_00FF :
                             (b_addr_byte == 2'b01) ? 32'h0000_FF00 :
                             (b_addr_byte == 2'b10) ? 32'h00FF_0000 :
                                                       32'hFF00_0000;
    wire [31:0] b_bm_32 = WEB[0] ? b_bm_byte : 32'h0000_0000;

    // Extrae el byte seleccionado de los 32 bits que devuelve la macro
    wire [31:0] b_dout_32;
    wire [7:0]  dob_8bit = (b_addr_byte == 2'b00) ? b_dout_32[ 7: 0] :
                            (b_addr_byte == 2'b01) ? b_dout_32[15: 8] :
                            (b_addr_byte == 2'b10) ? b_dout_32[23:16] :
                                                      b_dout_32[31:24];
    assign DOB = {24'd0, dob_8bit};

    RM_IHPSG13_2P_512x32_c2_bm_bist sram_ihp (
        // Puerto A: procesador (32 bits)
        .A_CLK   (CLKA),
        .A_MEN   (ENA),
        .A_WEN   (|WEA),
        .A_REN   (~|WEA),
        .A_ADDR  (addra_safe[13:5]),
        .A_DIN   (DIA),
        .A_DLY   (1'b0),
        .A_DOUT  (DOA),
        .A_BM    ({ {8{WEA[3]}}, {8{WEA[2]}}, {8{WEA[1]}}, {8{WEA[0]}} }),
        .A_BIST_CLK(1'b0), .A_BIST_EN(1'b0), .A_BIST_MEN(1'b0),
        .A_BIST_WEN(1'b0), .A_BIST_REN(1'b0), .A_BIST_ADDR(9'b0),
        .A_BIST_DIN(32'b0), .A_BIST_BM(32'b0),

        // Puerto B: minimac2 (8 bits multiplexados sobre bus de 32)
        .B_CLK   (CLKB),
        .B_MEN   (ENB),
        .B_WEN   (WEB[0]),
        .B_REN   (~WEB[0]),
        .B_ADDR  (b_addr_word),
        .B_DIN   (b_din_32),
        .B_DLY   (1'b0),
        .B_DOUT  (b_dout_32),
        .B_BM    (b_bm_32),
        .B_BIST_CLK(1'b0), .B_BIST_EN(1'b0), .B_BIST_MEN(1'b0),
        .B_BIST_WEN(1'b0), .B_BIST_REN(1'b0), .B_BIST_ADDR(9'b0),
        .B_BIST_DIN(32'b0), .B_BIST_BM(32'b0)
    );

`endif
endmodule