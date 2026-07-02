# SoCBilbao_arty/

Proyecto Vivado para la implementación del SoC en la **FPGA Arty A7-35T** (Xilinx Artix-7, dispositivo `XC7A35TICSG324-1L`). Abrir el fichero `.xpr` directamente con Vivado.

---

## Estructura

```
SoCBilbao_arty/
├── SoCBilbao_arty.xpr          # Fichero de proyecto Vivado (punto de entrada)
├── SoCBilbao_arty.hw/          # Configuración hardware del proyecto
│   └── SoCBilbao_arty.lpr
├── SoCBilbao_arty.cache/       # Caché interna de Vivado (no editar)
└── SoCBilbao_arty.srcs/        # Fuentes del proyecto
    ├── sources_1/              # Ficheros RTL Verilog del diseño
    └── constrs_1/              # Ficheros de constraints (.xdc)
```

Los ficheros RTL referenciados por el proyecto Vivado se encuentran en `SoCBilbao_files/picorv32_ihp_SoCBILBAO/picosoc/` y en las subcarpetas `boards/arty/` y `RTL/`.

---

## Cómo usar

### 1. Abrir el proyecto

```
Vivado → Open Project → SoCBilbao_arty/SoCBilbao_arty.xpr
```

### 2. Generar bitstream

Ejecutar el flujo completo desde Vivado (síntesis → implementación → bitstream). El fichero generado es `arty_top.bit` (2,2 MB).

### 3. Compilar el firmware

```bash
cd SoCBilbao_files/picorv32_ihp_SoCBILBAO/picosoc
make arty_firmware
```

Genera `boards/arty/arty_flash_firmware/firmware.bin`.

### 4. Generar el archivo de programación Flash (.mcs)

```bash
make flash
```

Combina bitstream y firmware en `boards/arty/flash/Flash_arty_bit_fir_00300000.mcs`, con el firmware a partir de la dirección `0x0030_0000` de la Flash QSPI de 16 MB.

### 5. Programar la placa

Desde Vivado Hardware Manager, seleccionar la placa Arty y programar la Flash con el fichero `.mcs`. En el siguiente arranque, la FPGA se autoconfigura y arranca el firmware automáticamente.

---

## Resultados de implementación

| Recurso | Utilizado | Disponible | % |
|---|---|---|---|
| LUT | 3.597 | 20.800 | 17,3 % |
| FF | 2.961 | 41.600 | 7,1 % |
| BRAM | 4,5 | 50 | 9,0 % |
| DSP | 4 | 90 | 4,4 % |
| I/O | 70 | 210 | 33,3 % |

**Timing**: WNS = 5,29 ns · WHS = 0,05 ns · Sin violaciones

---

## Mapa de la Flash QSPI (16 MB)

```
0x0000_0000   Bitstream FPGA (2,2 MB)
              ─────────────────────────
0x0022_0000   Margen de seguridad
              ─────────────────────────
0x0030_0000   Firmware PicoRV32 (hasta 13 MB)
              PROGADDR_RESET = 0x0030_0000
              PROGADDR_IRQ   = 0x0030_0010
```
