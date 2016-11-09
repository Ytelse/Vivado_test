open_hw
connect_hw_server -host localhost -port 60001 -url localhost:3121
current_hw_target [get_hw_targets */xilinx_tcf/Digilent/210203339395A
set_property PARAM.FREQUENCY 15000000 [get_hw_targets */xilinx_tcf/Digilen/210203339395A]
open_hw_target
set_property PROGRAM.FILE {../Exercise-1-Top.bit} [lindex[get_hw_devices] 0]
set msg "Upload is run now!"
