#!/usr/bin/env python

import sys

def main():
    offset = 0
    for line in sys.stdin:
        is_dmem_bit, bin_addr, hex_val = line.split()
        expupd_val = (int(is_dmem_bit, base=2) << 42) + \
                     (int(bin_addr, base=2) << 32) + \
                     int(hex_val, base=16)
        for i in range(6):
            print("{} 0x{:02X}".format(offset + i, (expupd_val >> 8*(5-i)) & 0xFF))
        offset += 8

if __name__ == '__main__':
    main()
