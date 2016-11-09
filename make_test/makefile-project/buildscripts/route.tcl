route_design

write_checkpoint $env(DCP) -force
report_utilization -file $env(UTIL_RPT) -hierarchical
report_timing_summary -file $env(TIMING_SUMMARY)
report_timing -sort_by group -max_paths 5 -path_type summary -file $env(TIMING_RPT)
report_power -file $env(POWER_RPT)

## potential other reports:
# create_slack_histogram: groups paths into bins based on slack.
# report_design_analysis: provides timing data and design complexity problems.
# report_methodology: runs checks against two default rule sets.
# report_exceptions: report timing exceptions.
