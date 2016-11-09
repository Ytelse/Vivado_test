#!/bin/bash

topdir=$(dirname $(readlink -f "$0"))
(find -L "${topdir}/framework" "${topdir}/src" "${topdir}/sim-tests/tb_cfgs" -name '*.vhd' | xargs -n1 -I{} echo "vhdl work" {})
