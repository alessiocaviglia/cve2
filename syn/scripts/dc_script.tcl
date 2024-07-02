
set SET_LIBS ${SCRIPT_DIR}/set_libs.tcl
set CONSTRAINTS ${SCRIPT_DIR}/set_constraints.tcl

remove_design -all

source ${SET_LIBS}

source ${READ_SOURCES}.tcl

elaborate ${TOP_MODULE}
link

write -f ddc -hierarchy -output ${REPORT_DIR}/precompiled.ddc

source ${CONSTRAINTS}

report_clocks > ${REPORT_DIR}/clocks.rpt
report_timing -loop -max_paths 10 > ${REPORT_DIR}/timing_loop.rpt

# compile_ultra -no_autoungroup -no_boundary_optimization -timing -gate_clock
# compile_ultra
compile

write -f ddc -hierarchy -output ${REPORT_DIR}/compiled.ddc

report_area -hier -nosplit > ${REPORT_DIR}/area.rpt

ungroup -all -flatten

change_names -rules verilog -hier

write -format verilog -hier -o netlist.v

report_timing -nosplit > ${REPORT_DIR}/timing.rpt
report_resources -hierarchy > ${REPORT_DIR}/resources.rpt
report_power > ${REPORT_DIR}/power.rpt
