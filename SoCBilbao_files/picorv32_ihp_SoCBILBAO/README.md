# SoCBilbao_files/

Contiene todo el código fuente del proyecto: descripción RTL en Verilog, firmware bare-metal en C y los testbenches de simulación. La carpeta raíz del proyecto de trabajo es `picorv32_ihp_SoCBILBAO/picosoc/`.

---

## Estructura

```
picorv32_ihp_SoCBILBAO/
└── picosoc/
    ├── Makefile               # Sistema de construcción unificado (firmware + simulación)
    ├── start.s                # Código de arranque: inicializa SP y salta a main()
    ├── sections.lds           # Plantilla del linker script (procesada con cpp)
    ├── ASIC/                  # Ficheros GDS/LEF/LIB/CDL de las macros SRAM IHP
    ├── RTL/                   # Descripción hardware en Verilog
    │   ├── picosoc_ihp_SoCBilbao_minimac2.v  # Top-level del SoC
    │   ├── picorv32_wb_adapter.v             # Adaptador bus nativo → Wishbone
    │   ├── simpleuart.v                      # UART minimalista
    │   ├── spimemio.v                        # Controlador SPI Flash (XIP)
    │   ├── minimac2/rtl/                     # IP core MAC Ethernet (Milkymist)
    │   ├── ha1588/                           # IP core PTP (FreeCores)
    │   │   ├── rtl/                          # Fuentes RTL (RTC, TSU, Wishbone)
    │   │   ├── par/FIFO_OpenSource/          # FIFO asíncrona doble reloj (Gray ptr)
    │   │   ├── doc/                          # Documentación y capturas .pcap del core
    │   │   └── sim/                          # Testbenches originales del core HA1588
    │   ├── spiflash/                         # Modelo Verilog de Flash para simulación
    │   └── RM_IHP/                           # Modelos de comportamiento SRAM IHP SG13G2
    ├── firmware/              # Firmware bare-metal en C (RV32IMC, sin OS)
    │   ├── main.c             # Bucle principal y máquina de estados PTP
    │   ├── minimac2/          # Driver Ethernet: minimac2.c/h, ptp_packets_example.c/h
    │   ├── ha1588/            # Driver PTP: ha1588.c/h (RTC + TSU)
    │   ├── simpleuart/        # Driver UART: simpleuart.c/h
    │   └── spiflash/          # Driver SPI Flash: spiflash.c/h
    ├── boards/                # Ficheros específicos de cada plataforma hardware
    │   ├── arty/              # Arty A7-35T — plataforma principal de validación
    │   │   ├── arty_top.v                  # Top-level de la FPGA Arty
    │   │   ├── Arty-A7-35-SoCBilabo.xdc   # Constraints de pines
    │   │   ├── RAMB16BWER_wrapper_arty.v  # Wrapper BRAM Xilinx para Minimac2
    │   │   ├── gen_mcs.tcl                # Script Tcl para generar .mcs de Flash
    │   │   ├── arty_flash_firmware/       # Firmware compilado para hardware real
    │   │   ├── arty_flash_firmware_sim/   # Firmware compilado para simulación CocoTB
    │   │   └── flash/                     # Artefactos .mcs/.prm de programación Flash
    │   ├── zedboard/          # ZedBoard (plataforma legacy, Icarus Verilog)
    │   └── icebreaker/        # iCEBreaker (plataforma legacy, nextpnr/ice40)
    └── sim/                   # Entorno de simulación funcional
        ├── cocotb/
        │   └── cocotb_picosoc/
        │       ├── Makefile            # Runner CocoTB (backend: Questa)
        │       ├── requirements.txt    # Dependencias Python del testbench
        │       ├── test/
        │       │   ├── cocotb_picosoc.py     # Testbench principal (7 pasos)
        │       │   ├── test_cocotb_picosoc.py # Wrapper pytest
        │       │   └── pcap/ptpv2.pcap       # Tráfico PTP IEEE 1588 real (Wireshark)
        │       └── top/
        │           ├── cocotb_picosoc.v  # Top-level Verilog del DUT para CocoTB
        │           └── fw_sim.hex        # Firmware compilado para simulación (generado)
        └── tb_dual_core/
            ├── tb_dual_core.v    # Testbench Verilog: 2 SoC interconectados por MII
            └── firmware/         # Firmware compilado para el testbench dual
```

---

## Comandos principales

```bash
# Firmware para Arty A7 (hardware real)
make arty_firmware

# Firmware para simulación CocoTB
make sim_firmware

# Simulación CocoTB (SoC aislado)
cd sim/cocotb/cocotb_picosoc
make

# Simulación doble SoC con Questa
cd sim/tb_dual_core
vsim -do "vsim tb_dual_core; run -all"
```

---

## `shell.nix`

Define el entorno Nix con versiones exactas y fijas de todas las herramientas EDA open-source necesarias para el flujo ASIC: Yosys, OpenROAD, KLayout, etc. Lanzar `nix-shell` en el directorio `picorv32_ihp_SoCBILBAO/` garantiza un entorno reproducible independientemente del sistema operativo del host.

## `ASIC/`

Contiene los ficheros de las macros SRAM del PDK IHP SG13G2 necesarios tanto para la simulación funcional (modelos Verilog `.v`) como para el flujo físico ORFS (`.gds`, `.lef`, `.lib`, `.cdl`). Estos ficheros se distribuyen por separado del directorio `OpenROAD_files/` porque también se usan en la simulación del diseño ASIC con el testbench `tb_dual_core`.
