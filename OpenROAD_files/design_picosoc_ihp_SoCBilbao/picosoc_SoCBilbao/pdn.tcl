# standard cells
add_global_connection -net {VDD} -pin_pattern {^VDD$} -power
add_global_connection -net {VDD} -pin_pattern {^VDDPE$}
add_global_connection -net {VDD} -pin_pattern {^VDDCE$}
add_global_connection -net {VSS} -pin_pattern {^VSS$} -ground
add_global_connection -net {VSS} -pin_pattern {^VSSE$}

# macros
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VDD!} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VSS!} -ground
add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {^VDD$} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {^VSS$} -ground

add_global_connection -net {VDD} -inst_pattern {.*} -pin_pattern {VDDARRAY!} -power
add_global_connection -net {VSS} -inst_pattern {.*} -pin_pattern {VSSARRAY!} -ground

global_connect

# core voltage domain
set_voltage_domain -name {CORE} -power {VDD} -ground {VSS}

# stdcell grid
define_pdn_grid -name {grid} -voltage_domains {CORE} -pins {TopMetal1 TopMetal2}
add_pdn_stripe -grid {grid} -layer {Metal1} -width {0.44} -pitch {7.56} -offset {0} \
 -followpins -extend_to_core_ring

add_pdn_ring -grid {grid} -layers {Metal5 TopMetal1} -widths {8.0} -spacings {5.0} \
 -core_offsets {4.5} -connect_to_pads

add_pdn_stripe -grid {grid} -layer {TopMetal1} -width {4.0} -pitch {60.0} -offset {10.0} \
 -extend_to_core_ring

add_pdn_stripe -grid {grid} -layer {TopMetal2} -width {4.0} -pitch {60.0} -offset {10.0} \
 -extend_to_core_ring
 
add_pdn_connect -grid {grid} -layers {Metal1 TopMetal1}
add_pdn_connect -grid {grid} -layers {Metal5 TopMetal1}
add_pdn_connect -grid {grid} -layers {Metal5 TopMetal2}
add_pdn_connect -grid {grid} -layers {TopMetal1 TopMetal2}

# macro grid (RAMs IHP: 1P 512x32, 2P 512x32, 2P 64x32)
define_pdn_grid -name {macro_grid} -voltage_domains {CORE} -macro \
    -cells {RM_IHPSG13_1P_512x32_c2_bm_bist RM_IHPSG13_2P_512x32_c2_bm_bist RM_IHPSG13_2P_64x32_c2} \
    -halo {4.0}
 
add_pdn_connect -grid {macro_grid} -layers {Metal4 TopMetal1}
add_pdn_connect -grid {macro_grid} -layers {TopMetal1 TopMetal2}
