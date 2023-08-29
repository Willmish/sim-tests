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

*** Settings ***
# These variables are defined in the individual robot tests this script is
# prepended to, and otherwise via command line arguments to the robot test
# framework.
Variables  variables/common_fpga.py
Library  FPGALibrary.py  board_id=${FPGA_BOARD_ID}  timeout=${LOG_TIMEOUT}  quiesce_delay_seconds=${FPGA_QUIESCE_DELAY_SECONDS}

