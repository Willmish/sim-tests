#!/bin/bash

if [[ -z "${ROOTDIR}" ]]; then
    echo "Source build/setup.sh first"
    exit 1
fi

set -u # Treat unset params as errors.

RENODE_DIR="${OUT}/host/renode"
TESTS_RESULTS="${OUT}/renode_test_results"

source "${RENODE_DIR}/tests/common.sh"

STTY_CONFIG=$(stty -g 2>/dev/null)

ARGS=(
    -u "$(get_path "${RENODE_DIR}/tests/run_tests.py")"
    --exclude "skip_${DETECTED_OS}"
    -r "$(get_path "${TESTS_RESULTS}")"
    --robot-framework-remote-server-full-directory "${RENODE_DIR}/bin"
    --css-file "${RENODE_DIR}/tests/robot.css"
    --show-log
    "$@"
)
RUNNER="mono"
if [[ -f "${RENODE_DIR}/tag" ]]; then
    if grep -q "renode-" "${RENODE_DIR}/tag"; then
        RUNNER="none"
        ARGS+=(
            --robot-framework-remote-server-full-directory "${RENODE_DIR}"
            --robot-framework-remote-server-name renode
            --runner none
        )
    fi
fi

echo "Renode uses runner ${RUNNER}"

${PYTHON_RUNNER} "${ARGS[@]}"


RESULT_CODE=$?
if [[ -n "${STTY_CONFIG:-}" ]]; then
    stty "${STTY_CONFIG}"
fi
exit ${RESULT_CODE}
