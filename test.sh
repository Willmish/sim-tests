#!/bin/bash

if [[ -z "${ROOTDIR}" ]]; then
    echo "Source build/setup.sh first"
    exit 1
fi

set -u # Treat unset params as errors.

RENODE_SRC_DIR="${ROOTDIR}/sim/renode"
RENODE_DIR="${OUT}/host/renode"
TESTS_FILE="${RENODE_SRC_DIR}/tests/tests.yaml"
TESTS_RESULTS="${OUT}/renode_test_results"

. "${RENODE_SRC_DIR}/tools/common.sh"

STTY_CONFIG=`stty -g 2>/dev/null`
${PYTHON_RUNNER} -u "$(get_path "${RENODE_SRC_DIR}/tests/run_tests.py")" \
    --exclude "skip_${DETECTED_OS}" \
    --properties-file "$(get_path "${RENODE_SRC_DIR}/output/properties.csproj")" \
    -r "$(get_path "${TESTS_RESULTS}")" \
    -t "$(get_path "${TESTS_FILE}")" "$@" \
    --variable PATH:"${ROOTDIR}" \
    --robot-framework-remote-server-full-directory "${RENODE_DIR}" \
    --show-log

RESULT_CODE=$?
if [[ -n "${STTY_CONFIG:-}" ]]; then
    stty "${STTY_CONFIG}"
fi
exit ${RESULT_CODE}
