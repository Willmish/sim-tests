
*** Settings ***
Suite Setup     Setup
Suite Teardown  Teardown
Test Setup      Reset Emulation
Library         DebugLibrary
Resource        ${RENODEKEYWORDS}

*** Variables ***
${BOOTROM_ELF}          @${PATH}/out/shodan/build-bin/sw/device/boot_rom/boot_rom_sim_verilator.elf
${SHODAN_SECURE_REPL}   @${PATH}/sim/config/shodan_secure.repl
${TOCK_TEST}            @${PATH}/out/tock/riscv32imc-unknown-none-elf/release/earlgrey-nexysvideo.elf
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

Tock Test
    Create Machine          ${TOCK_TEST}

    Create Terminal Tester  ${UART}

    Start Emulation
    Wait For Line On Uart   Boot ROM initialisation has completed, jump into flash!	timeout=1
    Wait For Line On Uart   OpenTitan initialisation complete	timeout=1
