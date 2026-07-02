export DESIGN_NAME = picosoc_ihp
export DESIGN_FOLDER = picosoc_SoCBilbao
export PLATFORM = ihp-sg13g2

export VDD_NET = VDD
export GND_NET = VSS
export VDD_NETS_MACROS = VDD VDDARRAY!
export GND_NETS_MACROS = VSS

export STDBUF_CMD =

# synth
export SYNTH_MEMORY_MAX_BITS = 128000

export VERILOG_FILES = \
$(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/$(DESIGN_NAME).v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/picosoc_ihp_SoCBilbao_minimac2.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/picorv32.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/async_fifo.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/fifomem.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/ha1588.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/ha1588_wb.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2_ctlif.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2_memory.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2_psync.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2_rx.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2_sync.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2_tx.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/minimac2.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/picorv32_wb_adapter.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/ptp_parser.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/ptp_queue.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RAMB16BWER_wrapper_arty.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/reg.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_1P_512x32_c2_bm_bist.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_1P_core_behavioral_bm_bist.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_1P_core_behavioral.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_2P_512x32_c2_bm_bist.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_2P_64x32_c2.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_2P_core_behavioral_bm_bist_ideal.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/RM_IHPSG13_2P_core_behavioral_ideal.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/rptr_empty.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/rtc.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/simpleuart.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/SoCBILBAO_top.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/spimemio.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/sync_r2w.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/sync_w2r.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/tsu.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/wb_slv_wrapper.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/wptr_full.v \
$(DESIGN_HOME)/src/picosoc_SoCBilbao/wrapper_dcfifo_128b_16_opensource.v

export VERILOG_DEFINES = -D ASIC -D SYNTHESIS

export MACRO_PLACEMENT_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/macro_placement.tcl

export SDC_FILE = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/constraint.sdc

export FOOTPRINT_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/pad.tcl

export PDN_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/pdn.tcl

export PRE_GRT_TCL = $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/pre_grt.tcl

export ADDITIONAL_LEFS = $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/lef/*.lef)

export ADDITIONAL_LIBS = $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/lib/*.lib)

export ADDITIONAL_GDS = $(wildcard $(DESIGN_HOME)/$(PLATFORM)/$(DESIGN_FOLDER)/gds/*.gds)

export DIE_AREA = 0.0 0.0 2800.0 2800.0
export CORE_AREA = 400 400 2400 2400
export PLACE_DENSITY = 0.4
