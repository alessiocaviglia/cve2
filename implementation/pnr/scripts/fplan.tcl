# Chip space (stringi una volta che sai quanto occupa)
create_floorplan -box_size {0 0 3000 2000 200 200 2800 1800 250 250 2750 1750}

# Power rings
add_rings -nets {VDD VSS} -type core_rings -follow core -layer {top M3 bottom M3 left M4 right M4} -width {top 10 bottom 10 left 10 right 10} -spacing {top 5 bottom 5 left 5 right 5} -offset {top 3.5 bottom 3.5 left 3.5 right 3.5} -center 0 -threshold 0 -jog_distance 0 -snap_wire_center_to_grid none

# route follow pins
# VSS
route_special -connect {core_pin} -layer_change_range { M1(1) M9(9) } -core_pin_target {first_after_row_end} -allow_jogging 1 -crossover_via_layer_range { M1(1) M9(9) } -nets { VSS } -allow_layer_change 1 -target_via_layer_range { M1(1) M9(9) }

#VDD
route_special -connect {core_pin} -layer_change_range { M1(1) M9(9) } -core_pin_target {first_after_row_end} -allow_jogging 1 -crossover_via_layer_range { M1(1) M9(9) } -nets { VDD } -allow_layer_change 1 -target_via_layer_range { M1(1) M9(9) }

source scripts/fplan_mesh.tcl

write_netlist -exclude_leaf_cells -include_pg_ports artefacts/export/${design(TOPLEVEL)}_floorplan.v

write_db artefacts/db/heepocrates_floorplan.db

# Open GUI
gui_show
