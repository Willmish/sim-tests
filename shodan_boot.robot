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

*** Comments ***
Tests for shodan system from bootup to running apps.

*** Settings ***
Resource  resources/common.resource
Variables  variables/common.py
Variables  variables/${PLATFORM}_${BUILD_TYPE}.py

*** Test Cases ***
Test Boot
    Prepare Machine
    Start Emulation
    Create Terminal Tester      ${SMC_UART}
    Wait For Prompt On Uart     EOF
    # The following commented lines would cause the test failed to be saved.
    Provides                    shodan-bootup

Test C hello app (no SDK)
    Requires                    shodan-bootup
    Install App                 hello
    Wait For Line On Uart       I am a C app!
    Wait For Line On Uart       Done
    Uninstall App               hello

# TODO(sleffler): This test failed with debug artifacts.
Test SDK keyval support (+SecurityCoordinator)
    Requires                    shodan-bootup
    Install App                 keyval
    Wait For Line On Uart       read(foo) failed as expected
    Wait For Line On Uart       write ok
    Wait For Line On Uart       read returned [49, 50, 51, 0
    Wait For Line On Uart       delete ok
    Wait For Line On Uart       delete ok (for missing key)
    Uninstall App               keyval

Test SDK log support
    Requires                    shodan-bootup
    Install App                 logtest
    Wait For Line On Uart       ping!
    Wait For Line On Uart       DONE
    Uninstall App               logtest

Test panic app
    Requires                    shodan-bootup
    Install App                 panic
    Wait For Line On Uart       Goodbye, cruel world
    Uninstall App               panic

Test SDK + TimerService (oneshot & periodic)
    Requires                    shodan-bootup
    Install App                 timer
    Wait For Line On Uart       sdk_timer_cancel returned Err(SDKInvalidTimer) with nothing running
    Wait For Line On Uart       sdk_timer_poll returned Ok(0) with nothing running
    Wait For Line On Uart       sdk_timer_oneshot returned Err(SDKNoSuchTimer) with an invalid timer id
    # oneshot
    Wait For Line On Uart       Timer 0 started
    Wait For Line On Uart       Timer 0 completed
    # periodic
    Wait For Line On Uart       Timer 1 started
    Wait For Line On Uart       Timer completed: mask 0b0010 ms 75
    Wait For Line On Uart       Timer completed: mask 0b0010 ms 150
    # NB: 10 timer events
    # NB: intentionally match "cancel"; the code has a typo so prints "canceld" :)
    Wait For Line On Uart       Timer 1 cancel
    # 2x periodic with 2:1 durations
    Wait For Line On Uart       Timer 1 started
    Wait For Line On Uart       Timer 2 started
    Wait For Line On Uart       Timer completed: mask 0b0010 1 \ 1 2 \ 0
    Wait For Line On Uart       Timer completed: mask 0b0010 1 \ 2 2 \ 0
    # NB: lots of timer events (2 timers running)
    Wait For Line On Uart       Timer completed: mask 0b0100 1 14 2 \ 7
    Wait For Line On Uart       Timer 2 cancel
    Wait For Line On Uart       Timer 1 cancel
    Wait For Line On Uart       DONE
    Uninstall App               timer

Test SDK + MlCoordinator (oneshot & periodic)
    Requires                    shodan-bootup
    # UART analyzer is marked as transient so it needs to be set up at subtest.
    Execute Command             showAnalyzer "smc-uart-analyzer" ${SMC_UART} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Add SMC_UART virtual time so we can check the machine execution time
    Execute Command             smc-uart-analyzer TimestampFormat Virtual
    Write Line to Uart          start mltest                                    waitForEcho=${WAIT_ECHO}
    Wait For Line On Uart       sdk_model_oneshot(nonexistent) returned Err(SDKNoSuchModel) (as expected)
    # start oneshot
    Wait For Line On Uart       ${MODEL_FILENAME} started
    Wait For Line On Uart       ${MODEL_FILENAME} completed
    # start periodic
    Wait For Line On Uart       Model ${MODEL_FILENAME} started
    # NB: 10 runs of the model
    FOR    ${i}    IN RANGE    10
      Wait For Line On Uart     Model completed: mask 0b0001
    END
    Wait For Line On Uart       DONE
    Write Line To Uart          stop mltest                                     waitForEcho=${WAIT_ECHO}
    Wait For Line On Uart       Bundle "mltest" stopped
