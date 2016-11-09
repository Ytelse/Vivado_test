#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <WDB file>" >&2
    exit 1
fi

wdb_file="$1"
xsim -gui "${wdb_file}"
