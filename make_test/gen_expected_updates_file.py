#!/usr/bin/env python3

import argparse
import math
import re
import sys

from init_state_util import *

class ExpectedUpdate(object):
    def __init__(self, is_dest_dmem, addr, value, dmem_depth):
        assert_in_range("Address", addr, 0, dmem_depth-1)
        assert_in_range("Value", value, -(2**31), 2**32 - 1)
        self.is_dest_dmem = is_dest_dmem
        self.addr = addr
        self.value = value
        self.dmem_addr_width = int(math.ceil(math.log2(dmem_depth)))

    reg_update_line = re.compile(reg_update_regex_str())
    dmem_update_line = re.compile(dmem_update_regex_str())

    @staticmethod
    def from_line(line, dmem_depth):
        try:
            match = ExpectedUpdate.dmem_update_line.match(line)
            is_dest_dmem = bool(match)
            match = match if is_dest_dmem else \
                    ExpectedUpdate.reg_update_line.match(line)
            return ExpectedUpdate(is_dest_dmem,
                                  int(match.group(1), 0),
                                  int(match.group(2), 0),
                                  dmem_depth)
        except Exception as ex:
            print("[WARNING]: line parse exception {}".format(ex))
            return None

    def __str__(self):
        # Line format:
        # <is_dest_dmem_bit>' '<10-bit binary address>' '<32-bit hex value>
        return "{} {} {}".format(
            '1' if self.is_dest_dmem else '0',
            fixed_width_bin(self.addr, self.dmem_addr_width),
            fixed_width_hex(self.value, 32))

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("exp_updates_file")
    parser.add_argument("dmem_depth", type=int)
    args = parser.parse_args()
    with open(args.exp_updates_file, "w") as exp_updates_file:
        for line in sys.stdin:
            line = line.strip()
            if line:
                exp_update = ExpectedUpdate.from_line(line, args.dmem_depth)
                if not exp_update:
                    print("[WARNING]: Unrecognized expected state update " +
                          "line '{}'".format(line))
                else:
                    print(exp_update, file=exp_updates_file)

if __name__ == '__main__':
   main()
