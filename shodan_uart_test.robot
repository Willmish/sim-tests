
*** Settings ***
Suite Setup     Setup
Suite Teardown  Teardown
Test Setup      Reset Emulation
Resource        ${RENODEKEYWORDS}

*** Test Cases ***
Should Boot from BootROM
    Execute Command     mach create
    Execute Command     machine LoadPlatformDescription @${PATH}/sim/config/shodan_secure.repl
    Execute Command     sysbus LoadELF @${PATH}/out/opentitan/build-bin/sw/device/boot_rom/boot_rom_sim_verilator.elf
    Execute Command     sysbus LoadELF @${PATH}/out/opentitan/build-out/sw/device/tests/dif_uart_sanitytest_sim_verilator.elf
    Execute Command     sysbus.cpu_0 PC 0x8084

    Create Terminal Tester  sysbus.uart

    Start Emulation

    Wait For Line On Uart   Boot ROM initialisation has completed, jump into flash!


