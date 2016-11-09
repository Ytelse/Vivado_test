#!/bin/bash

if [ -z "$1" ]; then
    echo "Usage: $0 <test name>" >&2
    exit 1
fi

function normalize() {
    echo -n "$1" | tr --complement 'a-zA-Z0-9_' '_'
}

pushd sim-tests/vivado-workdir
test_name=$(normalize "$(basename $1 .test)")
test_folder="$(dirname $1)"/"${test_name}"
wdb_file="${test_folder}/waveform.wdb"

xsim -gui "${wdb_file}"

popd
