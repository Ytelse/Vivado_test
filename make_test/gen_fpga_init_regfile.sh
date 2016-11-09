#!/bin/bash

# For each byte in regfile value, print it w/ byte address.
awk '{ for (i = 0; i < 4; i++) {
             print (4*$1 + i) " " and(rshift(strtonum("0x"$2), 8*(3-i)), 0xFF);
    }}'
