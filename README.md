# SoCBilbao

SoC basado en RISC-V con sincronización de tiempo precisa mediante **IEEE 1588 PTP** sobre Ethernet, implementado tanto en FPGA (Arty A7-35T) como en ASIC (IHP SG13G2 130 nm) mediante flujo open-source.

Desarrollado como Trabajo de Fin de Máster en la Universidad del País Vasco (UPV/EHU), Cátedra SoC4Sensing.

---

## Resultados

| Métrica | Valor |
|---|---|
| Offset de sincronización (media, N=29) | **8,5 ns** (σ = 5,7 ns, máx. 22 ns) |
| Frecuencia de sistema | 50 MHz · WNS = 5,29 ns (Arty A7) |
| Ocupación FPGA (LUT / FF / BRAM) | 3.597 / 2.961 / 4,5 bloques |
| Violaciones DRC (flujo ASIC) | **0** |
| Violaciones de antena (flujo ASIC) | **0** |
| Potencia estimada (ASIC) | 2,03 mW |
| Área del die (ASIC) | 2,8 × 2,8 mm² |

---

## Arquitectura

| Bloque | Descripción |
|---|---|
| **PicoRV32** | Núcleo softcore RISC-V (RV32IMC_Zicsr) a 50 MHz |
| **Minimac2** | Controlador Ethernet MAC 10/100 Mbps con interfaz MII |
| **HA1588** | Periférico PTP: RTC de alta resolución + TSU de captura hardware |
| **SPI Flash XIP** | Carga de firmware desde Flash QSPI externa |
| **SimpleUART** | Interfaz de comandos serie a 115200 baudios |

---

## Estructura del repositorio

```
SoCBilbao/
├── SoCBilbao_files/          # Fuentes RTL, firmware y simulación
│   └── picorv32_ihp_SoCBILBAO/
│       ├── shell.nix         # Entorno Nix reproducible para ORFS
│       └── picosoc/
│           ├── Makefile      # Sistema de construcción unificado
│           ├── start.s       # Código de arranque RISC-V
│           ├── sections.lds  # Plantilla del linker script
│           ├── RTL/          # Descripción hardware en Verilog
│           ├── firmware/     # Firmware bare-metal en C
│           ├── boards/       # Ficheros específicos de plataforma
│           │   ├── arty/     # Arty A7-35T (plataforma principal)
│           │   ├── zedboard/ # ZedBoard (legacy)
│           │   └── icebreaker/ # iCEBreaker (legacy)
│           └── sim/          # Testbenches de simulación
│               ├── cocotb/   # Testbench Python (SoC aislado)
│               └── tb_dual_core/ # Testbench Verilog doble SoC (Questa)
├── SoCBilbao_arty/           # Proyecto Vivado para FPGA Arty A7-35T
└── OpenROAD_files/           # Flujo RTL-a-GDS con ORFS (IHP SG13G2)
    ├── design_picosoc_ihp_SoCBilbao/  # Configuración del diseño ORFS
    ├── src_picosoc_SoCBilbao/         # Fuentes RTL aplanadas para ORFS
    ├── logs_picosoc_SoCBilbao/        # Logs de cada etapa del flujo
    ├── reports_picosoc_SoCBilbao/     # Reportes de timing, DRC, congestión
    ├── results_picosoc_SoCBilbao/     # Netlist y GDS generados
    └── capturas/                      # Capturas de pantalla del layout
```

---

## Inicio rápido

### Requisitos

| Herramienta | Versión |
|---|---|
| riscv-none-elf-gcc (xPack) | v13.2.0-2 |
| Icarus Verilog / Questa | ≥ v12 / 2023.4 |
| CocoTB + cocotbext-eth + scapy | ≥ 1.9.1 |
| Yosys | v0.62 |
| OpenROAD Flow Scripts | commit `5fb699a0` |
| Xilinx Vivado | ≥ 2022.2 |

### Compilar firmware para Arty A7-35T

```bash
cd SoCBilbao_files/picorv32_ihp_SoCBILBAO/picosoc
make arty_firmware
```

### Compilar firmware para simulación CocoTB

```bash
cd SoCBilbao_files/picorv32_ihp_SoCBILBAO/picosoc
make sim_firmware
```

### Simulación doble SoC (Questa)

```bash
cd SoCBilbao_files/picorv32_ihp_SoCBILBAO/picosoc/sim/tb_dual_core
vsim -do "vsim tb_dual_core; run -all"
```

### Síntesis FPGA (Vivado)

Abrir `SoCBilbao_arty/SoCBilbao_arty.xpr` en Vivado y ejecutar *Generate Bitstream*.

### Flujo ASIC (OpenROAD)

```bash
cd SoCBilbao_files/picorv32_ihp_SoCBILBAO
nix-shell
cd ../../../OpenROAD_files
make DESIGN_CONFIG=design_picosoc_ihp_SoCBilbao/picosoc_SoCBilbao/config.mk
```

El GDS final se genera en `results_picosoc_SoCBilbao/picosoc_ihp/base/6_final.gds`.

---

## Licencias de terceros

| Componente | Licencia |
|---|---|
| PicoRV32 | ISC (YosysHQ) |
| Minimac2 | LGPL-2.1 (Milkymist Project) |
| HA1588 | Apache 2.0 (FreeCores) |
| PDK IHP SG13G2 | Apache 2.0 (IHP) |
| OpenROAD Flow Scripts | BSD 3-Clause |
| CocoTB | BSD 2-Clause (FOSSi Foundation) |
| async_fifo | MIT (olofk) |

---

## Autor

**Gonzalo De Pablo** — TFM, UPV/EHU, 2026  
Cátedra SoC4Sensing · Bilbao, España
