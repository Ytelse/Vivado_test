#!/usr/bin/env python3

from __future__ import print_function

import argparse
import itertools
import os
import time
import subprocess
import sys

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
        import serial
        self._serial = serial.Serial()
        self._serial.port = port
        self._serial.baudrate = 115200
        self._serial.dsrdtr = True

    def __enter__(self):
        self._serial.open()
        # When the connection is opened to the FTDI USB-to-serial driver, if
        # there are no other active connections the FTDI driver drives the
        # serial DTR signal low for a duration. If the jumper JP2 is set on the
        # Arty board, this DTR line is connect to the active-low red reset
        # button, which we also use as the reset button for our designs.
        # Therefore, we must wait for this reset signal to subside before we
        # try to communicate with the FPGA (since the reset signal will knock
        # out the uart module on the FPGA). Experiments conducted with the
        # measure_reset_duration.py script put the reset duration at
        # approximately 0.4 ms. We therefore sleep for 2 ms (5X) to ensure that
        # reset will not be active when we start our communication.
        time.sleep(0.002) # Sleep 2 ms to let reset become inactive.
        return self

    def __exit__(self, exc_type, exc_value, traceback):
        self._serial.close()

    def _writeCommand(self, command):
        # print("Writing command", command, end="")
        self._serial.write(command.encode('ASCII'))

    def _writeByte(self, addr, val):
        cmd = "w {:02X} {:04X}\n".format(val, addr)
        self._writeCommand(cmd)

    def _writeBytesBigEndian(self, addr, val, num_bytes):
        for i in range(num_bytes):
            self._writeByte(addr+i, (val >> (8*(num_bytes-1-i))) & 0xFF)

    def _writeBytes(self, addr, val, num_bytes):
        self._writeBytesBigEndian(addr, val, num_bytes)

    def _readByte(self, addr):
        cmd = "r {:04X}\n".format(addr)
        self._writeCommand(cmd)
        return int(self._serial.read(4), 16)

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
        cycles_hi = self._readByte(addr=3)
        cycles_lo = self._readByte(addr=4)
        return cycles_lo + (cycles_hi << 8)

    def read_update_pair(self):
        exp_type = self._readByte(addr=0x9)
        exp_addr = self._readByte(addr=0xA)
        exp_addr = (exp_addr << 8) + self._readByte(addr=0xB)
        exp_val = self._readByte(addr=0xC)
        exp_val = (exp_val << 8) + self._readByte(addr=0xD)
        exp_val = (exp_val << 8) + self._readByte(addr=0xE)
        exp_val = (exp_val << 8) + self._readByte(addr=0xF)

        actual_type = self._readByte(addr=0x10)
        actual_addr = self._readByte(addr=0x11)
        actual_addr = (actual_addr << 8) + self._readByte(addr=0x12)
        actual_val = self._readByte(addr=0x13)
        actual_val = (actual_val << 8) + self._readByte(addr=0x14)
        actual_val = (actual_val << 8) + self._readByte(addr=0x15)
        actual_val = (actual_val << 8) + self._readByte(addr=0x16)

        return StateUpdate(exp_type, exp_addr, exp_val),\
            StateUpdate(actual_type, actual_addr, actual_val)

    def close(self):
        self._serial.close()


class TestTree(object):
    def __init__(self, test_dir, testw_file, disabled_subtrees):
        if not os.path.isdir(test_dir):
            print("Error: could not find ./{} directory".format(test_dir),
                  file=sys.stderr)
            sys.exit(1)

        if not os.path.isfile(testw_file):
            print("Error: could not find ./{} file".format(testw_file),
                  file=sys.stderr)
            sys.exit(1)

        self.disabled_subtrees = []
        for subtree in disabled_subtrees:
            if not os.path.exists(subtree):
                print("Warning: the subtree {} does not exist".format(subtree),
                      file=sys.stderr)
            else:
                self.disabled_subtrees.append(subtree)

        self.test_dir = test_dir
        self.testw_file = testw_file
        self.test_weights = TestTree._read_test_weights(testw_file)

    def evaluate_test_score(self, test_strategy):

        total_points, tests_covered = self._traverse_tests(
            EvaluationVisitor(self.test_weights, test_strategy))
        expected_tests = set(self.test_weights.keys())
        uncovered_tests = list(filter(self._is_subgroup_path_enabled,
                                      expected_tests - tests_covered))
