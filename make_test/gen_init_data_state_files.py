#!/usr/bin/env python3

import argparse
import re
import sys

from init_state_util import *

class State(object):
    def __init__(self, regex_str):
        self.line_regex = re.compile(regex_str)

    def try_add(self, line):
        match = self.line_regex.match(line)
        if match:
            try:
                self.add_match(match)
                return True
            except Exception as ex:
                print("[WARNING]: line parse exception {}".format(ex))
        return False

class RegisterState(State):
    def __init__(self):
        super(RegisterState, self).__init__(reg_update_regex_str())
        self.init_regvals = {}

    def add_match(self, match):
        self.add_init_value(int(match.group(1), 0), int(match.group(2), 0))

    def add_init_value(self, regnum, value):
        assert_in_range("Register number", regnum, 1, 31)
        assert_in_range("Register value", value, -(2**31), 2**32 - 1)
        self.init_regvals[regnum] = value

    def __str__(self):
        # Print one register initial value per line.
        # Line format:
        #   <reg num, integer><single space><initial value, 32 bit in hex>
        return "\n".join(
            [str(reg) + " " + fixed_width_hex(value, 32)
             for reg, value in sorted(self.init_regvals.items())])

class DmemState(State):
    def __init__(self, depth):
        super(DmemState, self).__init__(dmem_update_regex_str())
        self.init_dmem = {}
        self.depth = depth

    def add_match(self, match):
        self.add_init_word(int(match.group(1), 0), int(match.group(2), 0))

    def add_init_word(self, word_address, word):
        assert 0 <= word_address < self.depth, \
            "Words address {} exceeds data memory depth {}".\
            format(word_address, self.depth)
        assert_in_range("Data memory word", word, -(2**31), 2**32)
        self.init_dmem[word_address] = word

    def __str__(self):
        # Output initial values in ascending address range.
        # Two lines per initial value. Line format:
        #   '@'<address, 32-bit hex> 
        #   <value, 36-bit hex>
        return "\n".join([
            '@' + fixed_width_hex(addr, 32) + "\n" +
            fixed_width_hex(value, 36)
            for addr, value in sorted(self.init_dmem.items())
        ])

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("regs_init_file")
    parser.add_argument("dmem_init_file")
    parser.add_argument("dmem_depth", type=int)
    args = parser.parse_args()
    with open(args.regs_init_file, "w") as regs_init_file:
        with open(args.dmem_init_file, "w") as dmem_init_file:
            regfile_state = RegisterState()
            dmem_state = DmemState(args.dmem_depth)
            for line in sys.stdin:
                line = line.strip()
                if line:
                    if not regfile_state.try_add(line) and not dmem_state.try_add(line):
                        print("[WARNING]: unrecognized initial state line '{}'".
                              format(line), file=sys.stderr)
            print(regfile_state, file=regs_init_file)
            print(dmem_state, file=dmem_init_file)

if __name__ == '__main__':
   main()
