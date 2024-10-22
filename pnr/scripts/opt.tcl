push_snapshot_stack

set_db timing_analysis_aocv true

opt_design -setup -post_route
opt_design -hold -post_route
opt_design -drv -post_route

pop_snapshot_stack
create_snapshot -name opt_route -categories "design setup hold route power"
report_metric -format vivid -file artefacts/metrics/5_post_opt_route.html
write_metric -format json -file artefacts/metrics/5_post_opt_route.json
write_db artefacts/db/post_opt_route.db
write_stream -map_file $design(map_file) artefacts/export/post_opt.gds