# set(self.test_weights.keys()).difference(tests_covered)
        # uncovered_tests = list(filter(self._is_subgroup_disabled, uncovered_tests))
        if uncovered_tests:
            print_warning("No tests found in groups " + ",".join(uncovered_tests))
        return total_points

    def _traverse_tests(self, visitor, cur_dir=None, depth=0):
        cur_dir = cur_dir if cur_dir else self.test_dir
        children = list(os.scandir(cur_dir))
        if not children:
            print_warning("Encountered empty test group {}".format(cur_dir))
            return visitor.get_default_ret_value()
        else:
            subgroups = list(filter(lambda c: c.is_dir(), children))
            subtests = list(filter(lambda c: c.is_file() and
                                c.name.endswith(".test"), children))
            if subgroups and subtests:
                print_warning(("Test group {} has both subgroups and subtests - " +
                            "ignoring it!").format(cur_dir))
                return visitor.get_default_ret_value()

            elif len(subgroups) + len(subtests) < len(children):
                print_warning("Unrecognized files ({}) in test group {}".
                            format(', '.join([c.name for c in children
                                                if not c in subgroups and
                                                not c in subtests]),
                                    cur_dir))
            if subgroups:
                subgroup_results = []
                for sg in subgroups:
                    if self._is_subgroup_path_enabled(sg.path):
                        if visitor.visit_subgroup_preorder(sg, depth):
                            # subgroup_results.append(
                            #     self._traverse_tests(self, visitor, sg.path, depth+1))
                            subgroup_results.append(
                                visitor.visit_subgroup_postorder(
                                    sg, depth,
                                    self._traverse_tests(
                                        visitor, sg.path, depth+1)))

                    else:
                        print("Skipping subgroup", sg.path)
                    #         )
                    # visitor.visit_subgroup_postorder(sg, depth, subgroup_results[-1])
                return visitor.combine_subgroup_results(sg, depth,
                                                          subgroup_results)

            elif subtests:
                test_results = []
                for test in subtests:
                    test_results.append(visitor.visit_test(test, depth+1))
                return visitor.combine_test_results(test_results, depth)

            else:
                print_warning(("No files in {} recognized as either subgroups " +
                            "or subtests, ignoring it!").format(cur_dir))
                return 0, tests_covered

    def _is_subgroup_path_enabled(self, sg_path):
        return not any([sg_path.startswith(subtree)
                        for subtree in self.disabled_subtrees])
    def print_self(self):
        self._traverse_tests(PrettyPrintVisitor())

    def generate_tests(self, arch_name):
        self._traverse_tests(TestGeneratingVisitor(arch_name))

    @staticmethod
    def _read_test_weights(test_weight_file):
        with open(test_weight_file) as f:
            weights =  { d : int(w) for d, w in
                [tuple(line.split()) for line in f if len(line.strip()) > 0 ] }
            parent_keyf = lambda d: '/'.join(d.split("/")[:-1])
            for test_group, group_members in itertools.groupby(sorted(weights,
                                                                    key=parent_keyf),
                                                            parent_keyf):
                test_sum = sum([ weights[d] for d in group_members ])
                if test_sum != 100:
                    print("[BUG] TEST SETUP ERROR: sum of weights of members in " +
                        "test group {} is {} != 100".format(test_group, test_sum),
                        file=sys.stderr)
                    sys.exit(1)
            return weights

    def _run_tests(self, test_strategy, depth=0, tests_covered = set()):
        points = 0

        children = list(os.scandir(test_dir))
        if not children:
            print_warning("Encountered empty test group {}".format(test_dir))
            return 0, tests_covered
        else:
            subgroups = list(filter(lambda c: c.is_dir(), children))
            subtests = list(filter(lambda c: c.is_file() and
                                c.name.endswith(".test"), children))
            if subgroups and subtests:
                print_warning(("Test group {} has both subgroups and subtests - " +
                            "ignoring it!").format(test_dir))
                return 0, tests_covered

            elif len(subgroups) + len(subtests) != len(children):
                print_warning("Unrecognized files ({}) in test group {}".
                            format(', '.join([c.name for c in children
                                                if not c in subgroups and
                                                not c in subtests]),
                                    test_dir))
            if subgroups:
                for sg in subgroups:
                    sg_name = test_dir + "/" + sg.name
                    if not sg_name in weights:
                        print_warning(("Unspecified weight for subgroup {} - " +
                                    "it will be ignored!").format(sg_name))
                    else:
                        print("{}Subgroup {}".
                            format(' ' * depth, sg.name))
                        subdir_points, tests_covered = \
                            self._run_tests(sg_name, weights,
                                    depth+1, tests_covered)
                        subdir_points = round((subdir_points * weights[sg_name]) /
                                            100.0)
                        print(" "*depth + "Points:", subdir_points)
                        points += subdir_points
                        tests_covered.add(sg_name)
                return points, tests_covered

            elif subtests:
                num_passed = 0
                num_tests = len(subtests)
                for test in subtests:
                    num_passed += run_test(test_dir + "/" + test.name, depth+1)
                print("{}{} / {} tests passed".format(' '*depth, num_passed,
                                                    num_tests))
                return ((num_passed * 100.0) / num_tests), tests_covered

            else:
                print_warning(("No files in {} recognized as either subgroups " +
                            "or subtests, ignoring it!").format(test_dir))
                return 0, tests_covered

