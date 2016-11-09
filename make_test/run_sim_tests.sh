#!/bin/bash
function normalize() {
    echo -n "$1" | tr --complement 'a-zA-Z0-9_' '_'
}

./setup_sim_workdir.sh || exit 1
echo "Running simulations in ./sim-tests/vivado-workdir"
echo "(all file references will be relative to this location)"
echo

./process_tests.py --action run_sim_tests $@
