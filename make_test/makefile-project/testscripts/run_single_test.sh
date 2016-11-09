#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <project file> <test bench name>"
    exit 1
fi

project_file=$(readlink -f "$1")
script_dir=$(dirname $(readlink -f "$0"))
elab_script="${script_dir}"/elab_tests.sh
run_tb_script="${script_dir}"/run_tb_cfg.sh

tb_name="$2"
log_dir="${tb_name}"
mkdir -p "${log_dir}"

script_log="${log_dir}/run_test_script.log"

echo "--------------------------------------------" >> "${script_log}"
date >> "${script_log}"
xelab -debug typical "${tb_name}" -prj "${project_file}" >> "${script_log}" 2>&1
if [ $? -ne 0 ]; then
    echo "[FAILURE]: Could not elaborate design. See ${script_log} for details."
    exit 1
fi

xsim_stdout_log="${log_dir}/xsim_stdout.log"
xsim_stderr_log="${log_dir}/xsim_stderr.log"
xsim_wdb="${log_dir}/waveform.wdb"

(cat <<EOF
log_wave -r /*;
run all;
quit;
EOF
) | xsim -wdb "${xsim_wdb}" -onerror quit -onfinish quit "work.${tb_name}" \
         2>"${xsim_stderr_log}" \
    | tee "${xsim_stdout_log}"

sim_launch_errors=$(cat "${xsim_stderr_log}")
if [ ! -z "${sim_launch_errors}" ]; then
    echo "[FAILURE]: Failed to launch test. " \
         "Check $(readlink -f ${xsim_stderr_log}) for details."
fi
