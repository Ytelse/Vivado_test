#!/bin/bash

# Get 36 bits of IMEM init data per line.
fold -w9 -b |
    # Remove first nibble from 36-bit imem width in FPGA simulation init.
    cut -c2- |
    # # First step big-endian => little-endian: reverse each line |
    # rev |
    # # Second step: split at each byte, two hex chars.
    fold -w2 -b |
    # # Final step: reverse the nibble-chars in each byte.
    # rev |
    # Add 0x prefix.
    awk '{print "0x"$1}' |
    # Add address offsets to bytes.
    nl -v0  -nln