class EvaluationVisitor(object):
    def __init__(self, test_weights, test_strategy):
        self.tests_covered = set()
        self.weights = test_weights
        self.test_strategy = test_strategy

    def get_default_ret_value(self):
        return 0, self.tests_covered

    def visit_subgroup_preorder(self, sg, depth):
        if not sg.path in self.weights:
            print_warning(("Unspecified weight for subgroup {} - " +
                            "it will be ignored!").format(sg.path))
            return False
        else:
            print("{}Subgroup {}".
                    format(' ' * depth, sg.name))
            return True

    def visit_subgroup_postorder(self, sg, depth, result):
        subdir_points = ((result[0] * self.weights[sg.path]) / 100.0)
        print("{}Subgroup {} score: {:.2f} * {}/100 = {:.2f} %".format(
            " "*depth, sg.path, result[0], self.weights[sg.path], subdir_points))
        self.tests_covered.add(sg.path)
        return subdir_points

    def visit_test(self, test, depth):
        return self.test_strategy(test.path, depth)

    def combine_test_results(self, results, depth):
        num_passed = sum(results)
        num_tests = len(results)
        print("{}{} / {} tests passed".format(' '*depth, num_passed,
                                                num_tests))
        return ((num_passed * 100.0) / num_tests), self.tests_covered

    def combine_subgroup_results(self, sg, depth, results):
        # return sum([x for x, _ in results]), self.tests_covered
        return sum(results), self.tests_covered

class PrettyPrintVisitor(object):
    def __init__(self):
        pass

    def get_default_ret_value(self):
        pass

    def visit_subgroup_preorder(self, sg, depth):
        # print("{}\\".format(' ' * (depth-1)))
        print("{}-{}". format(' ' * depth, sg.name))
        return True

    def visit_subgroup_postorder(self, sg, depth, result):
        pass

    def visit_test(self, test, depth):
        print('{} * {}'.format(' '*depth, test.name))

    def combine_test_results(self, results, depth):
        pass

    def combine_subgroup_results(self, sg, depth, results):
        pass

class TestGeneratingVisitor(object):
    def __init__(self, arch_name):
        self.arch_name = arch_name

    def get_default_ret_value(self):
        pass

    def visit_subgroup_preorder(self, sg, depth):
        return True

    def visit_subgroup_postorder(self, sg, depth, result):
        pass

    def visit_test(self, test, depth):
        print("Generating test files for", test.path)
        run_test_gen_script(test.path, self.arch_name)

    def combine_test_results(self, results, depth):
        pass

    def combine_subgroup_results(self, sg, depth, results):
        pass

def main():
    actions = {
        'gen_tests' : lambda tree, args: tree.generate_tests(args.arch_name),
        'print_tests' : lambda tree, args: tree.print_self(),
        'run_sim_tests' : lambda tree, args: tree.evaluate_test_score(simulation_test),
        'run_fpga_tests': run_fpga_tests
    }

    parser = argparse.ArgumentParser()
    parser.add_argument("--action", choices = actions, required=True)
    parser.add_argument("--arch-name")
    parser.add_argument("--disabled-subtrees", nargs="+", default=[])
    args = parser.parse_args()
    if (args.action == "gen_tests") != (args.arch_name != None):
        parser.print_usage(file=sys.stderr)
        print("The --arch-name argument must be supplied if and only if the action is gen_tests",
              file=sys.stderr)
        sys.exit(1)

    tree = TestTree(test_dir="tests", testw_file="test_weights",
                    disabled_subtrees=args.disabled_subtrees)
    result = actions[args.action](tree, args)
    if result:
        print("Total score: {:.2f} %".format(result))

