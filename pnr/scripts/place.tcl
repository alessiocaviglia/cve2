push_snapshot_stack

place_opt_design

pop_snapshot_stack
create_snapshot -name place -categories "design setup power"
report_metric -format vivid -file artefacts/metrics/1_post_place.html
write_metric -format json -file artefacts/metrics/1_post_place.json
write_db artefacts/db/post_place
write_stream -map_file $design(map_file) artefacts/export/post_place.gds
