push_snapshot_stack

ccopt_design

pop_snapshot_stack
create_snapshot -name cts -categories "design setup hold power"
report_metric -format vivid -file artefacts/metrics/2_post_cts.html
write_metric -format json -file artefacts/metrics/2_post_cts.json
write_db artefacts/db/post_cts
write_stream -map_file $design(map_file) artefacts/export/post_cts.gds
