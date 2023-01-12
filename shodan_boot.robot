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
    Set Default Uart Timeout    10
    Create Log Tester           ${LOG_TIMEOUT}

Install App
    [Arguments]                 ${app}
    # UART analyzer is marked as transient so it needs to be set up at subtest.
    Execute Command             showAnalyzer "uart5-analyzer" ${UART5} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Disable uart5 timestamp diff
    Execute Command             uart5-analyzer TimestampFormat None
    Write Line To Uart          install ${app}.app
    Wait For Line on Uart       Application "${app}" installed
    Write Line To Uart          start ${app}
    Wait For Line On Uart       Bundle "${app}" started

Uninstall App
    [Arguments]                 ${app}
    Write Line To Uart          stop ${app}
    Wait For Line On Uart       Bundle "${app}" stopped
    Write Line To Uart          uninstall ${app}
    Wait For Line On Uart       Bundle "${app}" uninstalled

*** Test Cases ***
Prepare Flash Tarball
    Run Process                 mkdir  -p    ${ROOTDIR}/out/tmp
    Run Process                 ln     -sfr  ${MATCHA_BUNDLE_RELEASE}       ${OUT_TMP}/matcha-tock-bundle
    Run Process                 ln     -sfr  ${CANTRIP_KERNEL_RELEASE}      ${OUT_TMP}/kernel
    Run Process                 ln     -sfr  ${CANTRIP_ROOTSERVER_RELEASE}  ${OUT_TMP}/capdl-loader
    Run Process                 tar    -C    ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_TAR}  matcha-tock-bundle  kernel  capdl-loader
    Provides                    flash-tarball


Test Shodan Boot
    Requires                    flash-tarball
    Prepare Machine
    Start Emulation
    Create Terminal Tester      ${UART5}
    Wait For Prompt On Uart     ${PROMPT}
    # The following commented lines would cause the test failed to be saved.
    Provides                    shodan-bootup

Test Smoke Test
    Requires                    shodan-bootup
    # UART analyzer is marked as transient so it needs to be set up at subtest.
    Execute Command             showAnalyzer "uart5-analyzer" ${UART5} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Write Line To Uart          install mobilenet_v1_emitc_static.model
    # Bundle ID needs to be retrieved at runtime
    ${l}=  Wait For Line On Uart    Model "([^"]+)" installed    treatAsRegex=true
    Write Line to Uart          test_mlexecute anything ${l.groups[0]}
    Wait For Prompt On Uart     ${PROMPT}
    Wait For LogEntry           "main returned: ", 0
    # Test timer
    Write Line To Uart          test_timer_blocking 10
    Wait For LogEntry           Timer completed.

Test C hello app (no SDK)
    Requires                    shodan-bootup
    Install App                 hello
    Wait For Line On Uart       I am a C app!
    Wait For Line On Uart       Done
    Uninstall App               hello

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
    Execute Command             showAnalyzer "uart5-analyzer" ${UART5} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Write Line To Uart          install mltest.app
    Wait For Line On Uart       Application "mltest" installed
    Write Line To Uart          install mobilenet_v1_emitc_static.model
    Wait For Line On Uart       Model "mobilenet_v1_emitc_static" installed
    Write Line to Uart          start mltest
    Wait For Line On Uart       sdk_model_oneshot(nonexistent) returned Err(SDKNoSuchModel) (as expected)
    # start oneshot
    Wait For Line On Uart       mobilenet_v1_emitc_static started
    Wait For LogEntry           "main returned: ", 0
    Wait For Line On Uart       mobilenet_v1_emitc_static completed
    # start periodic
    Wait For Line On Uart       Model mobilenet_v1_emitc_static started
    # NB: 10 runs of the model
    FOR    ${i}    IN RANGE    10
      Wait For LogEntry         "main returned: ", 0
      Wait For Line On Uart     Model completed: mask 0b0001
    END
    Wait For Line On Uart       DONE
    Write Line To Uart          stop mltest
    Wait For Line On Uart       Bundle "mltest" stopped
    Write Line To Uart          uninstall mltest
    Wait For Line On Uart       Bundle "mltest" uninstalled
    Write Line To Uart          uninstall mobilenet_v1_emitc_static
    Wait For Line On Uart       Bundle "mobilenet_v1_emitc_static" uninstalled
