#!/bin/bash

# Remove initial @ for both address and extra nibble in 36-bit dmem line.
cut -b2- |
    # Merge address and value line to let awk operate on both
    xargs -n2 |
    # For each byte in dmem value, print it w/ byte address.
    awk '{ for (i = 0; i < 4; i++) {
             print (4*strtonum("0x"$1) + i) \
                " " and(rshift(strtonum("0x"$2), 8*(3-i)), 0xFF);
    }}'
