#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <top-level project directory>" >&2
    exit 1
fi

topdir=$1
(find -L "${topdir}/framework" "${topdir}/src" "${topdir}/tests" -name '*.vhd' | xargs -n1 -I{} echo "vhdl work" {})
