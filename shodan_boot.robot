*** Comments ***
Tests for shodan system from bootup to running apps.

*** Variables ***
# This variable is set to be 0 by default, and should be override in CLI to test debug
# sim/tests/test.sh --debug sim/tests/shodan_boot.robot
${RUN_DEBUG}                     0

${WAIT_ECHO}                     true
IF      ${NO_UART_ECHO} == 1
  ${WAIT_ECHO}                   false
END

${LOG_TIMEOUT}                   2
${DEBUG_LOG_TIMEOUT}             10
${ROOTDIR}                       ${CURDIR}/../..
${SCRIPT}                        sim/config/shodan.resc
${PROMPT}                        CANTRIP>
${UART5}                         sysbus.uart5

${MATCHA_BUNDLE_RELEASE}         ${ROOTDIR}/out/matcha-bundle-release.elf
${MATCHA_BUNDLE_DEBUG}           ${ROOTDIR}/out/matcha-bundle-debug.elf

${CANTRIP_KERNEL_RELEASE}        ${ROOTDIR}/out/cantrip/riscv32-unknown-elf/release/kernel/kernel.elf
${CANTRIP_ROOTSERVER_RELEASE}    ${ROOTDIR}/out/cantrip/riscv32-unknown-elf/release/capdl-loader

${CANTRIP_KERNEL_DEBUG}          ${ROOTDIR}/out/cantrip/riscv32-unknown-elf/debug/kernel/kernel.elf
${CANTRIP_ROOTSERVER_DEBUG}      ${ROOTDIR}/out/cantrip/riscv32-unknown-elf/debug/capdl-loader

${OUT_TMP}                       ${ROOTDIR}/out/tmp

${FLASH_RELEASE_TAR}             out/ext_flash_release.tar
${CPIO_RELEASE}                  out/cantrip/riscv32-unknown-elf/release/ext_builtins.cpio
${FLASH_DEBUG_TAR}               out/ext_flash_debug.tar
${CPIO_DEBUG}                    out/cantrip/riscv32-unknown-elf/debug/ext_builtins.cpio

*** Keywords ***
Prepare Machine
    Execute Command             path set @${ROOTDIR}
    IF      ${RUN_DEBUG} == 1
      Execute Command             $tar=@${FLASH_DEBUG_TAR}
      Execute Command             $cpio=@${CPIO_DEBUG}
      Execute Command             $kernel=@${CANTRIP_KERNEL_DEBUG}
      Set Default Uart Timeout    20
      Create Log Tester           ${DEBUG_LOG_TIMEOUT}
    ELSE
      Execute Command             $tar=@${FLASH_RELEASE_TAR}
      Execute Command             $cpio=@${CPIO_RELEASE}
      Execute Command             $kernel=@${CANTRIP_KERNEL_RELEASE}
      Set Default Uart Timeout    10
      Create Log Tester           ${LOG_TIMEOUT}
    END
    Execute Script              ${SCRIPT}
    # Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Execute Command             cpu0 IsHalted false

Install App
    [Arguments]                 ${app}
    # UART analyzer is marked as transient so it needs to be set up at subtest.
    Execute Command             showAnalyzer "uart5-analyzer" ${UART5} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Disable uart5 timestamp diff
    Execute Command             uart5-analyzer TimestampFormat None
    Write Line To Uart          start ${app}          waitForEcho=${WAIT_ECHO}
    # NB: don't 'Wait For Line On Uart       Bundle "${app}" started' as this races
    #    against the app-generated output that is waited for below

Uninstall App
    [Arguments]                 ${app}
    Write Line To Uart          stop ${app}           waitForEcho=${WAIT_ECHO}
    Wait For Line On Uart       Bundle "${app}" stopped

*** Test Cases ***
Prepare Flash Tarball
    Run Process                 mkdir  -p    ${ROOTDIR}/out/tmp

    IF     ${RUN_DEBUG} == 1
      Run Process                 cp     -f  ${MATCHA_BUNDLE_DEBUG}       ${OUT_TMP}/matcha-tock-bundle-debug
      Run Process                 riscv32-unknown-elf-strip  ${OUT_TMP}/matcha-tock-bundle-debug
      Run Process                 riscv32-unknown-elf-objcopy  -O  binary  -g  ${OUT_TMP}/matcha-tock-bundle-debug  ${OUT_TMP}/matcha-tock-bundle.bin
      Run Process                 ln     -sfr  ${CANTRIP_KERNEL_DEBUG}      ${OUT_TMP}/kernel
      Run Process                 ln     -sfr  ${CANTRIP_ROOTSERVER_DEBUG}  ${OUT_TMP}/capdl-loader
      Run Process                 tar    -C    ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_DEBUG_TAR}  matcha-tock-bundle.bin  kernel  capdl-loader
    ELSE
      Run Process                 cp     -f  ${MATCHA_BUNDLE_RELEASE}       ${OUT_TMP}/matcha-tock-bundle-release
      Run Process                 riscv32-unknown-elf-strip  ${OUT_TMP}/matcha-tock-bundle-release
      Run Process                 riscv32-unknown-elf-objcopy  -O  binary  -g  ${OUT_TMP}/matcha-tock-bundle-release  ${OUT_TMP}/matcha-tock-bundle.bin
      Run Process                 ln     -sfr  ${CANTRIP_KERNEL_RELEASE}      ${OUT_TMP}/kernel
      Run Process                 ln     -sfr  ${CANTRIP_ROOTSERVER_RELEASE}  ${OUT_TMP}/capdl-loader
      Run Process                 tar    -C    ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_RELEASE_TAR}  matcha-tock-bundle.bin  kernel  capdl-loader
    END
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
    IF      ${RUN_DEBUG} == 1
      Write Line to Uart        test_mlexecute anything mobilenet_v1_emitc_static       waitForEcho=${WAIT_ECHO}
      Wait For LogEntry         "main returned: ", 0

      # Test timer
      Write Line To Uart        test_timer_blocking 10
      Wait For LogEntry         Timer completed.
    END

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
    Execute Command             showAnalyzer "uart5-analyzer" ${UART5} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Write Line to Uart          start mltest                                    waitForEcho=${WAIT_ECHO}
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
    Write Line To Uart          stop mltest                                     waitForEcho=${WAIT_ECHO}
    Wait For Line On Uart       Bundle "mltest" stopped
