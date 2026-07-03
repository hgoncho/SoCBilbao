# OpenROAD_files/

Contiene todos los artefactos del flujo de implementación física **RTL-a-GDS** ejecutado con **OpenROAD Flow Scripts (ORFS)** sobre el PDK de código abierto **IHP SG13G2 (130 nm BiCMOS)**.

> Este flujo es una validación de prueba de concepto. El análisis de tiempos se ha realizado únicamente bajo la esquina nominal (TT, 1,2 V, 25 °C). Los análisis de IR drop, congestión y multiesquina PVT quedan fuera del alcance actual.

---

## Estructura

```
OpenROAD_files/
├── design_picosoc_ihp_SoCBilbao/
│   └── picosoc_SoCBilbao/          # Configuración del diseño para ORFS
│       ├── config.mk               # Parámetro principal: módulo, plataforma, die area
│       ├── picosoc_ihp.v           # Wrapper top-level con IOPads del PDK IHP
│       ├── constraint.sdc          # Restricciones temporales (50 MHz)
│       ├── pdn.tcl                 # Red de distribución de energía (PDN)
│       ├── pad.tcl                 # Distribución de 40 IOPads en el perímetro
│       ├── macro_placement.tcl     # Posicionamiento manual de las 5 macros SRAM
│       ├── cdl/                    # Ficheros CDL de las macros SRAM (para LVS)
│       ├── gds/                    # Ficheros GDS de las macros SRAM
│       ├── lef/                    # Ficheros LEF de las macros SRAM (abstracciones físicas)
│       └── lib/                    # Librerías Liberty de las macros SRAM (timing, esquina TT)
├── src_picosoc_SoCBilbao/
│   └── picosoc_SoCBilbao/          # Copia aplanada de todos los ficheros RTL para ORFS
│       ├── picosoc_ihp_SoCBilbao_minimac2.v
│       ├── picorv32.v
│       ├── minimac2*.v
│       ├── ha1588*.v / tsu.v / rtc.v / reg.v / ptp_parser.v / ptp_queue.v
│       ├── async_fifo.v / wrapper_dcfifo*.v / fifomem.v / *ptr*.v / sync_*.v
│       ├── SoCBILBAO_top.v         # Top-level con IOPads (igual que picosoc_ihp.v)
│       └── RM_IHPSG13_*.v          # Modelos de comportamiento SRAM (para simulación ASIC)
├── logs_picosoc_SoCBilbao/
│   └── picosoc_ihp/base/           # Logs de cada etapa del flujo ORFS
│       ├── 1_synth.log             # Síntesis Yosys
│       ├── 2_*.log                 # Floorplan (4 sub-etapas)
│       ├── 3_*.log                 # Colocación (5 sub-etapas)
│       ├── 4_1_cts.log             # Síntesis del árbol de reloj
│       ├── 5_*.log                 # Enrutamiento global y detallado
│       └── 6_*.log                 # Finish (relleno, merge, reporte final)
├── reports_picosoc_SoCBilbao/
│   └── picosoc_ihp/base/           # Reportes de cada etapa
│       ├── synth_stat.txt          # Estadísticas de síntesis (celdas, área)
│       ├── 2_floorplan_final.rpt   # Reporte de floorplan
│       ├── 3_*.rpt                 # Reportes de colocación y resizer
│       ├── 4_cts_final.rpt         # Reporte CTS (skew, latencia)
│       ├── 5_route_drc.rpt         # Reporte DRC tras enrutamiento (0 violaciones)
│       ├── 6_finish.rpt            # Reporte final (timing, potencia, área)
│       ├── congestion*.rpt         # Informe de congestión de enrutamiento global
│       ├── VDD.rpt                 # Análisis de IR drop de la PDN
│       ├── drt_antennas.log        # Verificación de antena (0 violaciones)
│       └── *.webp.png              # Capturas automáticas del layout por etapa
├── results_picosoc_SoCBilbao/
│   └── picosoc_ihp/base/           # Artefactos generados por el flujo
│       ├── 1_2_yosys.v             # Netlist post-síntesis
│       ├── 6_final.v               # Netlist post-enrutamiento
│       ├── 6_final.spef            # Extracción de parásitos (para STA post-layout)
│       └── 6_final.sdc             # Constraints finales
└── capturas/                       # Capturas de pantalla del layout en KLayout/OpenROAD
    ├── floorplan.png
    ├── place_*.png
    ├── cts*.png
    ├── route*.png
    ├── final_*.png                 # Layout final con distintas capas visibles
    └── PTP_ha1588.png              # Detalle del bloque HA1588 en el layout
```

