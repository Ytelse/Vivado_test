#!/usr/bin/env python3

import argparse
import io
import serial

class StateUpdate(object):
    def __init__(self, is_dmem, addr, val):
        self.is_dmem = is_dmem
        self.addr = addr
        self.val = val

    def __str__(self):
        upd_kind = "data memory" if self.is_dmem else "register"
        address = ("0x{:03X}" if self.is_dmem else "{:02d}").format(self.addr)
        return upd_kind + " " + address + " value " + "0x{:08X}".format(self.val)

class HostcommProxy(object):
    def __init__(self, port):
        self._serial = serial.Serial()
        self._serial.port = port
        self._serial.baudrate = 115200
        self._serial.timeout = 500

    def __enter__(self):
        self._serial.open()
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self._serial.close()

    def _writeCommand(self, command):
        print("Writing command", command, end="")
        self._serial.write(command.encode('ASCII'))

    def _writeByte(self, addr, val):
        cmd = "w {:02X} {:04X}\n".format(val, addr)
        self._writeCommand(cmd)

    def _writeBytes(self, addr, val, num_bytes):
        for i in range(num_bytes):
            self._writeByte(addr+i, (val >> (8*i)) & 0xFF)

    def _readByte(self, addr):
        cmd = "r {:04X}\n".format(addr)
        self._writeCommand(cmd)
        data = self._serial.read(4)
        while len(data) < 4:
            data.append(self._serial.read(4 - len(data)))
        return int(data, 16)

    def start_processor(self):
        self._writeByte(addr=0, val=1)

    def stop_processor(self):
        self._writeByte(addr=0, val=0)

    def reset_processor(self):
        self._writeByte(addr=1, val=1)
        self._writeByte(addr=1, val=0)

    def init_imem(self, imem_init_file):
        self._init_mem(imem_init_file, 0xC000)

    def _init_mem(self, init_mem_file, baseaddr):
        for dest in init_mem_file:
            offset, val = dest.split()
            offset = int(offset, base=0)
            val = int(val, base=0)
            self._writeByte(addr=baseaddr + offset, val=val)

    def init_dmem(self, dmem_init_file):
        self._init_mem(dmem_init_file, 0x8000)

    def init_regfile(self, regfile_init_file):
        self._init_mem(regfile_init_file, 0x3000)

    def init_expected_updates(self, expected_updates_init_file):
        self._init_mem(expected_updates_init_file, 0x2000)

    def init_test_config(self, test_config_file):
        test_config = self._parse_test_config(test_config_file)
        self._writeBytes(addr=5, val=test_config.num_exp_updates, num_bytes=2)
        self._writeBytes(addr=7, val=test_config.timeout, num_bytes=2)

    def _parse_test_config(self, test_config_file):
        class TestConfig(object):
            def __init__(self, num_exp_updates, timeout):
                self.num_exp_updates = num_exp_updates
                self.timeout = timeout

        num_exp_updates, timeout = None, None
        for line in test_config_file:
            name, val = line.split(" = ")
            if name == "num_expected_updates":
                num_exp_updates = int(val, base=0)
            elif name == "timeout":
                timeout = int(val, base=0)
            else:
                print("Malformed test config file", test_config_file,
                        ": no field named", name, file=sys.stderr)

        if num_exp_updates == None:
            print("Malformed test config file: missing num_expected_updates",
                  file=sys.stderr)
        elif timeout == None:
            print("Malformed test config file: missing timeout",
                  file=sys.stderr)

        return TestConfig(num_exp_updates, timeout)

    def first_nonzero_testcode(self):
        testcode = self._readByte(addr=2)
        while testcode == 0:
            testcode = self._readByte(addr=2)
        return testcode

    def read_cycle_count(self):
        cycles_lo = self._readByte(addr=3)
        cycles_hi = self._readByte(addr=4)
        return cycles_lo + (cycles_hi << 8)

    def read_update_pair(self):
        exp_type = self._readByte(addr=0x9)
        exp_addr_lo = self._readByte(addr=0xA)
        exp_addr_hi = self._readByte(addr=0xB)
        exp_val0 = self._readByte(addr=0xC)
        exp_val1 = self._readByte(addr=0xD)
        exp_val2 = self._readByte(addr=0xE)
        exp_val3 = self._readByte(addr=0xF)

        actual_type = self._readByte(addr=0x10)
        actual_addr_lo = self._readByte(addr=0x11)
        actual_addr_hi = self._readByte(addr=0x12)
        actual_val0 = self._readByte(addr=0x13)
        actual_val1 = self._readByte(addr=0x14)
        actual_val2 = self._readByte(addr=0x15)
        actual_val3 = self._readByte(addr=0x16)

        return StateUpdate(
            exp_type, exp_addr_lo + (exp_addr_hi << 8),
            exp_val0 + (exp_val1 << 8) +
            (exp_val2 << 16) + (exp_val3 << 24)),\
            StateUpdate(actual_type, actual_addr_lo + (actual_addr_hi << 8),
                        actual_val0 + (actual_val1 << 8) +
                        (actual_val2 << 16) + (actual_val3 << 24))

    def close(self):
        self._serial.close()

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--expected-updates-file", type=argparse.FileType('r'),
                        required=True)
    parser.add_argument("--imem-init-file", type=argparse.FileType('r'),
                        required=True)
    parser.add_argument("--dmem-init-file", type=argparse.FileType('r'),
                        required=True)
    parser.add_argument("--regfile-init-file", type=argparse.FileType('r'),
                        required=True)
    parser.add_argument("--test-config-file", type=argparse.FileType('r'),
                        required=True)
    args = parser.parse_args()

    with HostcommProxy("/dev/fpga_uart") as hostcomm:
        hostcomm.stop_processor()
        hostcomm.reset_processor()
        hostcomm.init_imem(args.imem_init_file)
        hostcomm.init_dmem(args.dmem_init_file)
        hostcomm.init_regfile(args.regfile_init_file)
        hostcomm.init_expected_updates(args.expected_updates_file)
        hostcomm.init_test_config(args.test_config_file)

        hostcomm.start_processor()

        test_code = hostcomm.first_nonzero_testcode()
        cycles = hostcomm.read_cycle_count()
        if test_code == 1:
            msg = "Test success"
        elif test_code == 2:
            msg = "Test timeout"
        elif test_code == 3:
            msg = "Update while disabled"
            _, actual = hostcomm.read_update_pair()
            msg += " (erroneous update: " + str(actual) + ")"
        elif test_code == 4:
            msg = "More updates than expected"
            _, actual = hostcomm.read_update_pair()
            msg += " (erroneous update: " + str(actual) + ")"
        elif test_code == 5:
            msg = "Incorrect update: "
            expected, actual = hostcomm.read_update_pair()
            msg += "expected update to " + str(expected) + " but got "  + str(actual)
        else:
            print("Unknown test code:", test_code)

        print("In cycle {}: {}.".format(cycles, msg))
        hostcomm.stop_processor()

if __name__ == '__main__':
   main()
