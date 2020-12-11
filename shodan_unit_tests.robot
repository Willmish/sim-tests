
*** Settings ***
Suite Setup     Setup
Suite Teardown  Teardown
Test Setup      Reset Emulation
Library         DebugLibrary
Resource        ${RENODEKEYWORDS}

*** Variables ***
${BOOTROM_ELF}          @${PATH}/out/shodan/build-bin/sw/device/boot_rom/boot_rom_sim_verilator.elf
${SHODAN_SECURE_REPL}   @${PATH}/sim/config/shodan_secure.repl
${UART_SANITY_TEST}     @${PATH}/out/shodan/build-out/sw_shodan/device/tests/dif_uart_sanitytest_sim_verilator.elf
${UART_TX_RX_TEST}      @${PATH}/out/shodan/build-out/sw_shodan/device/tests/uart_tx_rx_test_sim_verilator.elf
${PLIC_SANITY_TEST}     @${PATH}/out/shodan/build-out/sw_shodan/device/tests/dif_plic_sanitytest_sim_verilator.elf
${UART}                 sysbus.uart

*** Keywords ***
Create Machine
    [Arguments]  ${elf}

    Execute Command     mach create
    Execute Command     machine LoadPlatformDescription @${SHODAN_SECURE_REPL}
    Execute Command     sysbus LoadELF @${BOOTROM_ELF}
    Execute Command     sysbus LoadELF @${elf}
    Execute Command     sysbus.cpu_0 PC 0x8084


*** Test Cases ***

UART Sanity Test
    Create Machine          ${UART_SANITY_TEST}

    Create Terminal Tester  ${UART}

    Start Emulation
    Wait For Line On Uart   Boot ROM initialisation has completed, jump into flash!	timeout=1
    Wait For Line On Uart   PASS!	timeout=1


UART TX RX Test
    Create Machine          ${UART_TX_RX_TEST}

    Create Terminal Tester  ${UART}

    Start Emulation

    Wait For Line On Uart   Boot ROM initialisation has completed, jump into flash!	timeout=1
    Wait For Line On Uart   UART TX RX test	timeout=1
    Wait For Line On Uart   Initializing the UART	timeout=1
    Wait For Line on Uart   Initializing the PLIC	timeout=1
    Wait For Line on Uart   Executing the test.		timeout=1

PLIC Sanity Test
    Create Machine          ${PLIC_SANITY_TEST}

    Create Terminal Tester  ${UART}

    Start Emulation
    Wait For Line On Uart   Boot ROM initialisation has completed, jump into flash!	timeout=1
    Wait For Line On Uart   PASS!	timeout=1
