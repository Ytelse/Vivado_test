#!/bin/bash

CROSS=$(find /bin /usr/bin -name '*mips*-as')
CROSS=${CROSS%-as}
if [ -z "$CROSS" ]; then
    echo "Could not locate a cross-compiler for MIPS in /bin or /usr/bin" >&2
    CROSS=mips-linux-gnu
    echo "Trying to use ${CROSS} as a default" >&2
fi

tmp_as_in=$(mktemp -t "tmp_as_in-XXXXXX.s")
tmp_as_output=$(mktemp -t "tmp_as_out-XXXXXX.o")
tmp_ld_output=$(mktemp -t "tmp_ld_out-XXXXXX.o")

cat <<EOF
-----------------------------------
Welcome to the MIPS assembler REPL!

Write lines of MIPS assembly, and hit enter to get the hex equivalent.

To quit, enter an empty line.

If you want to jump to labels, the assembler must consider multiple lines at the
same time. To begin such a multi-line section, type "multiline". The prompt will
change to ">>". To end the section, type "end".

GLHF!
===================================
EOF

while read -p "> " instr; do
    echo -e ".set noreorder\n.set noat" > "${tmp_as_in}"
    case "${instr}" in
        "")
            break
            ;;
        multiline)
            while read -p ">> " instr; do
                case "${instr}" in
                    end)
                        break;
                        ;;
                    *)
                        echo "${instr}" >> "${tmp_as_in}"
                esac
            done
            ;;
        *)
            echo "${instr}" >> "${tmp_as_in}"
    esac
    ${CROSS}-as -o "${tmp_as_output}" "${tmp_as_in}" &&
    ${CROSS}-ld --entry=0 -Ttext=0 -o "${tmp_ld_output}" "${tmp_as_output}" &&
    ${CROSS}-objdump -d -j .text -Mgpr-names=numeric "${tmp_ld_output}" | \
        tail -n+8
done
