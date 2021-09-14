*** Settings ***
Suite Setup                     Setup
Suite Teardown                  Teardown
Test Setup                      Reset Emulation
Test Teardown                   Test Teardown
Resource                        ${RENODEKEYWORDS}

*** Variables ***
${LOG_TIMEOUT}                   1
${ROOTDIR}                       @${CURDIR}/../..
${SCRIPT}                        sim/config/shodan_all.resc
${PROMPT}                        KATA>
${UART0}                         sysbus.uart0
${UART1}                         sysbus.uart1
${UART2}                         sysbus.uart2
${UART3}                         sysbus.uart3

*** Keywords ***
Prepare Machine
    Execute Command             path set ${ROOTDIR}
    Execute Script              ${SCRIPT}
    Execute Command             cpu0 IsHalted false
    Execute Command             cpu1 IsHalted false
    Set Default Uart Timeout    300


*** Test Cases ***
Shodan Smoke Test
    [Documentation]             Test TockOS boot, seL4 boot and ML Execution
    [Tags]                      ml tock seL4 uart
    Prepare Machine
    Create Log Tester           ${LOG_TIMEOUT}
    ${tockuart}=                Create Terminal Tester        ${UART0}
    ${sel4uart}=                Create Terminal Tester        ${UART1}
    Start Emulation

    Wait For Line On Uart       OpenTitan initialisation complete.               testerId=${tockuart}
    Wait For Line On Uart       Booting all finished, dropped to user space      testerId=${sel4uart}
    Wait For Prompt On Uart     ${PROMPT}           testerId=${sel4uart}
    Write Line To Uart          test_mlexecute      testerId=${sel4uart}
    Wait For Prompt On Uart     ${PROMPT}           testerId=${sel4uart}
    Wait For LogEntry           "main returned: ", 0
