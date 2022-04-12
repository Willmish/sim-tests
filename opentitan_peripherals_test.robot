*** Settings ***
Suite Setup                     Setup
Suite Teardown                  Teardown
Test Setup                      Reset Emulation
Test Teardown                   Test Teardown
Resource                        ${RENODEKEYWORDS}

*** Variables ***
${UART}                         sysbus.uart0
${ROOTDIR}                      @${CURDIR}/../..
${AES_BIN}                      ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/aes_smoketest_fpga_nexysvideo.elf
${UART_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/uart_smoketest_fpga_nexysvideo.elf
${HMAC_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/hmac_smoketest_fpga_nexysvideo.elf
${KMAC_BIN}                     ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/kmac_smoketest_fpga_nexysvideo.elf
${KMAC_CSHAKE_BIN}              ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/kmac_mode_cshake_test_fpga_nexysvideo.elf
${KMAC_KMAC_BIN}                ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/kmac_mode_kmac_test_fpga_nexysvideo.elf
${FLASH_CTRL_BIN}               ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/flash_ctrl_test_fpga_nexysvideo.elf
${BOOT_ROM_BIN}                 ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/boot_rom/boot_rom_fpga_nexysvideo.elf
${BOOT_ROM_SCR_VMEM}            ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/boot_rom/boot_rom_fpga_nexysvideo.scr.39.vmem
${TIMER_BIN}                    ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/rv_timer_smoketest_fpga_nexysvideo.elf
${RESET_BIN}                    ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/rstmgr_smoketest_fpga_nexysvideo.elf
${SW_RESET_BIN}                 ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/tests/rstmgr_sw_req_test_fpga_nexysvideo.elf
${HELLO_WORLD_BIN}              ${ROOTDIR}/out/opentitan/sw/build-out/sw/device/examples/hello_world/hello_world_fpga_nexysvideo.elf

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

*** Keywords ***
Setup Machine
    Execute Command             mach create
    Execute Command             machine LoadPlatformDescription ${ROOTDIR}/sim/tests/opentitan-earlgrey-gen.repl
    Execute Command             showAnalyzer ${UART}
    Execute Command             machine LoadPlatformDescriptionFromString ${LEDS}
    Execute Command             sysbus LoadELF ${BOOT_ROM_BIN}
    Execute Command             sysbus LoadELF ${HELLO_WORLD_BIN}
    Execute Command             sysbus.cpu0 PC 0x00008084

    Create Terminal Tester      ${UART}
    Set Default Uart Timeout    1

Setup Machine Without Boot ROM
    Execute Command             mach create
    Execute Command             machine LoadPlatformDescription ${ROOTDIR}/sim/tests/opentitan-earlgrey-gen.repl
    Execute Command             showAnalyzer ${UART}
    Execute Command             machine LoadPlatformDescriptionFromString ${LEDS}
    Execute Command             sysbus LoadELF $bin

    Create Terminal Tester      ${UART}
    Set Default Uart Timeout    1

Load Scrambled Boot ROM Vmem
    Execute Command             sysbus.rom_ctrl LoadVmem ${BOOT_ROM_SCR_VMEM}
    Execute Command             sysbus.cpu0 PC 0x00008084

Run Smoketest
    [Arguments]                 ${bin}
    Execute Command             $bin=${bin}
    Setup Machine
    Execute Command             sysbus LoadELF $bin
    Start Emulation

    Wait For Line On UART       PASS

Run Smoketest With Scrambled Boot ROM Vmem
    [Arguments]                 ${bin}
    Execute Command             $bin=${bin}
    Setup Machine Without Boot ROM
    Load Scrambled Boot ROM Vmem
    Start Emulation

    Wait For Line On UART       PASS

*** Test Cases ***
Should Print To Uart
    Setup Machine
    Start Emulation

    Wait For Line On Uart       The LEDs show the ASCII code of the last character.

    Provides                    initialization

Should Echo On Uart
    Requires                    initialization

    Write Line To Uart          Testing testing 1-2-3

    Provides                    working-uart

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
    Run Smoketest               ${AES_BIN}

Should Pass UART Smoketest
    Run Smoketest               ${UART_BIN}

Should Pass HMAC Smoketest
    Run Smoketest               ${HMAC_BIN}

Should Pass Flash Smoketest
    Run Smoketest               ${FLASH_CTRL_BIN}

Should Pass Timer Smoketest
    Run Smoketest               ${TIMER_BIN}

Should Pass KMAC Smoketest
    Run Smoketest               ${KMAC_BIN}

Should Pass KMAC CSHAKE Mode
    Run Smoketest               ${KMAC_CSHAKE_BIN}

Should Pass KMAC KMAC Mode
    Run Smoketest               ${KMAC_KMAC_BIN}

Should Pass Reset Smoketest
    Run Smoketest               ${RESET_BIN}

Should Pass Software Reset Test
    Run Smoketest               ${SW_RESET_BIN}

Should Pass AES Smoketest With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${AES_BIN}

Should Pass UART Smoketest With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${UART_BIN}

Should Pass HMAC Smoketest With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${HMAC_BIN}

Should Pass Flash Smoketest With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${FLASH_CTRL_BIN}

Should Pass KMAC Smoketest With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${KMAC_BIN}

Should Pass KMAC CSHAKE Mode With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${KMAC_CSHAKE_BIN}

Should Pass KMAC KMAC Mode With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${KMAC_KMAC_BIN}

Should Pass Reset Smoketest With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${RESET_BIN}

Should Pass Software Reset Test With Scrambled Boot ROM Vmem
    Run Smoketest With Scrambled Boot ROM Vmem      ${SW_RESET_BIN}