---

## Configuración del diseño (`design_picosoc_ihp_SoCBilbao/picosoc_SoCBilbao/config.mk`)

Parámetros principales del flujo:

```makefile
DESIGN_NAME    = picosoc_ihp          # Módulo raíz Verilog
PLATFORM       = ihp-sg13g2           # PDK objetivo
DIE_AREA       = 0.0 0.0 2800.0 2800.0   # 2,8 × 2,8 mm²
CORE_AREA      = 400 400 2400 2400        # Anillo perimetral de 400 µm para IOPads
PLACE_DENSITY  = 0.4                  # Densidad de colocación del 40 %
```

---

## Macros SRAM utilizadas

| Macro | Capacidad | Uso en el SoC |
|---|---|---|
| `RM_IHPSG13_1P_512x32_c2_bm_bist` | 512×32 b (2 KB) | Memoria principal CPU |
| `RM_IHPSG13_2P_64x32_c2` | 64×32 b (256 B) | Banco de registros PicoRV32 |
| `RM_IHPSG13_2P_512x32_c2_bm_bist` | 512×32 b (2 KB) | Buffers Ethernet Minimac2 (×3) |

---

## Posicionamiento de macros SRAM

Las 5 macros se distribuyen en dos columnas dentro del núcleo:

```
Columna izquierda       Columna derecha
────────────────        ───────────────
rxb0  (Minimac2 RX0)    RAM CPU (512×32)
rxb1  (Minimac2 RX1)    Banco registros (64×32)
txb   (Minimac2 TX)
```

---

## Distribución de IOPads (40 pads)

| Lado | Señales |
|---|---|
| Sur | RX MII: `rxd[3:0]`, `rx_dv`, `rx_er`, `col`, `crs` |
| Este | UART, MDIO, PPS, control PHY (`phy_rst`, `phy_mii_clk`, `phy_mii_data`) |
| Norte | Reloj, reset, SPI Flash (`csb`, `clk`, `io[3:0]`) |
| Oeste | TX MII: `txd[3:0]`, `tx_en`, `tx_er`, `phy_rx_clk`, `phy_tx_clk` |

---

## Resultados del flujo

| Métrica | Valor |
|---|---|
| Área del die | 2,8 × 2,8 mm² |
| Área de núcleo | 1,40 mm² (35 % utilización) |
| Área de macros SRAM | 0,584 mm² |
| Celdas estándar | 41.675 |
| Celdas de relleno | 230.394 |
| Longitud total de interconexión | 2,67 mm |
| Total de vías | 308.801 |
| Potencia estimada | 2,03 mW |
| IR drop máximo VDD/VSS | 0,235 mV / 0,316 mV |
| Violaciones DRC | **0** |
| Violaciones de antena | **0** |
| WNS (setup) / WHS (hold) | positivos |

---

## Ejecución del flujo

```bash
# Desde el directorio picorv32_ihp_SoCBILBAO/ con nix-shell activo:
cd ../../../OpenROAD_files
make DESIGN_CONFIG=design_picosoc_ihp_SoCBilbao/picosoc_SoCBilbao/config.mk

# Por etapas:
make synth     DESIGN_CONFIG=...
make floorplan DESIGN_CONFIG=...
make place     DESIGN_CONFIG=...
make cts       DESIGN_CONFIG=...
make route     DESIGN_CONFIG=...
make finish    DESIGN_CONFIG=...
```
