#!/bin/bash

if [ $# -ne 1 ]; then
    echo "Usage: $0 <num instructions storable in imem>"
    exit 1
fi

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
tmp_objcopy_output=$(mktemp -t "tmp_objcopy_out-XXXXXX.bin")
tmp_od_output=$(mktemp -t "tmp_od_out-XXXXXX")

imem_depth="$1"
last_16_instr_addr=$(printf "0x%x" $(((4*(${imem_depth} - 16)))))

## The linker script ensures that whatever instructions are placed in the
## section ".final_16_instructions" are added to the .text section, at the
## correct address. It also sets the .text section address to zero.
linker_script=$(cat <<EOF
SECTIONS {
  .text 0 : {
    *(.text)
    . = ${last_16_instr_addr};
    *(.final_16_instructions)
  }
}
EOF
)

## .set noat lets us use register 1 ($at) in our tests (normally, this is
## reserved for the assembler in order to implement pseudoinstructions).
##.set noreorder ensures that no branch delay slots are inserted after branches
## in our tests.
(echo -e ".set noat\n.set noreorder"; cat -) > "${tmp_as_in}"
## The "(echo ...; cat -)" prepends the assembler attributes to the program text
## which is received through stdin.

## Chain operations with && so that any errors stops further operation.
${CROSS}-as "${tmp_as_in}" -o "${tmp_as_output}" &&
    ${CROSS}-ld -T<(echo "${linker_script}") "${tmp_as_output}" \
            -o "${tmp_ld_output}" &&
    ${CROSS}-objcopy -O binary --gap-fill 0 -j .text \
            "${tmp_ld_output}" "${tmp_objcopy_output}" &&
    od -A none -t x4 --endian=big -w4 --output-duplicates \
       "${tmp_objcopy_output}" > "${tmp_od_output}"

if [ $? -ne 0 ]; then
    echo "Could not generate initial instruction memory content" >&2
    exit 1
fi

num_instr=$(wc -l "${tmp_od_output}" | cut -f1 -d ' ')
xargs < "${tmp_od_output}" -n1 -I{} echo "0{}" | tr -d '\n'

if [ "${num_instr}" -gt "${imem_depth}" ]; then
    echo "[WARNING]: Test assembles to ${num_instr} instructions, " \
         "exceeding the specified instruction memory depth $1" >&2
    echo "(See ${tmp_od_output} for assembler result.)" >&2
else
    rm "${tmp_as_output}" "${tmp_ld_output}" \
       "${tmp_objcopy_output}" "${tmp_od_output}"
fi
