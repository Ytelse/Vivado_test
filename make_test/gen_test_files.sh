#!/bin/bash

if [ $# -lt 2 -o $# -gt 4 ]; then
    echo "Usage: $0 <test file> <processor VHDL architecture name> " \
         "[dmem depth=1024] [imem depth=1024]">&2
    exit 1
fi

test_file="$1"
arch_name="$2"
dmem_depth="${3-1024}"
imem_depth="${4-1024}"

function normalize() {
    echo -n "$1" | tr --complement 'a-zA-Z0-9_' '_'
}

sim_test_base_dir=sim-tests/test-resources
# test_name=$(normalize "${test_file%%.test}")
sim_test_dir="${sim_test_base_dir}"/$(dirname "${test_file}")/$(normalize $(basename "${test_file}" .test))
sim_init_dmem_file="${sim_test_dir}/init_dmem"
sim_init_regs_file="${sim_test_dir}/init_regfile"
sim_init_exp_upd_file="${sim_test_dir}/init_exp_updates"
sim_init_imem_file="${sim_test_dir}/init_imem"
tb_log_file="${sim_test_dir}/test_log"

mkdir -p "${sim_test_dir}"
./get_test_section.sh "${test_file}" "Initial state" \
    | ./gen_init_data_state_files.py \
          "${sim_init_regs_file}" "${sim_init_dmem_file}" "${dmem_depth}"
./get_test_section.sh "${test_file}" "Expected state updates" \
    | ./gen_expected_updates_file.py "${sim_init_exp_upd_file}" "${dmem_depth}"
./get_test_section.sh "${test_file}" "Test code" \
    | ./gen_init_imem_file.sh "${imem_depth}" > "${sim_init_imem_file}"
timeout_cycles=$(./get_test_section.sh "${test_file}" "Timeout cycle count")
if [ -z "${timeout_cycles}" ]; then
    echo "Missing timeout specification in test ${test_file}" >&2
    exit 1
fi

num_exp_updates=$(wc -l "${sim_init_exp_upd_file}" | cut -f1 -d ' ')

tb_cfg_name=$(normalize "${test_file%%.test}")
# $(basename "${test_file}" .test)
mkdir -p sim-tests/tb_cfgs
cat > sim-tests/tb_cfgs/${tb_cfg_name}.vhd <<EOF
configuration ${tb_cfg_name} of tb is
  for Behavioural
    for tb_driver : tb_MIPSProcessor
      use entity work.tb_MIPSProcessor
        generic map (
          IMEM_INIT_FILE             => "${sim_init_imem_file##${sim_test_base_dir}/}",
          DMEM_INIT_FILE             => "${sim_init_dmem_file##${sim_test_base_dir}/}",
          EXPECTED_UPDATES_INIT_FILE => "${sim_init_exp_upd_file##${sim_test_base_dir}/}",
          LOG_FILE                   => "${tb_log_file##${sim_test_base_dir}/}",
          NUM_EXPECTED_UPDATES       => ${num_exp_updates},
          TEST_TIMEOUT_CYCLES        => ${timeout_cycles});
      for Behavioural
        for Processor : MIPSProcessor
          use entity work.MIPSProcessor(${arch_name});
          for ${arch_name}
            for all : RegisterFile
              use entity work.RegisterFile(Behavioural)
                generic map (
                  REGS_INIT_FILE => "${sim_init_regs_file##${sim_test_base_dir}/}",
                  ENABLE_INIT    => true);
            end for;
          end for;
        end for;
      end for;
    end for;
  end for;

end configuration ${tb_cfg_name};
EOF

fpga_test_base_dir=fpga-tests/test-resources
fpga_test_dir="${fpga_test_base_dir}"/$(dirname "${test_file}")/$(normalize $(basename "${test_file}" .test))
fpga_init_dmem_file="${fpga_test_dir}/init_dmem"
fpga_init_regs_file="${fpga_test_dir}/init_regfile"
fpga_init_exp_upd_file="${fpga_test_dir}/init_exp_updates"
fpga_init_imem_file="${fpga_test_dir}/init_imem"
fpga_test_config_file="${fpga_test_dir}/test_config"

mkdir -p "${fpga_test_dir}"
./gen_fpga_init_imem.sh < "${sim_init_imem_file}" > "${fpga_init_imem_file}"
./gen_fpga_init_dmem.sh < "${sim_init_dmem_file}" > "${fpga_init_dmem_file}"
./gen_fpga_init_regfile.sh < "${sim_init_regs_file}" > "${fpga_init_regs_file}"
./gen_fpga_expupd_file.py < "${sim_init_exp_upd_file}" > "${fpga_init_exp_upd_file}"
cat > "${fpga_test_config_file}" <<EOF
num_expected_updates = ${num_exp_updates}
timeout = ${timeout_cycles}
EOF
