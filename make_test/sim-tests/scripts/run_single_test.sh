#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <project file> <test configuration name>"
    exit 1
fi

project_file=$(readlink -f "$1")
# test_dir="$2"
script_dir=$(dirname $(readlink -f "$0"))
elab_script="${script_dir}"/elab_tests.sh
run_tb_script="${script_dir}"/run_tb_cfg.sh

tb_cfg_name="$2"
tb_cfg_dir=$(dirname "${script_dir}")/tb_cfgs
tb_cfg_file="${tb_cfg_dir}"/"${tb_cfg_name}".vhd

# workdir=$(mktemp -d -t "vivado-workdir-${tb_cfg_name}.XXXXXX")
# cp -r "${test_dir}"/* "${workdir}"
# cd "${workdir}"

# mkdir -p vivado-workdir
# cd vivado-workdir

# log="${test_dir}/run_test_script.log"
log_file=$(grep -Eo '[^"]+/test_log' "${tb_cfg_file}")
log_dir=$(dirname "${log_file}")
if [ ! -d "${log_dir}" ]; then
    echo "Directory ${log_dir} does not exist. Copy ../test-resources/tests into vivado-workdir first." >&2
    exit 1
fi
log="${log_dir}"/run_test_script.log

# echo "Elaborating design..."
echo "--------------------------------------------" >> "${log}"
date >> "${log}"
"${elab_script}" "${project_file}" "${tb_cfg_name}" >> "${log}" 2>&1
if [ $? -ne 0 ]; then
    echo "[FAILURE]: Could not elaborate design. See ${log} for details."
else
# echo "Running the test bench..."
    "${run_tb_script}" "${tb_cfg_name}" "${log_dir}"
fi
