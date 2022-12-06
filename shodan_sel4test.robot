# m sel4test+wrapper robot script; expects/runs pre-built artifacts
# Takes ~15 mins (wall time) on a cloudtop
# TODO: need build target to just build artifacts

*** Settings ***
Suite Setup                     Setup
Suite Teardown                  Teardown
Test Setup                      Reset Emulation
Test Teardown                   Test Teardown
Resource                        ${RENODEKEYWORDS}

*** Variables ***
${LOG_TIMEOUT}                   2
${ROOTDIR}                       @${CURDIR}/../..
${SCRIPT}                        sim/config/shodan.resc
${UART0}                         sysbus.uart0
${UART1}                         sysbus.uart1
${UART2}                         sysbus.uart2
${UART3}                         sysbus.uart3
${UART5}                         sysbus.uart5

*** Keywords ***
Prepare Machine
    Execute Command             path set ${ROOTDIR}
    Execute Command             $tar=@out/sel4test-wrapper/riscv32-unknown-elf/release/ext_flash.tar
    Execute Command             $kernel=@out/sel4test-wrapper/riscv32-unknown-elf/release/kernel/kernel.elf
    Execute Command             $cpio=@/dev/null
    Execute Script              ${SCRIPT}
# Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Execute Command             cpu0 IsHalted false
    Set Default Uart Timeout    30


*** Test Cases ***
Shodan seL4test with Rust syscall wrappers
    [Documentation]             Test TockOS boot, seL4 boot and sel4test
    [Tags]                      tock seL4 sel4test uart
    Prepare Machine
    Create Log Tester           ${LOG_TIMEOUT}
    ${tockuart}=                Create Terminal Tester        ${UART0}
    ${sel4uart}=                Create Terminal Tester        ${UART5}
    Start Emulation

    Wait For Line On Uart       load_sel4() completed successfully               testerId=${tockuart}
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
