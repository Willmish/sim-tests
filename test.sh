#!/bin/bash
set -e
set -u

ROOT_PATH="${ROOTDIR}/sim/renode"
TESTS_FILE="$ROOT_PATH/tests/tests.yaml"
TESTS_RESULTS="$OUT/host/renode/tests"

. "${ROOT_PATH}/tools/common.sh"

set +e
STTY_CONFIG=`stty -g 2>/dev/null`
$PYTHON_RUNNER -u "`get_path "$ROOT_PATH/tests/run_tests.py"`" --exclude "skip_${DETECTED_OS}" --properties-file "`get_path "$ROOT_PATH/output/properties.csproj"`" -r "`get_path "$TESTS_RESULTS"`" -t "`get_path "$TESTS_FILE"`" "$@"
RESULT_CODE=$?
set -e
if [ -n "${STTY_CONFIG:-}" ]
then
    stty "$STTY_CONFIG"
fi
exit $RESULT_CODE
