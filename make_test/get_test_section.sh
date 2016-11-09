#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <test file> <section name>" >&2
    exit 1
fi

test_file="$1"
section_name="$2"
awk "/----------/ { active=0; } /.+/ { if (active==1) print \$0 } /${section_name}/ { active=1; }" \
    < "${test_file}"
