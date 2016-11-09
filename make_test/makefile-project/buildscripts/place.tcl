opt_design
power_opt_design
place_design
phys_opt_design

write_checkpoint $env(DCP) -force
report_utilization -file $env(UTIL_RPT) -hierarchical
report_timing -sort_by group -max_paths 5 -path_type summary -file $env(TIMING_RPT)
report_timing_summary -file $env(TIMING_SUMMARY)
report_clock_utilization -file $env(CLOCK_UTIL_RPT)
