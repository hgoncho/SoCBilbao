# SoCBilbao

SoC basado en RISC-V con sincronización de tiempo precisa mediante IEEE 1588 PTP sobre Ethernet,
implementado tanto en FPGA (Arty A7-35T) como en ASIC (IHP SG13G2 130 nm) mediante flujo open-source.

## Descripción

SoCBilbao integra los siguientes componentes:

- **PicoRV32** — núcleo RISC-V RV32IMC a 50 MHz
- **Minimac2** — controlador Ethernet MII 10/100 Mbps
- **HA1588** — periférico PTP con RTC y TSU para marcado temporal hardware
- **Firmware bare-metal** — controlador PI de sincronización, CLI UART, drivers SPI Flash

La sincronización alcanzada en hardware es de **~8.5 ns de media** (σ = 5.7 ns, N = 29 muestras),
por debajo del umbral de un ciclo de reloj de sistema (20 ns).

## Estructura del repositorio
SoCBilbao/

  ├── OpenROAD_files/       # Flujo RTL-to-GDS (ORFS, IHP SG13G2)
  
  ├── SoCBilbao_arty/       # Proyecto Vivado para FPGA Arty A7-35T
  
  └── SoCBilbao_files/      # RTL, firmware y testbenches


## Requisitos

| Herramienta | Versión |
|---|---|
| riscv-none-elf-gcc (xPack) | v13.2.0-2 |
| Icarus Verilog / Questa | v12.0 / 2023.4 |
| CocoTB | v1.9.1 |
| Yosys | v0.62 |
| OpenROAD Flow Scripts | commit `5fb699a0` |
| Xilinx Vivado | v2022.2 |
| KLayout | v0.30.6 |

## Simulación

```bash
cd SoCBilbao_files
make sim          # testbench dual-core CocoTB
make sim_verilog  # testbench Verilog puro (Icarus)
```

## Síntesis FPGA

Abrir el proyecto en Vivado desde `SoCBilbao_arty/` y ejecutar *Generate Bitstream*.
Target: `XC7A35TICSG324-1L` (Arty A7-35T).

## Flujo ASIC (OpenROAD)

```bash
cd OpenROAD_files
nix-shell
make
```

PDK: IHP SG13G2 BiCMOS 130 nm. El GDS final se genera en `results/picosoc_ihp/base/6_1_merged.gds`.

## Trabajo fin de máster

Este repositorio es el artefacto técnico del TFM *SoCBILBAO: Diseño e implementación de un SoC 
RISC-V con soporte PTP sobre Ethernet* — Máster en Sistemas Electrónicos Avanzados, UPV/EHU,
Cátedra SoC4Sensing, 2025.

## Licencia

MIT


