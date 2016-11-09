# 
# Synthesis run script generated by Vivado
# 

set_msg_config -id {HDL 9-1061} -limit 100000
set_msg_config -id {HDL 9-1654} -limit 100000
set_msg_config -id {Synth 8-256} -limit 10000
set_msg_config -id {Synth 8-638} -limit 10000
create_project -in_memory -part xc7a35tftg256-2

set_param project.singleFileAddWarning.threshold 0
set_param project.compositeFile.enableAutoGeneration 0
set_param synth.vivado.isSynthRun true
set_property webtalk.parent_dir /home/shomeb/u/ulrichji/Documents/dmpro/test_ebi/test_ebi.cache/wt [current_project]
set_property parent.project_path /home/shomeb/u/ulrichji/Documents/dmpro/test_ebi/test_ebi.xpr [current_project]
set_property default_lib xil_defaultlib [current_project]
set_property target_language VHDL [current_project]
read_vhdl -library xil_defaultlib /home/shomeb/u/ulrichji/Documents/dmpro/test_ebi/test_ebi.srcs/sources_1/new/Generator.vhd
foreach dcp [get_files -quiet -all *.dcp] {
  set_property used_in_implementation false $dcp
}
read_xdc /home/shomeb/u/ulrichji/Documents/dmpro/test_ebi/test_ebi.srcs/constrs_1/new/constraints.xdc
set_property used_in_implementation false [get_files /home/shomeb/u/ulrichji/Documents/dmpro/test_ebi/test_ebi.srcs/constrs_1/new/constraints.xdc]


synth_design -top Generator -part xc7a35tftg256-2


write_checkpoint -force -noxdef Generator.dcp

catch { report_utilization -file Generator_utilization_synth.rpt -pb Generator_utilization_synth.pb }