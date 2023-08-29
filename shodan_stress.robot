# Copyright 2022 Google LLC
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
#
*** Comments ***
Tests to stress out the Shodan system in 4MB of RAM using released binaries.

*** Settings ***
Resource  resources/common.resource
Variables  variables/common.py

*** Variables ***
${MAX_ITER}                      100
${SCRIPT}                        sim/config/shodan.resc

*** Test Cases ***
Test Shodan Boot
    Prepare Machine
    Start Emulation
    Create Terminal Tester      ${SMC_UART}
    Wait For Prompt On Uart     EOF

    FOR    ${iter}    IN RANGE    ${MAX_ITER}
      IF     ${{random.randint(0, 2)}} == 0
        Write Line to Uart          start hello
        Wait For Line On Uart       Done
        Stop App                    hello
      END

      IF     ${{random.randint(0, 2)}} == 0
        Write Line to Uart          start fibonacci
        Wait For Line On Uart       [10]
        Stop App                    fibonacci
      END

      IF     ${{random.randint(0, 2)}} == 0
        Write Line to Uart          start keyval
        Wait For Line On Uart       delete ok (for missing key)
        Stop App                    keyval
      END

      IF     ${{random.randint(0, 2)}} == 0
        Write Line to Uart          start logtest
        Wait For Line On Uart       DONE
        Stop App                    logtest
      END

      IF     ${{random.randint(0, 2)}} == 0
        Write Line to Uart          start panic
        Wait For Line On Uart       Goodbye, cruel world
        Stop App                    panic
      END

      IF     ${{random.randint(0, 2)}} == 0
        Write Line to Uart          start timer
        Wait For Line On Uart       DONE!
        Stop App                    timer
      END

      IF     ${{random.randint(0, 4)}} == 0
        Write Line to Uart          start mltest
        Wait For Line On Uart       DONE!
        Stop App                    mltest
      END

      Write Line to Uart          mdebug
      Wait For Prompt On Uart     ${PROMPT}
    END
