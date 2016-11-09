#!/bin/bash

mkdir -p sim-tests/test-resources &&
    ./process_tests.py --action gen_tests $@ &&
    echo "Setting up test environment in sim-tests/vivado-workdir" &&
    ./setup_sim_workdir.sh &&
    echo "Good to go!"
