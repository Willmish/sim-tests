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

function die {
  echo "$@" >/dev/stderr
  exit 1
}

function usage {
  cat <<EOF
Usage: fpga_test.sh [options] <fpga-board-number> <test-suite-filename>

Where [options] is one of:

    --no-echo-check    Disables the checks for echoed back characters
                       from the FPGA shell prompt.
    --timeout NN       Sets the length of time to wait for a response
                       on read or write to the UART. Defaults to 60
                       seconds.
    --robot PATH       Overrides the path to the robot test script
                       runner. Defaults to searching the PATH.
    --help | -h        Show this usage information.

fpga-board-number must be a two digit number, prefixed with a leading
zero if necessary.

test-suite-filename is the path to the test suite to run.
Ie: sim/tests/shodan_boot.robot.

Note: options are positional -- fpga-board-number and test-suite-filename
must be the last arguments on the command line, in that order.
EOF
  exit 1
}

function cleanup {
  rm -f "${TMP_TEST_SUITE}"
}

ROBOT=$(which robot)
FPGA_HEADER="${ROOTDIR}/sim/tests/fpga_header.robot"

ARGS=()

if [[ "$1" == "--no-echo-check" ]]; then
  shift
  ARGS+=(--variable "WAIT_ECHO:false")
fi

if [[ "$1" == "--timeout" ]]; then
  shift
  ARGS+=(--variable "FPGA_UART_TIMEOUT:$1")
  shift
fi

if [[ "$1" == "--robot" ]]; then
  shift
  ROBOT="$1"
  shift
fi

if [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  usage
fi

FPGA_BOARD_ID="$(printf '%02d' $1)"
ARGS+=(--variable "FPGA_BOARD_ID:${FPGA_BOARD_ID}")
shift
TEST_SUITE="$1"
shift

if [[ -z "${TEST_SUITE}" ]]; then
  echo "No FPGA number or test suite specified." >/dev/stderr
  echo >/dev/stderr
  usage
fi

if [[ ! -z "$1" ]]; then
  die "Unknown argument $1"
fi

trap cleanup EXIT
TMP_TEST_SUITE=$(mktemp /tmp/test_suite.robot.XXXXXX)

cat "${FPGA_HEADER}" "${TEST_SUITE}" > "${TMP_TEST_SUITE}"
echo "${ROBOT}" "${ARGS[@]}" "${TMP_TEST_SUITE}"
"${ROBOT}" "${ARGS[@]}" "${TMP_TEST_SUITE}" || exit 1

