#!/bin/bash -f
xv_path="/opt/Xilinx/Vivado/2016.2"
ExecStep()
{
"$@"
RETVAL=$?
if [ $RETVAL -ne 0 ]
then
exit $RETVAL
fi
}
ExecStep $xv_path/bin/xelab -wto 76d9513d609f4dc6b4fb6cdd06397eab -m64 --debug typical --relax --mt 8 -L xil_defaultlib -L secureip --snapshot Generator_behav xil_defaultlib.Generator -log elaborate.log
