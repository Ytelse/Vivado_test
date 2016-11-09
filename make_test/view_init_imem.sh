#!/bin/bash

if [ $# -ne 1 -a $# -ne 2 ]; then
    echo "Usage: $0 <imem initialization file> [--use-byte-addresses=FALSE]">&2
    exit 1
fi

case "$2" in
    --use-byte-addresses)
        increment=4
        ;;
    *)
        increment=1
esac

# Wrap at nine characters, cut away the first in each line, add line numbers
# from 0 as instruction addresses, or optionally as byte addresses
fold -b -w9 "$1" | cut -c2- | nl -v 0 -i ${increment}
