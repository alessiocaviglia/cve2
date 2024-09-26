delete_empty_hinsts
update_names -nocase
# add filler cells
add_fillers -base_cells $design(fillers)

create_snapshot -name final -categories "design setup hold route power"
report_metric -format vivid -file artefacts/metrics/6_final.html
write_metric -format json -file artefacts/metrics/6_final.json

# write db
write_db artefacts/db/${design(TOPLEVEL)}

#write stream
write_stream -merge ${design(ALL_GDS)} -map_file $design(map_file) -die_area_as_boundary -unit 1000 artefacts/export/${design(TOPLEVEL)}.gds.gz
file copy -force artefacts/export/${design(TOPLEVEL)}.gds.gz ../../implementation/lvs/${design(TOPLEVEL)}.gds.gz

#write netlist for LVS
write_netlist -exclude_leaf_cells -exclude_insts_of_cells $design(lvs_excludes) -phys artefacts/export/${design(TOPLEVEL)}_lvs.v
write_netlist -exclude_leaf_cells -exclude_insts_of_cells $design(lvs_excludes) -phys ../../implementation/lvs/netlist_lvs.v

#write stub netlist for LVS
write_netlist -phys -exclude_insts_of_cells $design(lvs_excludes) artefacts/export/${design(TOPLEVEL)}_lvs_stubs.v
write_netlist -phys -exclude_insts_of_cells $design(lvs_excludes) ../../implementation/lvs/netlist_lvs_stubs.v

#write netlist for postlayout
write_netlist -exclude_leaf_cells -include_pg_ports artefacts/export/${design(TOPLEVEL)}_pg.v
write_netlist -exclude_leaf_cells -include_pg_ports ../innovus_latest/artefacts/export/${design(TOPLEVEL)}_pg.v

set sdf_min_view [lind $hold_views 0]
set sdf_typ_view [lind $setup_views 0]
set sdf_max_view [lind $setup_views 1]

set_db timing_enable_simultaneous_setup_hold_mode true
set_db timing_recompute_sdf_in_setuphold_mode true

write_sdf artefacts/export/${design(TOPLEVEL)}.sdf.gz -precision 4 -min_period_edges posedge -recompute_parallel_arcs -adjust_setup_hold_for_zero_hold_slack -min_view $sdf_min_view -typical_view $sdf_typ_view -max_view $sdf_max_view

# write reports for post-pnr analysis
rm -rf $design(FLOW_ROOT)/implementation/pnr/last_output
mkdir $design(FLOW_ROOT)/implementation/pnr/last_output

write_netlist $design(FLOW_ROOT)/implementation/pnr/last_output/netlist.v
write_sdc $design(FLOW_ROOT)/implementation/pnr/last_output/netlist.sdc
write_sdf $design(FLOW_ROOT)/implementation/pnr/last_output/netlist.sdf -precision 4 -min_period_edges posedge -recompute_parallel_arcs -adjust_setup_hold_for_zero_hold_slack -min_view $sdf_min_view -typical_view $sdf_typ_view -max_view $sdf_max_view

extract_rc
foreach corner {corner_rcworst corner_rcbest} {
   write_parasitics -spef_file $design(FLOW_ROOT)/implementation/pnr/last_output/HEEPerator_${corner}.spef -rc_corner $corner
}

check_connectivity -ignore_dangling_wires -out_file $design(FLOW_ROOT)/implementation/pnr/last_output/signoff_step_connectivity.rpt
