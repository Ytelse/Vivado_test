#!/bin/bash

workdir=sim-tests/vivado-workdir

mkdir -p ${workdir}
## Always regenerate the project file, in case new source files have been added.
./gen_prj.sh > sim-tests/vivado-workdir/sim-prj.prj;

## Always copy the test-resources folder, if it exists, before running; its
## content may be modified. If it does not exist and there is no tests directory
## in the simulation working directory, issue an error message and abort.
if [ ! -d sim-tests/test-resources ]; then
    if [ ! -d ${workdir}/tests ]; then
        echo "Error: directory ./sim-tests/test-resources does not exist" >&2
        echo "Run ./init_tests.sh to generate it." >&2
        exit 1
    fi
else
    rsync -a sim-tests/test-resources/tests/ ${workdir}/tests/
fi

