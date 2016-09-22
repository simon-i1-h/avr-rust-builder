#!/bin/sh

set -u
unset TOP STATUS TOOLCHAIN_LIST DEFAULT_TOOLCHAIN toolchain

TOOLCHAIN_LIST='
nightly-2016-09-09
'

DEFAULT_TOOLCHAIN='nightly-2016-09-09'

TOP="$(cd $(dirname "$0"); pwd)"
cd "${TOP}"

if [ "$#" = 0 ]; then
    echo "select default toolchain: \`${DEFAULT_TOOLCHAIN}'"
    "${TOP}/${DEFAULT_TOOLCHAIN}/build.sh"
    STATUS="$?"
    exit "${STATUS}"
fi

for toolchain in ${TOOLCHAIN_LIST}; do
    if [ "${toolchain}" = "$1" ]; then
        "${TOP}/${DEFAULT_TOOLCHAIN}/build.sh"
        STATUS="$?"
        exit "${STATUS}"
    fi
done

echo "error: \`$1' toolchain not found." >&2
exit 1
