# macro_placement.tcl
# CORE_AREA = 400 400 2400 2400  (2000 x 2000 um utiles)

# --- Columna izquierda: los 3 buffers RX/TX ---

place_macro -macro_name {picosoc_core.soc.minimac2core.memory.rxb0.sram_ihp} \
    -location {450 600} -orientation R0

place_macro -macro_name {picosoc_core.soc.minimac2core.memory.rxb1.sram_ihp} \
    -location {450 1020} -orientation R0


place_macro -macro_name {picosoc_core.soc.minimac2core.memory.txb.sram_ihp} \
    -location {450 1500} -orientation R0


# --- Columna derecha: RAM principal y banco de registros ---
place_macro -macro_name {picosoc_core.soc.memory.sram} \
    -location {1185.49 600} -orientation R0

place_macro -macro_name {picosoc_core.soc.cpu.cpuregs.reg_sram} \
    -location {1185.49 1000} -orientation R0

# --- PADDING DE SEGURIDAD PARA LOS RELOJES ---
set mis_macros [get_cells {
    picosoc_core.soc.minimac2core.memory.rxb0.sram_ihp
    picosoc_core.soc.minimac2core.memory.rxb1.sram_ihp
    picosoc_core.soc.minimac2core.memory.txb.sram_ihp
    picosoc_core.soc.memory.sram
    picosoc_core.soc.cpu.cpuregs.reg_sram
}]

# Añadimos un padding de 40
set_placement_padding -instances $mis_macros -left 40 -right 40