def run_test_gen_script(test, arch_name):
    run_test_gen_cmd = [ "./gen_test_files.sh", test, arch_name ]
    subprocess.run(run_test_gen_cmd)

def simulation_test(test, depth):
    print("{}- {}: ".format(' '*depth, os.path.basename(test)).ljust(60),
          end="", flush=True)
    script_file = "../scripts/run_single_test.sh"
    prj_file = "./sim-prj.prj"
    test_wo_suffix = test[:-5] ## Strip away .test suffix
    test_wo_special_chars = ''.join([ x if x.isalnum() or x == '_' else '_'
                                      for x in test_wo_suffix ])
    os.chdir("sim-tests/vivado-workdir")
    try:
        run_sim_cmd = [
            os.path.abspath(script_file),
            os.path.abspath(prj_file),
            test_wo_special_chars
        ]

        res = subprocess.run(run_sim_cmd, stdout=subprocess.PIPE,
                             stderr=subprocess.PIPE, universal_newlines=True)
        if res.stderr:
            res_str = res.stderr[:res.stderr.find('\n')]
        else:
            res_str = res.stdout[:res.stdout.find('\n')]
        if res_str.startswith("[OK]"):
            if res_str.endswith("Test success."):
                print(res_str)
                return 1
            else:
                print("[FAILURE] Unexpected test termination. " +
                      "See xsim_stdout.log for details.")
                return 0
        elif res_str.startswith("[FAILURE]"):
            print(res_str)
            return 0
        else:
            print("[FAILURE] Could not interpret result string.")
            print("Unknown result string:", res_str, file=sys.stderr)
            return 0
    finally:
        os.chdir("../..")

def run_fpga_tests(tree, args):
    tree.evaluate_test_score(fpga_test)

def fpga_test(test, depth):
    testname = os.path.basename(test)
    testname_wo_suffix = testname[:-5] ## Strip away .test suffix
    test_wo_special_chars = ''.join([ x if x.isalnum() or x == '_' else '_'
                                      for x in testname_wo_suffix ])
    fpga_testdir = "fpga-tests/test-resources/{}/{}".format(
        os.path.dirname(test), test_wo_special_chars)

    imem_fname = fpga_testdir + "/init_imem"
    dmem_fname = fpga_testdir + "/init_dmem"
    regfile_fname = fpga_testdir + "/init_regfile"
    expupd_fname = fpga_testdir + "/init_exp_updates"
    test_config_fname = fpga_testdir + "/test_config"

    print("{}- {}: ".format(' '*depth, testname).ljust(60),
          end="", flush=True)
    with open(imem_fname) as imem_file,\
         open(dmem_fname) as dmem_file,\
         open(regfile_fname) as regs_file,\
         open(expupd_fname) as expupd_file,\
         open(test_config_fname) as test_config,\
         HostcommProxy("/dev/fpga_uart") as hostcomm:

        hostcomm.stop_processor()
        hostcomm.reset_processor()
        hostcomm.init_imem(imem_file)
        hostcomm.init_dmem(dmem_file)
        hostcomm.init_regfile(regs_file)
        hostcomm.init_expected_updates(expupd_file)
        hostcomm.init_test_config(test_config)

        hostcomm.start_processor()

        test_code = hostcomm.first_nonzero_testcode()
        cycles = hostcomm.read_cycle_count()
        test_res = "[FAILURE]"
        points = 0
        if test_code == 1:
            test_res = "[OK]"
            msg = "Test success"
            points = 1
        elif test_code == 2:
            msg = "Test timeout"
        elif test_code == 3:
            msg = "Update while disabled"
        elif test_code == 4:
            msg = "More updates than expected"
        elif test_code == 5:
            msg = "Incorrect update: "
            expected, actual = hostcomm.read_update_pair()
            msg += "expected update to " + str(expected) + " but got "  + str(actual)
        else:
            print("Unknown test code:", test_code)

        print("{} In cycle {}: {}.".format(test_res, cycles, msg))
        hostcomm.stop_processor()
        return points


def print_warning(msg):
    print("[WARNING]:", msg, file=sys.stderr)

def print_test_ok_sign(end="\n"):
    print("[OK]", end=end)

if __name__ == '__main__':
   main()
