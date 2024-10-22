global design

set design(TOPLEVEL) vcve2_top
set design(FLOW_ROOT) $::env(FLOW_ROOT)

set design(ALL_LEFS) {}
set design(ALL_GDS) {}

# Timing constraints and netlist from synthesis
set design(default_sdc) $design(FLOW_ROOT)/syn/scripts/netlist.sdc
set design(netlist) $design(FLOW_ROOT)/syn/netlist/netlist.v

# Global nets
set design(all_ground_nets) {VSS VSSIO}
set design(all_power_nets) {VDD}

# Filler cell (verifica che ci siano nella TSMC65 che abbiamo noi)
set design(fillers) {FILL1LVT FILL2LVT FILL4LVT FILL8LVT FILL16LVT FILL32LVT FILL64LVT}

set design(always_on_pins_tvdd) {PTINVD1HVT PTINVD2HVT PTINVD4HVT PTINVD8HVT PTINVD8HVT PTINVD4HVT PTINVD2HVT PTINVD1HVT PTINVD8HVT PTINVD4HVT PTINVD2HVT PTINVD1HVT PTBUFFD1HVT PTBUFFD2HVT PTBUFFD4HVT PTBUFFD8HVT PTBUFFD8HVT PTBUFFD4HVT PTBUFFD2HVT PTBUFFD1HVT PTBUFFD8HVT PTBUFFD4HVT PTBUFFD2HVT PTBUFFD1HVT}
set design(always_on_pins_tvss) { PTFBUFFD1HVT  PTFBUFFD2HVT  PTFBUFFD4HVT  PTFBUFFD8HVT  PTFDFCND1HVT  PTFINVD1HVT  PTFINVD2HVT  PTFINVD4HVT  PTFINVD8HVT  PTFINVD8HVT  PTFINVD4HVT  PTFINVD2HVT  PTFINVD1HVT  PTFDFCND1HVT  PTFBUFFD8HVT  PTFBUFFD4HVT  PTFBUFFD2HVT PTFBUFFD1HVT PTFINVD8HVT PTFINVD4HVT PTFINVD2HVT  PTFINVD1HVT PTFDFCND1HVT PTFBUFFD8HVT PTFBUFFD4HVT PTFBUFFD2HVT PTFBUFFD1HVT}
set design(always_on_pins) {}
foreach cell $design(always_on_pins_tvdd) {lappend design(always_on_pins) ${cell}:TVDD}
foreach cell $design(always_on_pins_tvss) {lappend design(always_on_pins) ${cell}:TVSS}

set design(lvs_excludes) $design(fillers)
lappend design(lvs_excludes) {*}{PFILLER05 PFILLER1 PFILLER5 PFILLER10 PFILLER20 PCORNER PRCUT UCSRN UCSRN_NOVIA01 UCSRN_NOVIA001 CORNER_B N65CHIPCDU2_New PAD60L RNPOLYWO RPPOLYWO heep_cover}

# Technology lefs (non lo abbiamo)
# lappend design(ALL_LEFS) {/software/dk/tsmc/65nm/IP_65nm/utilities/PRTF_EDI_65nm_001_Cad_V24a/PR_tech/Cadence/LefHeader/HVH/PRTF_EDI_N65_9M_6X1Z1U_RDL.24a.tlef}

# Standard cells (controllare i path)
lappend design(ALL_LEFS) /software/dk/tsmc65/digital/Back_End/lef/tcbn65lplvt_200a/lef/tcbn65lplvt_9lmT2.lef
lappend design(ALL_LEFS) /software/dk/tsmc65/digital/Back_End/lef/tcbn65lphvt_200a/lef/tcbn65lphvt_9lmT2.lef
lappend design(ALL_LEFS) /software/dk/tsmc65/digital/Back_End/lef/tcbn65lpcghvt_200a/lef/tcbn65lpcghvt_9lmT2.lef

lappend design(ALL_GDS) /software/dk/tsmc65/digital/Back_End/gds/tcbn65lplvt_200a/tcbn65lplvt.gds
lappend design(ALL_GDS) /software/dk/tsmc65/digital/Back_End/gds/tcbn65lphvt_200a/tcbn65lphvt.gds
lappend design(ALL_GDS) /software/dk/tsmc65/digital/Back_End/gds/tcbn65lpcghvt_200a/tcbn65lpcghvt.gds

# IOs (non li usi, te li lascio nel caso in cui Innovus te li chieda esplicitamente, ma controlla i path)
# lappend design(ALL_LEFS) /software/dk/tsmc65/digital/Back_End/lef/tpan65lpnv2od3_200a/mt_2/9lm/lef/tpan65lpnv2od3_9lm.lef
# lappend design(ALL_LEFS) /software/dk/tsmc65/digital/Back_End/lef/tpan65lpnv2od3_200a/mt_2/9lm/lef/antenna_9lm.lef
# lappend design(ALL_GDS)  /software/dk/tsmc65/digital/Back_End/gds/tpan65lpnv2od3_200a/mt_2/9lm/tpan65lpnv2od3.gds
# lappend design(ALL_GDS)  /software/dk/tsmc65/digital/Back_End/gds/tpdn65lpnv2od3_140b/mt_2/9lm/tpdn65lpnv2od3.gds
# lappend design(ALL_LEFS) /software/dk/tsmc65/digital/Back_End/lef/tpdn65lpnv2od3_140b/mt_2/9lm/lef/antenna_9lm.lef

source scripts/helper_functions.tcl

set ::env(CALIBRE_HOME) /eda/mentor/2020-21/RHELx86/CALIBRE_2020.4.15.9/
set ::env(MGC_CALIBRE_INNOVUS_CUI_MODE) "1298096"

source $::env(CALIBRE_HOME)/aoi_cal_2020.4_15.9/lib/cal_enc.tcl
