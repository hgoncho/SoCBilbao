# ============================================================================
# CONFIGURACIÓN GENERAL
# ============================================================================
CROSS=riscv-none-elf-
CFLAGS=

# Directorios de destino
ICE_DIR = boards/icebreaker
ZED_DIR = boards/zedboard
ZED_SIM_OUT = $(ZED_DIR)/sim_vivado

# Directorios de minimac2
MAC_RTL_DIR = RTL/minimac2/rtl
MAC_RTL_RAM = boards/arty/RAMB16BWER_wrapper_arty.v
#MAC_SIM_DIR = minimac2/test

# Directorios de HA1588
HA_RTL_TOP = RTL/ha1588/rtl/top
HA_RTL_REG = RTL/ha1588/rtl/reg
HA_RTL_WB  = RTL/ha1588/rtl/bus/wishbone
HA_RTL_RTC = RTL/ha1588/rtl/rtc
HA_RTL_TSU = RTL/ha1588/rtl/tsu
HA_IP_DEF  = RTL/ha1588/par

HA_FIFO_OS  = RTL/ha1588/par/FIFO_OpenSource/async_fifo/rtl
HA_FIFO_RTL = $(HA_FIFO_OS)/wrapper_dcfifo_128b_16_opensource.v \
	      $(HA_FIFO_OS)/async_fifo.v $(HA_FIFO_OS)/sync_r2w.v \
	      $(HA_FIFO_OS)/sync_w2r.v $(HA_FIFO_OS)/rptr_empty.v \
	      $(HA_FIFO_OS)/fifomem.v $(HA_FIFO_OS)/wptr_full.v			

# Archivos comunes (están en la raíz)
COMMON_HDL = RTL/spimemio.v RTL/simpleuart.v ../picorv32.v RTL/spiflash/spiflash.v RTL/picosoc_ihp_SoCBilbao_minimac2.v RTL/picorv32_wb_adapter.v
COMMON_FW  = start.s firmware.c sections.lds

# Archivos de IHP RAM y REG
IHP_MODELS = RTL/RM_IHP/RM_IHPSG13_1P_512x32_c2_bm_bist.v \
             RTL/RM_IHP/RM_IHPSG13_1P_core_behavioral_bm_bist.v \
             RTL/RM_IHP/RM_IHPSG13_2P_64x32_c2.v \
             RTL/RM_IHP/RM_IHPSG13_2P_core_behavioral_ideal.v \
             RTL/RM_IHP/RM_IHPSG13_2P_512x32_c2_bm_bist.v \
             RTL/RM_IHP/RM_IHPSG13_2P_core_behavioral_bm_bist_ideal.v

