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
${PROMPT}                        KATA>
${UART0}                         sysbus.uart0
${UART1}                         sysbus.uart1
${UART2}                         sysbus.uart2
${UART3}                         sysbus.uart3
${UART5}                         sysbus.uart5

*** Keywords ***
Prepare Machine
    Execute Command             path set ${ROOTDIR}
    Execute Script              ${SCRIPT}
    Execute Command             cpu0 IsHalted false
    Set Default Uart Timeout    300


*** Test Cases ***
Shodan Smoke Test
    [Documentation]             Test TockOS boot, seL4 boot and ML Execution
    [Tags]                      ml tock seL4 uart
    Prepare Machine
    Create Log Tester           ${LOG_TIMEOUT}
    ${tockuart}=                Create Terminal Tester        ${UART0}
    ${sel4uart}=                Create Terminal Tester        ${UART5}
    Start Emulation

    Wait For Line On Uart       load_sel4() completed successfully               testerId=${tockuart}
    Wait For Line On Uart       Booting all finished, dropped to user space      testerId=${sel4uart}
    Wait For Prompt On Uart     ${PROMPT}                                        testerId=${sel4uart}
    Write Line To Uart          install mobilenet_v1_emitc_static.model          testerId=${sel4uart}
    Wait For Prompt On Uart     Bundle "fake.26" installed                       testerId=${sel4uart}
    Write Line to Uart          test_mlexecute fake.26 mobilenet_v1_emitc_static.model  testerId=${sel4uart}
    Wait For Prompt On Uart     ${PROMPT}                                             testerId=${sel4uart}
    Wait For LogEntry           "main returned: ", 0
    Write Line To Uart          test_timer_blocking 10      testerId=${sel4uart}
    Wait For LogEntry           Timer completed.
