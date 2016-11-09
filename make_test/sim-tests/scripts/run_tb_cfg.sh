#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Usage: $0 <tb configuration name> <log dir>" >&2
    exit 1
fi

cfg_name=$1
log_dir=$2

xsim_stdout_log="${log_dir}/xsim_stdout.log"
xsim_stderr_log="${log_dir}/xsim_stderr.log"
xsim_wdb="${log_dir}/waveform.wdb"

(cat <<EOF 
log_wave -r /tb/*;
run all;
quit;
EOF
) | xsim -wdb "${xsim_wdb}" -onerror quit -onfinish quit "work.${cfg_name}" \
         > "${xsim_stdout_log}" 2>"${xsim_stderr_log}"

sim_launch_errors=$(cat "${xsim_stderr_log}")
if [ ! -z "${sim_launch_errors}" ]; then
    echo "[FAILURE]: Failed to launch test. " \
         "Check $(readlink -f ${xsim_stderr_log}) for details."
else
    # log_file=$(grep -Eo '[^"]+/test_log' ${cfg_name}.vhd)
    log_file="${log_dir}/test_log"
    if [ ! -f "${log_file}" ]; then
        echo "!!! [TEST SETUP BUG]: Could not find log file '${log_file}'"
    else
        result=$(tail -n1 "${log_file}")
        if [ -z "${result}" ]; then
            echo "Log file ${log_file} empty - simulation probably crashed. " \
                 "Check $(readlink -f ${xsim_stdout_log}) for details."
        else
            echo "${result}"
        fi
    fi
fi
