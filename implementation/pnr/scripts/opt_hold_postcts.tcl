push_snapshot_stack

opt_design -hold -post_cts

pop_snapshot_stack

create_snapshot -name cts_opt -categories "design setup hold route power"
report_metric -format vivid -file artefacts/metrics/3_post_cts_opt.html
write_metric -format json -file artefacts/metrics/3_post_cts_opt.json
write_db artefacts/db/post_cts_opt.db
write_stream -map_file $design(map_file) artefacts/export/post_cts_opt.gds
