*** Comments ***
Tests for OpenTitan built at hw/opentitan-upstream
*** Settings ***
Suite Setup                     Setup
Suite Teardown                  Teardown
Test Setup                      Reset Emulation
Test Teardown                   Test Teardown
Resource                        ${RENODEKEYWORDS}

*** Variables ***
${UART}                         sysbus.uart0
${SHODAN_DIR}                   ${CURDIR}/../..
${ROOTDIR}                      @${SHODAN_DIR}
${AES_BIN}                      ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/aes_smoketest_prog_fpga_cw310
${CSRNG_BIN}                    ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/csrng_smoketest_prog_fpga_cw310
${FLASH_CTRL_BIN}               ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/flash_ctrl_test_prog_fpga_cw310
${GPIO_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/gpio_smoketest_prog_fpga_cw310
${HMAC_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/hmac_smoketest_prog_fpga_cw310
${KMAC_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/kmac_smoketest_prog_fpga_cw310
${KMAC_CSHAKE_BIN}              ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/kmac_mode_cshake_test_prog_fpga_cw310
${KMAC_KMAC_BIN}                ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/kmac_mode_kmac_test_prog_fpga_cw310
${LC_OTP_CFG}                   ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/lc_ctrl_otp_hw_cfg_test_prog_fpga_cw310
${RESET_BIN}                    ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/rstmgr_smoketest_prog_fpga_cw310
${SW_RESET_BIN}                 ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/rstmgr_sw_req_test_prog_fpga_cw310
${TEST_ROM_SCR_VMEM}            ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/boot_rom/test_rom_fpga_cw310.scr.39.vmem
${TIMER_BIN}                    ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/rv_timer_smoketest_prog_fpga_cw310
${UART_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/uart_smoketest_prog_fpga_cw310
${ALERT_HANDLER}                ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/alert_renode_test_prog_fpga_cw310
${ALERT_HANDLER_PING}           ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/alert_handler_ping_timeout_test_prog_fpga_cw310
${SPI_HOST}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/spi_host_smoketest_prog_fpga_cw310
${AON_TIMER_IRQ_BIN}            ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/aon_timer_irq_test_prog_fpga_cw310
${AON_TIMER_WDOG_SLEEP_BIN}     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/aon_timer_sleep_wdog_sleep_pause_test_prog_fpga_cw310
${AON_TIMER_BIN}                ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/aon_timer_smoketest_prog_fpga_cw310
${AON_TIMER_WDOG_BITE_BIN}      ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/aon_timer_wdog_bite_reset_test_prog_fpga_cw310

${HELLO_WORLD_BIN}              ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/examples/hello_world/hello_world_fpga_cw310.elf

${OTP_IMG_SCRIPT}               ${SHODAN_DIR}/hw/opentitan-upstream/util/design/gen-otp-img.py
${OTP_IMG_CFG}                  ${SHODAN_DIR}/sim/tests/otp_ctrl_img_smoketest.hjson
${OTP_VMEM}                     ${SHODAN_DIR}/out/opentitan/sw/build-out/sw/device/otp_img/otp_img_smoketest.vmem

${LEDS}=    SEPARATOR=
...  """                                     ${\n}
...  gpio:                                   ${\n}
...  ${SPACE*4}8 -> led0@0                   ${\n}
...  ${SPACE*4}9 -> led1@0                   ${\n}
...  ${SPACE*4}10 -> led2@0                  ${\n}
...  ${SPACE*4}11 -> led3@0                  ${\n}
...  ${SPACE*4}12 -> led4@0                  ${\n}
...  ${SPACE*4}13 -> led5@0                  ${\n}
...  ${SPACE*4}14 -> led6@0                  ${\n}
...  ${SPACE*4}15 -> led7@0                  ${\n}
...                                          ${\n}
...  led0: Miscellaneous.LED @ gpio 8        ${\n}
...  led1: Miscellaneous.LED @ gpio 9        ${\n}
...  led2: Miscellaneous.LED @ gpio 10       ${\n}
...  led3: Miscellaneous.LED @ gpio 11       ${\n}
...  led4: Miscellaneous.LED @ gpio 12       ${\n}
...  led5: Miscellaneous.LED @ gpio 13       ${\n}
...  led6: Miscellaneous.LED @ gpio 14       ${\n}
...  led7: Miscellaneous.LED @ gpio 15       ${\n}
...  """

${SPI_FLASH}=    SEPARATOR=
...  """                                     ${\n}
...  spi_flash: Memory.MappedMemory          ${\n}
...  ${SPACE*4}size: 0x1000000               ${\n}
...                                          ${\n}
...  mt25q: SPI.Micron_MT25Q @ spi_host0 0   ${\n}
...  ${SPACE*4}underlyingMemory: spi_flash   ${\n}
...  """

*** Keywords ***
Setup Machine
    Execute Command             path set ${ROOTDIR}
    Execute Command             using sysbus
    Execute Command             mach create "EarlGrey"
    Execute Command             include @sim/config/shodan_infrastructure/AddressRangeStub.cs
    Execute Command             machine LoadPlatformDescription @sim/config/platforms/opentitan-earlgrey-cw310.repl
    Execute Command             showAnalyzer ${UART}
    Execute Command             sysbus SilenceRange <0x40050000 0x2000>
    Execute Command             machine LoadPlatformDescriptionFromString ${LEDS}
    Execute Command             machine LoadPlatformDescriptionFromString ${SPI_FLASH}
    Execute Command             sysbus.otp_ctrl LoadVmem @${OTP_VMEM}
    Execute Command             rom_ctrl LoadVmem ${TEST_ROM_SCR_VMEM}

    Set Default Uart Timeout    1
    Create Terminal Tester      ${UART}

Run Test
    [Arguments]                 ${bin}
    Execute Command             $bin=${bin}
    Setup Machine
    Execute Command             sysbus LoadELF $bin
    Execute Command             cpu0 PC 0x00008084
    Start Emulation

    Wait For Line On UART       PASS

*** Test Cases ***

Build OTP Image
    Run Process                 python3  ${OTP_IMG_SCRIPT}  --img-cfg  ${OTP_IMG_CFG}  --out   ${OTP_VMEM}

Should Print To Uart
    Setup Machine
    Execute Command             sysbus LoadELF ${HELLO_WORLD_BIN}
    Execute Command             cpu0 PC 0x00008084
    Start Emulation

    Wait For Line On Uart       The LEDs show the ASCII code of the last character.

    Provides                    initialization

Should Echo On Uart
    Requires                    initialization

    Write Line To Uart          Testing testing 1-2-3

    Provides                    working-uart

# This test is can only work with hello-world patched with LED fix.
# Output pins are configured to 0x00FF: https://github.com/lowRISC/opentitan/blob/1e86ba2a238dc26c2111d325ee7645b0e65058e5/sw/device/examples/hello_world/hello_world.c#L66 ,
# while chars are outputed to 0xFF00: https://github.com/lowRISC/opentitan/blob/1e86ba2a238dc26c2111d325ee7645b0e65058e5/sw/device/examples/demos.c#L88
Should Display Output on GPIO
    Requires                    working-uart

    Execute Command             emulation CreateLEDTester "led0" sysbus.gpio.led0
    Execute Command             emulation CreateLEDTester "led1" sysbus.gpio.led1
    Execute Command             emulation CreateLEDTester "led2" sysbus.gpio.led2
    Execute Command             emulation CreateLEDTester "led3" sysbus.gpio.led3

    Execute Command             emulation CreateLEDTester "led4" sysbus.gpio.led4
    Execute Command             emulation CreateLEDTester "led5" sysbus.gpio.led5
    Execute Command             emulation CreateLEDTester "led6" sysbus.gpio.led6
    Execute Command             emulation CreateLEDTester "led7" sysbus.gpio.led7

    Send Key To Uart            0x0

    Execute Command             led0 AssertState false 0.2
    Execute Command             led1 AssertState false 0.2
    Execute Command             led2 AssertState false 0.2
    Execute Command             led3 AssertState false 0.2

    Execute Command             led4 AssertState false 0.2
    Execute Command             led5 AssertState false 0.2
    Execute Command             led6 AssertState false 0.2
    Execute Command             led7 AssertState false 0.2

    Write Char On Uart          B
    # B is 0100 0010

    Execute Command             led0 AssertState false 0.2
    Execute Command             led1 AssertState true 0.2
    Execute Command             led2 AssertState false 0.2
    Execute Command             led3 AssertState false 0.2

    Execute Command             led4 AssertState false 0.2
    Execute Command             led5 AssertState false 0.2
    Execute Command             led6 AssertState true 0.2
    Execute Command             led7 AssertState false 0.2

Should Pass AES Smoketest
    Run Test               ${AES_BIN}

Should Pass UART Smoketest
    Run Test               ${UART_BIN}

Should Pass HMAC Smoketest
    Run Test               ${HMAC_BIN}

Should Pass Flash Smoketest
    Run Test               ${FLASH_CTRL_BIN}

Should Pass Timer Smoketest
    Run Test               ${TIMER_BIN}

Should Pass KMAC Smoketest
    Run Test               ${KMAC_BIN}

Should Pass KMAC CSHAKE Mode
    Run Test               ${KMAC_CSHAKE_BIN}

Should Pass KMAC KMAC Mode
    Run Test               ${KMAC_KMAC_BIN}

Should Pass Reset Smoketest
    Run Test               ${RESET_BIN}

Should Pass Software Reset Test
    Run Test               ${SW_RESET_BIN}

Should Pass Life Cycle Smoketest
    Run Test               ${LC_OTP_CFG}

Should Pass CSRNG Smoketest
    Run Test               ${CSRNG_BIN}

Should Pass GPIO Smoketest
    Run Test               ${GPIO_BIN}

Should Pass Alert Handler Smoketest
    Run Test               ${ALERT_HANDLER}

Should Pass Alert Handler Ping Smoketest
    Run Test               ${ALERT_HANDLER_PING}

Should Pass SPI Host Smoketest
    Run Test               ${SPI_HOST}

Should Pass Aon Timer Interrupt Smoketest
    Run Test               ${AON_TIMER_IRQ_BIN}

Should Pass Aon Timer Watchdog Sleep Pause Smoketest
    Run Test               ${AON_TIMER_WDOG_SLEEP_BIN}

Should Pass Aon Timer Smoketest
    Run Test               ${AON_TIMER_BIN}

Should Pass Aon Timer Watchdog Bite Reset Smoketest
    Run Test               ${AON_TIMER_WDOG_BITE_BIN}
