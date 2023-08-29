#!/bin/bash
#
# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

if [[ -z "${ROOTDIR}" ]]; then
    echo "Source build/setup.sh first"
    exit 1
fi

set -u # Treat unset params as errors.

RENODE_DIR="${CACHE}/renode"
TESTS_RESULTS="${OUT}/renode_test_results"

source "${RENODE_DIR}/tests/common.sh"

STTY_CONFIG=$(stty -g 2>/dev/null)

BUILD_TYPE=release
ARGS=(
    -u "$(get_path "${RENODE_DIR}/tests/run_tests.py")"
    --variable "PLATFORM:${PLATFORM}"
)

if [[ $1 == "--debug" ]]; then
  echo "Running debug artifacts"
  shift
  BUILD_TYPE=debug
fi

if [[ $1 == "--wrapper" ]]; then
  echo "Running sel4test+wrapper artifacts"
  shift
  ARGS+=(
    --variable "RUN_WRAPPER:1"
  )
fi

if [[ $1 == "--no-echo-check" ]]; then
  echo "Disable UART input echo check"
  shift
  ARGS+=(
    --variable "WAIT_ECHO:false"
  )
fi

if [[ "${BUILD_TYPE}" == "debug" ]]; then
  ARGS+=(
    --variable "RUN_DEBUG:1"
    --variable "BUILD_TYPE:debug"
  )
fi

ARGS+=(
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
