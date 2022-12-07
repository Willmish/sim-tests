*** Settings ***
Suite Setup                     Setup
Suite Teardown                  Teardown
Test Setup                      Reset Emulation
Test Teardown                   Test Teardown
Resource                        ${RENODEKEYWORDS}

*** Variables ***
${LOG_TIMEOUT}                   2
${ROOTDIR}                       ${CURDIR}/../..
${SCRIPT}                        sim/config/shodan.resc
${PROMPT}                        CANTRIP>
${UART0}                         sysbus.uart0
${UART1}                         sysbus.uart1
${UART2}                         sysbus.uart2
${UART3}                         sysbus.uart3
${UART5}                         sysbus.uart5

${MATCHA_BUNDLE_RELEASE}         ${ROOTDIR}/out/matcha-bundle-release.elf
${CANTRIP_KERNEL_RELEASE}        ${ROOTDIR}/out/cantrip/riscv32-unknown-elf/release/kernel/kernel.elf
${CANTRIP_ROOTSERVER_RELEASE}    ${ROOTDIR}/out/cantrip/riscv32-unknown-elf/release/capdl-loader
${OUT_TMP}                       ${ROOTDIR}/out/tmp

${FLASH_TAR}                     out/ext_flash_release.tar
${CPIO}                          out/cantrip/riscv32-unknown-elf/release/ext_builtins.cpio

*** Keywords ***
Prepare Machine
    Execute Command             path set @${ROOTDIR}
    Execute Command             $tar=@${FLASH_TAR}
    Execute Command             $cpio=@${CPIO}
    Execute Script              ${SCRIPT}
# Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Execute Command             cpu0 IsHalted false
    Set Default Uart Timeout    300


*** Test Cases ***
Prepare Flash Tarball
    Run Process                 mkdir  -p    ${ROOTDIR}/out/tmp
    Run Process                 ln     -sfr  ${MATCHA_BUNDLE_RELEASE}       ${OUT_TMP}/matcha-tock-bundle
    Run Process                 ln     -sfr  ${CANTRIP_KERNEL_RELEASE}      ${OUT_TMP}/kernel
    Run Process                 ln     -sfr  ${CANTRIP_ROOTSERVER_RELEASE}  ${OUT_TMP}/capdl-loader
    Run Process                 tar    -C    ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_TAR}  matcha-tock-bundle  kernel  capdl-loader
    Provides                    initialization

Shodan Smoke Test
    [Documentation]             Test TockOS boot, seL4 boot and ML Execution
    [Tags]                      ml tock seL4 uart
    Requires                    initialization
    Prepare Machine
    Create Log Tester           ${LOG_TIMEOUT}
    ${tockuart}=                Create Terminal Tester        ${UART0}
    ${sel4uart}=                Create Terminal Tester        ${UART5}
    Start Emulation

    Wait For Line On Uart       load_sel4() completed successfully               testerId=${tockuart}
    Wait For Line On Uart       Booting all finished, dropped to user space      testerId=${sel4uart}
    Wait For Prompt On Uart     ${PROMPT}                                        testerId=${sel4uart}
    Write Line To Uart          install mobilenet_v1_emitc_static.model          testerId=${sel4uart}
# Bundle ID needs to be retrieved at runtime
    ${l}=  Wait For Line On Uart    Model "([^"]+)" installed                    testerId=${sel4uart}  treatAsRegex=true
    Write Line to Uart          test_mlexecute anything ${l.groups[0]}           testerId=${sel4uart}
    Wait For Prompt On Uart     ${PROMPT}                                        testerId=${sel4uart}
    Wait For LogEntry           "main returned: ", 0
# Test timer
    Write Line To Uart          test_timer_blocking 10      testerId=${sel4uart}
    Wait For LogEntry           Timer completed.
