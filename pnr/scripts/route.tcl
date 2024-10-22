push_snapshot_stack

set_pg_pins_use_signal_route $design(always_on_pins)
route_secondary_pg_pins

route_design

pop_snapshot_stack
create_snapshot -name route -categories "design setup hold route power"
report_metric -format vivid -file artefacts/metrics/4_post_route.html
write_metric -format json -file artefacts/metrics/4_post_route.json
write_db artefacts/db/post_route.db
write_stream -map_file $design(map_file) artefacts/export/post_route.gds