# Archivos de minimac2
MINIMAC2 = $(MAC_RTL_DIR)/*.v $(MAC_RTL_RAM)

# Archivos de PTP HA1588
HA1588 = $(HA_RTL_TOP)/*.v $(HA_RTL_REG)/*.v $(HA_RTL_WB)/*.v $(HA_RTL_RTC)/*.v $(HA_RTL_TSU)/*.v \
	 $(HA_IP_DEF)/*.h $(HA_FIFO_RTL)


# 1. Definimos la carpeta de destino y los nuevos archivos
ARTY_DIR = boards/arty
ARTY_FW_DIR = $(ARTY_DIR)/arty_flash_firmware
NUEVOS_INC  = -I firmware/ -I firmware/minimac2/ -I firmware/ha1588/ -I firmware/simpleuart/ -I firmware/spiflash/

NUEVOS_SRC = firmware/main.c firmware/minimac2/minimac2.c firmware/ha1588/ha1588.c firmware/simpleuart/simpleuart.c firmware/spiflash/spiflash.c firmware/minimac2/ptp_packets_example.c

NUEVOS_ASM = start.s

# --- Control TARGET para simulaciones ---
# Uso: make sim_dual TARGET=fpga  (defecto)
#      make sim_dual TARGET=asic
TARGET ?= fpga
ifeq ($(TARGET),asic)
  SIM_TARGET_FLAG = -DASIC_SIM
  DUAL_HDL_EXTRA  = $(IHP_MODELS)
  # -DASIC es el define que comprueba picosoc_ihp_SoCBilbao_minimac2.v
  # (`ifdef ASIC) para elegir la macro real de IHP en vez del array
  # genérico. ASIC_SIM/FUNCTIONAL se dejan igual, son independientes.
  DUAL_DEFINES    = -DFUNCTIONAL -DASIC_SIM -DASIC
else
  SIM_TARGET_FLAG = -DFPGA_SIM
  DUAL_HDL_EXTRA  =
  DUAL_DEFINES    = -DFPGA_SIM -DFPGA
endif

# Directorio de salida del simulador dual
DUAL_SIM_DIR = sim/tb_dual_core
DUAL_FW_DIR  = $(DUAL_SIM_DIR)/firmware
DUAL_TB_VVP  = $(DUAL_SIM_DIR)/dual_core_tb.vvp
DUAL_TB_V    = $(DUAL_SIM_DIR)/tb_dual_core.v

# ============================================================================
# OBJETIVOS PRINCIPALES
# ============================================================================

# Simulación completa ZedBoard
sim_completa_zed_iverlilog: clean_zed
	@mkdir -p $(ZED_DIR)
	# Configuramos PATH y compilamos firmware
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/opt/oss-cad-suite/bin:$(PATH)" && \
	$(MAKE) $(ZED_DIR)/zedboard_fw.hex CROSS=riscv-none-elf- && \
	$(MAKE) $(ZED_DIR)/zedboard_tb.vvp && \
	$(MAKE) zedbsim

# Simulación completa icebreaker
sim_completa_ice: clean_ice
	@mkdir -p $(ICE_DIR)
	# Configuramos PATH y compilamos firmware
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:/opt/oss-cad-suite/bin:$(PATH)" && \
	$(MAKE) $(ICE_DIR)/icebreaker_fw.hex CROSS=riscv-none-elf- && \
	$(MAKE) $(ICE_DIR)/icebreaker_tb.vvp && \
	$(MAKE) icebsim


# ============================================================================
# EXPORTAR FIRMWARE BINARIO EN ARTY
# ============================================================================
# Comando directo: "make binary"
binary: arty/firmware.bin

arty/firmware.bin: $(ZED_DIR)/zedboard_fw.elf
	@mkdir -p arty
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)objcopy -O binary $< $@
	

# ============================================================================
# GENERAR ARCHIVOS DE FLASH (.MCS y .PRM) PARA ARTY
# ============================================================================
# Ruta a tu archivo .bit generado por Vivado (Ajusta la ruta relativa si es necesario)
ARTY_BITSTREAM = /home/gonzalo/Vivado/picorv32_ihp_SoCBILBAO/picorv32_ihp_SoCBILBAO.runs/impl_1/arty_top.bit

# Comando directo: "make flash"
flash: $(ARTY_DIR)/arty_flash_firmware/firmware.bin
	@echo "--- Copiando la carpeta firmware entera a arty/flash/ ---"
	@mkdir -p $(ARTY_DIR)/flash
	@cp -r firmware $(ARTY_DIR)/flash/
	@echo "--- Generando script Tcl para Vivado ---"
	@echo 'write_cfgmem -force -format mcs -size 16 -interface SPIx4 -loadbit "up 0x00000000 $(ARTY_BITSTREAM)" -loaddata "up 0x00300000 boards/arty/arty_flash_firmware/firmware.bin" -file "boards/arty/flash/Flash_arty_bit_fir_00300000.mcs"' > $(ARTY_DIR)/gen_mcs.tcl
	@echo "--- Ejecutando Vivado en modo batch ---"
	vivado -mode batch -source $(ARTY_DIR)/gen_mcs.tcl -notrace -log $(ARTY_DIR)/flash/vivado_log/vivado.log -journal $(ARTY_DIR)/flash/vivado_log/vivado.jou

# ============================================================================
# NUEVO FLUJO MODULAR PARA ARTY (FIRMWARE MULTI-ARCHIVO)
# ============================================================================
DEST_DIR ?= /home/gonzalo/modelos_picosoc/picorv32_ihp_SoCBILBAO/picosoc/RTL/spiflash

# 2. Objetivo principal: Añadimos la copia como paso final
arty_firmware: $(ARTY_FW_DIR)/firmware.bin $(ARTY_FW_DIR)/fw_arty.hex
	@mkdir -p $(DEST_DIR)
	cp $(ARTY_FW_DIR)/fw_arty.hex $(DEST_DIR)/firmware.hex
	@echo "--- ¡Firmware copiado a $(DEST_DIR)/firmware.hex! ---"

# 3. Generar el Linker Script para Arty
$(ARTY_FW_DIR)/arty_sections.lds: sections.lds
	@mkdir -p $(ARTY_FW_DIR)
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)cpp -P -DARTY -o $@ $<

# 4. Compilar el Firmware (ELF) con todos los archivos .c y las rutas Include (-I)
$(ARTY_FW_DIR)/firmware.elf: $(ARTY_FW_DIR)/arty_sections.lds $(NUEVOS_ASM) $(NUEVOS_SRC)
	@mkdir -p $(ARTY_FW_DIR)
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)gcc $(CFLAGS) -DARTY $(NUEVOS_INC) -mabi=ilp32 -march=rv32imc -Wl,-Bstatic,-T,$(ARTY_FW_DIR)/arty_sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ $(NUEVOS_ASM) $(NUEVOS_SRC)

# 5. Extraer el binario final
$(ARTY_FW_DIR)/firmware.bin: $(ARTY_FW_DIR)/firmware.elf
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)objcopy -O binary $< $@

# 5.1 Extraer el archivo HEX (formato Verilog)
$(ARTY_FW_DIR)/fw_arty.hex: $(ARTY_FW_DIR)/firmware.elf
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)objcopy -O verilog $< $@

# 6. Limpieza específica para esta carpeta
clean_arty_fw:
	rm -rf $(ARTY_FW_DIR)
	
# ========================================================================================
# ZEDBOARD FLOW (Directorio: zedboard/) con iverilog  **VOLVER AL QUITAR EL IP XILINX**
# ========================================================================================

# 1. Linker Script específico para ZedBoard (2KB RAM)
$(ZED_DIR)/zedboard_sections.lds: sections.lds
	@mkdir -p $(ZED_DIR)
	$(CROSS)cpp -P -DZEDBOARD -o $@ $<

# 2. Compilación del Firmware (ELF)
$(ZED_DIR)/zedboard_fw.elf: $(ZED_DIR)/zedboard_sections.lds $(COMMON_FW)
	@mkdir -p $(ZED_DIR)
	$(CROSS)gcc $(CFLAGS) -DZEDBOARD -mabi=ilp32 -march=rv32imc -Wl,-Bstatic,-T,$(ZED_DIR)/zedboard_sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ start.s firmware.c

# 3. Conversión a HEX
$(ZED_DIR)/zedboard_fw.hex: $(ZED_DIR)/zedboard_fw.elf
	$(CROSS)objcopy -O verilog $< $@

# 4. Compilación del Testbench (VVP)
# Nota: Busca los fuentes específicos DENTRO de $(ZED_DIR)
$(ZED_DIR)/zedboard_tb.vvp: $(ZED_DIR)/tb_zedboard_top.v $(ZED_DIR)/zedboard_top.v \
                            $(ZED_DIR)/SoCBILBAO_top.v \
			    $(COMMON_HDL) $(IHP_MODELS) $(MINIMAC2) $(HA1588)
	@mkdir -p $(ZED_DIR)
	iverilog -s tb_zedboard_top -I $(HA_IP_DEF) -o $@ -DFUNCTIONAL $^ -DNO_ICE40_DEFAULT_ASSIGNMENTS

# 5. Ejecución de la simulación
zedbsim: $(ZED_DIR)/zedboard_tb.vvp $(ZED_DIR)/zedboard_fw.hex
	# Copiamos el hex a la raíz con nombre genérico para que el modelo verilog lo encuentre si usa $readmemh("firmware.hex")
	cp $(ZED_DIR)/zedboard_fw.hex firmware.hex
	vvp -N $(ZED_DIR)/zedboard_tb.vvp

# Visualización
visualizar_señales_zed_iverlilog:
	export PATH="/opt/oss-cad-suite/bin:$$PATH" && \
	gtkwave $(ZED_DIR)/zedboard_sim.vcd $(ZED_DIR)/Señales_simulacion_zedboard.gtkw &


# ============================================================================
# ICEBREAKER FLOW (Directorio: icebreaker/)
# ============================================================================

# 1. Linker Script
$(ICE_DIR)/icebreaker_sections.lds: sections.lds
	@mkdir -p $(ICE_DIR)
	$(CROSS)cpp -P -DICEBREAKER -o $@ $<

# 2. Firmware ELF
$(ICE_DIR)/icebreaker_fw.elf: $(ICE_DIR)/icebreaker_sections.lds $(COMMON_FW)
	@mkdir -p $(ICE_DIR)
	$(CROSS)gcc $(CFLAGS) -DICEBREAKER -mabi=ilp32 -march=rv32ic -Wl,-Bstatic,-T,$(ICE_DIR)/icebreaker_sections.lds,--strip-debug -ffreestanding -nostdlib -o $@ start.s firmware.c

# 3. Firmware HEX (Para simulación)
$(ICE_DIR)/icebreaker_fw.hex: $(ICE_DIR)/icebreaker_fw.elf
	$(CROSS)objcopy -O verilog $< $@

# 4. Firmware BIN (Para flashear en placa)
$(ICE_DIR)/icebreaker_fw.bin: $(ICE_DIR)/icebreaker_fw.elf
	$(CROSS)objcopy -O binary $< $@

# 5. Simulación (Compilación VVP)
# NOTA: Incluye tus memorias IHP + ice40up5k_spram + picosoc (vía COMMON_HDL)
$(ICE_DIR)/icebreaker_tb.vvp: $(ICE_DIR)/icebreaker_tb.v $(ICE_DIR)/icebreaker.v \
                              $(ICE_DIR)/ice40up5k_spram.v \
                              $(COMMON_HDL) $(IHP_MODELS) $(MINIMAC2)
	@mkdir -p $(ICE_DIR)
	iverilog -s testbench_ice -o $@ \
	-DFUNCTIONAL -DNO_ICE40_DEFAULT_ASSIGNMENTS \
	$^ \
	`yosys-config --datdir/ice40/cells_sim.v`

# 6. Ejecución de Simulación
icebsim: $(ICE_DIR)/icebreaker_tb.vvp $(ICE_DIR)/icebreaker_fw.hex
	cp $(ICE_DIR)/icebreaker_fw.hex firmware.hex
	vvp -N $(ICE_DIR)/icebreaker_tb.vvp +firmware=firmware.hex

# --- FLUJO DE SÍNTESIS Y HARDWARE ---

# 7. Síntesis (JSON)
$(ICE_DIR)/icebreaker.json: $(ICE_DIR)/icebreaker.v $(ICE_DIR)/ice40up5k_spram.v $(COMMON_HDL)
	@mkdir -p $(ICE_DIR)
	# Nota: Excluimos los modelos de simulación IHP (IHP_MODELS) para síntesis real
	yosys -ql $(ICE_DIR)/icebreaker.log -p 'synth_ice40 -dsp -top icebreaker -json $@' \
	$(ICE_DIR)/icebreaker.v $(ICE_DIR)/ice40up5k_spram.v $(COMMON_HDL)

# 8. Place & Route (ASC)
$(ICE_DIR)/icebreaker.asc: $(ICE_DIR)/icebreaker.pcf $(ICE_DIR)/icebreaker.json
	nextpnr-ice40 --freq 13 --up5k --package sg48 --asc $@ --pcf $< --json $(word 2,$^)

# 9. Bitstream (BIN) y Reporte de tiempos
$(ICE_DIR)/icebreaker.bin: $(ICE_DIR)/icebreaker.asc
	icetime -d up5k -c 12 -mtr $(ICE_DIR)/icebreaker.rpt $<
	icepack $< $@

# 10. Programación (Flash)
icebprog: $(ICE_DIR)/icebreaker.bin $(ICE_DIR)/icebreaker_fw.bin
	iceprog $(ICE_DIR)/icebreaker.bin
	iceprog -o 1M $(ICE_DIR)/icebreaker_fw.bin

# 11. Programación (Solo Firmware)
icebprog_fw: $(ICE_DIR)/icebreaker_fw.bin
	iceprog -o 1M $<

# --- SIMULACIÓN POST-SÍNTESIS (Opcional) ---

$(ICE_DIR)/icebreaker_syn.v: $(ICE_DIR)/icebreaker.json
	yosys -p 'read_json $<; write_verilog $@'

$(ICE_DIR)/icebreaker_syn_tb.vvp: $(ICE_DIR)/icebreaker_tb.v $(ICE_DIR)/icebreaker_syn.v spiflash.v
	iverilog -s testbench_ice -o $@ \
	-DNO_ICE40_DEFAULT_ASSIGNMENTS \
	$^ \
	`yosys-config --datdir/ice40/cells_sim.v`

icebsynsim: $(ICE_DIR)/icebreaker_syn_tb.vvp $(ICE_DIR)/icebreaker_fw.hex
	cp $(ICE_DIR)/icebreaker_fw.hex firmware.hex
	vvp -N $< +firmware=firmware.hex

# Visualización
visualizar_señales_ice:
	export PATH="/opt/oss-cad-suite/bin:$$PATH" && \
	gtkwave $(ICE_DIR)/testbench_ice.vcd &

# ============================================================================
# FIRMWARE PARA SIMULACIÓN COCOTB
# Usa -DSIM para activar el modo flash compatible con spiflash.v
#
# Uso:
#   make sim_firmware          -> genera y copia el hex a cocotb
#   make clean_sim_firmware    -> limpia los ficheros generados
#
# Requiere en spiflash.c:
#   void set_flash_mode_quad() {
#   #ifdef SIM
#       reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00240000; // SIMULADA
#   #else
#       reg_spictrl = (reg_spictrl & ~0x007f0000) | 0x00280000; // ARTY
#   #endif
#   }
# ============================================================================
 
SIM_FW_DIR  = boards/arty/arty_flash_firmware_sim
COCOTB_DIR  = sim/cocotb/cocotb_picosoc/top
 
.PHONY: sim_firmware clean_sim_firmware
 
# Target principal: genera y copia el hex al directorio cocotb
sim_firmware: $(COCOTB_DIR)/fw_sim.hex
	@echo ""
	@echo "============================================"
	@echo "  Firmware de simulacion generado:"
	@echo "  $(COCOTB_DIR)/fw_sim.hex"
	@echo "============================================"
 
# 1. Linker Script para simulacion (igual que ARTY)
$(SIM_FW_DIR)/sim_sections.lds: sections.lds
	@mkdir -p $(SIM_FW_DIR)
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)cpp -P -DARTY -DSIM -o $@ $<
 
# 2. Compilar ELF con -DSIM (activa modo flash simulado en spiflash.c)
$(SIM_FW_DIR)/firmware_sim.elf: $(SIM_FW_DIR)/sim_sections.lds $(NUEVOS_ASM) $(NUEVOS_SRC)
	@mkdir -p $(SIM_FW_DIR)
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)gcc $(CFLAGS) -DARTY -DSIM $(NUEVOS_INC) \
		-mabi=ilp32 -march=rv32imc \
		-Wl,-Bstatic,-T,$(SIM_FW_DIR)/sim_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $@ $(NUEVOS_ASM) $(NUEVOS_SRC)
 
# 3. Generar HEX formato Verilog
$(SIM_FW_DIR)/fw_sim.hex: $(SIM_FW_DIR)/firmware_sim.elf
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)objcopy -O verilog $< $@
 
# 4. Copiar al directorio cocotb
$(COCOTB_DIR)/fw_sim.hex: $(SIM_FW_DIR)/fw_sim.hex
	@mkdir -p $(COCOTB_DIR)
	cp $< $@
 
# Limpieza
clean_sim_firmware:
	rm -rf $(SIM_FW_DIR)
	rm -f $(COCOTB_DIR)/fw_sim.hex



# ============================================================================
# SIMULACIÓN DUAL-CORE VERILOG (tb_dual_core.v)
#
# Uso:
#   make sim_dual                -> TARGET=fpga (defecto)
#   make sim_dual TARGET=asic    -> con modelos IHP
#   make sim_dual TARGET=fpga TIMEOUT=100000000  -> timeout en ns (defecto 50ms)
#   make clean_dual              -> limpia artefactos
# ============================================================================

TIMEOUT ?= 50000000

.PHONY: sim_dual clean_dual

# 1. Linker Script
$(DUAL_FW_DIR)/dual_sections.lds: sections.lds
	@mkdir -p $(DUAL_FW_DIR)
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)cpp -P -DARTY -DSIM -o $@ $<

# 2. Firmware ELF (incluye flag FPGA_SIM o ASIC_SIM según TARGET)
$(DUAL_FW_DIR)/fw_dual.elf: $(DUAL_FW_DIR)/dual_sections.lds $(NUEVOS_ASM) $(NUEVOS_SRC)
	@mkdir -p $(DUAL_FW_DIR)
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)gcc $(CFLAGS) -DARTY -DSIM -DSIM_DUAL $(SIM_TARGET_FLAG) $(NUEVOS_INC) \
		-mabi=ilp32 -march=rv32imc \
		-Wl,-Bstatic,-T,$(DUAL_FW_DIR)/dual_sections.lds,--strip-debug \
		-ffreestanding -nostdlib \
		-o $@ $(NUEVOS_ASM) $(NUEVOS_SRC)

# 3. Firmware HEX
$(DUAL_FW_DIR)/fw_dual.hex: $(DUAL_FW_DIR)/fw_dual.elf
	export PATH="$(HOME)/riscv-tools/xpack-riscv-none-elf-gcc-13.2.0-2/bin:$$PATH" && \
	$(CROSS)objcopy -O verilog $< $@

# 4. Compilar testbench con iverilog
$(DUAL_TB_VVP): $(DUAL_TB_V) \
                boards/arty/arty_top_flash.v \
                boards/zedboard/SoCBILBAO_top.v \
                $(COMMON_HDL) $(DUAL_HDL_EXTRA) $(MINIMAC2) $(HA1588)
	@mkdir -p $(DUAL_SIM_DIR)
	export PATH="/opt/oss-cad-suite/bin:$$PATH" && \
	iverilog -s tb_dual_core \
		-I $(HA_IP_DEF) \
		-DNO_ICE40_DEFAULT_ASSIGNMENTS \
		$(DUAL_DEFINES) \
		-o $@ $^

# 5. Ejecutar simulación — salida en tiempo real por terminal
sim_dual: $(DUAL_TB_VVP) $(DUAL_FW_DIR)/fw_dual.hex
	@echo ""
	@echo "============================================"
	@echo "  Simulacion DUAL-CORE  [TARGET=$(TARGET)]"
	@echo "  Timeout: $(TIMEOUT) ns"
	@echo "============================================"
	@echo ""
	cp $(DUAL_FW_DIR)/fw_dual.hex firmware.hex
	export PATH="/opt/oss-cad-suite/bin:$$PATH" && \
	vvp -N $(DUAL_TB_VVP) +timeout_ns=$(TIMEOUT)

# 6. Ver señales en GTKWave
visualizar_dual:
	export PATH="/opt/oss-cad-suite/bin:$$PATH" && \
	gtkwave dual_core_sim.vcd &

# 7. Limpieza
clean_dual:
	rm -f $(DUAL_TB_VVP)
	rm -f $(DUAL_FW_DIR)/fw_dual.hex
	rm -f $(DUAL_FW_DIR)/fw_dual.elf
	rm -f $(DUAL_FW_DIR)/dual_sections.lds
	rm -f sim/tb_dual_core/dual_core_sim.fst   # antes era .vcd
	rm -f firmware.hex



# ============================================================================
# SIMULACIÓN DUAL-CORE con QUESTA (mucho más rápido que iverilog)
# Uso:
#   make sim_dual_questa
#   make sim_dual_questa TARGET=asic
# ============================================================================

QUESTA = /eda/Siemens/2023-24/RHELx86/QUESTA-CORE-PRIME_2023.4/questasim/linux_x86_64
VLOG   = $(QUESTA)/vlog
VSIM   = $(QUESTA)/vsim
QUESTA_WORK = sim/tb_dual_core/questa_work

.PHONY: sim_dual_questa clean_questa

# 1. Compilar RTL con vlog
$(QUESTA_WORK)/.compiled: $(DUAL_TB_V) \
                boards/arty/arty_top_flash.v \
                boards/zedboard/SoCBILBAO_top.v \
                $(COMMON_HDL) $(DUAL_HDL_EXTRA) $(MINIMAC2) $(HA1588)
		@mkdir -p $(QUESTA_WORK)
	$(VLOG) -work $(QUESTA_WORK) \
		+incdir+RTL/ha1588/par \
		+define+NO_ICE40_DEFAULT_ASSIGNMENTS \
		+define+$(if $(filter asic,$(TARGET)),FUNCTIONAL+ASIC_SIM+ASIC,FPGA_SIM+FPGA) \
		$^
	@touch $(QUESTA_WORK)/.compiled

# 2. Ejecutar simulación
sim_dual_questa: $(QUESTA_WORK)/.compiled $(DUAL_FW_DIR)/fw_dual.hex
	@echo ""
	@echo "============================================"
	@echo "  Simulacion DUAL-CORE QUESTA [TARGET=$(TARGET)]"
	@echo "============================================"
	@echo ""
	cp $(DUAL_FW_DIR)/fw_dual.hex firmware.hex
	$(VSIM) -batch -do \
		"vsim -lib $(QUESTA_WORK) tb_dual_core; \
		 run -all; \
		 quit -f" \
		+timeout_ns=$(TIMEOUT) \
		2>&1 | tee sim/tb_dual_core/questa_run.log

# 3. Limpieza
clean_questa:
	rm -rf $(QUESTA_WORK)
	rm -f sim/tb_dual_core/questa_run.log



# ============================================================================
# LIMPIEZA
# ============================================================================
clean_vivado:
	@echo "--- Limpiando basura de Vivado en la raiz ---"
	rm -f vivado*.log vivado*.jou vivado*.str

clean: clean_zed clean_ice
	rm -f firmware.hex testbench.vcd zedboard_sim.vcd

clean_ice:
	rm -f $(ICE_DIR)/*.elf $(ICE_DIR)/*.hex $(ICE_DIR)/*.bin $(ICE_DIR)/*.vvp $(ICE_DIR)/*.lds $(ICE_DIR)/*.vcd

clean_zed:
	rm -f $(ZED_DIR)/*.elf $(ZED_DIR)/*.hex $(ZED_DIR)/*.bin $(ZED_DIR)/*.vvp $(ZED_DIR)/*.lds $(ZED_DIR)/*.vcd
