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

# m sel4test+wrapper robot script; expects/runs pre-built artifacts
# Takes ~15 mins (wall time) on a cloudtop
# TODO: need build target to just build artifacts

*** Comments***
seL4 tests running on shodan system.

*** Variables ***
# Run sel4test+wrapper (sel4test + Rust syscall wrappers) instead of sel4test
# This variable is 0 by default, use ./test.sh --wrapper to override
${RUN_WRAPPER}                   0

*** Variables ***
${LOG_TIMEOUT}                   2
${ROOTDIR}                       ${CURDIR}/../..
${SCRIPT}                        sim/config/shodan.resc
${UART0}                         sysbus.uart0
${UART1}                         sysbus.uart1
${UART2}                         sysbus.uart2
${UART3}                         sysbus.uart3
${UART5}                         sysbus.uart5

${MATCHA_BUNDLE_RELEASE}         ${ROOTDIR}/out/matcha-bundle-release.elf

${OUT_TMP}                       ${ROOTDIR}/out/tmp

${SEL4TEST_WRAPPER_KERNEL}       ${ROOTDIR}/out/sel4test-wrapper/shodan/debug/kernel/kernel.elf
${SEL4TEST_WRAPPER_ROOTSERVER}   ${ROOTDIR}/out/sel4test-wrapper/shodan/debug/apps/sel4test-driver/sel4test-driver
${FLASH_WRAPPER_TAR}             out/sel4test-wrapper/shodan/debug/ext_flash.tar

${SEL4TEST_KERNEL}               ${ROOTDIR}/out/sel4test/shodan/debug/kernel/kernel.elf
${SEL4TEST_ROOTSERVER}           ${ROOTDIR}/out/sel4test/shodan/debug/apps/sel4test-driver/sel4test-driver
${FLASH_TAR}                     out/sel4test/shodan/debug/ext_flash.tar

*** Keywords ***
Prepare Machine
    Execute Command             path set @${ROOTDIR}
    IF      ${RUN_WRAPPER} == 1
      Execute Command             $kernel=@${SEL4TEST_WRAPPER_KERNEL}
      Execute Command             $tar=@${FLASH_WRAPPER_TAR}
    ELSE
      Execute Command             $kernel=@${SEL4TEST_KERNEL}
      Execute Command             $tar=@${FLASH_TAR}
    END
    Execute Command             $cpio=@/dev/null
    Execute Command             $sc_bin=@${OUT_TMP}/matcha-tock-bundle.bin
    Execute Script              ${SCRIPT}
# Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Execute Command             cpu0 IsHalted false
    Set Default Uart Timeout    30


*** Test Cases ***
Prepare Flash Tarball
    # NB: must have at least 2x spaces between Run Process arguments!
    IF      ${RUN_WRAPPER} == 1
      Run Process               mkdir  -p  ${OUT_TMP}
      Run Process               cp  -f  ${MATCHA_BUNDLE_RELEASE}  ${OUT_TMP}/matcha-tock-bundle
      Run Process               riscv32-unknown-elf-strip  ${OUT_TMP}/matcha-tock-bundle
      Run Process               riscv32-unknown-elf-objcopy  -O  binary  -g  ${OUT_TMP}/matcha-tock-bundle  ${OUT_TMP}/matcha-tock-bundle.bin
      Run Process               ln  -sfr  ${SEL4TEST_WRAPPER_KERNEL}       ${OUT_TMP}/kernel
      Run Process               ln  -sfr  ${SEL4TEST_WRAPPER_ROOTSERVER}   ${OUT_TMP}/capdl-loader
      Run Process               tar  -C  ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_WRAPPER_TAR}  matcha-tock-bundle.bin  kernel  capdl-loader
    ELSE
      Run Process               mkdir  -p  ${OUT_TMP}
      Run Process               cp  -f  ${MATCHA_BUNDLE_RELEASE}  ${OUT_TMP}/matcha-tock-bundle
      Run Process               riscv32-unknown-elf-strip  ${OUT_TMP}/matcha-tock-bundle
      Run Process               riscv32-unknown-elf-objcopy  -O  binary  -g  ${OUT_TMP}/matcha-tock-bundle  ${OUT_TMP}/matcha-tock-bundle.bin
      Run Process               ln  -sfr  ${SEL4TEST_KERNEL}       ${OUT_TMP}/kernel
      Run Process               ln  -sfr  ${SEL4TEST_ROOTSERVER}   ${OUT_TMP}/capdl-loader
      Run Process               tar  -C  ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_TAR}  matcha-tock-bundle.bin  kernel  capdl-loader
    END
    Provides                    initialization

