*** Keywords ***
Prepare Machine
    Execute Command             path set @${ROOTDIR}
    Execute Command             $tar=@${FLASH_TAR}
    Execute Command             $cpio=@${CPIO}
    Execute Command             $kernel=@${CANTRIP_KERNEL}
    Execute Command             $repl_file=@sim/config/platforms/${PLATFORM}-${BUILD_TYPE}.repl
    Execute Command             $sc_bin=@${CANTRIP_OUTDIR}/tmp/matcha-tock-bundle.bin
    Set Default Uart Timeout    20
    Create Log Tester           ${LOG_TIMEOUT}
    Execute Script              ${SCRIPT}
    Execute Command             showAnalyzer "smc-uart-analyzer" ${SMC_UART} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Add SMC_UART virtual time so we can check the machine execution time
    Execute Command             smc-uart-analyzer TimestampFormat Virtual
    Execute Command             cpu0 IsHalted false

Install App
    [Arguments]                 ${app}
    # UART analyzer is marked as transient so it needs to be set up at subtest.
    Execute Command             showAnalyzer "smc-uart-analyzer" ${SMC_UART} Antmicro.Renode.Analyzers.LoggingUartAnalyzer
    # Disable uart5 timestamp diff
    Execute Command             smc-uart-analyzer TimestampFormat None
    Write Line To Uart          start ${app}          waitForEcho=${WAIT_ECHO}
    # NB: don't 'Wait For Line On Uart       Bundle "${app}" started' as this races
    #    against the app-generated output that is waited for below

Uninstall App
    [Arguments]                 ${app}
    Write Line To Uart          stop ${app}           waitForEcho=${WAIT_ECHO}
    Wait For Line On Uart       Bundle "${app}" stopped

Stop App
    [Arguments]                 ${app}
    Write Line To Uart          stop ${app}
    Wait For Line On Uart       Bundle "${app}" stopped

