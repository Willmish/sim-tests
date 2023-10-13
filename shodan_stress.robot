*** Comments ***
Stress test for shodan system.

*** Variables ***
${MAX_ITER}                      100

${LOG_TIMEOUT}                   2
${FPGA_UART_TIMEOUT}             60
${ROOTDIR}                       ${CURDIR}/../..
${SCRIPT}                        sim/config/shodan.resc
${PROMPT}                        CANTRIP>
${UART5}                         sysbus.uart5

${MATCHA_BUNDLE_RELEASE}         ${ROOTDIR}/out/matcha-bundle-release.elf
${CANTRIP_KERNEL_RELEASE}        ${ROOTDIR}/out/cantrip/shodan/release/kernel/kernel.elf
${CANTRIP_ROOTSERVER_RELEASE}    ${ROOTDIR}/out/cantrip/shodan/release/capdl-loader

${OUT_TMP}                       ${ROOTDIR}/out/tmp

${FLASH_RELEASE_TAR}             out/cantrip/shodan/release/ext_flash.tar
${CPIO_RELEASE}                  out/cantrip/shodan/release/ext_builtins.cpio

*** Keywords ***
Prepare Machine
    Execute Command             path set @${ROOTDIR}
    Execute Command             $tar=@${FLASH_RELEASE_TAR}
    Execute Command             $cpio=@${CPIO_RELEASE}
    Execute Command             $kernel=@${CANTRIP_KERNEL_RELEASE}
    Execute Command             $sc_bin=@${OUT_TMP}/matcha-tock-bundle.bin
    Set Default Uart Timeout    10
    Create Log Tester           ${LOG_TIMEOUT}
    Execute Script              ${SCRIPT}
    # Add UART5 virtual time so we can check the machine execution time
    Execute Command             uart5-analyzer TimestampFormat Virtual
    Execute Command             cpu0 IsHalted false

Stop App
    [Arguments]                 ${app}
    Write Line To Uart          stop ${app}
    Wait For Line On Uart       Bundle "${app}" stopped

*** Test Cases ***
    # NB: must have at least 2x spaces between Run Process arguments!
Prepare Flash Tarball
    Run Process                 mkdir  -p    ${OUT_TMP}
    Run Process                 cp     -f  ${MATCHA_BUNDLE_RELEASE}       ${OUT_TMP}/matcha-tock-bundle-release
    Run Process                 riscv32-unknown-elf-strip  ${OUT_TMP}/matcha-tock-bundle-release
    Run Process                 riscv32-unknown-elf-objcopy  -O  binary  -g  ${OUT_TMP}/matcha-tock-bundle-release  ${OUT_TMP}/matcha-tock-bundle.bin
    Run Process                 ln     -sfr  ${CANTRIP_KERNEL_RELEASE}      ${OUT_TMP}/kernel
    Run Process                 ln     -sfr  ${CANTRIP_ROOTSERVER_RELEASE}  ${OUT_TMP}/capdl-loader
    Run Process                 tar    -C    ${OUT_TMP}  -cvhf  ${ROOTDIR}/${FLASH_RELEASE_TAR}  matcha-tock-bundle.bin  kernel  capdl-loader
    Provides                    flash-tarball

Test Shodan Boot
    Requires                    flash-tarball
    Prepare Machine
    Start Emulation
    Create Terminal Tester      ${UART5}
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