Shodan seL4test with Rust syscall wrappers
    [Documentation]             Test TockOS boot, seL4 boot and sel4test
    [Tags]                      tock seL4 sel4test uart
    Requires                    initialization
    Prepare Machine
    Create Log Tester           ${LOG_TIMEOUT}
    ${tockuart}=                Create Terminal Tester        ${UART0}
    ${sel4uart}=                Create Terminal Tester        ${UART5}
    Start Emulation

    Wait For Line On Uart       SEC: Booting seL4 from TockOS app done!          testerId=${tockuart}
    Wait For Line On Uart       Booting all finished, dropped to user space      testerId=${sel4uart}
    Wait For Line On Uart       MCS configuration                                testerId=${sel4uart}
    Wait For Line On Uart       Starting test suite sel4test                     testerId=${sel4uart}
    Wait For Line On Uart       Test BIND0001 passed                             testerId=${sel4uart}
    Wait For Line On Uart       Test BIND0002 passed                             testerId=${sel4uart}
    Wait For Line On Uart       Test BIND0003 passed                             testerId=${sel4uart}
    Wait For Line On Uart       Test BIND0004 passed                             testerId=${sel4uart}
    Wait For Line On Uart       Test BIND005 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test BIND006 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test CANCEL_BADGED_SENDS_0001 passed             testerId=${sel4uart}
    Wait For Line On Uart       Test CANCEL_BADGED_SENDS_0002 passed             testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0001 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0002 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0003 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0004 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0005 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0006 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0007 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CNODEOP0008 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test CSPACE0001 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test DOMAINS0001 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test DOMAINS0002 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test DOMAINS0003 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test FPU0000 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test FPU0001 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test FRAMEDIPC0001 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test FRAMEDIPC0002 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test FRAMEDIPC0003 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test FRAMEEXPORTS0001 passed                     testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0001 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0002 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0003 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0004 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0010 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0011 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0012 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0013 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0014 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0015 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0016 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0017 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0018 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0019 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0020 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0021 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0022 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0023 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0024 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0025 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0026 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC0027 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC1001 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC1002 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC1003 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPC1004 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test IPCRIGHTS0001 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test IPCRIGHTS0002 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test IPCRIGHTS0003 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test NBWAIT0001 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT0001 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT0002 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT0003 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT0004 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT1001 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT1002 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT1003 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test PAGEFAULT1004 passed                        testerId=${sel4uart}
    Wait For Line On Uart       Test REGRESSIONS0001 passed                      testerId=${sel4uart}
    Wait For Line On Uart       Test RETYPE0000 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test RETYPE0001 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test RETYPE0002 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0002 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0003 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0004 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0005 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0007 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0016 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0017 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0019 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED0020 passed                            testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED_CONTEXT_0001 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED_CONTEXT_0003 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED_CONTEXT_0006 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED_CONTEXT_0007 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SCHED_CONTEXT_0008 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLIENT_001 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLIENT_002 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLIENT_003 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLIENT_004 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLIENT_005 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLI_PROC_001 passed                 testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLI_PROC_002 passed                 testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLI_PROC_003 passed                 testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLI_PROC_004 passed                 testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_CLI_PROC_005 passed                 testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_001 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_002 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_003 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_004 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_005 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_006 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_007 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_008 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_009 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SERSERV_PARENT_010 passed                   testerId=${sel4uart}
    Wait For Line On Uart       Test SYNC001 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test SYNC002 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test SYNC003 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test SYNC004 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test THREADS0004 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test THREADS0005 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test TIMEOUTFAULT0001 passed                     testerId=${sel4uart}
    Wait For Line On Uart       Test TIMEOUTFAULT0002 passed                     testerId=${sel4uart}
    Wait For Line On Uart       Test TIMEOUTFAULT0003 passed                     testerId=${sel4uart}
    Wait For Line On Uart       Test TLS0001 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test TLS0002 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test TLS0006 passed                              testerId=${sel4uart}
    Wait For Line On Uart       Test TRIVIAL0000 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test TRIVIAL0001 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test TRIVIAL0002 passed                          testerId=${sel4uart}
    Wait For Line On Uart       Test VSPACE0000 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test VSPACE0002 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test VSPACE0003 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test VSPACE0004 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test VSPACE0005 passed                           testerId=${sel4uart}
    Wait For Line On Uart       Test VSPACE0006 passed                           testerId=${sel4uart}
#    Wait For Line On Uart       Test suite passed. 139 tests passed. 43 tests disabled.                 testerId=${sel4uart}
#    ${passed} ${disabled} = Wait For Line On Uart       Test suite passed. (\\d+) tests passed. (\\d+) tests disabled.                      testerId=${sel4uart}
    Wait For Line On Uart       All is well in the universe                      testerId=${sel4uart}
