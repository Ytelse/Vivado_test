#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <project file> <tb configuration name>" >&2
    exit 1
fi

# tb_cfgs=$(ls *.vhd | xargs -n1 -I{} echo work.$(basename {} .vhd) | tr '\n' ' ')
tb_cfg="$1"

# echo xelab ${tb_cfgs} -prj $1
xelab -debug typical $2 -prj $1
