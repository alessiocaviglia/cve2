# Power mesh (forse devi adattare)
set_db add_stripes_skip_via_on_wire_shape {  noshape   }
deselect_obj -all
add_stripes -nets {VDD VSS} -layer M4 -direction vertical -width 2 -spacing 5 -set_to_set_distance 45 -start_from left -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit M9 -pad_core_ring_bottom_layer_limit M2 -block_ring_top_layer_limit M9 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid none
set_db add_stripes_skip_via_on_wire_shape {  followpin  noshape   }
add_stripes -nets {VDD VSS} -layer M5 -direction horizontal -width 2 -spacing 5 -set_to_set_distance 50 -start_from top -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit M9 -pad_core_ring_bottom_layer_limit M2 -block_ring_top_layer_limit M9 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid none
add_stripes -nets {VSS VDD} -layer M6 -direction vertical -width 6 -spacing 5 -set_to_set_distance 100 -start_from left -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit M9 -pad_core_ring_bottom_layer_limit M2 -block_ring_top_layer_limit M9 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid none

set_db add_stripes_ignore_block_check false ; set_db add_stripes_break_at none ; set_db add_stripes_route_over_rows_only false ; set_db add_stripes_rows_without_stripes_only false ; set_db add_stripes_extend_to_closest_target none ; set_db add_stripes_stop_at_last_wire_for_area false ; set_db add_stripes_partial_set_through_domain false ; set_db add_stripes_ignore_non_default_domains true ; set_db add_stripes_trim_antenna_back_to_shape none ; set_db add_stripes_spacing_type edge_to_edge ; set_db add_stripes_spacing_from_block 0 ; set_db add_stripes_stripe_min_length stripe_width ; set_db add_stripes_stacked_via_top_layer AP ; set_db add_stripes_stacked_via_bottom_layer M1 ; set_db add_stripes_via_using_exact_crossover_size false ; set_db add_stripes_split_vias false ; set_db add_stripes_orthogonal_only true ; set_db add_stripes_allow_jog { padcore_ring  block_ring } ; set_db add_stripes_skip_via_on_pin {  standardcell } ; set_db add_stripes_skip_via_on_wire_shape {  followpin  noshape   }

add_stripes -nets {VDD VSS} -layer M7 -direction horizontal -width 6 -spacing 5 -set_to_set_distance 100 -start_from bottom -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit M9 -pad_core_ring_bottom_layer_limit M2 -block_ring_top_layer_limit M9 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid none
add_stripes -nets {VSS VDD} -layer M8 -direction vertical -width 12 -spacing 5 -set_to_set_distance 200 -start_from left -start_offset 25 -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit M9 -pad_core_ring_bottom_layer_limit M1 -block_ring_top_layer_limit M9 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid none
add_stripes -nets {VSS VDD} -layer M9 -direction horizontal -width 12 -spacing 5 -set_to_set_distance 200 -start_from bottom -start_offset 25 -switch_layer_over_obs false -max_same_layer_jog_length 2 -pad_core_ring_top_layer_limit M9 -pad_core_ring_bottom_layer_limit M1 -block_ring_top_layer_limit M9 -block_ring_bottom_layer_limit M1 -use_wire_group 0 -snap_wire_center_to_grid none

deselect_obj -all
select_routes -shapes {blockring  blockwire  corewire  drcfill  fillwire  fillwireopc  followpin  iowire  none  stripe}
edit_trim_routes -selected
deselect_obj -all
