#!/bin/bash
function normalize() {
    echo -n "$1" | tr --complement 'a-zA-Z0-9_' '_'
}

function get_tb_cfg_name() {
    echo -n $(normalize "${1%%.test}")
}

if [ $# -ne 1 ]; then
    echo "Usage: $0 <test file>" >&2
    exit 1
fi

./setup_sim_workdir.sh || exit 1

echo "Running simulations in ./sim-tests/vivado-workdir"
echo "(all file references will be relative to this location)"
echo

cd sim-tests/vivado-workdir &&
    ../scripts/run_single_test.sh ./sim-prj.prj $(get_tb_cfg_name "$1")

